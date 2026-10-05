import { describe, expect, it } from "vitest";
import { createTestApp } from "../helpers/app.js";
import {
	BRACELET_UID,
	checkin,
	createMenuItem,
	createSessionGroup,
	placeOrder,
	registerBracelet,
} from "../helpers/factories.js";

const app = await createTestApp();

describe("POST /sessions/checkin/group", () => {
	it("cria um grupo com o responsável", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin/group",
			payload: {
				responsibleCpf: "12345678901",
				responsiblePhoneNumber: "11999999999",
			},
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().sessionGroup).toEqual({
			id: expect.any(String),
			responsibleCpf: "12345678901",
			responsiblePhoneNumber: "11999999999",
		});
	});

	it("não cria um grupo com CPF inválido", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin/group",
			payload: { responsibleCpf: "123", responsiblePhoneNumber: "11999999999" },
		});

		expect(response.statusCode).toBe(400);
	});
});

describe("POST /sessions/checkin", () => {
	it("abre uma sessão para uma pulseira cadastrada", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: BRACELET_UID,
				sessionGroupId: await createSessionGroup(app),
			},
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().session).toMatchObject({
			braceletId: BRACELET_UID,
			status: "OPEN",
			total: "0",
			sessionType: "NORMAL",
			checkoutDate: null,
		});
	});

	it("abre uma sessão do tipo KID", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: BRACELET_UID,
				sessionGroupId: await createSessionGroup(app),
				sessionType: "KID",
			},
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().session.sessionType).toBe("KID");
	});

	it("não permite check-in de pulseira não cadastrada", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: BRACELET_UID,
				sessionGroupId: await createSessionGroup(app),
			},
		});

		expect(response.statusCode).toBe(404);
	});

	it("não permite check-in em um grupo inexistente", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: BRACELET_UID,
				sessionGroupId: "grupo-inexistente",
			},
		});

		expect(response.statusCode).toBe(404);
	});

	it("não permite duas sessões ativas na mesma pulseira", async () => {
		await checkin(app);

		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: BRACELET_UID,
				sessionGroupId: await createSessionGroup(app),
			},
		});

		expect(response.statusCode).toBe(409);
	});

	it("permite um novo check-in depois que a sessão é encerrada", async () => {
		await checkin(app);
		await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/close`,
		});

		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: BRACELET_UID,
				sessionGroupId: await createSessionGroup(app),
			},
		});

		expect(response.statusCode).toBe(200);
	});
});

describe("POST /sessions/:braceletId/close", () => {
	it("encerra a sessão ativa da pulseira", async () => {
		await checkin(app);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/close`,
		});
		expect(response.statusCode).toBe(200);

		const secondClose = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/close`,
		});
		expect(secondClose.statusCode).toBe(404);
	});

	it("retorna 404 quando a pulseira não tem sessão ativa", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/close`,
		});

		expect(response.statusCode).toBe(404);
	});

	it("não permite encerrar sessão de pulseira não cadastrada", async () => {
		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/close`,
		});

		expect(response.statusCode).toBe(404);
	});
});

describe("POST /sessions/:braceletId/exit", () => {
	it("libera a saída de pulseira sem sessão ativa", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
		});

		expect(response.statusCode).toBe(200);
		expect(response.json()).toEqual({ message: "Exit authorized" });
	});

	it("libera a saída de sessão sem consumo e encerra a sessão", async () => {
		await checkin(app);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
		});
		expect(response.statusCode).toBe(200);

		const closeResponse = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/close`,
		});
		expect(closeResponse.statusCode).toBe(404);
	});

	it("bloqueia a saída de sessão com consumo pendente e mantém a sessão aberta", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app, { price: "10.50" });
		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: menuItem.id, amount: 1 },
		]);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
		});
		expect(response.statusCode).toBe(409);
		expect(response.json()).toEqual({
			message: "Session has a pending balance of 10.50",
		});

		const closeResponse = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/close`,
		});
		expect(closeResponse.statusCode).toBe(200);
	});

	it("não libera a saída de pulseira não cadastrada", async () => {
		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
		});

		expect(response.statusCode).toBe(404);
	});
});
