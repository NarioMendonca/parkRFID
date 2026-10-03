import { Decimal } from "decimal.js";
import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { menuItemToResponse } from "@/model/mappers/menu-item-to-response.js";
import { UpdateMenuItemUseCase } from "@/usecases/menu-items/update-menu-item.js";
import { UpdateMenuItemSchema } from "../schemas/menu-items/update-menu-item.schema.js";

const updateMenuItemUseCase = new UpdateMenuItemUseCase();

export async function updateMenuItemRoute(app: FastifyInstance) {
	app
		.withTypeProvider<ZodTypeProvider>()
		.patch("/:id", { schema: UpdateMenuItemSchema }, async (request, reply) => {
			const params = request.body;

			const menuItemRaw = await updateMenuItemUseCase.handle({
				...params,
				price: new Decimal(params.price),
			});

			const menuItem = menuItemToResponse(menuItemRaw);

			reply.status(200).send({ menuItem, message: "Succesfully updated" });
			return;
		});
}
