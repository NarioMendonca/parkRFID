import { buildApp } from "./app.js";
import { getPrinterConfig } from "./lib/printer.js";
import { PrintQueueWorker } from "./usecases/print/print-queue-worker.js";

const app = await buildApp();

const PORT = 3333;
await app.listen({ port: PORT, host: "0.0.0.0" });
console.log(`Server running on http://localhost:${PORT}`);
console.log(`Docs in http://localhost:${PORT}/docs`);

const printerConfig = getPrinterConfig();
if (printerConfig) {
	await new PrintQueueWorker(printerConfig).start();
	console.log(
		`Printing orders on ${printerConfig.host}:${printerConfig.port}`,
	);
} else {
	console.log("Printer not configured (set PRINTER_HOST to print orders)");
}
