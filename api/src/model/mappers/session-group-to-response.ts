import type { SessionGroupDTO } from "../dtos/session-group-dto.js";

export function sessionGroupToResponse(sessionGroupDTO: SessionGroupDTO) {
	return {
		id: sessionGroupDTO.id,
		responsibleCpf: sessionGroupDTO.responsibleCpf,
		responsiblePhoneNumber: sessionGroupDTO.responsiblePhoneNumber,
	};
}
