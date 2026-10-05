import type { FastifyInstance } from "fastify";
import { getSessionsSummaryRoute } from "./get-sessions-summary.route.js";
import { getTodayConsumptionRoute } from "./get-today-consumption.route.js";

export async function reportsRoutes(app: FastifyInstance) {
	app.register(getSessionsSummaryRoute);
	app.register(getTodayConsumptionRoute);
}
