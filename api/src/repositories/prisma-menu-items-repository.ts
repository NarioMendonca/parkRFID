import { Decimal } from "decimal.js";
import { MenuItem } from "@/entities/menu-item.js";
import { prisma } from "@/lib/prisma.js";
import type { MenuItems } from "../../generated/prisma/client.js";

function toMenuItemEntity(menuItem: MenuItems) {
	return MenuItem.restore({
		...menuItem,
		price: new Decimal(menuItem.price.toString()),
	});
}

export class PrismaMenuItemsRepository {
	async findItemByName(name: string) {
		const menuItem = await prisma.menuItems.findFirst({
			where: {
				name,
			},
		});

		return menuItem ? toMenuItemEntity(menuItem) : null;
	}

	async createMenuItem(menuItem: MenuItem) {
		await prisma.menuItems.create({
			data: {
				id: menuItem.id,
				name: menuItem.name,
				category: menuItem.category,
				price: menuItem.price,
				isAvaliable: menuItem.isAvaliable,
			},
		});
	}

	async fetchItems(category?: string) {
		const menuItems = await prisma.menuItems.findMany({
			where: {
				category,
			},
		});

		return menuItems;
	}

	async fetchItemsById(itemsId: string[]) {
		const items = await prisma.menuItems.findMany({
			where: {
				id: {
					in: itemsId,
				},
			},
		});

		return items.map(toMenuItemEntity);
	}

	async findItemById(id: string) {
		const menuItem = await prisma.menuItems.findFirst({
			where: {
				id,
			},
		});

		return menuItem ? toMenuItemEntity(menuItem) : null;
	}

	async updateMenuItem(menuItem: MenuItem) {
		await prisma.menuItems.update({
			where: {
				id: menuItem.id,
			},
			data: {
				name: menuItem.name,
				category: menuItem.category,
				price: menuItem.price,
				isAvaliable: menuItem.isAvaliable,
			},
		});
	}

	async deleteItem(id: string) {
		await prisma.menuItems.delete({
			where: {
				id,
			},
		});
	}
}
