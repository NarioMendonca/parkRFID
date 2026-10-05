import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { sessionToResponse } from "@/model/mappers/session-to-response.js";
import { fetchBraceletSessions } from "@/usecases/bracelets/readModel/fetch-bracelet-sessions.js";
import { SessionSchema } from "../schemas/session.schema.js";

export async function fetchBraceletSessionsRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().get(
		"/:uid_rfid/sessions",
		{
			schema: {
				params: z.object({
					uid_rfid: z.string(),
				}),
				response: {
					200: z.object({
						sessions: z.array(SessionSchema),
					}),
					404: z.object({
						message: z.string(),
					}),
				},
			},
		},
		async (request, reply) => {
			const { uid_rfid } = request.params;
			const sessions = await fetchBraceletSessions(uid_rfid);

			reply.status(200).send({ sessions: sessions.map(sessionToResponse) });
			return;
		},
	);
}
