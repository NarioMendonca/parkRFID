import { prisma } from "@/lib/prisma.js";

export class PrismaBraceletsRepository {
	async findByUidRfid(uid_rfid: string) {
		const bracelet = await prisma.bracelets.findFirst({
			where: {
				uid_rfid,
			},
		});

		return bracelet;
	}

	async register(uid_rfid: string) {
		await prisma.bracelets.create({
			data: {
				uid_rfid,
			},
		});
	}

	async remove(uid_rfid: string) {
		await prisma.bracelets.delete({
			where: {
				uid_rfid,
			},
		});
	}
}
