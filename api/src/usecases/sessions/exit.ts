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
			throw new NotFoundError("Pulseira não cadastrada");
		}

		if (!bracelet.activeSession) {
			throw new NotFoundError("Nenhuma sessão ativa foi encontrada nessa pulseira")
		}

		const closedSession = bracelet.exit();
		if (!closedSession) {
			throw new DomainError("Erro ao marcar sessão como fechada")
		}

		await this.prismaSessionsRepository.saveSession(closedSession);

		// if the closed session is the last of a group, it should be closed
		const sessionGroup = await this.prismaSessionsRepository.findActiveSessionGroupById(closedSession.group.id)
		if (!sessionGroup) {
			console.error(`Critical: A session group of a session was closed or not created while session is active, sessionId: ${closedSession.id}`)
			// TODO: create a Log to show a critical error: group of the session not found
			return
		}

		if (sessionGroup.size === 0) {
			sessionGroup.close()
			await this.prismaSessionsRepository.saveGroup(sessionGroup)
		}
	}
}
