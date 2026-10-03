import { prisma } from "@/lib/prisma.js";
import type { Prisma } from "../../generated/prisma/client.js";

export class PrismaMenuItemsRepository {
	async findItemByName(name: string) {
		const menuItem = await prisma.menuItems.findFirst({
			where: {
				name,
			},
		});

		return menuItem;
	}

	async createMenuItem(data: Prisma.MenuItemsCreateInput) {
		const menuItem = await prisma.menuItems.create({
			data,
		});

		return menuItem;
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

		return items;
	}

	async findItemById(id: string) {
		const menuItem = await prisma.menuItems.findFirst({
			where: {
				id,
			},
		});

		return menuItem;
	}

	async updateMenuItem(
		data: Prisma.MenuItemsUpdateWithoutOrderItemsInput & { id: string },
	) {
		const menuItem = await prisma.menuItems.update({
			where: {
				id: data.id,
			},
			data,
		});

		return menuItem;
	}

	async deleteItem(id: string) {
		await prisma.menuItems.delete({
			where: {
				id,
			},
		});
	}
}
