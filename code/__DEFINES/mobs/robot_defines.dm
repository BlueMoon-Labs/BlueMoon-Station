// Hats

#define HAT_STAND_OFFSET 	"hat_offset_stand"
#define HAT_REST_OFFSET 	"hat_offset_rest"
#define HAT_SIT_OFFSET 		"hat_offset_sit"
#define HAT_BELLYUP_OFFSET 	"hat_offset_bellyup"
#define HAT_NAP_OFFSET		"hat_offset_rest_deep"
#define HAT_REST_WAG_OFFSET "hat_offset_rest_alt"
#define HAT_SIT_WAG_OFFSET  "hat_offset_sit_alt"

#define HAT_NO_RENDER "hat_no_render"

#define NORMAL_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(0, -3), "south" = list(0, -3), "east" = list(4, -3), "west" = list(-4, -3)))

#define TALL_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(0, 15), "south" = list(0, 15), "east" = list(2, 15), "west" = list(-2, 15)), \
	HAT_REST_OFFSET = alist("north" = list(0, 1), "south" = list(0, 1), "east" = list(2, 1), "west" = list(-2, 1)), \
	HAT_SIT_OFFSET = alist("north" = list(3, 1), "south" = list(3, 1), "east" = list(3, 1), "west" = list(3, 1)), \
	HAT_BELLYUP_OFFSET = alist("north" = list(0, 1), "south" = list(0, 1), "east" = list(2, 1), "west" = list(-2, 1)))

#define ZOOMBA_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(0, -13), "south" = list(0, -13), "east" = list(0, -13), "west" = list(0, -13)))

#define DROID_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(0, 4), "south" = list(0, 4), "east" = list(0, 4), "west" = list(0, 4)))

#define BORGI_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(16, -8), "south" = list(16, -8), "east" = list(22, -8), "west" = list(10, -8)), \
	HAT_REST_OFFSET = alist("north" = list(16, -10), "south" = list(16, -10), "east" = list(22, -10), "west" = list(10, -10)), \
	HAT_SIT_OFFSET = alist("north" = list(16, -8), "south" = list(16, -7), "east" = list(21, -7), "west" = list(11, -7)), \
	HAT_BELLYUP_OFFSET = HAT_NO_RENDER)

#define PUP_CLEAN_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(16, -1), "south" = list(16, -1), "east" = list(31, -1), "west" = list(1, -1)), \
	HAT_REST_OFFSET = alist("north" = list(16, -7), "south" = list(16, -7), "east" = list(31, -7), "west" = list(1, -7)), \
	HAT_SIT_OFFSET = alist("north" = list(16, 5), "south" = list(17, 4), "east" = list(26, 7), "west" = list(6, 7)), \
	HAT_BELLYUP_OFFSET = HAT_NO_RENDER)

#define PUP_DOZER_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(16, -1), "south" = list(16, -1), "east" = list(31, -1), "west" = list(1, -1)), \
	HAT_REST_OFFSET = alist("north" = list(16, -7), "south" = list(16, -7), "east" = list(31, -7), "west" = list(1, -7)), \
	HAT_SIT_OFFSET = alist("north" = list(16, -7), "south" = list(16, -7), "east" = list(31, -7), "west" = list(1, -7)), \
	HAT_BELLYUP_OFFSET = HAT_NO_RENDER)

#define BLADE_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(16, 3), "south" = list(16, -3), "east" = list(31, -3), "west" = list(1, -3)), \
	HAT_REST_OFFSET = alist("north" = list(1, -8), "south" = list(31, -8), "east" = list(31, -8), "west" = list(1, -8)))

#define VALE_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(16, 3), "south" = list(16, 3), "east" = list(28, 3), "west" = list(4, 3)), \
	HAT_REST_OFFSET = alist("north" = list(16, -3), "south" = list(16, -3), "east" = list(28, -7), "west" = list(4, -7)), \
	HAT_SIT_OFFSET = alist("north" = list(16, 3), "south" = list(16, 3), "east" = list(28, 3), "west" = list(4, 3)), \
	HAT_BELLYUP_OFFSET = HAT_NO_RENDER)

#define DRAKE_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(16, -2), "south" = list(16, -2), "east" = list(36, -2), "west" = list(-4, -2)), \
	HAT_REST_OFFSET = alist("north" = list(16, -7), "south" = list(16, -7), "east" = list(34, -7), "west" = list(-4, -7)), \
	HAT_SIT_OFFSET = alist("north" = list(16, -4), "south" = list(16, -4), "east" = list(29, -1), "west" = list(1, -1)), \
	HAT_BELLYUP_OFFSET = HAT_NO_RENDER, \
	HAT_NAP_OFFSET = alist("north" = list(1, -11), "south" = list(30, -11), "east" = list(30, -11), "west" = list(1, -11)), \
	HAT_REST_WAG_OFFSET = alist("north" = list(16, -7), "south" = list(16, -7), "east" = list(34, -7), "west" = list(-4, -7)), \
	HAT_SIT_WAG_OFFSET = alist("north" = list(16, -4), "south" = list(16, -4), "east" = list(29, -1), "west" = list(1, -1)))

#define HOUND_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(16, 1), "south" = list(16, 1), "east" = list(26, 1), "west" = list(4, 1)), \
	HAT_REST_OFFSET = alist("north" = list(16, -6), "south" = list(16, -6), "east" = list(31, -6), "west" = list(1, -6)), \
	HAT_SIT_OFFSET = alist("north" = list(16, 2), "south" = list(16, 2), "east" = list(23, 3), "west" = list(9, 3)), \
	HAT_BELLYUP_OFFSET = HAT_NO_RENDER)

#define DULLAHAN_TAUR_HAT_OFFSET alist( \
	HAT_STAND_OFFSET = alist("north" = list(1, 15), "south" = list(1, 15), "east" = list(7, 15), "west" = list(-7, 15)), \
	HAT_REST_OFFSET = alist("north" = list(1, 1), "south" = list(1, 1), "east" = list(7, 1), "west" = list(-7, 1)), \
	HAT_SIT_OFFSET = alist("north" = list(-1, -2), "south" = list(-1, -2), "east" = list(-1, -2), "west" = list(-1, -2)), \
	HAT_BELLYUP_OFFSET = alist("north" = list(1, 1), "south" = list(1, 1), "east" = list(7, 1), "west" = list(-7, 1)))
