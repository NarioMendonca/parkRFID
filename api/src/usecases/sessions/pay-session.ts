import { NotFoundError } from "@/errors/NotFoundError.js";
import { PrismaBraceletsRepository } from "@/repositories/prisma-bracelets-repository.js";
import { PrismaSessionsRepository } from "@/repositories/prisma-sessions-repository.js";

type PaySessionInput = {
	braceletId: string;
};

export class PaySessionUseCase {
	private prismaSessionsRepository = new PrismaSessionsRepository();
	private prismaBraceletsRepository = new PrismaBraceletsRepository();

	async handle({ braceletId }: PaySessionInput) {
		const bracelet =
			await this.prismaBraceletsRepository.findByUidRfid(braceletId);
		if (!bracelet) {
			throw new NotFoundError("Bracelet not registered");
		}

		const { session, payment } = bracelet.pay();

		await this.prismaSessionsRepository.savePayment(session, payment);
		return { paidAmount: payment.amount };
	}
}
