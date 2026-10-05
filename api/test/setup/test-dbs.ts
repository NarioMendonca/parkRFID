import { fileURLToPath } from "node:url";

// Folder for the test SQLite files: one migrated template, copied per test file
export const testDbsDir = fileURLToPath(
	new URL("../../.test-dbs", import.meta.url),
);

export const templateDbPath = `${testDbsDir}/template.db`;
