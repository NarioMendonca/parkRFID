import net from "node:net";
import type { Codepage } from "./escpos.js";

export type PrinterConfig = {
	host: string;
	port: number;
	columns: number;
	codepage: Codepage;
};

// Printing is only enabled when PRINTER_HOST is set
export function getPrinterConfig(): PrinterConfig | null {
	const host = process.env.PRINTER_HOST?.trim();
	if (!host) {
		return null;
	}

	return {
		host,
		port: Number(process.env.PRINTER_PORT) || 9100,
		columns: Number(process.env.PRINTER_COLUMNS) || 42,
		codepage: process.env.PRINTER_CODEPAGE === "ascii" ? "ascii" : "850",
	};
}

// Sends raw bytes to a network printer (RAW / port 9100) and closes the
// connection. Rejects when the printer can't be reached or stops answering.
export function sendToPrinter(
	config: Pick<PrinterConfig, "host" | "port">,
	data: Buffer,
	timeoutMs = 8000,
) {
	return new Promise<void>((resolve, reject) => {
		const socket = net.createConnection({
			host: config.host,
			port: config.port,
		});

		let finished = false;
		let sent = false;

		const finish = (error?: Error) => {
			if (finished) {
				return;
			}

			finished = true;
			socket.destroy();

			if (error) {
				reject(error);
				return;
			}

			resolve();
		};

		socket.setTimeout(timeoutMs, () => {
			finish(new Error(`Printer ${config.host}:${config.port} timed out`));
		});

		socket.once("error", (error) => finish(error));

		// The printer closing the connection after receiving everything is fine
		socket.once("close", () => {
			finish(sent ? undefined : new Error("Printer closed the connection"));
		});

		socket.once("connect", () => {
			socket.end(data, () => {
				sent = true;
				// Gives the printer a moment to take the data before closing
				setTimeout(() => finish(), 500);
			});
		});
	});
}
