// Регрессы по прод-раундам 10150 и 10151. Тесты названы по симптому в логе,
// а не по внутреннему механизму.

/// "list index out of bounds" в deactivate() апгрейдов киборга.
/// ResetModule() сначала подменяет модуль пустым, и только потом дёргает
/// deactivate(): заменяемого инструмента в списках уже нет, а старый код всё
/// равно уходил в Swap(0, x).
/datum/unit_test/borg_upgrade_deactivate_without_its_tool/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	var/obj/item/borg/upgrade/rped/upgrade = allocate(/obj/item/borg/upgrade/rped)
	borg.upgrades += upgrade

	TEST_ASSERT_EQUAL(upgrade.find_module_index(borg, /obj/item/storage/part_replacer/bluespace/cyborg), 0, \
		"test premise: в пустом модуле не должно быть блюспейс-РПЕДа")

	var/modules_before = length(borg.module.modules)
	upgrade.deactivate(borg)
	TEST_ASSERT_EQUAL(length(borg.module.modules), modules_before, \
		"deactivate() без своего инструмента в модуле не должен ничего туда класть")

	borg.upgrades -= upgrade

/// Тот же путь целиком: перерезанный провод Reset Module.
/// Апгрейд обязан оказаться на полу, а deactivate() - отработать ровно один раз.
/datum/unit_test/borg_reset_module_drops_upgrades/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	var/obj/item/borg/upgrade/rped/upgrade = allocate(/obj/item/borg/upgrade/rped)
	borg.add_to_upgrades(upgrade)
	TEST_ASSERT(upgrade in borg.upgrades, "test premise: апгрейд должен встать в список киборга")

	borg.ResetModule()

	TEST_ASSERT_EQUAL(length(borg.upgrades), 0, "сброс модуля обязан очистить список апгрейдов")
	TEST_ASSERT_EQUAL(upgrade.loc, get_turf(borg), "сброс модуля обязан выложить апгрейд на пол")

/// remove_from_upgrades() сравнивал свой loc вместо loc апгрейда, поэтому условие
/// раннего выхода не срабатывало никогда: перемещение внутри киборга снимало апгрейд.
/datum/unit_test/borg_upgrade_survives_internal_move/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	var/obj/item/borg/upgrade/rped/upgrade = allocate(/obj/item/borg/upgrade/rped)
	borg.add_to_upgrades(upgrade)
	TEST_ASSERT_EQUAL(upgrade.loc, borg, "test premise: апгрейд должен лежать внутри киборга")

	borg.remove_from_upgrades(upgrade)
	TEST_ASSERT(upgrade in borg.upgrades, "апгрейд внутри киборга не должен сниматься по сигналу перемещения")

	upgrade.forceMove(get_turf(borg))
	TEST_ASSERT(!(upgrade in borg.upgrades), "вынутый наружу апгрейд обязан сняться")

/// "Cannot execute null.Copy()" в dust_spill_everything: список имплантов
/// объявлен null и наполняется лениво.
/datum/unit_test/dust_spill_without_implant_list/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.implants = null // прод-состояние: у моба без имплантов ленивого списка просто нет

	dummy.dust_spill_everything()
	TEST_ASSERT_NULL(dummy.implants, "разброс содержимого не должен заводить список имплантов на пустом месте")

	var/obj/item/implant/freedom/implant = allocate(/obj/item/implant/freedom)
	LAZYADD(dummy.implants, implant)
	dummy.dust_spill_everything()

	TEST_ASSERT_EQUAL(LAZYLEN(dummy.implants), 0, "имплант обязан быть снят со списка")
	TEST_ASSERT_EQUAL(implant.loc, get_turf(dummy), "имплант обязан выпасть на пол")

/// "destroy proc was called multiple times" у сборного модуля брони МОДа:
/// его on_uninstall() звал qdel(src), а Destroy() снова заходил в uninstall().
/datum/unit_test/mod_prebuild_armor_deletes_once/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/mod/module/armor/prebuild/laser/plate = new(mod)
	mod.install(plate)
	TEST_ASSERT(plate in mod.modules, "test premise: сборный модуль брони должен встать в костюм")

	var/modules_before = length(mod.modules)
	qdel(plate)

	TEST_ASSERT(QDELETED(plate), "модуль обязан удалиться")
	TEST_ASSERT_EQUAL(length(mod.modules), modules_before - 1, \
		"снятый модуль обязан выйти из списка костюма ровно один раз")

