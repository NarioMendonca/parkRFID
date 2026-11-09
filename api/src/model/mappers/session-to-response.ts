import type { SessionDTO } from "../dtos/session-dto.js";

export function sessionToResponse(sessionDTO: SessionDTO) {
	return {
		id: sessionDTO.id,
		ownerName: sessionDTO.ownerName,
		braceletId: sessionDTO.braceletId,
		checkoutDate: sessionDTO.checkoutDate,
		checkinDate: sessionDTO.checkinDate,
		status: sessionDTO.status,
		total: sessionDTO.total.toString(),
		sessionType: sessionDTO.sessionType,
		sessionsGroupId: sessionDTO.sessionGroupId,
	};
}
