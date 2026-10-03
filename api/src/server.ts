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

const app = fastify();
app.setValidatorCompiler(validatorCompiler);
app.setSerializerCompiler(serializerCompiler);

app.register(fastifyCors, {
	origin: process.env.CLIENTS_URL?.split(",") ?? "http://localhost:8080",
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

const PORT = 3333;
await app.listen({ port: PORT, host: "0.0.0.0" });
console.log(`Server running on http://localhost:${PORT}`);
console.log(`Docs in http://localhost:${PORT}/docs`);
