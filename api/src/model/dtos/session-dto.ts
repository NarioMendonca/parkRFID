import type { Decimal } from "decimal.js";

export type SessionDTO = {
	id: string;
	braceletId: string;
	checkoutDate: Date | null;
	checkinDate: Date;
	status: Status;
	total: Decimal;
	sessionType: SessionType;
	sessionsGroupId: string;
};

export type Status = "OPEN" | "CLOSED";

export type SessionType = "NORMAL" | "KID";