/// "Cannot read null.loc" в update_overlays пожарной сигнализации: лава сжигала
/// её прямо в Initialize турфа, и к моменту перерисовки loc был уже null.
/datum/unit_test/firealarm_overlays_without_loc/Run()
	var/obj/machinery/firealarm/alarm = allocate(/obj/machinery/firealarm)
	alarm.moveToNullspace()
	TEST_ASSERT_NULL(alarm.loc, "test premise: сигнализация должна оказаться вне мира")

	var/list/produced = alarm.update_overlays()
	TEST_ASSERT(length(produced) > 0, "сигнализация вне мира обязана собрать оверлеи, а не падать на src.loc")

/// "undefined variable /obj/item/clothing/mod_part/shoes/var/can_be_tied":
/// в слот обуви влезает не только /obj/item/clothing/shoes.
/datum/unit_test/mod_boots_are_not_laced_shoes/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/clothing/mod_part/shoes/boots = mod.mod_parts[MOD_PART_FEET]
	TEST_ASSERT_NOTNULL(boots, "test premise: у МОДа должны быть ботинки")
	TEST_ASSERT(!istype(boots, /obj/item/clothing/shoes), \
		"test premise: МОД-ботинки не наследуются от /obj/item/clothing/shoes - на этом и падало событие шнурков")

	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.shoes = boots
	var/datum/smite/knot_shoes/smite = new
	// Базовый effect() пишет punish_log через клиента админа, которого в тесте нет.
	smite.should_log = FALSE
	smite.effect(null, dummy)
	TEST_ASSERT_EQUAL(dummy.shoes, boots, "смайт шнурков не должен трогать обувь без шнурков")
	dummy.shoes = null
	qdel(smite)

/// "Cannot execute null.percent()" при осмотре зарядника: у заряжаемого предмета
/// может вовсе не быть ячейки.
/datum/unit_test/recharger_examine_without_cell/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/obj/machinery/recharger/charger = allocate(/obj/machinery/recharger)
	var/obj/item/cellless = allocate(/obj/item/screwdriver)

	charger.machine_stat = NONE
	charger.charging = cellless
	TEST_ASSERT_NULL(cellless.get_cell(), "test premise: у предмета не должно быть ячейки")

	var/list/examine_lines = charger.examine(viewer)
	charger.charging = null
	TEST_ASSERT(length(examine_lines) > 0, "осмотр зарядника обязан вернуть текст, а не падать на null.percent()")

/// teach() у крав-мага и рестлинга не возвращал ничего, и вызывающие считали
/// успешное обучение провалом - панель игрока после этого qdel-ила уже выданный
/// стиль, харддел обнулял mind.martial_art, а кнопки приёмов оставались на HUD.
/datum/unit_test/martial_art_teach_reports_success/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.mind_initialize()

	var/datum/martial_art/krav_maga/krav = new
	TEST_ASSERT(krav.teach(dummy), "krav_maga.teach() обязан отчитаться об успехе")
	TEST_ASSERT_EQUAL(dummy.mind.martial_art, krav, "стиль обязан встать разуму")
	TEST_ASSERT(krav.legsweep in dummy.actions, "test premise: кнопка подсечки должна быть выдана")

	var/datum/martial_art/wrestling/wrassle = new
	TEST_ASSERT(wrassle.teach(dummy), "wrestling.teach() обязан отчитаться об успехе")
	wrassle.remove(dummy)
	qdel(wrassle)

	var/datum/action/leg_sweep/legsweep = krav.legsweep
	dummy.mind.martial_art = dummy.mind.default_martial_art
	qdel(krav)
	TEST_ASSERT(QDELETED(legsweep), "кнопка приёма обязана уйти вместе со стилем")
	TEST_ASSERT(!(legsweep in dummy.actions), "мёртвая кнопка приёма не должна оставаться на владельце")

/// "Cannot read null.streak" по клику на кнопку приёма, пережившую свой стиль.
/datum/unit_test/martial_art_button_without_style/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.mind_initialize()
	dummy.mind.martial_art = null

	var/datum/action/leg_sweep/legsweep = new
	legsweep.Grant(dummy)
	TEST_ASSERT_NULL(legsweep.owner_martial_art(), "test premise: стиля у владельца быть не должно")

	legsweep.Trigger()
	TEST_ASSERT_NULL(dummy.mind.martial_art, "кнопка без стиля не должна ничего заводить")

	qdel(legsweep)
	dummy.mind.martial_art = dummy.mind.default_martial_art

