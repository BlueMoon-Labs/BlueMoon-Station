/**
 * Растровые поверхности maptext, которые клиент держит до конца сессии.
 *
 * BYOND растеризует maptext в поверхность размером maptext_width * maptext_height * 4 байта,
 * и живёт она столько же, сколько appearance, в который попала: у 32-битного Dream Seeker
 * освободить её нечем. Поэтому объявленная коробка - это НЕ верстка, а прайс-лист: каждая
 * уникальная строка стоит ровно площадь коробки.
 *
 * Замер прода 28.08.2026: клиент после очистки кэша занимал 640 МБ и через десять минут -
 * 2771 МБ, то есть +213 МБ/мин. При коробке скринтипа 480x480 (0.92 МБ на строку) это
 * 2-4 уникальные строки в секунду - ровно темп человека, водящего мышью по объектам с
 * разными именами. Скринтипы включены по умолчанию у всех.
 *
 * Тест держит бюджет на самые частые коробки. Он намеренно проверяет ОБЪЯВЛЕННЫЙ размер, а
 * не отрисованный: платится именно объявленный, независимо от того, сколько текста внутри.
 */

/// Ширина вьюпорта на широком экране. Historic: до диеты коробка скринтипа равнялась ей.
#define MAPTEXT_WIDE_VIEW_PX 736
/// Байт в мебибайте - только для сообщения об ошибке.
#define MAPTEXT_BYTES_PER_MIB (1024 * 1024)
/// Потолок площади одной коробки maptext в пикселях. Это скринтип на широком экране после
/// диеты; всё, что заметно больше, стоит мегабайта на строку и должно обосновываться отдельно.
#define MAPTEXT_SURFACE_BUDGET_PX (MAPTEXT_WIDE_VIEW_PX * 128)

/datum/unit_test/maptext_surface_budget

/datum/unit_test/maptext_surface_budget/Run()
	// Скринтип, худший случай: потолок ширины (update_view() больше не тянет коробку на весь
	// вьюпорт) на потолок высоты (четыре строки контекста).
	var/screentip_worst = SCREENTIP_BOX_MAX_WIDTH * SCREENTIP_BOX_MAX_HEIGHT
	TEST_ASSERT(screentip_worst <= MAPTEXT_SURFACE_BUDGET_PX, \
		"худшая коробка скринтипа [SCREENTIP_BOX_MAX_WIDTH]x[SCREENTIP_BOX_MAX_HEIGHT] - это \
		[round(screentip_worst * 4 / MAPTEXT_BYTES_PER_MIB, 0.01)] МБ памяти клиента на КАЖДУЮ \
		уникальную строку, а строк там тысячи и они личные у каждого игрока")

	// Объявленная ширина не должна превышать потолок: именно её платит клиент, и именно она
	// раньше равнялась ширине вьюпорта, то есть 736 px на широком экране.
	var/screentip_width = /atom/movable/screen/screentip::maptext_width
	TEST_ASSERT(screentip_width > 0 && screentip_width <= SCREENTIP_BOX_MAX_WIDTH, \
		"объявленная ширина коробки скринтипа [screentip_width] px мимо потолка [SCREENTIP_BOX_MAX_WIDTH]")

	// И обычное наведение - без контекстных строк - обязано стоить ДЕШЕВЛЕ худшего случая.
	// Если высота снова станет фиксированной, этот ассерт упадёт.
	var/screentip_common = /atom/movable/screen/screentip::maptext_height
	TEST_ASSERT(screentip_common > 0 && screentip_common < SCREENTIP_BOX_MAX_HEIGHT, \
		"наведение без подсказок платит [screentip_common] px высоты при потолке \
		[SCREENTIP_BOX_MAX_HEIGHT]: коробка снова считается по худшему случаю")

	// Печатная машинка рунчата: каждый кадр - отдельная уникальная строка maptext, то есть
	// отдельная поверхность. Потолок кадров обязан РЕАЛЬНО связывать при нынешнем tick_lag,
	// иначе он стоит для красоты.
	var/uncapped_frames = CEILING(CHAT_MESSAGE_TYPING_TIME / world.tick_lag, 1)
	TEST_ASSERT(CHAT_MESSAGE_TYPEWRITER_MAX_FRAMES < uncapped_frames, \
		"потолок кадров печатной машинки [CHAT_MESSAGE_TYPEWRITER_MAX_FRAMES] не связывает: \
		при tick_lag [world.tick_lag] анимация и так укладывается в [uncapped_frames] кадров")

	// Панели нейроинтерфейса: обновляются на SSfastprocess, то есть до пяти раз в секунду.
	var/data_surface = /datum/neural_interface_module/data::maptext_width * /datum/neural_interface_module/data::maptext_height
	TEST_ASSERT(data_surface <= MAPTEXT_SURFACE_BUDGET_PX, \
		"коробка панели данных нейроинтерфейса выросла до [data_surface] px")
	var/logs_surface = /datum/neural_interface_module/logs::maptext_width * /datum/neural_interface_module/logs::maptext_height
	TEST_ASSERT(logs_surface <= MAPTEXT_SURFACE_BUDGET_PX, \
		"коробка панели логов нейроинтерфейса выросла до [logs_surface] px")

/**
 * Строки нейроинтерфейса не несут сырых float.
 *
 * Панель пересобирается пять раз в секунду, и "HEALTH:97.5333" на каждом тике здоровья - это
 * новая уникальная строка, то есть новая растровая поверхность у клиента навсегда. Целые
 * значения дают не больше сотни состояний на поле, и панель переиспользует уже готовые.
 */
/datum/unit_test/neural_interface_rounds_health

/datum/unit_test/neural_interface_rounds_health/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	// Урон дробный намеренно: именно такие значения приходят от реагентов и кровопотери.
	patient.adjustBruteLoss(7.3333)
	patient.adjustToxLoss(1.79999)

	var/datum/neural_monitor/health_scan/scan = new
	scan.target = patient
	var/line = scan.get_data()
	qdel(scan)

	TEST_ASSERT_NOTNULL(line, "монитор здоровья не отдал строку по живой цели")
	// Точка в числе означает, что в maptext уехал сырой float.
	for(var/field as anything in splittext(line, "\n"))
		var/list/parts = splittext(field, ":")
		if(length(parts) < 2)
			continue
		TEST_ASSERT(!findtext(parts[2], "."), \
			"поле \"[field]\" несёт дробное значение: каждая такая строка - отдельная растровая \
			поверхность у клиента, а поле обновляется пять раз в секунду")

#undef MAPTEXT_SURFACE_BUDGET_PX
#undef MAPTEXT_BYTES_PER_MIB
#undef MAPTEXT_WIDE_VIEW_PX
