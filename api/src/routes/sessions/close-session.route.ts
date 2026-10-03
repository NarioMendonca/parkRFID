import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { CloseSessionUseCase } from "@/usecases/sessions/close-session.js";

const closeSessionUseCase = new CloseSessionUseCase();

export async function closeSessionRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().post(
		"/:braceletId/close",
		{
			schema: {
				params: z.object({
					braceletId: z.string(),
				}),
				response: {
					200: z.object({
						message: z.string(),
					}),
					404: z.object({
						message: z.string(),
					}),
				},
			},
		},
		async (request, reply) => {
			const { braceletId } = request.params;
			await closeSessionUseCase.handle({
				braceletId,
			});

			reply.status(200).send({ message: "Successfully deleted" });
			return;
		},
	);
}
