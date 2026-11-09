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
	it("bloqueia inicializar um grupo sem uma sessão", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin/group",
			payload: {
				responsibleCpf: "12345678901",
				responsiblePhoneNumber: "11999999999",
			},
		});

		expect(response.statusCode).toBe(400);
	});
	
	it.only("cria um grupo com o responsável e sua sessão", async () => {
		await registerBracelet(app)
		const response = await createSessionGroup(app)

		expect(response.statusCode).toBe(200);
		expect(response.json().sessionGroup).toEqual({
			id: expect.any(String),
			responsibleCpf: "12345678901",
			responsiblePhoneNumber: "11999999999",
		});
		expect(response.json().session.braceletId)
	});

	it("Don't create a session group when session creation proccess fails", async () => {
		const sessionCpf = "12345678910"
		// trying to create a session group without a bracelet registed, so the bracelet creation process will fail
		await app.inject({
			method: "POST",
			url: "/sessions/checkin/group",
			payload: { 
				responsibleCpf: sessionCpf, 
				responsiblePhoneNumber: "11999999999", 
				groupFirstSession: {
					braceletId: BRACELET_UID, // this bracelet id was not created before
					sessionType: "NORMAL"
				}
			},
		})

		expect(await prisma.sessionsGroup.count()).toBe(0)
		expect(await prisma.sessions.count()).toBe(0)
	})

	it("não cria um grupo com CPF inválido", async () => {
		await registerBracelet(app)
		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin/group",
			payload: { 
				responsibleCpf: "123", 
				responsiblePhoneNumber: "11999999999", 
				groupFirstSession: {
					braceletId: BRACELET_UID,
					sessionType: "NORMAL"
				}
			},
		});

		expect(response.statusCode).toBe(400);
	});

	it("blocks a session group creation if another session group with same credentials are open", async () => {
		await registerBracelet(app)
		await registerBracelet(app, "bracelet2ABC123")

		await createSessionGroup(app)
		const response = await createSessionGroup(app, "bracelet2ABC123")

		expect(response.statusCode).toBe(409);
		expect(response.json().message).toBe("Uma sessão de grupo com o mesmo cpf já está ativa")
	})

	it("bloqueia inicializar um grupo com uma sessão do tipo KID", async () => {
		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin/group",
			payload: {
				responsibleCpf: "12345678901",
				responsiblePhoneNumber: "11999999999",
				groupFirstSession: {
					braceletId: BRACELET_UID,
					sessionType: "KID"
				}
			},
		});

		expect(response.statusCode).toBe(400);
		expect(response.json().message).toBe("A sessão do responsável do grupo não pode ser do tipo infantil");
	});
});


