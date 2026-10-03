import type { FastifyInstance } from "fastify";
import { braceletsRoutes } from "./bracelets/bracelets-routes.js";
import { menuItemsRoutes } from "./menu-items/menu-items-routes.js";
import { ordersRoutes } from "./orders/orders-routes.js";
import { sessionsRoutes } from "./sessions/sessions-routes.js";

export async function routes(app: FastifyInstance) {
	//sessions routes
	app.register(sessionsRoutes, {
		prefix: "/sessions",
	});
	app.register(menuItemsRoutes, {
		prefix: "/menu",
	});
	app.register(ordersRoutes, {
		prefix: "/orders",
	});
	app.register(braceletsRoutes, {
		prefix: "/bracelets",
	});
}
