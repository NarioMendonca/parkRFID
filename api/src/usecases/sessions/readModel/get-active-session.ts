import { prisma } from "@/lib/prisma.js";

export async function getActiveSession(braceletId: string) {
	return await prisma.sessions.findFirst({
		where: {
			braceletId,
			status: "OPEN",
		},
		include: {
			sessionGroup: true,
		},
	});
}
