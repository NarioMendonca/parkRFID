import type { Decimal } from "decimal.js";

export type SessionDTO = {
	id: string;
	ownerName: string;
	braceletId: string;
	checkoutDate: Date | null;
	checkinDate: Date;
	status: Status;
	total: Decimal;
	sessionType: SessionRole;
	sessionGroupId: string;
};

export type Status = "OPEN" | "CLOSED";

export type SessionRole = "NORMAL" | "KID";
