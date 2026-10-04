import { SessionGroup } from "@/entities/session-group.js";
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
	}: SessionGroupInput): Promise<SessionGroup> {
		const sessionGroup = SessionGroup.create({
			responsibleCpf,
			responsiblePhoneNumber,
		});

		await this.sessionsRepository.createSessionGroup(sessionGroup);
		return sessionGroup;
	}
}
