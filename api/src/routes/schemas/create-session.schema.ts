import z from "zod";
import { SessionSchema } from "./session.schema.js";

export const createSessionSchema = {
	body: z.object({
		braceletId: z.string(),
		sessionGroupId: z.string(),
		sessionType: z.enum(["NORMAL", "KID"]).default("NORMAL"),
	}),
	response: {
		200: z.object({
			session: SessionSchema,
			message: z.string(),
		}),
	},
};
