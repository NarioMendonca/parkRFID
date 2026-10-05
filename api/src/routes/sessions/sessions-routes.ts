import type { FastifyInstance } from "fastify";
import { closeSessionRoute } from "./close-session.route.js";
import { createSessionRoute } from "./create-session.route.js";
import { createSessionGroupRoute } from "./create-session-group.route.js";
import { exitRoute } from "./exit.route.js";

export async function sessionsRoutes(app: FastifyInstance) {
	app.register(createSessionRoute);
	app.register(createSessionGroupRoute);
	app.register(exitRoute);
	app.register(closeSessionRoute);
}
