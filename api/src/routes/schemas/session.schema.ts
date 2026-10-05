import z from "zod";

export const SessionSchema = z.object({
	id: z.string(),
	braceletId: z.string(),
	sessionType: z.enum(["NORMAL", "KID"]),
	checkoutDate: z.date().nullable(),
	checkinDate: z.date(),
	status: z.enum(["OPEN", "CLOSED"]),
	total: z.string(),
	sessionsGroupId: z.string(),
});
