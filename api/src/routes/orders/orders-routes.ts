import type { FastifyInstance } from "fastify";
import { createOrderRoute } from "./create-order.route.js";

export async function ordersRoutes(app: FastifyInstance) {
	app.register(createOrderRoute);
}
