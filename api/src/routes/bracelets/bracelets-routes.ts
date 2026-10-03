import type { FastifyInstance } from "fastify";
import { registerBracelet } from "./register-bracelet.route.js";
import { removeBracelet } from "./remove-bracelet.route.js";

export async function braceletsRoutes(app: FastifyInstance) {
	app.register(registerBracelet);
	app.register(removeBracelet);
}
