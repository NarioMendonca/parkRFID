import { SessionGroup } from "@/entities/session-group.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";
import { CreateSessionInput } from "./create-session.js";
import { SessionDTO } from "@/model/dtos/session-dto.js";
import { UseCase } from "../UseCase.js";
import { DomainError } from "@/errors/DomainError.js";
import { AlreadyExistsError } from "@/errors/AlreadyExistsError.js";

type InitializeSessionGroupInput = {
	responsibleCpf: string;
	responsiblePhoneNumber: string;
	groupFirstSession: Omit<CreateSessionInput, "sessionGroupId">
};

type InitializeSessionGroupOutput = {
	sessionGroup: SessionGroup;
	session: SessionDTO
}

export class InitializeSessionGroupUseCase {
	constructor(private readonly createSessionUseCase: UseCase<CreateSessionInput, Promise<SessionDTO>>) {}
	private sessionsRepository = new PrismaSessionsRepository();

	async handle({
		responsibleCpf,
		responsiblePhoneNumber,
		groupFirstSession
	}: InitializeSessionGroupInput): Promise<InitializeSessionGroupOutput> {
		const { braceletId, sessionType } = groupFirstSession

		if (sessionType !== "NORMAL") {
			throw new DomainError("A sessão do responsável do grupo não pode ser do tipo infantil")
		}

		const sessionGroupAlreadyExists = await this.sessionsRepository.findActiveSessionGroupByCpf(responsibleCpf)
		if (sessionGroupAlreadyExists) {
			throw new AlreadyExistsError("Uma sessão de grupo com o mesmo cpf já está ativa")
		}

		const sessionGroup = SessionGroup.create({
			responsibleCpf,
			responsiblePhoneNumber,
		});
		await this.sessionsRepository.createSessionGroup(sessionGroup);

		try {
			const session = await this.createSessionUseCase.handle({ braceletId, sessionType: "NORMAL", sessionGroupId: sessionGroup.id })

			return {
				sessionGroup,
				session
			};
		} catch (error) {
			await this.sessionsRepository.deleteSessionGroup(sessionGroup.id);
			throw error
		}

	}
}
