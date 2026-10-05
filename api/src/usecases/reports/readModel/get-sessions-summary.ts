import { startOfToday } from "@/lib/date.js";
import { prisma } from "@/lib/prisma.js";

export async function getSessionsSummary() {
	const [activeSessions, sessionsCreatedToday] = await Promise.all([
		prisma.sessions.count({
			where: {
				status: "OPEN",
			},
		}),
		prisma.sessions.count({
			where: {
				checkinDate: {
					gte: startOfToday(),
				},
			},
		}),
	]);

	return { activeSessions, sessionsCreatedToday };
}
