import type { Order } from "@/entities/order.js";
import type { Session } from "@/entities/session.js";
import { prisma } from "@/lib/prisma.js";

export class PrismaOrdersRepository {
	// The order and the session total are saved together, so an order is never
	// recorded without being charged to the session (or the other way around)
	async createOrder(order: Order, session: Session) {
		await prisma.$transaction([
			prisma.orders.create({
				data: {
					id: order.id,
					sessionId: order.sessionId,
					createdAt: order.createdAt,
					createdBy: order.createdBy,
					orderItem: {
						createMany: {
							data: order.items,
						},
					},
				},
			}),
			prisma.sessions.update({
				where: {
					id: session.id,
				},
				data: {
					total: session.total,
				},
			}),
		]);
	}

	async getSessionBalance(sessionId: string) {
		const sessionBalance = await prisma.$queryRaw<{
			sessionId: string;
			balance: string;
		}>`
			SELECT sessionId, SUM(price * amount) AS balance FROM Orders
			INNER JOIN OrderItems ON Orders.id = OrderItems.orderId
			INNER JOIN MenuItems ON OrderItems.menuItemId = MenuItems.id
  			WHERE Orders.sessionId = ${sessionId}
		`;

		return sessionBalance;
	}
}
