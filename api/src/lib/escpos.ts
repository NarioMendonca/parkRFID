const ESC = 0x1b;
const GS = 0x1d;
const LF = 0x0a;
const QUESTION_MARK = 0x3f;

export type Codepage = "850" | "ascii";

export type TicketOptions = {
	codepage: Codepage;
	columns: number;
};

export type OrderTicketData = {
	id: string;
	createdAt: Date;
	tableNumber: string | null;
	braceletId: string;
	items: { name: string; amount: number }[];
};

// The characters Portuguese needs above ASCII, in code page 850 (ESC t 2)
const CP850: Record<string, number> = {
	Ç: 0x80,
	ü: 0x81,
	é: 0x82,
	â: 0x83,
	ä: 0x84,
	à: 0x85,
	ç: 0x87,
	ê: 0x88,
	ë: 0x89,
	è: 0x8a,
	ï: 0x8b,
	î: 0x8c,
	ì: 0x8d,
	Ä: 0x8e,
	É: 0x90,
	ô: 0x93,
	ö: 0x94,
	ò: 0x95,
	û: 0x96,
	ù: 0x97,
	Ö: 0x99,
	Ü: 0x9a,
	á: 0xa0,
	í: 0xa1,
	ó: 0xa2,
	ú: 0xa3,
	ñ: 0xa4,
	Ñ: 0xa5,
	ª: 0xa6,
	º: 0xa7,
	Á: 0xb5,
	Â: 0xb6,
	À: 0xb7,
	ã: 0xc6,
	Ã: 0xc7,
	Ê: 0xd2,
	Ë: 0xd3,
	È: 0xd4,
	Í: 0xd6,
	Î: 0xd7,
	Ï: 0xd8,
	Ì: 0xde,
	Ó: 0xe0,
	Ô: 0xe2,
	Ò: 0xe3,
	õ: 0xe4,
	Õ: 0xe5,
	Ú: 0xe9,
	Û: 0xea,
	Ù: 0xeb,
};

function stripAccents(text: string) {
	return text.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function wrap(text: string, width: number) {
	const lines: string[] = [];
	let current = "";

	for (const word of text.split(/\s+/).filter(Boolean)) {
		current = current ? `${current} ${word}` : word;

		if (current.length > width && current.includes(" ")) {
			const lastSpace = current.lastIndexOf(" ");
			lines.push(current.slice(0, lastSpace));
			current = current.slice(lastSpace + 1);
		}

		while (current.length > width) {
			lines.push(current.slice(0, width));
			current = current.slice(width);
		}
	}

	if (current) {
		lines.push(current);
	}

	return lines;
}

export class EscPosTicket {
	private bytes: number[] = [];

	constructor(private options: TicketOptions) {
		this.bytes.push(ESC, 0x40); // initialize the printer

		if (options.codepage === "850") {
			this.bytes.push(ESC, 0x74, 2);
		}
	}

	align(mode: "left" | "center") {
		this.bytes.push(ESC, 0x61, mode === "center" ? 1 : 0);
		return this;
	}

	bold(enabled: boolean) {
		this.bytes.push(ESC, 0x45, enabled ? 1 : 0);
		return this;
	}

	// Character size multipliers, from 1 (normal) to 8
	size(width: number, height: number) {
		this.bytes.push(GS, 0x21, ((width - 1) << 4) | (height - 1));
		return this;
	}

	text(value: string) {
		this.bytes.push(...this.encode(value));
		return this;
	}

	line(value = "") {
		this.text(value);
		this.bytes.push(LF);
		return this;
	}

	separator() {
		return this.line("-".repeat(this.options.columns));
	}

	feed(lines: number) {
		this.bytes.push(ESC, 0x64, lines);
		return this;
	}

	// Feeds the paper to the cutter and cuts (partial cut)
	cut() {
		this.bytes.push(GS, 0x56, 66, 0);
		return this;
	}

	build() {
		return Buffer.from(this.bytes);
	}

	// Control characters are dropped, so text coming from requests can never
	// inject printer commands
	private encode(value: string) {
		const text =
			this.options.codepage === "ascii" ? stripAccents(value) : value;

		return Array.from(text, (char) => {
			const code = char.charCodeAt(0);

			if (code < 0x20 || code === 0x7f) {
				return 0x20;
			}

			if (code < 0x80) {
				return code;
			}

			return this.options.codepage === "850"
				? (CP850[char] ?? QUESTION_MARK)
				: QUESTION_MARK;
		});
	}
}

export function renderOrderTicket(
	order: OrderTicketData,
	options: TicketOptions,
) {
	const ticket = new EscPosTicket(options);
	const { columns } = options;
	const tableLabel = order.tableNumber ? `MESA ${order.tableNumber}` : "SEM MESA";

	ticket.align("center");

	ticket.size(3, 3).bold(true);
	for (const part of wrap(tableLabel, Math.floor(columns / 3))) {
		ticket.line(part);
	}
	ticket.size(1, 1).bold(false);

	ticket.align("left").separator();
	ticket.line(`Pedido: #${order.id.slice(0, 8)}`);
	ticket.line(`Pulseira: ${order.braceletId}`);
	ticket.line(
		order.createdAt.toLocaleString("pt-BR", {
			dateStyle: "short",
			timeStyle: "short",
		}),
	);
	ticket.separator();

	ticket.size(1, 2).bold(true);
	for (const item of order.items) {
		const [first = "", ...rest] = wrap(`${item.amount}x ${item.name}`, columns);
		ticket.line(first);
		for (const continuation of rest) {
			ticket.line(`   ${continuation}`);
		}
	}
	ticket.size(1, 1).bold(false);

	ticket.separator();
	ticket.feed(4).cut();

	return ticket.build();
}
