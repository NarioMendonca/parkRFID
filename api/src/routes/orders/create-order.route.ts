import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";
import { CreateOrderUseCase } from "@/usecases/orders/create-order.js";
import { CreateOrderSchema } from "../schemas/orders/create-order.schema.js";

const createOrderUseCase = new CreateOrderUseCase();

export async function createOrderRoute(app: FastifyInstance) {
	app
		.withTypeProvider<ZodTypeProvider>()
		.post("/", { schema: CreateOrderSchema }, async (request, reply) => {
			const params = request.body;
			await createOrderUseCase.handle(params);

			reply.status(200).send({ message: "Order succesfully created" });
			return;
		});
}
