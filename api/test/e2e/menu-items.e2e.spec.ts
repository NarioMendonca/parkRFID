import { randomUUID } from "node:crypto";
import { describe, expect, it } from "vitest";
import { createTestApp } from "../helpers/app.js";
import { createMenuItem } from "../helpers/factories.js";

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

	it("retorna 404 ao remover item inexistente", async () => {
		const response = await app.inject({
			method: "DELETE",
			url: `/menu/${randomUUID()}`,
		});

		expect(response.statusCode).toBe(404);
	});
});
