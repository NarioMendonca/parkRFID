import { Decimal } from "decimal.js";
import type { Order } from "@/entities/order.js";
import type { Session } from "@/entities/session.js";
import { prisma } from "@/lib/prisma.js";

export class PrismaOrdersRepository {
	// The order and the session total are saved together, so an order is never
	// recorded without being charged to the session (or the other way around).
	// When printing is on, the print job goes in the same transaction, so an
	// order is never saved without its ticket being queued.
	async createOrder(
		order: Order,
		session: Session,
		options: { enqueuePrint?: boolean } = {},
	) {
		await prisma.$transaction([
			prisma.orders.create({
				data: {
					id: order.id,
					sessionId: order.sessionId,
					sessionGroupId: session.group.id,
					createdAt: order.createdAt,
					createdFor: order.createdFor,
					tableNumber: order.tableNumber,
					orderItem: {
						createMany: {
							data: order.items,
						},
					},
					...(options.enqueuePrint ? { printJob: { create: {} } } : {}),
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

	// Sums the unit price kept on each order line, so menu price changes don't
	// affect it, using Decimal so the sum has no floating point error
	async getSessionBalance(sessionId: string) {
		const orderItems = await prisma.orderItems.findMany({
			where: {
				order: {
					sessionId,
				},
			},
			select: {
				amount: true,
				unitPrice: true,
			},
		});

		const balance = orderItems.reduce(
			(sum, orderItem) => sum.add(orderItem.unitPrice.mul(orderItem.amount)),
			new Decimal("0"),
		);

		return { sessionId, balance };
	}
}
