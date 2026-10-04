import type { MenuItemDTO } from "../dtos/menu-item-dto.js";

export function menuItemToResponse(menuItemDto: MenuItemDTO) {
	return {
		id: menuItemDto.id,
		name: menuItemDto.name,
		category: menuItemDto.category,
		price: menuItemDto.price.toString(),
		isAvaliable: menuItemDto.isAvaliable,
	};
}
