//map template annihilate_bounds
#define MAP_TEMPLATE_ANNIHILATE_PRELOAD 1		//annihilate bounds before starting loading
#define MAP_TEMPLATE_ANNIHILATE_LOADING 2		//"sweeping" delete during loading

/// Создаёт четыре направленных подтипа с правильным смещением для маппинга.
#define MAPPING_DIRECTIONAL_HELPERS(path, offset) ##path/directional/north {\
	dir = NORTH; \
	pixel_y = offset; \
} \
##path/directional/south {\
	dir = SOUTH; \
	pixel_y = -offset; \
} \
##path/directional/east {\
	dir = EAST; \
	pixel_x = offset; \
} \
##path/directional/west {\
	dir = WEST; \
	pixel_x = -offset; \
}
