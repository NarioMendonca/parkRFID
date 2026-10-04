import type { Decimal } from "decimal.js";
import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaMenuItemsRepository } from "@/repositories/prisma-menu-items-repository.js";

type CreateItemInput = {
	id: string;
	name: string;
	category: string;
	price: Decimal;
	isAvaliable: boolean;
};

export class UpdateMenuItemUseCase {
	private prismaMenuItemsRepository = new PrismaMenuItemsRepository();
	async handle({ id, name, category, price, isAvaliable }: CreateItemInput) {
		const menuItem = await this.prismaMenuItemsRepository.findItemById(id);

		if (!menuItem) {
			throw new NotFoundError("Item not found");
		}

		menuItem.update({
			name,
			category,
			price,
			isAvaliable,
		});

		await this.prismaMenuItemsRepository.updateMenuItem(menuItem);
		return menuItem;
	}
}
