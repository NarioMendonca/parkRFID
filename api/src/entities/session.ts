import { randomUUID } from "node:crypto";
import { Decimal } from "decimal.js";
import { DomainError } from "@/errors/DomainError.js";
import type { Bracelet } from "./bracelet.js";
import type { SessionGroup } from "./session-group.js";

export type SessionStatus = "OPEN" | "CLOSED";

export type SessionType = "NORMAL" | "KID";

type SessionProps = {
	id: string;
	braceletId: string;
	checkinDate: Date;
	checkoutDate: Date | null;
	status: SessionStatus;
	total: Decimal;
	sessionType: SessionType;
	sessionsGroupId: string;
};

type OpenSessionInput = {
	bracelet: Bracelet;
	sessionGroup: SessionGroup;
	sessionType: SessionType;
};

export class Session {
	private constructor(private props: SessionProps) {}

	static open({ bracelet, sessionGroup, sessionType }: OpenSessionInput) {
		return new Session({
			id: randomUUID(),
			braceletId: bracelet.uidRfid,
			checkinDate: new Date(),
			checkoutDate: null,
			status: "OPEN",
			total: new Decimal("0"),
			sessionType,
			sessionsGroupId: sessionGroup.id,
		});
	}

	static restore(props: SessionProps) {
		return new Session(props);
	}

	get id() {
		return this.props.id;
	}

	get braceletId() {
		return this.props.braceletId;
	}

	get checkinDate() {
		return this.props.checkinDate;
	}

	get checkoutDate() {
		return this.props.checkoutDate;
	}

	get status() {
		return this.props.status;
	}

	get total() {
		return this.props.total;
	}

	get sessionType() {
		return this.props.sessionType;
	}

	get sessionsGroupId() {
		return this.props.sessionsGroupId;
	}

	addValueToBalance(value: Decimal) {
		this.props.total = this.props.total.add(value);
	}

	hasPendingBalance() {
		return !this.props.total.equals("0");
	}

	// Settles the whole pending balance and returns the amount paid
	pay() {
		if (!this.hasPendingBalance()) {
			throw new DomainError("Session has no pending balance", 409);
		}

		const paidAmount = this.props.total;
		this.props.total = new Decimal("0");
		return paidAmount;
	}

	close() {
		if (this.props.status === "CLOSED") {
			throw new DomainError("Session already closed");
		}

		this.props.status = "CLOSED";
		this.props.checkoutDate = new Date();
	}
}
