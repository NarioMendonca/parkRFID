import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { getTodayConsumption } from "@/usecases/reports/readModel/get-today-consumption.js";

export async function getTodayConsumptionRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().get(
		"/consumption/today",
		{
			schema: {
				response: {
					200: z.object({
						date: z.string(),
						total: z.string(),
					}),
				},
			},
		},
		async (_request, reply) => {
			const { date, total } = await getTodayConsumption();

			reply.status(200).send({ date, total: total.toFixed(2) });
			return;
		},
	);
}
