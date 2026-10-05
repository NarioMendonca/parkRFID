import { Decimal } from "decimal.js";
import { NotFoundError } from "@/errors/NotFoundError.js";
import { prisma } from "@/lib/prisma.js";

export type SessionEvent =
	| { type: "CHECKIN"; date: Date }
	| {
			type: "ORDER";
			date: Date;
			orderId: string;
			total: string;
			items: {
				menuItemId: string;
				name: string;
				amount: number;
				unitPrice: string;
				subtotal: string;
			}[];
	  }
	| { type: "PAYMENT"; date: Date; paymentId: string; amount: string }
	| { type: "CHECKOUT"; date: Date };

export async function getSessionHistory(sessionId: string) {
	const session = await prisma.sessions.findUnique({
		where: {
			id: sessionId,
		},
		include: {
			orders: {
				include: {
					orderItems: {
						include: {
							menuItems: true,
						},
					},
				},
			},
			payments: true,
		},
	});
	if (!session) {
		throw new NotFoundError("Session not found");
	}

	const { orders, payments, ...sessionData } = session;

	const orderEvents: SessionEvent[] = orders.map((order) => {
		const items = order.orderItems.map((orderItem) => ({
			menuItemId: orderItem.menuItemId,
			name: orderItem.menuItems.name,
			amount: orderItem.amount,
			unitPrice: orderItem.unitPrice,
			subtotal: orderItem.unitPrice.mul(orderItem.amount),
		}));
		const total = items.reduce(
			(sum, item) => sum.add(item.subtotal),
			new Decimal("0"),
		);

		return {
			type: "ORDER",
			date: order.createdAt,
			orderId: order.id,
			total: total.toFixed(2),
			items: items.map((item) => ({
				...item,
				unitPrice: item.unitPrice.toFixed(2),
				subtotal: item.subtotal.toFixed(2),
			})),
		};
	});

	const paymentEvents: SessionEvent[] = payments.map((payment) => ({
		type: "PAYMENT",
		date: payment.createdAt,
		paymentId: payment.id,
		amount: payment.amount.toFixed(2),
	}));

	const events: SessionEvent[] = [
		{ type: "CHECKIN", date: session.checkinDate },
		...orderEvents,
		...paymentEvents,
	];
	if (session.checkoutDate) {
		events.push({ type: "CHECKOUT", date: session.checkoutDate });
	}

	// The sort is stable, so on a tie the check-in stays first and the checkout last
	events.sort((a, b) => a.date.getTime() - b.date.getTime());

	return { session: sessionData, events };
}