/// "bad icon operation" при сборке кастомного голоформа: стороны теперь добиваются
/// прозрачным полем до общего размера и вставляются под try/catch. Тест закрепляет
/// механизм добивки (Crop выравнивает габариты) и то, что выровненные стороны
/// собираются без рантайма. Сам триггер прод-отказа воспроизвести не удалось: Insert
/// принимает и разные размеры, и разное число кадров, и иконки из разных файлов.
/datum/unit_test/holoform_direction_frames_share_size/Run()
	var/icon/narrow = icon('icons/effects/effects.dmi', "nothing")
	var/icon/wide = icon('icons/effects/effects.dmi', "nothing")
	wide.Crop(1, 1, world.icon_size * 2, world.icon_size * 2)
	TEST_ASSERT_NOTEQUAL(narrow.Width(), wide.Width(), "test premise: стороны должны отличаться по размеру")

	narrow.Crop(1, 1, wide.Width(), wide.Height())
	TEST_ASSERT_EQUAL(narrow.Width(), wide.Width(), "добивка прозрачным полем обязана выровнять ширину")
	TEST_ASSERT_EQUAL(narrow.Height(), wide.Height(), "добивка прозрачным полем обязана выровнять высоту")

	// Выровненные стороны собираются без рантайма (рантайм внутри Run() валит тест сам).
	var/icon/combined = new
	combined.Insert(wide, dir = NORTH)
	combined.Insert(narrow, dir = SOUTH)

/// "addtimer called with a negative wait" у верстака патронов: турбо-время
/// считалось из ещё не зажатого значения и уходило в минус на сильных лазерах.
/datum/unit_test/ammo_workbench_turbo_time_stays_positive/Run()
	var/obj/machinery/ammo_workbench/bench = allocate(/obj/machinery/ammo_workbench)
	bench.component_parts = list()
	for(var/index in 1 to 2)
		var/obj/item/stock_parts/micro_laser/laser = new(bench)
		laser.rating = 5
		bench.component_parts += laser

	bench.RefreshParts()

	TEST_ASSERT(bench.time_per_round > 0, "обычное время сборки патрона обязано остаться положительным")
	TEST_ASSERT(bench.turbo_time_per_round > 0, "турбо-время сборки патрона обязано остаться положительным")

/// "doMove qdel-нутого /obj/item/paper/fluff/jobs/cargo/manifest": накладную
/// удалял взрыв прямо в contents ящика, а ящик продолжал держать на неё ссылку.
/datum/unit_test/crate_manifest_reference_drops_with_paper/Run()
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate)
	var/obj/item/paper/fluff/jobs/cargo/manifest/paper = new(crate)
	crate.set_manifest(paper)
	TEST_ASSERT_EQUAL(crate.manifest, paper, "test premise: накладная должна встать на ящик")

	qdel(paper)
	TEST_ASSERT_NULL(crate.manifest, "ссылка на накладную обязана опуститься вместе с бумагой")

	crate.open(null, TRUE)
	TEST_ASSERT(crate.opened, "ящик обязан открыться и без накладной")

/// "Cyborg stack created outside of a robot module, deleting.": apply_gauze()
/// плодил копию киборгского стака прямо в конечности, а та самоудалялась.
/datum/unit_test/cyborg_gauze_applies_normal_stack/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	var/obj/item/bodypart/chest = dummy.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_NOTNULL(chest, "test premise: у человека должна быть грудь")

	var/obj/item/robot_module/module = allocate(/obj/item/robot_module)
	var/obj/item/stack/medical/gauze/cyborg/borg_gauze = new(module, 5)
	TEST_ASSERT(!QDELETED(borg_gauze), "test premise: киборгский бинт внутри модуля обязан выжить")

	chest.apply_gauze(borg_gauze)

	TEST_ASSERT_NOTNULL(chest.current_gauze, "бинт обязан лечь на конечность")
	TEST_ASSERT(!QDELETED(chest.current_gauze), "легший бинт не должен самоудаляться")
	var/obj/item/stack/applied = chest.current_gauze
	TEST_ASSERT(!applied.is_cyborg, "на конечность обязан лечь обычный бинт, а не киборгский")

/// Кнопка накожного нанит-модуля и сама программа держали друг друга и уходили
/// в харддел с одной внешней ссылкой каждая.
/datum/unit_test/nanite_button_releases_its_program/Run()
	var/datum/nanite_program/dermal_button/program = new
	var/datum/action/innate/nanite_button/button = new(program, "Button", "power")
	program.button = button

	qdel(program)

	TEST_ASSERT(QDELETED(button), "кнопка обязана уйти вместе с программой")
	TEST_ASSERT_NULL(button.program, "кнопка не должна держать удалённую программу")
