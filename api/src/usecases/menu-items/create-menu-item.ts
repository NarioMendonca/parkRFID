import type { Decimal } from "decimal.js";
import { MenuItem } from "@/entities/menu-item.js";
import { AlreadyExistsError } from "@/errors/AlreadyExistsError.js";
import { PrismaMenuItemsRepository } from "@/repositories/prisma-menu-items-repository.js";

type CreateItemInput = {
	name: string;
	category: string;
	price: Decimal;
	isAvaliable: boolean;
};

export class CreateMenuItemUseCase {
	private prismaMenuItemsRepository = new PrismaMenuItemsRepository();
	async handle({ name, category, price, isAvaliable }: CreateItemInput) {
		const menuItemAlreadyExists =
			await this.prismaMenuItemsRepository.findItemByName(name);

		if (menuItemAlreadyExists) {
			throw new AlreadyExistsError("Item already exists");
		}

		const menuItem = MenuItem.create({
			name,
			category,
			price,
			isAvaliable,
		});

		await this.prismaMenuItemsRepository.createMenuItem(menuItem);
		return menuItem;
	}
}
