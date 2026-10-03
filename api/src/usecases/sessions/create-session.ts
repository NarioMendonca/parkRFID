import { Decimal } from "decimal.js";
import { AlreadyExistsError } from "@/errors/AlreadyExistsError.js";
import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

type CreateSessionInput = {
	sessionGroupId: string;
	braceletId: string;
	sessionType?: "NORMAL" | "KID";
};

export class CreateSessionUseCase {
	private prismaSessionsRepository = new PrismaSessionsRepository();

	async handle({
		braceletId,
		sessionGroupId,
		sessionType,
	}: CreateSessionInput) {
		const searchedSession =
			await this.prismaSessionsRepository.findActiveSessionByBraceletId(
				braceletId,
			);
		if (searchedSession) {
			throw new AlreadyExistsError(
				"Session active already exists in this bracelet",
			);
		}

		const searchedGroup =
			await this.prismaSessionsRepository.findSessionGroupById(sessionGroupId);
		if (!searchedGroup) {
			throw new NotFoundError(
				"Session Group to register bracelet session not found",
			);
		}

		const session = await this.prismaSessionsRepository.createSession({
			braceletId,
			checkoutDate: null,
			checkinDate: new Date(),
			total: new Decimal("0"),
			sessionType: sessionType ?? "NORMAL",
			status: "OPEN",
			sessionsGroupId: sessionGroupId,
		});
		return session;
	}
}