describe("POST /sessions/checkin", () => {
	it("abre uma sessão em uma pulseira em um grupo que já foi criado com outra pulseira", async () => {
		const newBraceletId = "1231412341234"
		await registerBracelet(app);
		await registerBracelet(app, newBraceletId);

		const createdGroup = (await createSessionGroup(app)).json()

		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: newBraceletId,
				sessionGroupId: createdGroup.sessionGroup.id,
			},
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().session).toMatchObject({
			braceletId: newBraceletId,
			status: "OPEN",
			total: "0",
			sessionType: "NORMAL",
			checkoutDate: null,
		});
	});

	it("abre uma sessão do tipo KID em um grupo", async () => {
		const kidBracelet = "kidbracelet123123"
		await registerBracelet(app);
		await registerBracelet(app, kidBracelet)

		const groupId = (await createSessionGroup(app)).json().sessionGroup.id

		const response = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: kidBracelet,
				sessionGroupId: groupId,
				sessionType: "KID",
			},
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().session.sessionType).toBe("KID");
	});

	it("não permite check-in de pulseira não cadastrada", async () => {
		const response = await createSessionGroup(app)

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

	it("não permite duas sessões ativas na mesma pulseira no mesmo grupo ou em grupos diferentes", async () => {
		await registerBracelet(app)
		const groupId = (await createSessionGroup(app)).json().sessionGroup.id

		const sessionOnSameGroup = await app.inject({
			method: "POST",
			url: "/sessions/checkin",
			payload: {
				braceletId: BRACELET_UID,
				sessionGroupId: groupId,
			},
		});

		const sessionOnDiffGroup = await createSessionGroup(app)

		expect(sessionOnSameGroup.statusCode).toBe(409);
		expect(sessionOnDiffGroup.statusCode).toBe(409);
	});

	it("permite um novo check-in depois da saída", async () => {
		await checkin(app);
		await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
		});

		const response = await createSessionGroup(app)

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
			message: "A sessão não tem saldo pendente",
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
	it("Bloqueia a saida de pulseira sem sessão ativa", async () => {
		await registerBracelet(app);

		const response = await app.inject({
			method: "POST",
			url: `/sessions/${BRACELET_UID}/exit`,
		});

		expect(response.statusCode).toBe(404);
		expect(response.json()).toEqual({ message: "Nenhuma sessão ativa foi encontrada nessa pulseira" });
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
			message: "A sessão tem um saldo pendente de R$ 10,50",
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

describe("GET /sessions/:sessionId/history", () => {
	async function getActiveSessionId() {
		const response = await app.inject({
			method: "GET",
			url: `/bracelets/${BRACELET_UID}/sessions`,
		});
		return response.json().sessions[0].id as string;
	}

	it("mostra entrada, pedidos, pagamentos e saída em ordem, com datas", async () => {
		await checkin(app);
		const sessionId = await getActiveSessionId();
		const menuItem = await createMenuItem(app, {
			name: "Pipoca",
			price: "10.50",
		});
		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: menuItem.id, amount: 2 },
		]);
		await app.inject({ method: "POST", url: `/sessions/${BRACELET_UID}/pay` });
		await app.inject({ method: "POST", url: `/sessions/${BRACELET_UID}/exit` });

		const response = await app.inject({
			method: "GET",
			url: `/sessions/${sessionId}/history`,
		});

		expect(response.statusCode).toBe(200);
		const { session, events } = response.json();
		expect(session).toMatchObject({ id: sessionId, status: "CLOSED" });
		expect(events).toEqual([
			{ type: "CHECKIN", date: expect.any(String) },
			{
				type: "ORDER",
				date: expect.any(String),
				orderId: expect.any(String),
				tableNumber: null,
				total: "21.00",
				items: [
					{
						menuItemId: menuItem.id,
						name: "Pipoca",
						amount: 2,
						unitPrice: "10.50",
						subtotal: "21.00",
					},
				],
			},
			{
				type: "PAYMENT",
				date: expect.any(String),
				paymentId: expect.any(String),
				amount: "21.00",
			},
			{ type: "CHECKOUT", date: expect.any(String) },
		]);
	});

	it("mantém o preço da época do pedido mesmo se o cardápio mudar", async () => {
		await checkin(app);
		const sessionId = await getActiveSessionId();
		const menuItem = await createMenuItem(app, { price: "10.50" });
		await placeOrder(app, BRACELET_UID, [
			{ menuItemId: menuItem.id, amount: 1 },
		]);
		await app.inject({
			method: "PATCH",
			url: `/menu/${menuItem.id}`,
			payload: { ...menuItem, price: "20" },
		});

		const response = await app.inject({
			method: "GET",
			url: `/sessions/${sessionId}/history`,
		});

		expect(response.json().events[1]).toMatchObject({
			type: "ORDER",
			total: "10.50",
			items: [{ unitPrice: "10.50" }],
		});
	});

	it("não mostra saída enquanto a sessão está aberta", async () => {
		await checkin(app);
		const sessionId = await getActiveSessionId();

		const response = await app.inject({
			method: "GET",
			url: `/sessions/${sessionId}/history`,
		});

		expect(response.statusCode).toBe(200);
		expect(response.json().events).toEqual([
			{ type: "CHECKIN", date: expect.any(String) },
		]);
	});

	it("retorna 404 para sessão inexistente", async () => {
		const response = await app.inject({
			method: "GET",
			url: "/sessions/sessao-inexistente/history",
		});

		expect(response.statusCode).toBe(404);
	});
});
