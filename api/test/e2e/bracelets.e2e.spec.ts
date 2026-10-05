import { describe, expect, it } from "vitest";
import { createTestApp } from "../helpers/app.js";
import {
	BRACELET_UID,
	checkin,
	createSessionGroup,
	registerBracelet,
} from "../helpers/factories.js";

const app = await createTestApp();

describe("POST /bracelets", () => {
	it("registra uma pulseira nova", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/bracelets",
			payload: { uid_rfid: BRACELET_UID },
		});

		expect(response.statusCode).toBe(201);
	});

	it("não registra a mesma pulseira duas vezes", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "POST",
			url: "/bracelets",
			payload: { uid_rfid: BRACELET_UID },
		});

		expect(response.statusCode).toBe(409);
	});
});

describe("DELETE /bracelets/:uid_rfid", () => {
	it("remove uma pulseira cadastrada, que deixa de poder fazer check-in", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "DELETE",
			url: `/bracelets/${BRACELET_UID}`,
		});
		expect(response.statusCode).toBe(204);

		const checkinResponse = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: BRACELET_UID,
				sessionGroupId: await createSessionGroup(app),
			},
		});
		expect(checkinResponse.statusCode).toBe(404);
	});

	it("retorna 404 ao remover uma pulseira não cadastrada", async () => {
		const response = await app.inject({
			method: "DELETE",
			url: `/bracelets/${BRACELET_UID}`,
		});

		expect(response.statusCode).toBe(404);
	});

	it("não remove uma pulseira com sessão ativa", async () => {
		await checkin(app);

		const response = await app.inject({
			method: "DELETE",
			url: `/bracelets/${BRACELET_UID}`,
		});

		expect(response.statusCode).toBe(409);
	});
});
