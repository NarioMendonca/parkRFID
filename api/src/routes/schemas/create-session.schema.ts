import z from "zod";

export const createSessionSchema = {
	body: z.object({
		braceletId: z.string(),
		sessionGroupId: z.string(),
		sessionType: z.enum(["NORMAL", "KID"]).default("NORMAL"),
	}),
	response: {
		200: z.object({
			session: z.object({
				id: z.string(),
				braceletId: z.string(),
				sessionType: z.enum(["NORMAL", "KID"]),
				checkoutDate: z.date().nullable(),
				checkinDate: z.date(),
				status: z.enum(["OPEN", "CLOSED"]),
				total: z.string(),
				sessionsGroupId: z.string(),
			}),
			message: z.string(),
		}),
	},
};
