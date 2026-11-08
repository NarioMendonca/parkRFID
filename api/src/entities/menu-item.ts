import { randomUUID } from "node:crypto";
import type { Decimal } from "decimal.js";
import { DomainError } from "@/errors/DomainError.js";

type MenuItemProps = {
	id: string;
	name: string;
	category: string;
	price: Decimal;
	isAvaliable: boolean;
	isActive: boolean;
};

type MenuItemInput = Omit<MenuItemProps, "id" | "isActive">;

export class MenuItem {
	private constructor(private props: MenuItemProps) {}

	static create(input: MenuItemInput) {
		MenuItem.assertValidPrice(input.price);

		return new MenuItem({ id: randomUUID(), ...input, isActive: true });
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

	get isActive() {
		return this.props.isActive;
	}

	update(input: MenuItemInput) {
		MenuItem.assertValidPrice(input.price);

		this.props = { ...this.props, ...input };
	}

	// Items are never deleted, since past orders still reference them; an
	// inactive item just leaves the menu
	deactivate() {
		this.props.isActive = false;
	}

	private static assertValidPrice(price: Decimal) {
		if (price.lessThanOrEqualTo("0")) {
			throw new DomainError("O preço deve ser maior que zero");
		}
	}
}
