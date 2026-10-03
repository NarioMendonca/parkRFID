import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { RemoveBraceletUseCase } from "@/usecases/bracelets/remove-bracelet.js";

const removeBraceletUseCase = new RemoveBraceletUseCase();

export async function removeBracelet(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().delete(
		"/:uid_rfid",
		{
			schema: {
				params: z.object({
					uid_rfid: z.string(),
				}),
				response: {
					204: z.object({
						message: z.string(),
					}),
					401: z.object({
						message: z.string(),
					}),
				},
			},
		},
		async (request, reply) => {
			const { uid_rfid } = request.params;

			await removeBraceletUseCase.handle({ uid_rfid });

			return reply.status(204).send({ message: "bracelet removed" });
		},
	);
}
