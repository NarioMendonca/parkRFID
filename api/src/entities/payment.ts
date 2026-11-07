import { randomUUID } from "node:crypto";
import type { Decimal } from "decimal.js";
import type { Session } from "./session.js";

export type PaymentTo = "SESSION" | "SESSION_GROUP";

type PaymentProps = {
	id: string;
	sessionId: string;
	amount: Decimal;
	createdAt: Date;
	paymentTo: PaymentTo;
};

type RegisterPaymentInput = {
	session: Session;
	amount: Decimal;
	paymentTo: PaymentTo;
};

export class Payment {
	private constructor(private props: PaymentProps) {}

	static register({ session, amount, paymentTo }: RegisterPaymentInput) {
		return new Payment({
			id: randomUUID(),
			sessionId: session.id,
			amount,
			createdAt: new Date(),
			paymentTo,
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

	get paymentTo() {
		return this.props.paymentTo;
	}
}
