import { randomUUID } from "node:crypto";
import { describe, expect, it } from "vitest";
import { prisma } from "@/lib/prisma.js";
import { createTestApp } from "../helpers/app.js";
import {
	BRACELET_UID,
	checkin,
	createMenuItem,
	placeOrder,
} from "../helpers/factories.js";

const app = await createTestApp();

describe("POST /menu", () => {
	it("cria um item no cardápio", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/menu",
			payload: {
				name: "Pipoca",
				category: "snack",
				price: "10.50",
				isAvaliable: true,
			},
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().menuItem).toEqual({
			id: expect.any(String),
			name: "Pipoca",
			category: "snack",
			price: "10.5",
			isAvaliable: true,
		});
	});

	it("não cria dois itens com o mesmo nome", async () => {
		await createMenuItem(app, { name: "Pipoca" });

		const response = await app.inject({
			method: "POST",
			url: "/menu",
			payload: {
				name: "Pipoca",
				category: "snack",
				price: "5",
				isAvaliable: true,
			},
		});

		expect(response.statusCode).toBe(409);
	});

	it("permite recriar um item com o nome de um item removido", async () => {
		const menuItem = await createMenuItem(app, { name: "Pipoca" });
		await app.inject({ method: "DELETE", url: `/menu/${menuItem.id}` });

		const response = await app.inject({
			method: "POST",
			url: "/menu",
			payload: {
				name: "Pipoca",
				category: "snack",
				price: "5",
				isAvaliable: true,
			},
		});

		expect(response.statusCode).toBe(200);
	});

	it.each(["0", "-5"])("não cria item com preço %s", async (price) => {
		const response = await app.inject({
			method: "POST",
			url: "/menu",
			payload: { name: "Pipoca", category: "snack", price, isAvaliable: true },
		});

		expect(response.statusCode).toBe(400);
	});
});

describe("GET /menu", () => {
	it("lista todos os itens", async () => {
		await createMenuItem(app, { name: "Pipoca", category: "snack" });
		await createMenuItem(app, { name: "Suco", category: "drink" });

		const response = await app.inject({ method: "GET", url: "/menu" });

		expect(response.statusCode).toBe(200);
		expect(response.json()).toHaveLength(2);
	});

	it("filtra os itens por categoria", async () => {
		await createMenuItem(app, { name: "Pipoca", category: "snack" });
		await createMenuItem(app, { name: "Suco", category: "drink" });

		const response = await app.inject({
			method: "GET",
			url: "/menu?category=drink",
		});

		expect(response.statusCode).toBe(200);
		expect(response.json()).toMatchObject([{ name: "Suco" }]);
	});
});

describe("PATCH /menu/:id", () => {
	it("atualiza e renomeia um item", async () => {
		const menuItem = await createMenuItem(app, { name: "Pipoca" });

		const response = await app.inject({
			method: "PATCH",
			url: `/menu/${menuItem.id}`,
			payload: {
				id: menuItem.id,
				name: "Pipoca Grande",
				category: "snack",
				price: "12",
				isAvaliable: false,
			},
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().menuItem).toEqual({
			id: menuItem.id,
			name: "Pipoca Grande",
			category: "snack",
			price: "12",
			isAvaliable: false,
		});
	});

	it("atualiza o item da URL, ignorando o id enviado no body", async () => {
		const pipoca = await createMenuItem(app, { name: "Pipoca" });
		const suco = await createMenuItem(app, { name: "Suco" });

		const response = await app.inject({
			method: "PATCH",
			url: `/menu/${pipoca.id}`,
			payload: { ...pipoca, id: suco.id, name: "Pipoca Grande" },
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().menuItem).toMatchObject({
			id: pipoca.id,
			name: "Pipoca Grande",
		});
		expect(
			await prisma.menuItems.findUniqueOrThrow({ where: { id: suco.id } }),
		).toMatchObject({ name: "Suco" });
	});

	it("não atualiza item com preço inválido", async () => {
		const menuItem = await createMenuItem(app);

		const response = await app.inject({
			method: "PATCH",
			url: `/menu/${menuItem.id}`,
			payload: { ...menuItem, price: "0" },
		});

		expect(response.statusCode).toBe(400);
	});

	it("retorna 404 ao atualizar item inexistente", async () => {
		const id = randomUUID();

		const response = await app.inject({
			method: "PATCH",
			url: `/menu/${id}`,
			payload: {
				id,
				name: "Pipoca",
				category: "snack",
				price: "10",
				isAvaliable: true,
			},
		});

		expect(response.statusCode).toBe(404);
	});

	it("retorna 404 ao atualizar item removido", async () => {
		const menuItem = await createMenuItem(app);
		await app.inject({ method: "DELETE", url: `/menu/${menuItem.id}` });

		const response = await app.inject({
			method: "PATCH",
			url: `/menu/${menuItem.id}`,
			payload: menuItem,
		});

		expect(response.statusCode).toBe(404);
	});
});

describe("DELETE /menu/:id", () => {
	it("remove um item do cardápio", async () => {
		const menuItem = await createMenuItem(app);

		const response = await app.inject({
			method: "DELETE",
			url: `/menu/${menuItem.id}`,
		});
		expect(response.statusCode).toBe(200);

		const listResponse = await app.inject({ method: "GET", url: "/menu" });
		expect(listResponse.json()).toHaveLength(0);
	});

	it("desativa o item em vez de apagá-lo do banco", async () => {
		const menuItem = await createMenuItem(app);

		await app.inject({ method: "DELETE", url: `/menu/${menuItem.id}` });

		expect(
			await prisma.menuItems.findUniqueOrThrow({ where: { id: menuItem.id } }),
		).toMatchObject({ isActive: false });
	});

	it("remove um item que já foi pedido, mantendo o pedido", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app);
		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: menuItem.id, amount: 1 },
		]);

		const response = await app.inject({
			method: "DELETE",
			url: `/menu/${menuItem.id}`,
		});

		expect(response.statusCode).toBe(200);
		expect(await prisma.orderItems.count()).toBe(1);
	});

	it("retorna 404 ao remover um item já removido", async () => {
		const menuItem = await createMenuItem(app);
		await app.inject({ method: "DELETE", url: `/menu/${menuItem.id}` });

		const response = await app.inject({
			method: "DELETE",
			url: `/menu/${menuItem.id}`,
		});

		expect(response.statusCode).toBe(404);
	});

	it("retorna 404 ao remover item inexistente", async () => {
		const response = await app.inject({
			method: "DELETE",
			url: `/menu/${randomUUID()}`,
		});

		expect(response.statusCode).toBe(404);
	});
});
