import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { PaySessionUseCase } from "@/usecases/sessions/pay-session.js";

const paySessionUseCase = new PaySessionUseCase();

export async function paySessionRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().post(
		"/:braceletId/pay",
		{
			schema: {
				params: z.object({
					braceletId: z.string(),
				}),
				response: {
					200: z.object({
						paidAmount: z.string(),
						message: z.string(),
					}),
					404: z.object({
						message: z.string(),
					}),
					409: z.object({
						message: z.string(),
					}),
				},
			},
		},
		async (request, reply) => {
			const { braceletId } = request.params;
			const { paidAmount } = await paySessionUseCase.handle({
				braceletId,
			});

			reply.status(200).send({
				paidAmount: paidAmount.toFixed(2),
				message: "Session successfully paid",
			});
			return;
		},
	);
}
