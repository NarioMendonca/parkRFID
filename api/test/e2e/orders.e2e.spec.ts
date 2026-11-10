import { describe, expect, it } from "vitest";
import { prisma } from "@/lib/prisma.js";
import { createTestApp } from "../helpers/app.js";
import {
	BRACELET_UID,
	checkin,
	createMenuItem,
	placeOrder,
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

	it.each([0, -1, 1.5])("não cria pedido com quantidade %s", async (amount) => {
		await checkin(app);
		const menuItem = await createMenuItem(app);

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [{ menuItemId: menuItem.id, amount }],
			},
		});

		expect(response.statusCode).toBe(400);
		expect(await prisma.orders.count()).toBe(0);
	});

	it("não cria pedido sem itens", async () => {
		await checkin(app);

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: { braceletId: BRACELET_UID, items: [] },
		});

		expect(response.statusCode).toBe(400);
		expect(await prisma.orders.count()).toBe(0);
	});

	it("não cria pedido com item indisponível", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app, { isAvaliable: false });

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [{ menuItemId: menuItem.id, amount: 1 }],
			},
		});

		expect(response.statusCode).toBe(409);
		expect(await prisma.orders.count()).toBe(0);
	});

	it("não cria pedido com item removido do cardápio", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app);
		await app.inject({ method: "DELETE", url: `/menu/${menuItem.id}` });

		const response = await app.inject({
			method: "POST",
			url: "/orders",
			payload: {
				braceletId: BRACELET_UID,
				items: [{ menuItemId: menuItem.id, amount: 1 }],
			},
		});

		expect(response.statusCode).toBe(404);
		expect(await prisma.orders.count()).toBe(0);
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

	it("Create an order for a session sum the order total on the session balance", async () => {
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

		expect("26").toBe(session.total.toString());
	});

	it("Create a order for the group", async () => {
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
				createdFor: "SESSION_GROUP"
			},
		});

		const sessionGroup = await prisma.sessionsGroup.findFirstOrThrow({
			where: { 
				status: "OPEN",
				session: {
					some: {
						braceletId: BRACELET_UID,
						status: "OPEN"						
					}
				} 
			},
		});

		expect("26").toBe(sessionGroup.balance.toString());
	});

	it("Ensure session balance if different of session group balance", async () => {
		await checkin(app);
		const pipoca = await createMenuItem(app, {
			name: "Pipoca",
			price: "10.50",
		});
		const suco = await createMenuItem(app, { name: "Suco", price: "5" });

		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: pipoca.id, amount: 1 },
			{ menuItemId: suco.id, amount: 1 },
		], "SESSION")

		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: pipoca.id, amount: 2 },
			{ menuItemId: suco.id, amount: 1 },
		], "SESSION_GROUP")

		const session = await prisma.sessions.findFirstOrThrow({
			where: { 
				status: "OPEN",
				braceletId: BRACELET_UID
			}
		});

		const sessionGroup = await prisma.sessionsGroup.findFirstOrThrow({
			where: { 
				status: "OPEN",
				session: {
					some: {
						braceletId: BRACELET_UID,
						status: "OPEN"						
					}
				} 
			},
		});

		expect("15.5").toBe(session.total.toString())
		expect("26").toBe(sessionGroup.balance.toString());
	})
});
