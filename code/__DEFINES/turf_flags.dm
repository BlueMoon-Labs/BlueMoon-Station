/**
 * Битовая укладка булевых свойств турфа (переменная /turf/var/turf_flags).
 *
 * Каждое из этих свойств раньше занимало собственный слот переменной на КАЖДОМ из 1.2 млн
 * турфов мира. У 32-битного DreamDaemon потолок адресного пространства 4 ГБ, и раунд стартует
 * с 79% от него, так что один слот на турфе - это 6.4 МБ запаса.
 *
 * Здесь только те свойства, которые ставятся из кода. Вареедитные в картах (blocks_air,
 * planetary_atmos) и горячие атмосные (excited, high_pressure_queued) оставлены переменными.
 */
/// Пол цел: провода идут ПОД ним. Снято - провода лежат поверх (плитинг, стекло, космос).
#define TURF_INTACT					(1<<0)
/// Гильза шипит, падая на этот турф (лава, вода, горячий песок).
#define TURF_BULLET_SIZZLE			(1<<1)
/// Турф разрешён к копированию в голодек.
#define TURF_HOLODECK_COMPATIBLE	(1<<2)
/// На турфе уже лежит напольное покрытие (мешает класть второе).
#define TURF_OVERFLOOR_PLACED		(1<<3)
/// Турф прямо сейчас меняет тип - ChangeTurf идёт, трогать нельзя.
#define TURF_CHANGING				(1<<4)
/// Турф надо добавить в обработку воздуха после Initialize().
#define TURF_REQUIRES_ACTIVATION	(1<<5)
/// Турф участвует в динамическом освещении.
#define TURF_DYNAMIC_LIGHTING		(1<<6)
/// На турфе копится грязь.
#define TURF_DIRT_BUILDUP_ALLOWED	(1<<7)
/// Турф использует декаль плиточной грязи.
#define TURF_TILED_DIRT				(1<<8)

/// Дефолт /turf: целый пол с динамическим освещением.
#define TURF_FLAGS_DEFAULT			(TURF_INTACT | TURF_DYNAMIC_LIGHTING)
/// Дефолт /turf/open/floor: пол копит грязь и носит плиточную декаль.
#define TURF_FLAGS_FLOOR			(TURF_FLAGS_DEFAULT | TURF_DIRT_BUILDUP_ALLOWED | TURF_TILED_DIRT)
/// Дефолт /turf/open/floor/holofloor: пол, который голодек умеет копировать.
#define TURF_FLAGS_HOLOFLOOR		(TURF_FLAGS_FLOOR | TURF_HOLODECK_COMPATIBLE)

/**
 * Производное состояние освещения турфа (переменная /turf/var/tmp/lighting_flags).
 *
 * Отдельным полем, а не в turf_flags: копир голодека переносит вары шаблона на приёмник
 * поимённо, и световое состояние шаблона переносить НЕЛЬЗЯ (см. turf_copy_forbidden_vars
 * в area_copy.dm). Одно имя в чёрном списке дешевле, чем маскирование битов в общем цикле.
 */
/// На турфе есть непрозрачный атом. Не путать с opacity самого турфа.
#define TURF_HAS_OPAQUE_ATOM				(1<<0)
/// Углы освещения турфа уже разложены.
#define TURF_LIGHTING_CORNERS_INITIALISED	(1<<1)

#define CHANGETURF_DEFER_CHANGE		1
#define CHANGETURF_IGNORE_AIR		2 // This flag prevents changeturf from gathering air from nearby turfs to fill the new turf with an approximation of local air
#define CHANGETURF_FORCEOP			4
#define CHANGETURF_SKIP				8 // A flag for PlaceOnTop to just instance the new turf instead of calling ChangeTurf. Used for uninitialized turfs NOTHING ELSE
#define CHANGETURF_INHERIT_AIR 		16 // Inherit air from previous turf. Implies CHANGETURF_IGNORE_AIR
#define CHANGETURF_RECALC_ADJACENT 32 //Immediately recalc adjacent atmos turfs instead of queuing.

/// Returns a list of turfs similar to CORNER_BLOCK but with offsets
#define CORNER_BLOCK_OFFSET(corner, width, height, offset_x, offset_y) ((block(locate(corner.x + offset_x, corner.y + offset_y, corner.z), locate(min(corner.x + (width - 1) + offset_x, world.maxx), min(corner.y + (height - 1) + offset_y, world.maxy), corner.z))))

/// Returns a list of around us
#define TURF_NEIGHBORS(turf) (CORNER_BLOCK_OFFSET(turf, 3, 3, -1, -1) - turf)
