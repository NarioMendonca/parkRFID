import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import z from "zod";
import { DeleteMenuItemUseCase } from "@/usecases/menu-items/delete-menu-item.js";

const deleteMenuItemUseCase = new DeleteMenuItemUseCase();

export async function deleteMenuItemRoute(app: FastifyInstance) {
	app.withTypeProvider<ZodTypeProvider>().delete(
		"/:id",
		{
			schema: {
				params: z.object({ id: z.string() }),
				200: z.object({ message: z.string() }),
				404: z.object({ message: z.string() }),
			},
		},
		async (request, reply) => {
			const { id } = request.params;
			await deleteMenuItemUseCase.handle({
				itemId: id,
			});

			reply.status(200).send({ message: "Succesfully deleted" });
			return;
		},
	);
}
