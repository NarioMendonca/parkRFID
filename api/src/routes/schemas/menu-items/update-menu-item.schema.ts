import z from "zod";
import { MenuItemSchema } from "./menu-item.schema.js";

export const UpdateMenuItemSchema = {
	params: z.object({
		id: z.string(),
	}),
	// The item id comes from the URL; an id sent in the body is ignored
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
		404: z.object({
			message: z.string(),
		}),
	},
};
