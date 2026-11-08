import { NotFoundError } from "@/errors/NotFoundError.js";
import { prisma } from "@/lib/prisma.js";

export async function fetchBraceletSessions(uidRfid: string) {
	const bracelet = await prisma.bracelets.findUnique({
		where: {
			uid_rfid: uidRfid,
		},
	});
	if (!bracelet) {
		throw new NotFoundError("Pulseira não cadastrada");
	}

	return await prisma.sessions.findMany({
		where: {
			braceletId: uidRfid,
		},
		orderBy: {
			checkinDate: "desc",
		},
	});
}
