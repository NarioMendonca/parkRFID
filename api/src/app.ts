import fastifyCors from "@fastify/cors";
import fastifySwagger from "@fastify/swagger";
import scallarApiReference from "@scalar/fastify-api-reference";
import { fastify } from "fastify";
import {
	jsonSchemaTransform,
	serializerCompiler,
	validatorCompiler,
} from "fastify-type-provider-zod";
import { routes } from "./routes/routes.js";

export async function buildApp() {
	const app = fastify();
	app.setValidatorCompiler(validatorCompiler);
	app.setSerializerCompiler(serializerCompiler);

	// An empty CLIENTS_URL falls back to the default origin instead of
	// allowing none
	const clientsUrl = process.env.CLIENTS_URL?.split(",")
		.map((url) => url.trim())
		.filter(Boolean);

	app.register(fastifyCors, {
		origin: clientsUrl?.length ? clientsUrl : "http://localhost:8080",
		methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
	});

	app.register(fastifySwagger, {
		openapi: {
			info: {
				title: "RFID Manager Park API",
				description: "docs for RFID Manager Park API",
				version: "1.0.0",
			},
		},
		transform: jsonSchemaTransform,
	});

	app.register(scallarApiReference, {
		routePrefix: "/docs",
	});

	app.get("/", async () => {
		return "Server running!";
	});

	app.register(routes);

	await app.ready();

	return app;
}
