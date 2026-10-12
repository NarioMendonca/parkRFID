import { Bracelet } from "@/entities/bracelet.js";
import { prisma } from "@/lib/prisma.js";
import { PrismaSessionsRepository, toSessionEntity } from "./prisma-sessions-repository.js";

const sessionRepository = new PrismaSessionsRepository()

export class PrismaBraceletsRepository {
	async findByUidRfid(uid_rfid: string) {
		const braceletData = await prisma.bracelets.findFirst({
			where: {
				uid_rfid,
			},
		});
		if (!braceletData) {
			return null;
		}

		const bracelet = Bracelet.restore({
			id: braceletData.id,
			uidRfid: braceletData.uid_rfid,
			createdAt: braceletData.createdAt,
			activeSession: null,
		});

		const session = await sessionRepository.findActiveSessionByBraceletId(uid_rfid)
		if (!session) {
			return bracelet
		}
		
		const sessionGroup = await sessionRepository.findActiveSessionGroupById(session.braceletId)
		if (!sessionGroup) {
			return bracelet
		}

		const braceleteWithSession = Bracelet.restore({
			id: braceletData.id,
			uidRfid: braceletData.uid_rfid,
			createdAt: braceletData.createdAt,
			activeSession: await toSessionEntity(session, sessionGroup),
		});
		return braceleteWithSession
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
