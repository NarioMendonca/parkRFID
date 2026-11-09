import { randomUUID } from "node:crypto";
import { Decimal } from "decimal.js";
import { DomainError } from "@/errors/DomainError.js";
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

export type OrderCreatedBy = "SESSION" | "SESSION_GROUP";

type OrderProps = {
	id: string;
	sessionId: string;
	createdAt: Date;
	items: OrderLine[];
	balance: Decimal;
	createdBy: OrderCreatedBy;
	tableNumber: string | null;
};

type PlaceOrderInput = {
	session: Session;
	items: OrderItem[];
	menuItems: MenuItem[];
	createdBy: OrderCreatedBy;
	tableNumber?: string;
};

export class Order {
	private constructor(private props: OrderProps) {}

	static place({
		session,
		items,
		menuItems,
		createdBy,
		tableNumber,
	}: PlaceOrderInput) {
		const menuItemsById = new Map(
			menuItems.map((menuItem) => [menuItem.id, menuItem]),
		);

		const lines = items.map((item) => {
			const menuItem = menuItemsById.get(item.menuItemId);
			if (!menuItem) {
				throw new NotFoundError(`O item do menu com Id ${item.menuItemId} é inválido`);
			}

			if (!menuItem.isAvaliable) {
				throw new DomainError(
					`'${menuItem.name}' não está disponível`,
					409,
				);
			}

			return { ...item, unitPrice: menuItem.price };
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
			createdBy,
			tableNumber: tableNumber ?? null,
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

	get createdBy() {
		return this.props.createdBy
	}

	get tableNumber() {
		return this.props.tableNumber;
	}
}
