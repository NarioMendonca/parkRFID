import { ApiError } from "./ApiError.js";

export class AlreadyExistsError extends ApiError {
	constructor(message: string = "Recurso já existe") {
		super(message, 409);
	}
}
