import { describe, expect, it } from "vitest";
import { prisma } from "@/lib/prisma.js";
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

	it("permite um novo check-in depois da saída", async () => {
		await checkin(app);
		await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
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

function findSession() {
	return prisma.sessions.findFirstOrThrow({
		where: { braceletId: BRACELET_UID },
		orderBy: { checkinDate: "desc" },
	});
}

describe("POST /sessions/:braceletId/pay", () => {
	it("zera o saldo e mantém a sessão aberta", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app, { price: "10.50" });
		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: menuItem.id, amount: 2 },
		]);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/pay`,
		});

		expect(response.statusCode).toBe(200);
		expect(response.json()).toEqual({
			paidAmount: "21.00",
			message: "Session successfully paid",
		});

		const session = await findSession();
		expect(session.total.toString()).toBe("0");
		expect(session.status).toBe("OPEN");
		expect(session.checkoutDate).toBeNull();
	});

	it("permite novos pedidos depois de pagar, que voltam a ser cobrados", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app, { price: "10.50" });
		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: menuItem.id, amount: 1 },
		]);
		await app.inject({ method: "POST", url: `/sessions/${BRACELET_UID}/pay` });

		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: menuItem.id, amount: 1 },
		]);

		const session = await findSession();
		expect(session.total.toString()).toBe("10.5");
	});

	it("não permite pagar uma sessão sem saldo pendente", async () => {
		await checkin(app);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/pay`,
		});

		expect(response.statusCode).toBe(409);
		expect(response.json()).toEqual({
			message: "Session has no pending balance",
		});
	});

	it("retorna 404 quando a pulseira não tem sessão ativa", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/pay`,
		});

		expect(response.statusCode).toBe(404);
	});

	it("não permite pagar sessão de pulseira não cadastrada", async () => {
		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/pay`,
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

		const session = await findSession();
		expect(session.status).toBe("CLOSED");
		expect(session.checkoutDate).toBeInstanceOf(Date);
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

		const session = await findSession();
		expect(session.status).toBe("OPEN");
	});

	it("libera a saída depois que a sessão é paga", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app, { price: "10.50" });
		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: menuItem.id, amount: 1 },
		]);
		await app.inject({ method: "POST", url: `/sessions/${BRACELET_UID}/pay` });

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
		});

		expect(response.statusCode).toBe(200);
		expect((await findSession()).status).toBe("CLOSED");
	});

	it("não libera a saída de pulseira não cadastrada", async () => {
		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
		});

		expect(response.statusCode).toBe(404);
	});
});
