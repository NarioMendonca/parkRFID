import { Bracelet } from "@/entities/bracelet.js";
import { prisma } from "@/lib/prisma.js";
import { toSessionEntity } from "./prisma-sessions-repository.js";

export class PrismaBraceletsRepository {
	async findByUidRfid(uid_rfid: string) {
		const bracelet = await prisma.bracelets.findFirst({
			where: {
				uid_rfid,
			},
		});

		if (!bracelet) {
			return null;
		}

		const activeSession = await prisma.sessions.findFirst({
			where: {
				braceletId: uid_rfid,
				status: "OPEN",
			},
		});

		return Bracelet.restore({
			id: bracelet.id,
			uidRfid: bracelet.uid_rfid,
			createdAt: bracelet.createdAt,
			activeSession: activeSession ? toSessionEntity(activeSession) : null,
		});
	}

	async register(bracelet: Bracelet) {
		await prisma.bracelets.create({
			data: {
				id: bracelet.id,
				uid_rfid: bracelet.uidRfid,
				createdAt: bracelet.createdAt,
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
