import { randomUUID } from "node:crypto";
import { Decimal } from "decimal.js";
import { NotFoundError } from "@/errors/NotFoundError.js";
import type { MenuItem } from "./menu-item.js";
import type { Session } from "./session.js";

export type OrderItem = {
	menuItemId: string;
	amount: number;
};

// The unit price is kept so the order value doesn't change with the menu
export type OrderLine = OrderItem & {
	unitPrice: Decimal;
};

type OrderProps = {
	id: string;
	sessionId: string;
	createdAt: Date;
	items: OrderLine[];
	balance: Decimal;
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

		const lines = items.map((item) => {
			const unitPrice = pricesById.get(item.menuItemId);
			if (!unitPrice) {
				throw new NotFoundError("Some Menu Item has invalid id");
			}

			return { ...item, unitPrice };
		});

		const orderTotalBalance = lines.reduce(
			(balance, line) => balance.add(line.unitPrice.mul(line.amount)),
			new Decimal("0"),
		);

		return new Order({
			id: randomUUID(),
			sessionId: session.id,
			createdAt: new Date(),
			items: lines,
			balance: orderTotalBalance,
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
