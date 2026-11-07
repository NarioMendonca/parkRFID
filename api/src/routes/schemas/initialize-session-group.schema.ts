import z from "zod";
import { sessionSchemaWithoutGroup } from "./create-session.schema.js";

export const createSessionGroupSchema = {
	body: z.object({
		responsibleCpf: z.string(),
		responsiblePhoneNumber: z.string(),
		// SessionGroup should be created with at least one session
		groupFirstSession: sessionSchemaWithoutGroup
	}),
	response: {
		200: z.object({
			sessionGroup: z.object({
				id: z.string(),
				responsibleCpf: z.string(),
				responsiblePhoneNumber: z.string(),
			}),
			session: sessionSchemaWithoutGroup,
			message: z.string(),
		}),
	},
};
