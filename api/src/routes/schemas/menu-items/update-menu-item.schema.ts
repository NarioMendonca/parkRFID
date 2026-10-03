import z from "zod";
import { MenuItemSchema } from "./menu-item.schema.js";

export const UpdateMenuItemSchema = {
	body: z.object({
		id: z.string(),
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
		404: z.object({
			message: z.string(),
		}),
	},
};
