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
	var/atom/movable/lighting_object/lit = tile.lighting_object
	TEST_ASSERT_NOTNULL(lit, "у тестового турфа обязан быть объект освещения")

	var/area/tile_area = tile.loc
	var/restore_contrast = tile_area.light_contrast
	var/restore_temperature = tile_area.light_temperature
	var/restore_was_dark = lit.prev_was_dark

	// Штатный профиль зоны и есть то, что сбивает значения углов с их сетки: контраст
	// 1.15 и ненулевая температура - обычные значения, а не выдуманные для теста.
	tile_area.light_contrast = 1.15
	tile_area.light_temperature = 0.07

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
	TEST_ASSERT(length(restore_corners), "у тестового турфа обязан быть хотя бы один угол освещения")

	lit.prev_was_dark = FALSE
	lit.update(use_animate = FALSE)

	var/list/applied = lit.color
	TEST_ASSERT(islist(applied), "цвет объекта освещения обязан быть матрицей, а не строкой")

	// Проверяем двенадцать цветовых каналов; хвост матрицы (смещения и единица альфы)
	// в update() не пишется и к сетке отношения не имеет.
	var/list/channels = list(1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15)
	var/off_grid = 0
	var/sample_index = 0
	var/sample_value = 0
	for(var/index in channels)
		var/value = applied[index]
		var/steps = value / LIGHTING_MATRIX_ROUND_VALUE
		if(abs(steps - round(steps)) > 1e-9)
			off_grid++
			if(!sample_index)
				sample_index = index
				sample_value = value

	tile_area.light_contrast = restore_contrast
	tile_area.light_temperature = restore_temperature
	lit.prev_was_dark = restore_was_dark
	for(var/datum/lighting_corner/corner as anything in restore_corners)
		var/list/saved = restore_corners[corner]
		corner.cache_r = saved[1]
		corner.cache_g = saved[2]
		corner.cache_b = saved[3]
		corner.cache_mx = saved[4]
	lit.update(use_animate = FALSE)

	TEST_ASSERT_EQUAL(off_grid, 0, "каналов вне сетки LIGHTING_MATRIX_ROUND_VALUE: [off_grid], первый - канал [sample_index] = [sample_value]. Значит, в update() появился множитель ПОСЛЕ округления, и каждый апдейт тайла снова плодит уникальный appearance у клиента.")
