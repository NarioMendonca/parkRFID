import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

type FinishSessionInput = {
	braceletId: string;
};

export class CloseSessionUseCase {
	private prismaSessionsRepository = new PrismaSessionsRepository();
	private prismaBraceletsRepository = new PrismaBraceletsRepository();

	async handle({ braceletId }: FinishSessionInput) {
		const bracelet =
			await this.prismaBraceletsRepository.findByUidRfid(braceletId);
		if (!bracelet) {
			throw new NotFoundError("Bracelet not registered");
		}

		const session = bracelet.closeSession();

		await this.prismaSessionsRepository.saveSession(session);
		return session;
	}
}
