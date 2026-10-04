import { randomUUID } from "node:crypto";
import type { Decimal } from "decimal.js";
import { DomainError } from "@/errors/DomainError.js";

type MenuItemProps = {
	id: string;
	name: string;
	category: string;
	price: Decimal;
	isAvaliable: boolean;
};

type MenuItemInput = Omit<MenuItemProps, "id">;

export class MenuItem {
	private constructor(private props: MenuItemProps) {}

	static create(input: MenuItemInput) {
		MenuItem.assertValidPrice(input.price);

		return new MenuItem({ id: randomUUID(), ...input });
	}

	static restore(props: MenuItemProps) {
		return new MenuItem(props);
	}

	get id() {
		return this.props.id;
	}

	get name() {
		return this.props.name;
	}

	get category() {
		return this.props.category;
	}

	get price() {
		return this.props.price;
	}

	get isAvaliable() {
		return this.props.isAvaliable;
	}

	update(input: MenuItemInput) {
		MenuItem.assertValidPrice(input.price);

		this.props = { ...this.props, ...input };
	}

	private static assertValidPrice(price: Decimal) {
		if (price.lessThanOrEqualTo("0")) {
			throw new DomainError("Price must be greather than 0");
		}
	}
}
