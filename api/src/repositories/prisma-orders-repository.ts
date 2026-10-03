import { prisma } from "@/lib/prisma.js";

export class PrismaOrdersRepository {
	async createOrderForSession(data: {
		sessionId: string;
		items: { menuItemId: string; amount: number }[];
	}) {
		const createdOrder = await prisma.orders.create({
			data: {
				sessionId: data.sessionId,
				orderItems: {
					createMany: {
						data: data.items,
					},
				},
			},
		});

		return createdOrder;
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
