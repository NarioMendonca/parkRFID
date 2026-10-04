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
	private prismaBraceletsRepository = new PrismaBraceletsRepository();
	private prismaOrdersRepository = new PrismaOrdersRepository();
	private prismaMenuItemsRepository = new PrismaMenuItemsRepository();

	async handle({ braceletId, items }: CreateOrderInput) {
		const bracelet =
			await this.prismaBraceletsRepository.findByUidRfid(braceletId);
		if (!bracelet) {
			throw new NotFoundError("Bracelet not registered");
		}

		const itemsIds = items.map((item) => item.menuItemId);
		const menuItems =
			await this.prismaMenuItemsRepository.fetchItemsById(itemsIds);

		const order = bracelet.placeOrder(items, menuItems);

		await this.prismaOrdersRepository.createOrder(order);
		return order;
	}
}
