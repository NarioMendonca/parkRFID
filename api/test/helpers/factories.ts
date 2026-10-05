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

export async function createSessionGroup(app: FastifyInstance) {
	const body = await post(app, "/sessions/checkin/group", {
		responsibleCpf: "12345678901",
		responsiblePhoneNumber: "11999999999",
	});

	return body.sessionGroup.id as string;
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
export async function checkin(app: FastifyInstance, uidRfid = BRACELET_UID) {
	await registerBracelet(app, uidRfid);
	const sessionGroupId = await createSessionGroup(app);
	await post(app, "/sessions/checkin", {
		braceletId: uidRfid,
		sessionGroupId,
	});

	return uidRfid;
}

export async function placeOrder(
	app: FastifyInstance,
	braceletId: string,
	items: { menuItemId: string; amount: number }[],
) {
	await post(app, "/orders", { braceletId, items });
}
