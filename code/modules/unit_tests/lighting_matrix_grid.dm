/**
 * Итоговая матрица цвета объекта освещения обязана лежать на сетке.
 *
 * ЗАЧЕМ ТЕСТ. BYOND интернирует appearance по значению и держит их у клиента до конца
 * сессии. Значения углов приходят в update() округлёнными к LIGHTING_ROUND_VALUE именно
 * ради этого: сетка ограничивает число различных состояний, и повтор схлопывается в уже
 * существующий appearance. Но дальше по проку значения домножаются на непрерывные
 * множители - контактную тень, контраст и температуру зоны, подкраску теней, - и без
 * обратного округления каждое движение любого источника света рождает у каждого видящего
 * клиента новый уникальный appearance навсегда.
 *
 * Цена промаха измерена на проде 27.08.2026 (раунд 10127, 87-105 игроков): 32-битный
 * Dream Seeker брал 732 МБ сразу после входа, добирал 2.4 ГБ за восемь минут и падал
 * около 3400 МБ, а перед падением рисовал чужие спрайты вместо штатных и чёрно-белые
 * квадраты вместо тайлов.
 *
 * Сломать инвариант молча очень просто: достаточно добавить в update() ещё один
 * множитель ПОСЛЕ округления. Ни компилятор, ни глаз на скриншоте этого не поймают -
 * картинка остаётся правильной, платит только память клиента. Поэтому проверка тут.
 */
/datum/unit_test/lighting_matrix_stays_on_grid/Run()
	var/turf/tile = run_loc_floor_bottom_left
	// Резервация юнит-теста лежит в world.area, а это /area/space с DYNAMIC_LIGHTING_DISABLED: у такого
	// турфа объекта освещения нет ни после create_lighting_for_zlevel() в Setup(), ни после ChangeTurf()
	// в пол - оба пути гейтятся по IS_DYNAMIC_LIGHTING(зона). Оборудование заводим сами, как и
	// остальные тесты света: уборка идёт через allocated_force_qdel, потому что обычный qdel
	// объект освещения игнорирует.
	//
	// Порядок здесь не косметический. lighting_corner/New() зовёт update_active(), а тот ставит
	// active только если объект освещения УЖЕ есть хоть у одного из четырёх соседних турфов.
	// Угол, созданный раньше объекта, остаётся неактивным навсегда: источники света пишут такому
	// углу effect_str = 0 и APPLY_CORNER пропускают, то есть турф резервации больше НИКОМУ не
	// светится до конца прогона - и следующий тест света падает на пустой освещённости.
	var/atom/movable/lighting_object/lit = ensure_lighting_object(tile)
	if(!(tile.lighting_flags & TURF_LIGHTING_CORNERS_INITIALISED))
		tile.generate_missing_corners()
	// Углы могли достаться нам от прошлого теста, созданные без объекта - поднимаем явно.
	tile.lc_topright?.update_active()
	tile.lc_topleft?.update_active()
	tile.lc_bottomright?.update_active()
	tile.lc_bottomleft?.update_active()
	TEST_ASSERT_NOTNULL(lit, "у тестового турфа обязан быть объект освещения")

	var/area/tile_area = tile.loc
	var/restore_contrast = tile_area.light_contrast
	var/restore_temperature = tile_area.light_temperature
	var/restore_was_dark = lit.prev_was_dark

	// Штатный профиль зоны и есть то, что сбивает значения углов с их сетки: контраст
	// LIGHT_CONTRAST_DEEP и ненулевая температура - обычные значения, а не выдуманные для теста.
	tile_area.light_contrast = LIGHT_CONTRAST_DEEP
	tile_area.light_temperature = LIGHT_TEMP_INDUSTRIAL

	// Частичная освещённость обязательна: полностью светлый и полностью тёмный тайлы
	// уходят на готовые матрицы (LIGHTING_BASE_MATRIX / LIGHTING_DARK_MATRIX) и ветку
	// со сборкой буфера не трогают вовсе. Значения берём с угловой сетки - ровно такие
	// туда и приходят из lighting_corner.
	var/list/restore_corners = list()
	for(var/datum/lighting_corner/corner in list(tile.lc_bottomleft, tile.lc_bottomright, tile.lc_topleft, tile.lc_topright))
		restore_corners[corner] = list(corner.cache_r, corner.cache_g, corner.cache_b, corner.cache_mx)
		corner.cache_r = 11 / 32
		corner.cache_g = 17 / 32
		corner.cache_b = 23 / 32
		corner.cache_mx = 23 / 32

	// У объекта НА ГРАНИЦЕ зон профиль усреднён с соседями и лежит на нём самом
	// (blend_is_local), и update() читает кэш, а не свежие значения зоны. Без пересборки
	// такой тест мерил бы дефолтный профиль и проходил вхолостую. У тайла внутри одной
	// зоны это быстрый путь и стоит ноль, поэтому зовём безусловно.
	lit.calculate_area_blend()

	lit.prev_was_dark = FALSE
	lit.update(use_animate = FALSE)

	var/list/applied = lit.color
	var/applied_is_matrix = islist(applied)

	// Проверяем двенадцать цветовых каналов; хвост матрицы (смещения и единица альфы)
	// в update() не пишется и к сетке отношения не имеет.
	var/list/channels = list(1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15)
	var/off_grid = 0
	var/sample_index = 0
	var/sample_value = 0
	if(applied_is_matrix)
		for(var/index in channels)
			var/value = applied[index]
			var/steps = value / LIGHTING_MATRIX_ROUND_VALUE
			if(abs(steps - round(steps)) > 1e-9)
				off_grid++
				if(!sample_index)
					sample_index = index
					sample_value = value

	// Уборка идёт ДО всех проверок и без единого условия. Зона тут - world.area, общая на
	// весь космос мира, а углы - настоящие углы резервации: тест, упавший на середине,
	// оставил бы чужой профиль зоны и чужие кэши следующим тестам. TEST_ASSERT возвращается из
	// прока сразу, finally в DM нет, поэтому единственный надёжный порядок - такой.
	tile_area.light_contrast = restore_contrast
	tile_area.light_temperature = restore_temperature
	for(var/datum/lighting_corner/corner as anything in restore_corners)
		var/list/saved = restore_corners[corner]
		corner.cache_r = saved[1]
		corner.cache_g = saved[2]
		corner.cache_b = saved[3]
		corner.cache_mx = saved[4]
	// Порядок важен: calculate_area_blend() сам сбрасывает prev_was_dark, поэтому
	// сохранённое значение возвращаем ПОСЛЕ него.
	lit.calculate_area_blend()
	lit.prev_was_dark = restore_was_dark
	lit.update(use_animate = FALSE)

	TEST_ASSERT(length(restore_corners), "у тестового турфа обязан быть хотя бы один угол освещения")
	TEST_ASSERT(applied_is_matrix, "цвет объекта освещения обязан быть матрицей, а не строкой")
	TEST_ASSERT_EQUAL(off_grid, 0, "каналов вне сетки LIGHTING_MATRIX_ROUND_VALUE: [off_grid], первый - канал [sample_index] = [sample_value]. Значит, в update() появился множитель ПОСЛЕ округления, и каждый апдейт тайла снова плодит уникальный appearance у клиента.")
