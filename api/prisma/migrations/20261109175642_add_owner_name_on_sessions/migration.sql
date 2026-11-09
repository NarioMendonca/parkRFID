/*
  Warnings:

  - You are about to drop the column `createdBy` on the `Orders` table. All the data in the column will be lost.
  - Added the required column `createdFor` to the `Orders` table without a default value. This is not possible if the table is not empty.
  - Made the column `sessionGroupId` on table `Orders` required. This step will fail if there are existing NULL values in that column.
  - Made the column `sessionId` on table `Orders` required. This step will fail if there are existing NULL values in that column.
  - Added the required column `ownerName` to the `Sessions` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Orders" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT NOT NULL,
    "sessionGroupId" TEXT NOT NULL,
    "createdFor" TEXT NOT NULL,
    "tableNumber" TEXT,
    CONSTRAINT "Orders_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Sessions" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Orders_sessionGroupId_fkey" FOREIGN KEY ("sessionGroupId") REFERENCES "SessionsGroup" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Orders" ("createdAt", "id", "sessionGroupId", "sessionId", "tableNumber") SELECT "createdAt", "id", "sessionGroupId", "sessionId", "tableNumber" FROM "Orders";
DROP TABLE "Orders";
ALTER TABLE "new_Orders" RENAME TO "Orders";
CREATE TABLE "new_Sessions" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "braceletId" TEXT NOT NULL,
    "ownerName" TEXT NOT NULL,
    "checkoutDate" DATETIME,
    "checkinDate" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "total" DECIMAL NOT NULL DEFAULT 0,
    "sessionType" TEXT NOT NULL DEFAULT 'NORMAL',
    "sessionGroupId" TEXT NOT NULL,
    CONSTRAINT "Sessions_sessionGroupId_fkey" FOREIGN KEY ("sessionGroupId") REFERENCES "SessionsGroup" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Sessions" ("braceletId", "checkinDate", "checkoutDate", "id", "sessionGroupId", "sessionType", "status", "total") SELECT "braceletId", "checkinDate", "checkoutDate", "id", "sessionGroupId", "sessionType", "status", "total" FROM "Sessions";
DROP TABLE "Sessions";
ALTER TABLE "new_Sessions" RENAME TO "Sessions";
CREATE UNIQUE INDEX "Sessions_braceletId_key" ON "Sessions"("braceletId") WHERE "status" = 'OPEN';
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
