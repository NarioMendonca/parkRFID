import type { SessionDTO } from "../dtos/session-dto.js";

export function sessionToResponse(sessionDTO: SessionDTO) {
	return {
		id: sessionDTO.id,
		braceletId: sessionDTO.braceletId,
		checkoutDate: sessionDTO.checkoutDate,
		checkinDate: sessionDTO.checkinDate,
		status: sessionDTO.status,
		total: sessionDTO.total.toString(),
		sessionType: sessionDTO.sessionType,
		sessionsGroupId: sessionDTO.sessionsGroupId,
	};
}
