import z from "zod";
import { SessionSchema } from "./session.schema.js";

export const sessionSchema = z.object({
	braceletId: z.string(),
	ownerName: z.string(),
	sessionGroupId: z.string(),
	sessionType: z.enum(["NORMAL", "KID"]).default("NORMAL"),
})

export const sessionSchemaWithoutGroup = z.object({
	ownerName: z.string(),
	braceletId: z.string(),
	sessionType: z.enum(["NORMAL", "KID"]).default("NORMAL"),
})

export const createSessionSchema = {
	body: sessionSchema,
	response: {
		200: z.object({
			session: SessionSchema,
			message: z.string(),
		}),
	},
};
