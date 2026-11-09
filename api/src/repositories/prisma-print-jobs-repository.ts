import { prisma } from "@/lib/prisma.js";

export class PrismaPrintJobsRepository {
	// A job left as PRINTING means the API stopped in the middle of it
	async requeueInterrupted() {
		await prisma.printJobs.updateMany({
			where: { status: "PRINTING" },
			data: { status: "PENDING" },
		});
	}

	async findNextPending() {
		return prisma.printJobs.findFirst({
			where: { status: "PENDING" },
			orderBy: { createdAt: "asc" },
		});
	}

	async findOrderForTicket(orderId: string) {
		return prisma.orders.findUnique({
			where: { id: orderId },
			include: {
				session: true,
				orderItem: { include: { menuItem: true } },
			},
		});
	}

	async markPrinting(id: string) {
		await prisma.printJobs.update({
			where: { id },
			data: { status: "PRINTING" },
		});
	}

	async markPrinted(id: string) {
		await prisma.printJobs.update({
			where: { id },
			data: { status: "PRINTED", printedAt: new Date(), lastError: null },
		});
	}

	async markRetry(
		id: string,
		attempts: number,
		error: string,
		nextAttemptAt: Date,
	) {
		await prisma.printJobs.update({
			where: { id },
			data: { status: "PENDING", attempts, lastError: error, nextAttemptAt },
		});
	}

	async markFailed(id: string, error: string) {
		await prisma.printJobs.update({
			where: { id },
			data: { status: "FAILED", lastError: error },
		});
	}
}
