import { randomUUID } from "node:crypto";
import type { Decimal } from "decimal.js";
import type { Session } from "./session.js";

type PaymentProps = {
	id: string;
	sessionId: string;
	amount: Decimal;
	createdAt: Date;
};

type RegisterPaymentInput = {
	session: Session;
	amount: Decimal;
};

export class Payment {
	private constructor(private props: PaymentProps) {}

	static register({ session, amount }: RegisterPaymentInput) {
		return new Payment({
			id: randomUUID(),
			sessionId: session.id,
			amount,
			createdAt: new Date(),
		});
	}

	get id() {
		return this.props.id;
	}

	get sessionId() {
		return this.props.sessionId;
	}

	get amount() {
		return this.props.amount;
	}

	get createdAt() {
		return this.props.createdAt;
	}
}
