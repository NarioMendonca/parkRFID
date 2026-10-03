import type { FastifyInstance } from "fastify";
import { createMenuItemRoute } from "./create-menu-item.route.js";
import { deleteMenuItemRoute } from "./delete-menu-item.route.js";
import { fetchMenuItemsRoute } from "./fetch-menu-items.route.js";
import { updateMenuItemRoute } from "./update-menu-item.route.js";

export async function menuItemsRoutes(app: FastifyInstance) {
	app.register(fetchMenuItemsRoute);
	app.register(createMenuItemRoute);
	app.register(updateMenuItemRoute);
	app.register(deleteMenuItemRoute);
}
