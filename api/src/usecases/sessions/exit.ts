import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

type ExitInput = {
	braceletId: string;
};

export class ExitUseCase {
	private prismaSessionsRepository = new PrismaSessionsRepository();
	private prismaBraceletsRepository = new PrismaBraceletsRepository();

	async handle({ braceletId }: ExitInput) {
		const bracelet =
			await this.prismaBraceletsRepository.findByUidRfid(braceletId);
		if (!bracelet) {
			throw new NotFoundError("Bracelet not registered");
		}

		if (!bracelet.activeSession) {
			throw new NotFoundError("No active session was found in bracelet")
		}

		const closedSession = bracelet.exit();
		if (closedSession) {
			await this.prismaSessionsRepository.saveSession(closedSession);
		}
	}
}
