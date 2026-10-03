import z from "zod";

export const MenuItemSchema = z.object({
	id: z.string(),
	name: z.string(),
	category: z.string(),
	price: z.string(),
	isAvaliable: z.boolean(),
});
