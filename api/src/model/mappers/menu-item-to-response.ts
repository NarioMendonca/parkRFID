import type { MenuItemDTO } from "../dtos/menu-item-dto.js";

export function menuItemToResponse(menuItemDto: MenuItemDTO) {
	return {
		...menuItemDto,
		price: menuItemDto.price.toString(),
	};
}
