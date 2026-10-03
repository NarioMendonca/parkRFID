import type { Decimal } from "decimal.js";
import { AlreadyExistsError } from "@/errors/AlreadyExistsError.js";
import { DomainError } from "@/errors/DomainError.js";
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

		if (price.lessThanOrEqualTo("0")) {
			throw new DomainError("Price must be greather than 0");
		}

		const createdMenuItem = await this.prismaMenuItemsRepository.createMenuItem(
			{
				name,
				category,
				price,
				isAvaliable,
			},
		);

		return createdMenuItem;
	}
}
