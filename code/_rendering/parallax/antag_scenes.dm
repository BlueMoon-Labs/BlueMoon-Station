/**
 * # Сцены за бортом от антагонистов
 *
 * Культ и вознёсшийся еретик меняют вид из иллюминатора. Механика у них одна и та
 * же, поэтому все такие сцены объявлены здесь списком, а не рассыпаны по файлам
 * антагонистов: те только называют нужный ключ в момент своего события.
 *
 * Сцена НЕ подменяет профиль уровня, а ложится слоями поверх него. Причина не
 * техническая: станционный фон - это ориентир сектора, по нему игрок понимает, где
 * он находится. Подмена профиля на время культа стёрла бы его вместе с планетой, и
 * вместо "небо побагровело" вышло бы "станцию куда-то перенесли".
 *
 * Каждая сцена собрана только из уже существующего арта: тонировка экрана нужного
 * цвета плюс, если явлению нужна фактура, один готовый ярус дымки или частиц.
 */

/// Культ дорос до трети экипажа: завеса истончается, небо чуть багровеет.
#define ANTAG_SCENE_CULT_RISEN "cult_risen"
/// Культ ascendent: красная жатва, небо заливает кровью.
#define ANTAG_SCENE_CULT_ASCENDENT "cult_ascendent"
/// Нар'Си призвана. Сильнее сцены в игре нет и быть не должно.
#define ANTAG_SCENE_NARSIE "narsie"
/// Вознесение еретика по путям.
#define ANTAG_SCENE_HERETIC_ASH "heretic_ash"
#define ANTAG_SCENE_HERETIC_RUST "heretic_rust"
#define ANTAG_SCENE_HERETIC_VOID "heretic_void"
#define ANTAG_SCENE_HERETIC_FLESH "heretic_flesh"

/// Токен культа. Один на все три ступени: повторный add_modifier с тем же токеном
/// ЗАМЕНЯЕТ запись, поэтому усиление сцены не складывается с предыдущей ступенью.
#define ANTAG_PARALLAX_TOKEN_CULT "antag_cult"
/// Токен вознесения еретика. Двое вознёсшихся - вторая сцена перекрывает первую.
#define ANTAG_PARALLAX_TOKEN_HERETIC "antag_heretic"

/// Ключ сцены -> слои поверх текущей сцены уровня.
GLOBAL_LIST_INIT(antag_parallax_scenes, list(
	ANTAG_SCENE_CULT_RISEN = list(
		/atom/movable/screen/parallax_layer/tint/antag/cult_veil,
	),
	ANTAG_SCENE_CULT_ASCENDENT = list(
		/atom/movable/screen/parallax_layer/tint/antag/cult_harvest,
		/atom/movable/screen/parallax_layer/goon/void_clouds_1,
	),
	ANTAG_SCENE_NARSIE = list(
		/atom/movable/screen/parallax_layer/tint/antag/cult_narsie,
		/atom/movable/screen/parallax_layer/goon/void_clouds_2,
	),
	ANTAG_SCENE_HERETIC_ASH = list(
		/atom/movable/screen/parallax_layer/tint/antag/heretic_ash,
		/atom/movable/screen/parallax_layer/goon/embers_sparse,
	),
	ANTAG_SCENE_HERETIC_RUST = list(
		/atom/movable/screen/parallax_layer/tint/antag/heretic_rust,
		/atom/movable/screen/parallax_layer/goon/dust_sparse,
	),
	ANTAG_SCENE_HERETIC_VOID = list(
		/atom/movable/screen/parallax_layer/tint/antag/heretic_void,
		/atom/movable/screen/parallax_layer/goon/void_clouds_2,
	),
	ANTAG_SCENE_HERETIC_FLESH = list(
		/atom/movable/screen/parallax_layer/tint/antag/heretic_flesh,
		/atom/movable/screen/parallax_layer/goon/blowout_clouds,
	),
))

/**
 * Ставит сцену антагониста на все станционные уровни под своим токеном.
 *
 * Возвращает число уровней, на которые сцена легла. Ноль означает, что станционных
 * уровней нет вообще - в игре так не бывает, но в тестовой сборке бывает.
 */
/proc/set_antag_parallax_scene(scene_key, token, fade_time = 8 SECONDS)
	var/list/scene_layers = GLOB.antag_parallax_scenes[scene_key]
	if(!length(scene_layers))
		stack_trace("Неизвестная сцена антагониста '[scene_key]'")
		return 0
	if(!token)
		CRASH("set_antag_parallax_scene без токена")
	. = 0
	for(var/station_z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		SSparallax.add_layers(station_z, token, scene_layers, PARALLAX_PRIORITY_ANTAG, fade_time)
		.++

/// Убирает сцену антагониста отовсюду. Возвращает TRUE, если что-то сняли.
/proc/clear_antag_parallax_scene(token, fade_time = 8 SECONDS)
	return SSparallax.remove_modifier_everywhere(token, fade_time)

// ---------------------------------------------------------------------------
// Тонировки
// ---------------------------------------------------------------------------

/**
 * Тонировка идёт через BLEND_ADD, то есть ДОБАВЛЯЕТ свет выбранного цвета, а не
 * гасит картинку. Затемнить ей нельзя ни при какой альфе, поэтому там, где явлению
 * нужно гнетущее небо, к тонировке идёт тёмный ярус дымки, а не чёрный фильтр.
 */
/atom/movable/screen/parallax_layer/tint/antag
	layer = 4.4
	fade_in_time = 8 SECONDS

/// Первая ступень культа. Едва заметный багрянец: это намёк, а не объявление.
/atom/movable/screen/parallax_layer/tint/antag/cult_veil
	color = "#5a0a12"
	alpha = 40

/// Красная жатва. Здесь уже нельзя не заметить.
/atom/movable/screen/parallax_layer/tint/antag/cult_harvest
	color = "#8a0f14"
	alpha = 80

/// Нар'Си в небе.
/atom/movable/screen/parallax_layer/tint/antag/cult_narsie
	color = "#c0121a"
	alpha = 120

/// Князь пепла: небо горит оранжевым.
/atom/movable/screen/parallax_layer/tint/antag/heretic_ash
	color = "#b34a12"
	alpha = 70

/// Ржавый всадник: рыжий налёт на всём.
/atom/movable/screen/parallax_layer/tint/antag/heretic_rust
	color = "#8a4a1a"
	alpha = 65

/// Дворянин пустоты: холодная синева.
/atom/movable/screen/parallax_layer/tint/antag/heretic_void
	color = "#2a3a7a"
	alpha = 70

/// Повелитель ночи: густой багрянец.
/atom/movable/screen/parallax_layer/tint/antag/heretic_flesh
	color = "#7a1030"
	alpha = 75
