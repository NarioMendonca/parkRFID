/*
  Warnings:

  - Added the required column `createdBy` to the `Orders` table without a default value. This is not possible if the table is not empty.
  - Added the required column `sessionGroupId` to the `Orders` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Orders" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT NOT NULL,
    "sessionGroupId" TEXT NOT NULL,
    "createdBy" TEXT NOT NULL,
    CONSTRAINT "Orders_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Sessions" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Orders" ("createdAt", "id", "sessionId") SELECT "createdAt", "id", "sessionId" FROM "Orders";
DROP TABLE "Orders";
ALTER TABLE "new_Orders" RENAME TO "Orders";
CREATE TABLE "new_SessionsGroup" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "responsibleCpf" TEXT NOT NULL,
    "responsiblePhoneNumber" TEXT NOT NULL,
    "balance" DECIMAL NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "checkoutDt" DATETIME,
    "status" TEXT NOT NULL DEFAULT 'OPEN'
);
INSERT INTO "new_SessionsGroup" ("id", "responsibleCpf", "responsiblePhoneNumber") SELECT "id", "responsibleCpf", "responsiblePhoneNumber" FROM "SessionsGroup";
DROP TABLE "SessionsGroup";
ALTER TABLE "new_SessionsGroup" RENAME TO "SessionsGroup";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
