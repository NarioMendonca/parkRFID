import type { FastifyInstance } from "fastify";

// Test data is created through the API itself, so tests stay at the endpoint level

export const BRACELET_UID = "04A1B2C3D4E5F6";

type MenuItemResponse = {
	id: string;
	name: string;
	category: string;
	price: string;
	isAvaliable: boolean;
};

async function post(app: FastifyInstance, url: string, payload: object) {
	const response = await app.inject({ method: "POST", url, payload });
	if (response.statusCode >= 400) {
		throw new Error(
			`Setup request POST ${url} failed: ${response.statusCode} ${response.body}`,
		);
	}

	return response.json();
}

export async function registerBracelet(
	app: FastifyInstance,
	uidRfid = BRACELET_UID,
) {
	await post(app, "/bracelets", { uid_rfid: uidRfid });
	return uidRfid;
}

export async function createSessionGroup(app: FastifyInstance, uidRfid: string = BRACELET_UID, responsibleCpf: string = "12345678901") {
	const response = await app.inject({
		method: "POST",
		url: "/sessions/checkin/group",
		payload: {
			responsibleCpf,
			responsiblePhoneNumber: "11999999999",
			groupFirstSession: {
				ownerName: "José Rogerio da Silva",
				braceletId: uidRfid,
				sessionType: "NORMAL"
			}
		}
	});

	return response
}

export async function createSession(app: FastifyInstance, groupId: string, uidRfid: string = BRACELET_UID) {
	const response = await app.inject({
		method: "POST",
		url: "/sessions/checkin",
		payload: {
			ownerName: "José Rogerio da Silva",
			braceletId: uidRfid,
			sessionGroupId: groupId,
			sessionType: "NORMAL"
		}
	});

	return response
}

export async function createMenuItem(
	app: FastifyInstance,
	overrides: Partial<Omit<MenuItemResponse, "id">> = {},
) {
	const body = await post(app, "/menu", {
		name: "Pipoca",
		category: "snack",
		price: "10.50",
		isAvaliable: true,
		...overrides,
	});

	return body.menuItem as MenuItemResponse;
}

// Registers the bracelet and opens a session for it
export async function checkin(app: FastifyInstance, uidRfid = BRACELET_UID, responsibleCpf = "12345678901") {
	await registerBracelet(app, uidRfid);
	await createSessionGroup(app, uidRfid, responsibleCpf);


	return uidRfid;
}

export async function placeOrder(
	app: FastifyInstance,
	braceletId: string,
	items: { menuItemId: string; amount: number }[],
) {
	await post(app, "/orders", { braceletId, items });
}
