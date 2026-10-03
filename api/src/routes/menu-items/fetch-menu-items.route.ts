import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { menuItemToResponse } from "@/model/mappers/menu-item-to-response.js";
import { fetchMenuItems } from "@/usecases/menu-items/readModel/fetch-menu-items.js";
import { MenuItemSchema } from "../schemas/menu-items/menu-item.schema.js";

export async function fetchMenuItemsRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().get(
		"/",
		{
			schema: {
				querystring: z.object({
					category: z.string().optional(),
				}),
				response: {
					200: z.array(MenuItemSchema),
				},
			},
		},
		async (request, reply) => {
			const { category } = request.query;
			const menuItemsRaw = await fetchMenuItems(category);
			const menuItems = menuItemsRaw.map((menuItemRaw) => {
				return menuItemToResponse(menuItemRaw);
			});

			reply.status(200).send(menuItems);
			return;
		},
	);
}
