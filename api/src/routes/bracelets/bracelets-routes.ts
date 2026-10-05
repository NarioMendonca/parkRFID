import type { FastifyInstance } from "fastify";
import { fetchBraceletSessionsRoute } from "./fetch-bracelet-sessions.route.js";
import { registerBracelet } from "./register-bracelet.route.js";
import { removeBracelet } from "./remove-bracelet.route.js";

export async function braceletsRoutes(app: FastifyInstance) {
	app.register(registerBracelet);
	app.register(removeBracelet);
	app.register(fetchBraceletSessionsRoute);
}
