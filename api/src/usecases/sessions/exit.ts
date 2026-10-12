import { DomainError } from "@/errors/DomainError.js";
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
		if (!closedSession) {
			throw new DomainError("Erro ao marcar sessão como fechada")
		}

		await this.prismaSessionsRepository.saveSession(closedSession);

		// if the closed session is the last of a group, it should be closed
		const sessionGroup = await this.prismaSessionsRepository.findActiveSessionGroupById(closedSession.group.id)
		if (!sessionGroup) {
			// TODO: create a Log to show a critical error: group of the session not found
			return
		}

		sessionGroup.close()

		if (sessionGroup.size === 0) {
			await this.prismaSessionsRepository.saveGroup(sessionGroup)
		}
	}
}
