import { ApiError } from "./ApiError.js";

export class AlreadyExistsError extends ApiError {
	constructor(message: string = "Resource already exists") {
		super(message, 409);
	}
}
