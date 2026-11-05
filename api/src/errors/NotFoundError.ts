import { ApiError } from "./ApiError.js";

export class NotFoundError extends ApiError {
	constructor(message: string = "Recurso não encontrado") {
		super(message, 404);
	}
}
