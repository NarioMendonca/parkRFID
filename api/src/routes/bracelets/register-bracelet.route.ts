import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { RegisterBraceletUseCase } from "@/usecases/bracelets/register-bracelet.js";

const registerBraceletUseCase = new RegisterBraceletUseCase();

export async function registerBracelet(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().post(
		"/",
		{
			schema: {
				body: z.object({
					uid_rfid: z.string(),
				}),
				response: {
					201: z.object({
						message: z.string(),
					}),
					401: z.object({
						message: z.string(),
					}),
					409: z.object({
						message: z.string(),
					}),
				},
			},
		},
		async (request, reply) => {
			const { uid_rfid } = request.body;

			await registerBraceletUseCase.handle({ uid_rfid });

			return reply.status(201).send({ message: "bracelet registered" });
		},
	);
}
