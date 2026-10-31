import net from "node:net";
import { afterEach, describe, expect, it } from "vitest";
import { prisma } from "@/lib/prisma.js";
import { getPrinterConfig } from "@/lib/printer.js";
import { PrintQueueWorker } from "@/usecases/print/print-queue-worker.js";
import { createTestApp } from "../helpers/app.js";
import { BRACELET_UID, checkin, createMenuItem } from "../helpers/factories.js";

const app = await createTestApp();

// A fake printer: a TCP server that keeps what each connection received
function startFakePrinter() {
	const tickets: string[] = [];
	const server = net.createServer((socket) => {
		const chunks: Buffer[] = [];
		socket.on("data", (chunk) => chunks.push(chunk));
		socket.on("end", () =>
			tickets.push(Buffer.concat(chunks).toString("latin1")),
		);
	});

	return new Promise<{
		tickets: string[];
		port: number;
		close: () => Promise<void>;
	}>((resolve) => {
		server.listen(0, "127.0.0.1", () => {
			const { port } = server.address() as net.AddressInfo;
			resolve({
				tickets,
				port,
				close: () => new Promise<void>((done) => server.close(() => done())),
			});
		});
	});
}

async function waitFor(condition: () => boolean | Promise<boolean>) {
	const startedAt = Date.now();
	while (!(await condition())) {
		if (Date.now() - startedAt > 10000) {
			throw new Error("Timed out waiting for the condition");
		}
		await new Promise((resolve) => setTimeout(resolve, 50));
	}
}

function usePrinter(port: number) {
	process.env.PRINTER_HOST = "127.0.0.1";
	process.env.PRINTER_PORT = String(port);

	const config = getPrinterConfig();
	if (!config) {
		throw new Error("Printer should be configured");
	}

	return new PrintQueueWorker(config);
}

async function placeOrder(
	menuItemId: string,
	tableNumber: string,
	amount = 2,
) {
	const response = await app.inject({
		method: "POST",
		url: "/orders",
		payload: {
			braceletId: BRACELET_UID,
			tableNumber,
			items: [{ menuItemId, amount }],
		},
	});

	expect(response.statusCode).toBe(200);
}

afterEach(() => {
	delete process.env.PRINTER_HOST;
	delete process.env.PRINTER_PORT;
});

describe("fila de impressão", () => {
	it(
		"imprime os pedidos um a um, na ordem, com a mesa e os acentos",
		{ timeout: 15000 },
		async () => {
			const printer = await startFakePrinter();
			const worker = usePrinter(printer.port);

			await checkin(app);
			const menuItem = await createMenuItem(app, { name: "Pão de queijo" });
			await placeOrder(menuItem.id, "12");
			await placeOrder(menuItem.id, "7");

			await worker.start();
			try {
				await waitFor(() => printer.tickets.length === 2);
			} finally {
				worker.stop();
				await printer.close();
			}

			expect(printer.tickets[0]).toContain("MESA 12");
			expect(printer.tickets[1]).toContain("MESA 7");
			// "ã" is byte 0xC6 in code page 850, which latin1 shows as "Æ"
			expect(printer.tickets[0]).toContain("2x P\u00c6o de queijo");
			expect(await prisma.printJobs.findMany()).toMatchObject([
				{ status: "PRINTED" },
				{ status: "PRINTED" },
			]);
		},
	);

	it(
		"mantém o pedido e o job na fila quando a impressora está fora do ar",
		{ timeout: 15000 },
		async () => {
			const printer = await startFakePrinter();
			const { port } = printer;
			await printer.close();
			const worker = usePrinter(port);

			await checkin(app);
			const menuItem = await createMenuItem(app);
			await placeOrder(menuItem.id, "3");
			expect(await prisma.orders.count()).toBe(1);

			await worker.start();
			try {
				await waitFor(
					async () => (await prisma.printJobs.findFirst())?.attempts === 1,
				);
			} finally {
				worker.stop();
			}

			const job = await prisma.printJobs.findFirstOrThrow();
			expect(job.status).toBe("PENDING");
			expect(job.lastError).not.toBeNull();
		},
	);

	it("não cria job de impressão quando a impressora não está configurada", async () => {
		await checkin(app);
		const menuItem = await createMenuItem(app);
		await placeOrder(menuItem.id, "5");

		expect(await prisma.orders.count()).toBe(1);
		expect(await prisma.printJobs.count()).toBe(0);
	});
});
