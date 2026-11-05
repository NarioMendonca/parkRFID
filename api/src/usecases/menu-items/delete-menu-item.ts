import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaMenuItemsRepository } from "@/repositories/prisma-menu-items-repository.js";

type DeleteMenuItemInput = {
	itemId: string;
};

export class DeleteMenuItemUseCase {
	private prismaMenuItemsRepository = new PrismaMenuItemsRepository();
	async handle({ itemId }: DeleteMenuItemInput) {
		const menuItem = await this.prismaMenuItemsRepository.findItemById(itemId);

		if (!menuItem) {
			throw new NotFoundError("Item do cardápio não encontrado");
		}

		menuItem.deactivate();

		await this.prismaMenuItemsRepository.updateMenuItem(menuItem);
	}
}
