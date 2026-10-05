import { execSync } from "node:child_process";
import { mkdirSync, rmSync } from "node:fs";
import { templateDbPath, testDbsDir } from "./test-dbs.js";

// Runs the migrations once; each test file then copies this template database
export function setup() {
	rmSync(testDbsDir, { recursive: true, force: true });
	mkdirSync(testDbsDir, { recursive: true });

	execSync("npx prisma migrate deploy", {
		env: { ...process.env, DATABASE_URL: `file:${templateDbPath}` },
		stdio: "ignore",
	});
}

export function teardown() {
	rmSync(testDbsDir, { recursive: true, force: true });
}
