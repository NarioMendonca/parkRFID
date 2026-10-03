import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { AuthorizeExitUseCase } from "@/usecases/sessions/authorize-exit.js";

const authorizeExitUseCase = new AuthorizeExitUseCase();

export async function authorizeExitRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().post(
		"/:braceletId/authorize",
		{
			schema: {
				params: z.object({
					braceletId: z.string(),
				}),
				response: {
					200: z.object({
						allowed: z.boolean(),
						message: z.string(),
					}),
					401: z.object({
						allowed: z.boolean(),
						message: z.string(),
					}),
				},
			},
		},
		async (request, reply) => {
			const { braceletId } = request.params;
			const response = await authorizeExitUseCase.handle({
				braceletId,
			});
			if (response.allowed) {
				reply
					.status(200)
					.send({ allowed: response.allowed, message: "Authorized" });
				return;
			}
			reply
				.status(401)
				.send({ allowed: response.allowed, message: "Unauthorized" });
			return;
		},
	);
}
