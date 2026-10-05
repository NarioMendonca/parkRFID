import { randomUUID } from "node:crypto";
import { AlreadyExistsError } from "@/errors/AlreadyExistsError.js";
import { DomainError } from "@/errors/DomainError.js";
import { NotFoundError } from "@/errors/NotFoundError.js";
import type { MenuItem } from "./menu-item.js";
import { Order, type OrderItem } from "./order.js";
import { Session, type SessionType } from "./session.js";
import type { SessionGroup } from "./session-group.js";

type BraceletProps = {
	id: string;
	uidRfid: string;
	createdAt: Date;
	activeSession: Session | null;
};

// Every bracelet action goes through this entity, and it only exists for
// bracelets registered in the Bracelets table, so an unregistered bracelet
// can't check in, order or leave.
export class Bracelet {
	private constructor(private props: BraceletProps) {}

	static register(uidRfid: string) {
		return new Bracelet({
			id: randomUUID(),
			uidRfid,
			createdAt: new Date(),
			activeSession: null,
		});
	}

	static restore(props: BraceletProps) {
		return new Bracelet(props);
	}

	get id() {
		return this.props.id;
	}

	get uidRfid() {
		return this.props.uidRfid;
	}

	get createdAt() {
		return this.props.createdAt;
	}

	get activeSession() {
		return this.props.activeSession;
	}

	checkin(sessionGroup: SessionGroup, sessionType: SessionType) {
		if (this.props.activeSession) {
			throw new AlreadyExistsError(
				"Session active already exists in this bracelet",
			);
		}

		const session = Session.open({ bracelet: this, sessionGroup, sessionType });
		this.props.activeSession = session;
		return session;
	}

	placeOrder(items: OrderItem[], menuItems: MenuItem[]) {
		if (!this.props.activeSession) {
			throw new NotFoundError("Session not found");
		}

		const order = Order.place({
			session: this.props.activeSession,
			items,
			menuItems,
		});

		this.props.activeSession.addValueToBalance(order.balance);

		return order;
	}

	// Paying keeps the session open, so the bracelet can still order and pay
	// again before leaving
	pay() {
		const session = this.props.activeSession;
		if (!session) {
			throw new NotFoundError("Session to pay not found");
		}

		const paidAmount = session.pay();
		return { session, paidAmount };
	}

	// Leaving the park closes the active session, so it must be paid first.
	// Returns the closed session, or null when there was no session to close.
	exit() {
		const session = this.props.activeSession;
		if (!session) {
			return null;
		}

		if (session.hasPendingBalance()) {
			throw new DomainError(
				`Session has a pending balance of ${session.total.toFixed(2)}`,
				409,
			);
		}

		session.close();
		this.props.activeSession = null;
		return session;
	}
}
