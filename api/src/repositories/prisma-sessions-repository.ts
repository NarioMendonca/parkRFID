import { Decimal } from "decimal.js";
import { Session } from "@/entities/session.js";
import { SessionGroup } from "@/entities/session-group.js";
import { prisma } from "@/lib/prisma.js";
import type { Sessions } from "../../generated/prisma/client.js";

export function toSessionEntity(session: Sessions) {
	return Session.restore({
		...session,
		total: new Decimal(session.total.toString()),
	});
}

export class PrismaSessionsRepository {
	async findSessionByBraceletId(braceletId: string) {
		const session = await prisma.sessions.findFirst({
			where: {
				braceletId,
			},
		});

		return session;
	}

	async findSessionGroupById(id: string) {
		const sessionGroup = await prisma.sessionsGroup.findFirst({
			where: {
				id,
			},
		});

		return sessionGroup ? SessionGroup.restore(sessionGroup) : null;
	}

	async createSessionGroup(sessionGroup: SessionGroup) {
		await prisma.sessionsGroup.create({
			data: {
				id: sessionGroup.id,
				responsibleCpf: sessionGroup.responsibleCpf,
				responsiblePhoneNumber: sessionGroup.responsiblePhoneNumber,
			},
		});
	}

	async createSession(session: Session) {
		await prisma.sessions.create({
			data: {
				id: session.id,
				braceletId: session.braceletId,
				checkinDate: session.checkinDate,
				checkoutDate: session.checkoutDate,
				status: session.status,
				total: session.total,
				sessionType: session.sessionType,
				sessionsGroupId: session.sessionsGroupId,
			},
		});
	}

	async saveSession(session: Session) {
		await prisma.sessions.update({
			where: {
				id: session.id,
			},
			data: {
				checkoutDate: session.checkoutDate,
				status: session.status,
				total: session.total,
			},
		});
	}
}
