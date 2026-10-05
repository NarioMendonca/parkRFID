import { describe, expect, it } from "vitest";
import { prisma } from "@/lib/prisma.js";
import { createTestApp } from "../helpers/app.js";
import { checkin, createMenuItem, placeOrder } from "../helpers/factories.js";

const app = await createTestApp();

const yesterday = () => new Date(Date.now() - 24 * 60 * 60 * 1000);

describe("GET /reports/sessions", () => {
	it("conta as sessões ativas agora e as criadas hoje", async () => {
		// Aberta hoje: ativa e criada hoje
		await checkin(app, "PULSEIRA-A");

		// Aberta e encerrada hoje: só criada hoje
		await checkin(app, "PULSEIRA-B");
		await app.inject({ method: "POST", url: "/sessions/PULSEIRA-B/exit" });

		// Aberta ontem e ainda ativa: só ativa
		await checkin(app, "PULSEIRA-C");
		await prisma.sessions.updateMany({
			where: { braceletId: "PULSEIRA-C" },
			data: { checkinDate: yesterday() },
		});

		const response = await app.inject({
			method: "GET",
			url: "/reports/sessions",
		});

		expect(response.statusCode).toBe(200);
		expect(response.json()).toEqual({
			activeSessions: 2,
			sessionsCreatedToday: 2,
		});
	});

	it("retorna zero quando não há sessões", async () => {
		const response = await app.inject({
			method: "GET",
			url: "/reports/sessions",
		});

		expect(response.json()).toEqual({
			activeSessions: 0,
			sessionsCreatedToday: 0,
		});
	});
});

describe("GET /reports/consumption/today", () => {
	it("soma apenas o consumo dos pedidos feitos hoje", async () => {
		const braceletId = await checkin(app);
		const pipoca = await createMenuItem(app, {
			name: "Pipoca",
			price: "10.50",
		});
		const suco = await createMenuItem(app, { name: "Suco", price: "5" });

		// Pedido de ontem, que não entra no total
		await placeOrder(app, braceletId, [{ menuItemId: suco.id, amount: 3 }]);
		await prisma.orders.updateMany({ data: { createdAt: yesterday() } });

		await placeOrder(app, braceletId, [
			{ menuItemId: pipoca.id, amount: 2 },
			{ menuItemId: suco.id, amount: 1 },
		]);

		const response = await app.inject({
			method: "GET",
			url: "/reports/consumption/today",
		});

		expect(response.statusCode).toBe(200);
		expect(response.json()).toEqual({
			date: new Date().toLocaleDateString("sv-SE"),
			total: "26.00",
		});
	});

	it("usa o preço da época do pedido, mesmo se o cardápio mudar", async () => {
		const braceletId = await checkin(app);
		const pipoca = await createMenuItem(app, { price: "10.50" });
		await placeOrder(app, braceletId, [{ menuItemId: pipoca.id, amount: 1 }]);

		await app.inject({
			method: "PATCH",
			url: `/menu/${pipoca.id}`,
			payload: { ...pipoca, price: "20" },
		});

		const response = await app.inject({
			method: "GET",
			url: "/reports/consumption/today",
		});

		expect(response.json().total).toBe("10.50");
	});

	it("retorna zero quando não houve consumo hoje", async () => {
		const response = await app.inject({
			method: "GET",
			url: "/reports/consumption/today",
		});

		expect(response.json().total).toBe("0.00");
	});
});
