import { ApiError } from "./ApiError.js";

export class NotFoundError extends ApiError {
	constructor(message: string = "Resource not found") {
		super(message, 404);
	}
}
