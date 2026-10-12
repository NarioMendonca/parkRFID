import { Decimal } from "decimal.js";
import type { Payment } from "@/entities/payment.js";
import { Session } from "@/entities/session.js";
import { SessionGroup } from "@/entities/session-group.js";
import { prisma } from "@/lib/prisma.js";
import type { Sessions } from "../../generated/prisma/client.js";

export async function toSessionEntity(session: Sessions, group: SessionGroup) {
	return Session.restore({
		...session,
		total: new Decimal(session.total.toString()),
		group
	});
}

export class PrismaSessionsRepository {
	async findActiveSessionByBraceletId(braceletId: string) {
		const session = await prisma.sessions.findFirst({
			where: {
				braceletId,
				status: "OPEN"
			},
		});

		return session;
	}

	async findActiveSessionGroupById(id: string) {
		const sessionGroup = await prisma.sessionsGroup.findFirst({
			where: {
				id,
				status: "OPEN"
			},
			include: {
				_count: {
					select: {
						session: true
					}
				}
			}
		});

		if (!sessionGroup) {
			return null;
		}

		const sessionsCount = sessionGroup._count.session

		return SessionGroup.restore({ ...sessionGroup, size: sessionsCount });
	}

	async createSessionGroup(sessionGroup: SessionGroup) {
		await prisma.sessionsGroup.create({
			data: {
				id: sessionGroup.id,
				responsibleCpf: sessionGroup.responsibleCpf,
				responsiblePhoneNumber: sessionGroup.responsiblePhoneNumber,
				balance: sessionGroup.balance,
				checkoutDt: sessionGroup.checkoutDt,
				createdAt: sessionGroup.createdAt,
				status: sessionGroup.status
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
				sessionsGroupId: session.group.id,
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

	async saveGroup(sessionGroup: SessionGroup) {
		await prisma.sessionsGroup.update({
			where: {
				id: sessionGroup.id,
			},
			data: {
				balance: sessionGroup.balance,
				checkoutDt: sessionGroup.checkoutDt,
				status: sessionGroup.status
			}
		})
	}

	// The session balance and its payment are saved together, so a payment is
	// never recorded without the balance being settled (or the other way around)
	async savePayment(session: Session, payment: Payment) {
		await prisma.$transaction([
			prisma.sessions.update({
				where: {
					id: session.id,
				},
				data: {
					total: session.total,
				},
			}),
			prisma.payments.create({
				data: {
					id: payment.id,
					sessionId: payment.sessionId,
					amount: payment.amount,
					createdAt: payment.createdAt,
				},
			}),
		]);
	}
}
