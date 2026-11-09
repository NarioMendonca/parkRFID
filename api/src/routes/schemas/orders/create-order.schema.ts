import z from "zod";

export const CreateOrderSchema = {
	body: z.object({
		braceletId: z.string(),
		// Printed in big letters on the kitchen ticket
		tableNumber: z.string().trim().min(1).max(10).optional(),
		items: z
			.array(
				z.object({
					menuItemId: z.string(),
					amount: z.number().int().positive(),
				}),
			)
			.min(1),
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
