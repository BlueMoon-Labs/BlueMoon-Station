// Спатиал-грид (порт tg): каждый z-уровень покрыт сеткой ячеек
// SPATIAL_GRID_CELLSIZE^2 турфов, в ячейках лежат списки "интересных"
// movables по каналам. Поиск по прямоугольнику ячеек заменяет дорогие
// view()-сканы и полные обходы игроков z-уровня.

/// Сторона ячейки спатиал-грида в турфах (при world.maxx 255 выходит 15 ячеек на сторону)
#define SPATIAL_GRID_CELLSIZE 17
/// Индекс ячейки грида (x или y) для координаты
#define GET_SPATIAL_INDEX(coord) ROUND_UP((coord) / SPATIAL_GRID_CELLSIZE)
/// Координата нижнего левого угла ячейки по её индексу (1..SPATIAL_GRID_CELLS_PER_SIDE)
#define GRID_INDEX_TO_COORDS(index) ((((index) - 1) * SPATIAL_GRID_CELLSIZE) + 1)
/// Число ячеек на сторону z-уровня; передавать world.maxx или world.maxy
#define SPATIAL_GRID_CELLS_PER_SIDE(world_bounds) GET_SPATIAL_INDEX(world_bounds)

// Каналы important_recursive_contents: movable числится в канале сам и
// прописан в списках всех вложенных locs, поэтому шкаф, внутри которого
// сидит слышащий моб, сам считается "слышащим" и двигает содержимое канала
// по ячейкам грида при своих перемещениях.

/// Канал слышащих атомов (flags_1 & HEAR_1 / become_hearing_sensitive)
#define RECURSIVE_CONTENTS_HEARING_SENSITIVE "recursive_contents_hearing_sensitive"
/// Канал мобов с клиентом
#define RECURSIVE_CONTENTS_CLIENT_MOBS "recursive_contents_client_mobs"

// Типы содержимого ячеек грида. Строки совпадают с recursive-каналами выше:
// на этом совпадении завязана синхронизация awareness в Entered/Exited.
#define SPATIAL_GRID_CONTENTS_TYPE_HEARING RECURSIVE_CONTENTS_HEARING_SENSITIVE
#define SPATIAL_GRID_CONTENTS_TYPE_CLIENTS RECURSIVE_CONTENTS_CLIENT_MOBS

/// Есть ли у movable хоть один грид-канал (свой или от содержимого)
#define HAS_SPATIAL_GRID_CONTENTS(movable) (movable.spatial_grid_key)

// Сигналы на ячейке ("разбуди меня, когда в ячейку войдёт игрок")
#define SPATIAL_GRID_CELL_ENTERED(contents_type) "spatial_grid_cell_entered_[contents_type]"
#define SPATIAL_GRID_CELL_EXITED(contents_type) "spatial_grid_cell_exited_[contents_type]"

// Внутренние макросы списков ячейки: пустой список ячейки - это ссылка на
// общий SSspatial_grid.dummy_list (экономия памяти без null-проверок и без
// замедления итерации, в отличие от лейзи-листов). Использовать только в
// коде SSspatial_grid.
#define GRID_CELL_ADD(cell_contents_list, movable_or_list) \
	if(!length(cell_contents_list)) { \
		cell_contents_list = list(); \
		cell_contents_list += movable_or_list; \
	} else { \
		cell_contents_list += movable_or_list; \
	};

#define GRID_CELL_SET(cell_contents_list, movable_or_list) \
	if(!length(cell_contents_list)) { \
		cell_contents_list = list(); \
		cell_contents_list += movable_or_list; \
	} else { \
		cell_contents_list |= movable_or_list; \
	};

#define GRID_CELL_REMOVE(cell_contents_list, movable_or_list) \
	cell_contents_list -= movable_or_list; \
	if(!length(cell_contents_list)) { \
		cell_contents_list = dummy_list; \
	};

/// Убрать movable из всех списков ячейки
#define GRID_CELL_REMOVE_ALL(cell, movable) \
	GRID_CELL_REMOVE(cell.hearing_contents, movable) \
	GRID_CELL_REMOVE(cell.client_contents, movable)
