import { ApiError } from "./ApiError.js";

export class InvalidResourceError extends ApiError {
	constructor(message: string = "Invalid resource") {
		super(message, 400);
	}
}
