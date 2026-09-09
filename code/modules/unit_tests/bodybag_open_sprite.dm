// Мешок для трупов рисуется двумя слоями: базовый icon_state - это ЦЕЛЫЙ закрытый
// мешок, а стейт "_open" - только расстёгнутый зев без корпуса вокруг. Стоит
// подставить "_open" прямо в icon_state - и на полу остаётся чёрная клякса,
// в которой мешок не узнаётся вообще. Ровно так он и уехал в раунд 10137.

/// Открытый мешок обязан оставить базовым стейтом закрытый мешок и добавить зев
/// оверлеем поверх него. Закрытие снимает оверлей и ничего больше не меняет.
/datum/unit_test/bodybag_open_overlay/Run()
	var/obj/structure/closet/body_bag/bag = allocate(/obj/structure/closet/body_bag)

	TEST_ASSERT_EQUAL(bag.icon_state, "bodybag", "закрытый мешок стоит не на базовом стейте")
	TEST_ASSERT(!("bodybag_open" in bag.update_overlays()), "закрытый мешок рисует зев")

	TEST_ASSERT(bag.open(force = TRUE), "мешок не открылся")
	TEST_ASSERT_EQUAL(bag.icon_state, "bodybag", "открытый мешок потерял корпус: зев уехал в icon_state вместо оверлея")
	TEST_ASSERT("bodybag_open" in bag.update_overlays(), "у открытого мешка нет оверлея зева - он выглядит закрытым")

	TEST_ASSERT(bag.close(), "мешок не закрылся")
	TEST_ASSERT_EQUAL(bag.icon_state, "bodybag", "закрытый мешок стоит не на базовом стейте")
	TEST_ASSERT(!("bodybag_open" in bag.update_overlays()), "закрытый мешок рисует зев")

/// У транспортного мешка застёгнутость живёт в базовом стейте, а открытость - в
/// оверлее. Эти два механизма не должны затирать друг друга.
/datum/unit_test/bodybag_sinched_state/Run()
	var/obj/structure/closet/body_bag/containment/prisoner/bag = allocate(/obj/structure/closet/body_bag/containment/prisoner)

	bag.sinched = TRUE
	bag.update_appearance()
	TEST_ASSERT_EQUAL(bag.icon_state, "prisonerenvirobag_sinched", "застёгнутый мешок не показывает ремни")

	TEST_ASSERT(bag.open(force = TRUE), "застёгнутый мешок не открылся принудительно")
	TEST_ASSERT(!bag.sinched, "открытие не расстегнуло ремни")
	TEST_ASSERT_EQUAL(bag.icon_state, "prisonerenvirobag", "открытый мешок стоит не на базовом стейте")
	TEST_ASSERT("prisonerenvirobag_open" in bag.update_overlays(), "у открытого транспортного мешка нет оверлея зева")

/// Спрайтовая половина того же инварианта: каждому мешку нужен свой "_open",
/// и этот "_open" обязан быть НЕПОЛНЫМ - у него нет пикселей там, где у закрытого
/// мешка корпус. Если кто-то дорисует зев до целого мешка, оверлейная схема
/// начнёт рисовать мешок дважды, и об этом надо узнать здесь, а не в раунде.
/datum/unit_test/bodybag_open_states_exist/Run()
	var/list/checked = list()
	for(var/obj/structure/closet/body_bag/bag as anything in typesof(/obj/structure/closet/body_bag))
		var/icon_file = initial(bag.icon)
		var/base_state = initial(bag.icon_state)
		if(!icon_file || !base_state)
			continue
		var/key = "[icon_file]:[base_state]"
		if(key in checked)
			continue
		checked[key] = TRUE

		var/list/present = icon_states(icon_file)
		TEST_ASSERT(base_state in present, "[bag]: в [icon_file] нет стейта '[base_state]'")
		TEST_ASSERT("[base_state]_open" in present, "[bag]: в [icon_file] нет стейта '[base_state]_open', открытый мешок будет невидим")

		var/icon/sheet = icon(icon_file)
		var/body_only_pixels = 0
		for(var/x in 1 to sheet.Width())
			for(var/y in 1 to sheet.Height())
				var/closed_pixel = sheet.GetPixel(x, y, base_state)
				var/open_pixel = sheet.GetPixel(x, y, "[base_state]_open")
				if(closed_pixel && !open_pixel)
					body_only_pixels++
		TEST_ASSERT(body_only_pixels, "[bag]: '[base_state]_open' закрывает закрытый мешок целиком - оверлейная схема нарисует мешок дважды")

	TEST_ASSERT(length(checked) >= 5, "ожидалось несколько видов мешков, проверено [length(checked)]")
