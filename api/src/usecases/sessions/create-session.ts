import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

type CreateSessionInput = {
	sessionGroupId: string;
	braceletId: string;
	sessionType?: "NORMAL" | "KID";
};

export class CreateSessionUseCase {
	private prismaSessionsRepository = new PrismaSessionsRepository();
	private prismaBraceletsRepository = new PrismaBraceletsRepository();

	async handle({
		braceletId,
		sessionGroupId,
		sessionType,
	}: CreateSessionInput) {
		const bracelet =
			await this.prismaBraceletsRepository.findByUidRfid(braceletId);
		if (!bracelet) {
			throw new NotFoundError("Bracelet not registered");
		}

		const sessionGroup =
			await this.prismaSessionsRepository.findActiveSessionGroupById(sessionGroupId);
		if (!sessionGroup) {
			throw new NotFoundError(
				"Session Group to register bracelet session not found",
			);
		}

		const session = bracelet.checkin(sessionGroup, sessionType ?? "NORMAL");

		await this.prismaSessionsRepository.createSession(session);
		return session;
	}
}
