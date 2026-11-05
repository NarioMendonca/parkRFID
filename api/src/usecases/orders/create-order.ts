import { InvalidResourceError } from "@/errors/InvalidResourceError.js";
import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";
import { PrismaMenuItemsRepository } from "@/repositories/prisma-menu-items-repository.js";
import { PrismaOrdersRepository } from "@/repositories/prisma-orders-repository.js";

type CreateOrderInput = {
	braceletId: string;
	items: {
		menuItemId: string;
		amount: number;
	}[];
};

export class CreateOrderUseCase {
	private braceletsRepository = new PrismaBraceletsRepository();
	private ordersRepository = new PrismaOrdersRepository();
	private menuItemsRepository = new PrismaMenuItemsRepository();

	async handle({ braceletId, items }: CreateOrderInput) {
		const bracelet = await this.braceletsRepository.findByUidRfid(braceletId);
		if (!bracelet) {
			throw new NotFoundError("Pulseira não cadastrada");
		}

		if (!bracelet.activeSession) {
			throw new NotFoundError(
				"Nenhuma sessão ativa foi encontrada nessa pulseira",
			);
		}

		const itemsIds = items.map((item) => item.menuItemId);
		const menuItems = await this.menuItemsRepository.fetchItemsById(itemsIds);

		const order = bracelet.placeOrder(items, menuItems);

		await this.ordersRepository.createOrder(order, bracelet.activeSession);

		return order;
	}
}
