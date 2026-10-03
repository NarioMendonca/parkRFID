import { NotFoundError } from "@/errors/NotFoundError.js";
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
	private prismaSessionsRepository = new PrismaSessionsRepository();
	private prismaOrdersRepository = new PrismaOrdersRepository();
	private prismaMenuItemsRepository = new PrismaMenuItemsRepository();

	async handle({ braceletId, items }: CreateOrderInput) {
		const session =
			await this.prismaSessionsRepository.findActiveSessionByBraceletId(
				braceletId,
			);
		if (!session) {
			throw new NotFoundError("Session not found");
		}

		const itemsIds = items.map((item) => item.menuItemId);
		const fetchedItems =
			await this.prismaMenuItemsRepository.fetchItemsById(itemsIds);
		if (fetchedItems.length !== items.length) {
			throw new NotFoundError("Some Menu Item has invalid id");
		}

		const createdOrder =
			await this.prismaOrdersRepository.createOrderForSession({
				sessionId: session.id,
				items,
			});

		return createdOrder;
	}
}
