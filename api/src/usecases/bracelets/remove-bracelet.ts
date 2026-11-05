import { DomainError } from "@/errors/DomainError.js";
import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";

type removeBraceletInput = {
	uid_rfid: string;
};

export class RemoveBraceletUseCase {
	private readonly braceletsRepository = new PrismaBraceletsRepository();

	async handle({ uid_rfid }: removeBraceletInput): Promise<void> {
		const braceletExists =
			await this.braceletsRepository.findByUidRfid(uid_rfid);

		if (!braceletExists) {
			throw new NotFoundError("Pulseira não cadastrada");
		}

		if (braceletExists.activeSession) {
			throw new DomainError(
				"A pulseira tem uma sessão ativa e não pode ser removida",
				409,
			);
		}

		await this.braceletsRepository.remove(uid_rfid);
	}
}
