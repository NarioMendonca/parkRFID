import { AlreadyExistsError } from "@/errors/AlreadyExistsError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";

type RegisterBraceletInput = {
	uid_rfid: string;
};

export class RegisterBraceletUseCase {
	private readonly braceletsRepository = new PrismaBraceletsRepository();

	async handle({ uid_rfid }: RegisterBraceletInput): Promise<void> {
		const braceletAlreadyRegisted =
			await this.braceletsRepository.findByUidRfid(uid_rfid);

		if (braceletAlreadyRegisted) {
			throw new AlreadyExistsError("Bracelet already exists");
		}

		await this.braceletsRepository.register(uid_rfid);
	}
}
