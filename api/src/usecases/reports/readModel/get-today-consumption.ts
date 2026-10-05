import { Decimal } from "decimal.js";
import { startOfToday, toDateString } from "@/lib/date.js";
import { prisma } from "@/lib/prisma.js";

export async function getTodayConsumption() {
	const today = startOfToday();

	const orderItems = await prisma.orderItems.findMany({
		where: {
			orders: {
				createdAt: {
					gte: today,
				},
			},
		},
		select: {
			amount: true,
			unitPrice: true,
		},
	});

	const total = orderItems.reduce(
		(sum, orderItem) => sum.add(orderItem.unitPrice.mul(orderItem.amount)),
		new Decimal("0"),
	);

	return { date: toDateString(today), total };
}
