import { ApiError } from "./ApiError.js";

export class InvalidResourceError extends ApiError {
	constructor(message: string = "Recurso inválido") {
		super(message, 400);
	}
}
