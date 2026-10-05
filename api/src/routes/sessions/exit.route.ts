import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { ExitUseCase } from "@/usecases/sessions/exit.js";

const exitUseCase = new ExitUseCase();

export async function exitRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().post(
		"/:braceletId/exit",
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
					409: z.object({
						message: z.string(),
					}),
				},
			},
		},
		async (request, reply) => {
			const { braceletId } = request.params;
			await exitUseCase.handle({ braceletId });

			reply.status(200).send({ message: "Exit authorized" });
			return;
		},
	);
}
