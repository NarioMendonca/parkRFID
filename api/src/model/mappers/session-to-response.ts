import type { SessionDTO } from "../dtos/session-dto.js";

export function sessionToResponse(sessionDTO: SessionDTO) {
	return {
		...sessionDTO,
		total: sessionDTO.total.toString(),
	};
}
