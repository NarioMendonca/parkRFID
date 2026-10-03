import z from "zod";
import { MenuItemSchema } from "./menu-item.schema.js";

export const CreateMenuItemSchema = {
	body: z.object({
		name: z.string(),
		category: z.string(),
		price: z.string(),
		isAvaliable: z.boolean(),
	}),
	response: {
		200: z.object({
			menuItem: MenuItemSchema,
			message: z.string(),
		}),
		409: z.object({
			message: z.string(),
		}),
	},
};
