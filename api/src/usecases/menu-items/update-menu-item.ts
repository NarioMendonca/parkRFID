import type { Decimal } from "decimal.js";
import { DomainError } from "@/errors/DomainError.js";
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
		const menuItemExists =
			await this.prismaMenuItemsRepository.findItemByName(name);

		if (!menuItemExists) {
			throw new NotFoundError("Item not found");
		}

		if (price.lessThanOrEqualTo("0")) {
			throw new DomainError("Price must be greather than 0");
		}

		const updatedMenuItem = await this.prismaMenuItemsRepository.updateMenuItem(
			{
				id,
				name,
				category,
				price,
				isAvaliable,
			},
		);

		return updatedMenuItem;
	}
}
