import { PrismaMenuItemsRepository } from "@/repositories/prisma-menu-items-repository.js";

export async function fetchMenuItems(category?: string) {
	const prismaMenuItemsRepository = new PrismaMenuItemsRepository();
	return await prismaMenuItemsRepository.fetchItems(category);
}
