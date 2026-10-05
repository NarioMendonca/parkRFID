import { randomUUID } from "node:crypto";
import { copyFileSync, rmSync } from "node:fs";
import { afterAll, beforeEach } from "vitest";
import { templateDbPath, testDbsDir } from "./test-dbs.js";

// Each test file gets its own copy of the database, so files can run in
// parallel. The env var must be set before the Prisma client is imported.
const dbPath = `${testDbsDir}/${randomUUID()}.db`;
copyFileSync(templateDbPath, dbPath);
process.env.DATABASE_URL = `file:${dbPath}`;

const { prisma } = await import("@/lib/prisma.js");

beforeEach(async () => {
	await prisma.orderItems.deleteMany();
	await prisma.orders.deleteMany();
	await prisma.sessions.deleteMany();
	await prisma.sessionsGroup.deleteMany();
	await prisma.menuItems.deleteMany();
	await prisma.bracelets.deleteMany();
});

afterAll(async () => {
	await prisma.$disconnect();
	rmSync(dbPath, { force: true });
});
