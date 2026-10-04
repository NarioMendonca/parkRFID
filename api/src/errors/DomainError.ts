import { ApiError } from "./ApiError.js";

export class DomainError extends ApiError {
	constructor(message: string, statusCode: number = 400) {
		super(message, statusCode);
	}
}
