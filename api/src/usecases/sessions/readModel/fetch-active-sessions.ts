import { prisma } from "@/lib/prisma.js";

export async function fetchActiveSessions() {
	return await prisma.session.findMany({
		where: {
			status: "OPEN",
		},
		include: {
			sessionGroup: true,
		},
	});
}

console.log(await fetchActiveSessions());
