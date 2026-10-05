import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
	resolve: {
		alias: {
			"@": fileURLToPath(new URL("./src", import.meta.url)),
		},
	},
	test: {
		include: ["test/**/*.spec.ts"],
		globalSetup: ["./test/setup/global-setup.ts"],
		setupFiles: ["./test/setup/database.ts"],
	},
});
