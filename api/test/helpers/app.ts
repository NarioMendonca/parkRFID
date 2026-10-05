import { afterAll } from "vitest";
import { buildApp } from "@/app.js";

export async function createTestApp() {
	const app = await buildApp();

	afterAll(async () => {
		await app.close();
	});

	return app;
}
