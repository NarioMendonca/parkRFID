import z from "zod";

export const CreateOrderSchema = {
	body: z.object({
		braceletId: z.string(),
		items: z.array(z.object({ menuItemId: z.string(), amount: z.number() })),
	}),
	response: {
		200: z.object({
			message: z.string(),
		}),
		404: z.object({
			message: z.string(),
		}),
	},
};
