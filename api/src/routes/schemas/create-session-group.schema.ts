import z from "zod";

export const createSessionGroupSchema = {
	body: z.object({
		responsibleCpf: z.string(),
		responsiblePhoneNumber: z.string(),
	}),
	response: {
		200: z.object({
			sessionGroup: z.object({
				id: z.string(),
				responsibleCpf: z.string(),
				responsiblePhoneNumber: z.string(),
			}),
			message: z.string(),
		}),
	},
};
