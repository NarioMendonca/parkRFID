import { Decimal } from "decimal.js";
import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { menuItemToResponse } from "@/model/mappers/menu-item-to-response.js";
import { CreateMenuItemUseCase } from "@/usecases/menu-items/create-menu-item.js";
import { CreateMenuItemSchema } from "../schemas/menu-items/create-menu-item.schema.js";

const createMenuItemUseCase = new CreateMenuItemUseCase();

export async function createMenuItemRoute(app: FastifyInstance) {
	app
		.withTypeProvider<ZodTypeProvider>()
		.post("/", { schema: CreateMenuItemSchema }, async (request, reply) => {
			const params = request.body;
			const menuItemRaw = await createMenuItemUseCase.handle({
				...params,
				price: new Decimal(params.price),
			});

			const menuItem = menuItemToResponse(menuItemRaw);

			reply.status(200).send({ menuItem, message: "Succesfully created" });
			return;
		});
}
