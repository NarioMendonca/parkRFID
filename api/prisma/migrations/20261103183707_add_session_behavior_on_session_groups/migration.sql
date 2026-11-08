/*
  Warnings:

  - You are about to drop the column `ordersId` on the `OrderItems` table. All the data in the column will be lost.
  - You are about to drop the column `sessionsGroupId` on the `Sessions` table. All the data in the column will be lost.
  - Added the required column `orderId` to the `OrderItems` table without a default value. This is not possible if the table is not empty.
  - Added the required column `createdBy` to the `Orders` table without a default value. This is not possible if the table is not empty.
  - Added the required column `paymentTo` to the `Payments` table without a default value. This is not possible if the table is not empty.
  - Added the required column `sessionGroupId` to the `Sessions` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_MenuItems" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "price" DECIMAL NOT NULL,
    "isAvaliable" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true
);
INSERT INTO "new_MenuItems" ("category", "id", "isAvaliable", "name", "price") SELECT "category", "id", "isAvaliable", "name", "price" FROM "MenuItems";
DROP TABLE "MenuItems";
ALTER TABLE "new_MenuItems" RENAME TO "MenuItems";
CREATE TABLE "new_OrderItems" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "amount" INTEGER NOT NULL,
    "unitPrice" DECIMAL NOT NULL,
    "menuItemId" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    CONSTRAINT "OrderItems_menuItemId_fkey" FOREIGN KEY ("menuItemId") REFERENCES "MenuItems" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "OrderItems_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "Orders" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_OrderItems" ("amount", "id", "menuItemId", "unitPrice") SELECT "amount", "id", "menuItemId", "unitPrice" FROM "OrderItems";
DROP TABLE "OrderItems";
ALTER TABLE "new_OrderItems" RENAME TO "OrderItems";
CREATE TABLE "new_Orders" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT,
    "sessionGroupId" TEXT,
    "createdBy" TEXT NOT NULL,
    CONSTRAINT "Orders_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Sessions" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Orders_sessionGroupId_fkey" FOREIGN KEY ("sessionGroupId") REFERENCES "SessionsGroup" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Orders" ("createdAt", "id", "sessionId") SELECT "createdAt", "id", "sessionId" FROM "Orders";
DROP TABLE "Orders";
ALTER TABLE "new_Orders" RENAME TO "Orders";
CREATE TABLE "new_Payments" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "amount" DECIMAL NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT NOT NULL,
    "paymentTo" TEXT NOT NULL,
    CONSTRAINT "Payments_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Sessions" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Payments" ("amount", "createdAt", "id", "sessionId") SELECT "amount", "createdAt", "id", "sessionId" FROM "Payments";
DROP TABLE "Payments";
ALTER TABLE "new_Payments" RENAME TO "Payments";
CREATE TABLE "new_Sessions" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "braceletId" TEXT NOT NULL,
    "checkoutDate" DATETIME,
    "checkinDate" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "total" DECIMAL NOT NULL DEFAULT 0,
    "sessionType" TEXT NOT NULL DEFAULT 'NORMAL',
    "sessionGroupId" TEXT NOT NULL,
    CONSTRAINT "Sessions_sessionGroupId_fkey" FOREIGN KEY ("sessionGroupId") REFERENCES "SessionsGroup" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Sessions" ("braceletId", "checkinDate", "checkoutDate", "id", "sessionType", "status", "total") SELECT "braceletId", "checkinDate", "checkoutDate", "id", "sessionType", "status", "total" FROM "Sessions";
DROP TABLE "Sessions";
ALTER TABLE "new_Sessions" RENAME TO "Sessions";
CREATE UNIQUE INDEX "Sessions_braceletId_key" ON "Sessions"("braceletId") WHERE "status" = 'OPEN';
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
