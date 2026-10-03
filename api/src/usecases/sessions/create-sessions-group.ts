import { InvalidResourceError } from "@/errors/InvalidResourceError.js";
import type { SessionGroupDTO } from "@/model/dtos/session-group-dto.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

type SessionGroupInput = {
	responsibleCpf: string;
	responsiblePhoneNumber: string;
};

export class CreateSessionGroupUseCase {
	private sessionsRepository = new PrismaSessionsRepository();

	async handle({
		responsibleCpf,
		responsiblePhoneNumber,
	}: SessionGroupInput): Promise<SessionGroupDTO> {
		if (responsibleCpf.length !== 11) {
			throw new InvalidResourceError("Invalid responsible cpf");
		}

		const sessionGroup = await this.sessionsRepository.createSessionGroup({
			responsibleCpf,
			responsiblePhoneNumber,
		});

		return sessionGroup;
	}
}
