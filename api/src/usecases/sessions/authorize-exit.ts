import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

type AuthorizeExitInput = {
	braceletId: string;
};

type AuthorizeExitOutput = {
	allowed: boolean;
};

export class AuthorizeExitUseCase {
	private prismaSessionsRepository = new PrismaSessionsRepository();
	private prismaBraceletsRepository = new PrismaBraceletsRepository();

	async handle({
		braceletId,
	}: AuthorizeExitInput): Promise<AuthorizeExitOutput> {
		const bracelet =
			await this.prismaBraceletsRepository.findByUidRfid(braceletId);
		if (!bracelet) {
			throw new NotFoundError("Bracelet not registered");
		}

		const { allowed, closedSession } = bracelet.authorizeExit();
		if (closedSession) {
			await this.prismaSessionsRepository.saveSession(closedSession);
		}

		return {
			allowed,
		};
	}
}
