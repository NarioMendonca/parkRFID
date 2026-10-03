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
			throw new NotFoundError("Bracelet to remove not found");
		}

		await this.braceletsRepository.remove(uid_rfid);
	}
}
