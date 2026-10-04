import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { sessionGroupToResponse } from "@/model/mappers/session-group-to-response.js";
import { CreateSessionGroupUseCase } from "@/usecases/sessions/create-sessions-group.js";
import { createSessionGroupSchema } from "../schemas/create-session-group.schema.js";

const createSessionGroupUseCase = new CreateSessionGroupUseCase();

export async function createSessionGroupRoute(app: FastifyInstance) {
	app
		.withTypeProvider<ZodTypeProvider>()
		.post(
			"/checkin/group",
			{ schema: createSessionGroupSchema },
			async (request, reply) => {
				const { responsibleCpf, responsiblePhoneNumber } = request.body;
				const sessionGroupRaw = await createSessionGroupUseCase.handle({
					responsibleCpf,
					responsiblePhoneNumber,
				});

				const sessionGroup = sessionGroupToResponse(sessionGroupRaw);

				reply
					.status(200)
					.send({ sessionGroup, message: "Succesfully created" });
				return;
			},
		);
}
