import { ApiError } from "./ApiError.js";

export class DomainError extends ApiError {
	constructor(message: string) {
		super(message, 400);
	}
}
