import { randomUUID } from "node:crypto";
import { NotFoundError } from "@/errors/NotFoundError.js";
import type { MenuItem } from "./menu-item.js";
import type { Session } from "./session.js";

export type OrderItem = {
	menuItemId: string;
	amount: number;
};

type OrderProps = {
	id: string;
	sessionId: string;
	createdAt: Date;
	items: OrderItem[];
};

type PlaceOrderInput = {
	session: Session;
	items: OrderItem[];
	menuItems: MenuItem[];
};

export class Order {
	private constructor(private props: OrderProps) {}

	static place({ session, items, menuItems }: PlaceOrderInput) {
		const menuItemsIds = new Set(menuItems.map((menuItem) => menuItem.id));
		if (!items.every((item) => menuItemsIds.has(item.menuItemId))) {
			throw new NotFoundError("Some Menu Item has invalid id");
		}

		return new Order({
			id: randomUUID(),
			sessionId: session.id,
			createdAt: new Date(),
			items,
		});
	}

	get id() {
		return this.props.id;
	}

	get sessionId() {
		return this.props.sessionId;
	}

	get createdAt() {
		return this.props.createdAt;
	}

	get items() {
		return this.props.items;
	}
}
