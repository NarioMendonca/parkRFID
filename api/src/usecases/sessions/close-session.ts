import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

type FinishSessionInput = {
	braceletId: string;
};

export class CloseSessionUseCase {
	private prismaSessionsRepository = new PrismaSessionsRepository();

	async handle({ braceletId }: FinishSessionInput) {
		const sessionToFinish =
			await this.prismaSessionsRepository.findActiveSessionByBraceletId(
				braceletId,
			);
		if (!sessionToFinish) {
			throw new NotFoundError("Session to finish not found");
		}

		const session =
			await this.prismaSessionsRepository.closeSession(braceletId);
		return session;
	}
}
