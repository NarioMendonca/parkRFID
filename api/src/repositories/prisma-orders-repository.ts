import type { Order } from "@/entities/order.js";
import { prisma } from "@/lib/prisma.js";

export class PrismaOrdersRepository {
	// When printing is on, the print job is saved together with the order, so an
	// order is never saved without its ticket being queued
	async createOrder(order: Order, options: { enqueuePrint?: boolean } = {}) {
		await prisma.orders.create({
			data: {
				id: order.id,
				sessionId: order.sessionId,
				createdAt: order.createdAt,
				tableNumber: order.tableNumber,
				orderItems: {
					createMany: {
						data: order.items,
					},
				},
				...(options.enqueuePrint ? { printJobs: { create: {} } } : {}),
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
