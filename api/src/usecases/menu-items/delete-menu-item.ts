import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaMenuItemsRepository } from "@/repositories/prisma-menu-items-repository.js";

type DeleteMenuItemInput = {
	itemId: string;
};

export class DeleteMenuItemUseCase {
	private prismaMenuItemsRepository = new PrismaMenuItemsRepository();
	async handle({ itemId }: DeleteMenuItemInput) {
		const menuItemExists =
			await this.prismaMenuItemsRepository.findItemById(itemId);

		if (!menuItemExists) {
			throw new NotFoundError("Menu item not found");
		}

		await this.prismaMenuItemsRepository.deleteItem(itemId);
	}
}
