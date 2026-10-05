import { describe, expect, it } from "vitest";
import { prisma } from "@/lib/prisma.js";
import { createTestApp } from "../helpers/app.js";
import {
	BRACELET_UID,
	checkin,
	createMenuItem,
	registerBracelet,
} from "../helpers/factories.js";

const app = await createTestApp();

describe("POST /orders", () => {
	it("cria um pedido para a sessão ativa da pulseira", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app);

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [{ menuItemId: menuItem.id, amount: 2 }],
			},
		});

		expect(response.statusCode).toBe(200);
		expect(await prisma.orderItems.findMany()).toMatchObject([
			{ menuItemId: menuItem.id, amount: 2 },
		]);
	});

	it("aceita o mesmo item em mais de uma linha do pedido", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app);

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [
					{ menuItemId: menuItem.id, amount: 1 },
					{ menuItemId: menuItem.id, amount: 3 },
				],
			},
		});

		expect(response.statusCode).toBe(200);
	});

	it("soma o valor do pedido no total da sessão", async () => {
		await checkin(app);
		const pipoca = await createMenuItem(app, {
			name: "Pipoca",
			price: "10.50",
		});
		const suco = await createMenuItem(app, { name: "Suco", price: "5" });

		await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [
					{ menuItemId: pipoca.id, amount: 2 },
					{ menuItemId: suco.id, amount: 1 },
				],
			},
		});

		const session = await prisma.sessions.findFirstOrThrow({
			where: { braceletId: BRACELET_UID, status: "OPEN" },
		});

		expect(session.total.toString()).toBe("26");
	});

	it("não cria pedido para pulseira não cadastrada", async () => {
		const menuItem = await createMenuItem(app);

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [{ menuItemId: menuItem.id, amount: 1 }],
			},
		});

		expect(response.statusCode).toBe(404);
	});

	it("não cria pedido para pulseira sem sessão ativa", async () => {
		await registerBracelet(app);
		const menuItem = await createMenuItem(app);

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [{ menuItemId: menuItem.id, amount: 1 }],
			},
		});

		expect(response.statusCode).toBe(404);
	});

	it("não cria pedido com item inexistente no cardápio", async () => {
		await checkin(app);

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [{ menuItemId: "item-inexistente", amount: 1 }],
			},
		});

		expect(response.statusCode).toBe(404);
		expect(await prisma.orders.count()).toBe(0);
	});
});
