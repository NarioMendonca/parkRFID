import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { sessionToResponse } from "@/model/mappers/session-to-response.js";
import { getSessionHistory } from "@/usecases/sessions/readModel/get-session-history.js";
import { SessionSchema } from "../schemas/session.schema.js";

const SessionEventSchema = z.discriminatedUnion("type", [
	z.object({ type: z.literal("CHECKIN"), date: z.date() }),
	z.object({
		type: z.literal("ORDER"),
		date: z.date(),
		orderId: z.string(),
		total: z.string(),
		items: z.array(
			z.object({
				menuItemId: z.string(),
				name: z.string(),
				amount: z.number(),
				unitPrice: z.string(),
				subtotal: z.string(),
			}),
		),
	}),
	z.object({
		type: z.literal("PAYMENT"),
		date: z.date(),
		paymentId: z.string(),
		amount: z.string(),
	}),
	z.object({ type: z.literal("CHECKOUT"), date: z.date() }),
]);

export async function getSessionHistoryRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().get(
		"/:sessionId/history",
		{
			schema: {
				params: z.object({
					sessionId: z.string(),
				}),
				response: {
					200: z.object({
						session: SessionSchema,
						events: z.array(SessionEventSchema),
					}),
					404: z.object({
						message: z.string(),
					}),
				},
			},
		},
		async (request, reply) => {
			const { sessionId } = request.params;
			const { session, events } = await getSessionHistory(sessionId);

			reply.status(200).send({ session: sessionToResponse(session), events });
			return;
		},
	);
}
