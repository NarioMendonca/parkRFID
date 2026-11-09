import { Decimal } from "decimal.js";
import { Status } from "./session-dto.js";

export type SessionGroupDTO = {
	id: string;
	responsibleCpf: string;
	responsiblePhoneNumber: string;
	balance: Decimal;
	createdAt: Date;
  	checkoutDt: Date | null;
  	status: Status
};
