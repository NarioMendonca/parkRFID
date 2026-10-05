import { InvalidResourceError } from "@/errors/InvalidResourceError.js";
import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";
import { PrismaMenuItemsRepository } from "@/repositories/prisma-menu-items-repository.js";
import { PrismaOrdersRepository } from "@/repositories/prisma-orders-repository.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

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
	private sessionsRepository = new PrismaSessionsRepository();

	async handle({ braceletId, items }: CreateOrderInput) {
		const bracelet =
			await this.braceletsRepository.findByUidRfid(braceletId);
		if (!bracelet) {
			throw new NotFoundError("Bracelet not registered");
		}

		if (!bracelet.activeSession) {
			throw new NotFoundError("Session not found in this bracelet")
		}

		const itemsIds = items.map((item) => item.menuItemId);
		const menuItems =
			await this.menuItemsRepository.fetchItemsById(itemsIds);

		const order = bracelet.placeOrder(items, menuItems);

		await this.ordersRepository.createOrder(order);
		await this.sessionsRepository.saveSession(bracelet.activeSession)

		return order;
	}
}
