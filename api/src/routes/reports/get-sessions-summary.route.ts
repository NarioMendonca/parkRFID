import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { getSessionsSummary } from "@/usecases/reports/readModel/get-sessions-summary.js";

export async function getSessionsSummaryRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().get(
		"/sessions",
		{
			schema: {
				response: {
					200: z.object({
						activeSessions: z.number(),
						sessionsCreatedToday: z.number(),
					}),
				},
			},
		},
		async (_request, reply) => {
			const summary = await getSessionsSummary();

			reply.status(200).send(summary);
			return;
		},
	);
}
