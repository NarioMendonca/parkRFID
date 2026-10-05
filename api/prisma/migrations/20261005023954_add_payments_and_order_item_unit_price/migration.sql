-- CreateTable
CREATE TABLE "Payments" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "amount" DECIMAL NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionId" TEXT NOT NULL,
    CONSTRAINT "Payments_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Sessions" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_OrderItems" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "amount" INTEGER NOT NULL,
    "unitPrice" DECIMAL NOT NULL,
    "menuItemId" TEXT NOT NULL,
    "ordersId" TEXT NOT NULL,
    CONSTRAINT "OrderItems_menuItemId_fkey" FOREIGN KEY ("menuItemId") REFERENCES "MenuItems" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "OrderItems_ordersId_fkey" FOREIGN KEY ("ordersId") REFERENCES "Orders" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
-- Existing order items get the current menu price, the only price known for them
INSERT INTO "new_OrderItems" ("amount", "id", "menuItemId", "ordersId", "unitPrice")
SELECT "OrderItems"."amount", "OrderItems"."id", "OrderItems"."menuItemId", "OrderItems"."ordersId", "MenuItems"."price"
FROM "OrderItems" INNER JOIN "MenuItems" ON "MenuItems"."id" = "OrderItems"."menuItemId";
DROP TABLE "OrderItems";
ALTER TABLE "new_OrderItems" RENAME TO "OrderItems";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
