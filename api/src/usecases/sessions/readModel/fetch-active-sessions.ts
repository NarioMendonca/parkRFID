import { prisma } from "@/lib/prisma.js";

export async function fetchActiveSessions() {
	return await prisma.sessions.findMany({
		where: {
			status: "OPEN",
		},
		include: {
			sessionGroup: true,
		},
	});
}

console.log(await fetchActiveSessions());
