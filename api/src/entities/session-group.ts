import { randomUUID } from "node:crypto";
import { InvalidResourceError } from "@/errors/InvalidResourceError.js";

type SessionGroupProps = {
	id: string;
	responsibleCpf: string;
	responsiblePhoneNumber: string;
};

type CreateSessionGroupInput = Omit<SessionGroupProps, "id">;

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
}
