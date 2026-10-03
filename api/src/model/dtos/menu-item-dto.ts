import type { Decimal } from "decimal.js";

export type MenuItemDTO = {
	id: string;
	name: string;
	category: string;
	price: Decimal;
	isAvaliable: boolean;
};
