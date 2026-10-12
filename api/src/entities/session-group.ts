import { randomUUID } from "node:crypto";
import { InvalidResourceError } from "@/errors/InvalidResourceError.js";
import { Decimal } from "decimal.js";
import { DomainError } from "@/errors/DomainError.js";

type GroupStatus = 'OPEN' | 'CLOSED'

type SessionGroupProps = {
	id: string;
	responsibleCpf: string;
	responsiblePhoneNumber: string;
	balance: Decimal;
	status: GroupStatus;
	createdAt: Date;
	checkoutDt: Date | null;
	size: number;
};

type CreateSessionGroupInput = {
	responsibleCpf: string;
	responsiblePhoneNumber: string;
}

export class SessionGroup {
	private constructor(private props: SessionGroupProps) {}

	static create({
		responsibleCpf,
		responsiblePhoneNumber,
	}: CreateSessionGroupInput) {
		if (responsibleCpf.length !== 11) {
			throw new InvalidResourceError("Invalid responsible cpf");
		}

		return new SessionGroup({
			id: randomUUID(),
			responsibleCpf,
			responsiblePhoneNumber,
			balance: new Decimal("0"),
			createdAt: new Date(),
			checkoutDt: null,
			status: "OPEN",
			size: 0
		});
	}

	static restore(props: SessionGroupProps) {
		return new SessionGroup(props);
	}

	get id() {
		return this.props.id;
	}

	get responsibleCpf() {
		return this.props.responsibleCpf;
	}

	get responsiblePhoneNumber() {
		return this.props.responsiblePhoneNumber;
	}

	get balance() {
		return this.props.balance
	}

	get status() {
		return this.props.status
	}

	get createdAt() {
		return this.props.createdAt
	}

	get checkoutDt() {
		return this.props.checkoutDt
	}

	get size() {
		return this.props.size
	}

	close() {
		if (this.status === "CLOSED") {
			throw new DomainError("Session Group already closed")
		}
		this.props.status = "CLOSED"
		this.props.checkoutDt = new Date()
	}
}
