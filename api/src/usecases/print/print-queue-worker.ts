import { renderOrderTicket } from "@/lib/escpos.js";
import { type PrinterConfig, sendToPrinter } from "@/lib/printer.js";
import { PrismaPrintJobsRepository } from "@/repositories/prisma-print-jobs-repository.js";

const POLL_INTERVAL_MS = 2000;
const BASE_RETRY_DELAY_MS = 2000;
const MAX_RETRY_DELAY_MS = 30000;

function errorMessage(error: unknown) {
	return error instanceof Error ? error.message : String(error);
}

// Prints the queued tickets one at a time, oldest first. While the printer is
// unreachable the job keeps being retried (with a growing delay) and the jobs
// behind it wait, so tickets always come out in the order orders were placed.
export class PrintQueueWorker {
	private repository = new PrismaPrintJobsRepository();
	private timer: NodeJS.Timeout | null = null;
	private busy = false;

	constructor(private config: PrinterConfig) {}

	async start() {
		await this.repository.requeueInterrupted();
		this.timer = setInterval(() => void this.tick(), POLL_INTERVAL_MS);
		void this.tick();
	}

	stop() {
		if (this.timer) {
			clearInterval(this.timer);
			this.timer = null;
		}
	}

	private async tick() {
		if (this.busy) {
			return;
		}

		this.busy = true;
		try {
			let keepGoing = true;
			while (keepGoing) {
				keepGoing = await this.processNext();
			}
		} catch (error) {
			console.error(`[print] queue error: ${errorMessage(error)}`);
		} finally {
			this.busy = false;
		}
	}

	// Returns true when the queue can move on to the next job
	private async processNext() {
		const job = await this.repository.findNextPending();
		if (!job || job.nextAttemptAt.getTime() > Date.now()) {
			return false;
		}

		await this.repository.markPrinting(job.id);

		let ticket: Buffer;
		try {
			const order = await this.repository.findOrderForTicket(job.orderId);
			if (!order) {
				throw new Error("Order not found");
			}

			ticket = renderOrderTicket(
				{
					id: order.id,
					createdAt: order.createdAt,
					tableNumber: order.tableNumber,
					braceletId: order.session.braceletId,
					items: order.orderItems.map((item) => ({
						name: item.menuItems.name,
						amount: item.amount,
					})),
				},
				this.config,
			);
		} catch (error) {
			// Nothing to retry: the ticket itself can't be built
			await this.repository.markFailed(job.id, errorMessage(error));
			console.error(`[print] job ${job.id} failed: ${errorMessage(error)}`);
			return true;
		}

		try {
			await sendToPrinter(this.config, ticket);
		} catch (error) {
			const attempts = job.attempts + 1;
			const delay = Math.min(
				MAX_RETRY_DELAY_MS,
				BASE_RETRY_DELAY_MS * 2 ** attempts,
			);

			await this.repository.markRetry(
				job.id,
				attempts,
				errorMessage(error),
				new Date(Date.now() + delay),
			);
			console.error(
				`[print] job ${job.id} not printed (attempt ${attempts}), retrying in ${delay / 1000}s: ${errorMessage(error)}`,
			);
			return false;
		}

		await this.repository.markPrinted(job.id);
		console.log(`[print] job ${job.id} printed`);
		return true;
	}
}
