import type { Order } from "@/entities/order.js";
import { prisma } from "@/lib/prisma.js";

export class PrismaOrdersRepository {
	async createOrder(order: Order) {
		await prisma.orders.create({
			data: {
				id: order.id,
				sessionId: order.sessionId,
				createdAt: order.createdAt,
				orderItems: {
					createMany: {
						data: order.items,
					},
				},
			},
		});
	}

	async getSessionBalance(sessionId: string) {
		const sessionBalance = await prisma.$queryRaw<{
			sessionId: string;
			balance: string;
		}>`
			SELECT sessionId, SUM(price * amount) AS balance FROM Orders 
  			INNER JOIN OrderItems ON Orders.id = OrderItems.ordersId 
  			INNER JOIN MenuItems ON OrderItems.menuItemId = MenuItems.id 
  			WHERE Orders.sessionId = ${sessionId}
		`;

		return sessionBalance;
	}
}
