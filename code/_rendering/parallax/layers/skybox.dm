/**
 * Скайбоксы: крупные нетайлящиеся фоны 736x736.
 *
 * Их не размножают сеткой - картинка масштабируется так, чтобы перекрыть вьюпорт
 * с запасом, и ровно этот запас тратится на параллаксный сдвиг. Приём взят у
 * Foundation-19 (`parallax_bleed_percent`) и доводит до того, что край фона не
 * может выехать в кадр математически, при каком угодно client.view.
 *
 * Скорость намеренно крошечная: у всех доноров скайбокс идёт около одного пикселя
 * на тайл, и это правильно - фон обязан читаться как "бесконечно далеко".
 */
/atom/movable/screen/parallax_layer/skybox
	icon = 'icons/effects/parallax/skyboxes.dmi'
	layer_mode = PARALLAX_MODE_SKYBOX
	tile_size = 736
	speed = 0.06
	// Строго над подложкой сцены и под всем остальным.
	layer = 0.5
	parallax_intensity = PARALLAX_LOW

/// Самый насыщенный фон выборки (разброс каналов 65 из 255 против 30 у остальных):
/// на полной альфе оранжевая заливка читается как светофильтр, а не как туманность.
/atom/movable/screen/parallax_layer/skybox/space_0
	icon_state = "space0"
	alpha = 165

/atom/movable/screen/parallax_layer/skybox/space_1
	icon_state = "space1"

/atom/movable/screen/parallax_layer/skybox/space_2
	icon_state = "space2"

/atom/movable/screen/parallax_layer/skybox/space_3
	icon_state = "space3"

/atom/movable/screen/parallax_layer/skybox/space_4
	icon_state = "space4"

/atom/movable/screen/parallax_layer/skybox/space_5
	icon_state = "space5"

/atom/movable/screen/parallax_layer/skybox/space_6
	icon_state = "space6"

/atom/movable/screen/parallax_layer/skybox/nebula
	icon_state = "nebula"

/// Обесцвеченная фрактальная дымка. Один стейт даёт любой цвет сектора,
/// поэтому он и помечен palette_tinted.
/atom/movable/screen/parallax_layer/skybox/dyable
	icon_state = "dyable"
	palette_tinted = TRUE

/// Чистая чернота. 3.7 КБ, нужна там, где фон обязан быть пустым, а не звёздным.
/atom/movable/screen/parallax_layer/skybox/void
	icon_state = "void"

// --- Секторные фоны Aurora -------------------------------------------------
// Отобраны по яркости кромки: взяты только те, у кого край темнее ~11 luma и
// потому сливается с чёрным космосом. Светлокромочные (srandmarr, ceti,
// star_nursery, valley_hale) отвергнуты - у них видна рамка.

/**
 * Aurora рисовала эти фоны под BLEND_MULTIPLY поверх белого плана, у нас же план
 * аддитивный поверх чёрного - на полной альфе они выходят кричаще насыщенными и
 * читаются как цветная стена, а не как далёкий сектор. 170 приводит их к яркости
 * кадра около 27, то есть к уровню фонов Polaris, которые рисовались под сложение.
 */
/atom/movable/screen/parallax_layer/skybox/sector
	alpha = 170

/**
 * В профили НЕ входит, хотя импортирован.
 *
 * Единственный из отобранных, который не удалось приручить: сплошное зелёное поле
 * с оранжевыми узлами на аддитивном плане читается как цветная стена, а не как
 * далёкий сектор, и приглушение альфой его только сереет. Лежит в DMI на случай,
 * если найдётся событие, которому такая заливка подойдёт по смыслу.
 */
/atom/movable/screen/parallax_layer/skybox/sector/arusha
	icon_state = "arusha"

/atom/movable/screen/parallax_layer/skybox/sector/badlands
	icon_state = "badlands"

/// Бирюзовые кольца - второй по насыщенности фон (51 из 255), приглушён сильнее прочих.
/atom/movable/screen/parallax_layer/skybox/sector/puddle_worlds
	icon_state = "puddle_worlds"
	alpha = 130

/atom/movable/screen/parallax_layer/skybox/sector/sparring_sea
	icon_state = "sparring_sea"

/atom/movable/screen/parallax_layer/skybox/sector/crescent_expanse
	icon_state = "crescent_expanse"

/**
 * Калибровочная мишень Polaris: рамка, поля, круг и диагонали.
 *
 * Единственный слой, у которого край намеренно виден. Нужен, чтобы глазами
 * проверить screen_loc, масштаб и запас скайбокса при нестандартном view -
 * на обычном фоне ошибка центрирования в пару пикселей просто не заметна.
 * В автоподбор не входит: ставится только вручную через админский инструмент.
 */
/atom/movable/screen/parallax_layer/skybox/diagnostic
	icon_state = "diagnostic"

/**
 * Редкие разноцветные звёзды на прозрачном фоне.
 *
 * Единственный по-настоящему бесшовный стейт во всей донорской выборке
 * (расхождение противоположных краёв ровно 0), поэтому он идёт ТАЙЛЯЩИМСЯ
 * поверх скайбокса, а не скайбоксом.
 */
/atom/movable/screen/parallax_layer/skybox/stars
	icon_state = "stars"
	layer_mode = PARALLAX_MODE_TILED
	speed = 0.8
	layer = 2
	parallax_intensity = PARALLAX_MED
	twinkle_time = 6 SECONDS
	twinkle_min_alpha = 165
