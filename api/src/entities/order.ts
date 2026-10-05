import { randomUUID } from "node:crypto";
import { NotFoundError } from "@/errors/NotFoundError.js";
import { MenuItem } from "./menu-item.js";
import type { Session } from "./session.js";
import { Decimal } from "decimal.js";

export type OrderItem = {
	menuItemId: string;
	amount: number;
};

type OrderProps = {
	id: string;
	sessionId: string;
	createdAt: Date;
	items: OrderItem[];
	balance: Decimal
};

type PlaceOrderInput = {
	session: Session;
	items: OrderItem[];
	menuItems: MenuItem[];
};

export class Order {
	private constructor(private props: OrderProps) {}

	static place({ session, items, menuItems }: PlaceOrderInput) {
		const pricesById = new Map(
			menuItems.map((menuItem) => [menuItem.id, menuItem.price]),
		);

		const orderTotalBalance = items.reduce((balance, item) => {
			const price = pricesById.get(item.menuItemId);
			if (!price) {
				throw new NotFoundError("Some Menu Item has invalid id");
			}

			return balance.add(price.mul(item.amount));
		}, new Decimal("0"));

		return new Order({
			id: randomUUID(),
			sessionId: session.id,
			createdAt: new Date(),
			items,
			balance: orderTotalBalance
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

	get balance(): Decimal {
		return this.props.balance;
	}
}
