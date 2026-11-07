import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { sessionGroupToResponse } from "@/model/mappers/session-group-to-response.js";
import { InitializeSessionGroupUseCase } from "@/usecases/sessions/initialize-sessions-group.js";
import { createSessionGroupSchema } from "../schemas/initialize-session-group.schema.js";
import { CreateSessionUseCase } from "@/usecases/sessions/create-session.js";
import { sessionToResponse } from "@/model/mappers/session-to-response.js";

const createSessionUsecase = new CreateSessionUseCase()
const initializeSessionGroupUseCase = new InitializeSessionGroupUseCase(createSessionUsecase);

export async function createSessionGroupRoute(app: FastifyInstance) {
	app
		.withTypeProvider<ZodTypeProvider>()
		.post(
			"/checkin/group",
			{ schema: createSessionGroupSchema },
			async (request, reply) => {
				const { responsibleCpf, responsiblePhoneNumber, groupFirstSession } = request.body;

				const { sessionGroup: sessionGroupRaw, session: sessionRaw } = await initializeSessionGroupUseCase.handle({
					responsibleCpf,
					responsiblePhoneNumber,
					groupFirstSession
				});

				const sessionGroup = sessionGroupToResponse(sessionGroupRaw);
				const session = sessionToResponse(sessionRaw)

				reply
					.status(200)
					.send({ sessionGroup, session, message: "Succesfully created" });
				return;
			},
		);
}
