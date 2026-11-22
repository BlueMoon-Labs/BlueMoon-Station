/// Ctrl/Alt-клик ИИ по пульту турелей передаёт кликнувшего в лог боя.
/datum/unit_test/turret_control_ai_click_passes_user/Run()
	var/obj/machinery/turretid/control = allocate(/obj/machinery/turretid)
	var/mob/living/carbon/human/clicker = allocate(/mob/living/carbon/human)
	var/was_enabled = control.enabled
	var/was_lethal = control.lethal

	control.AICtrlClick(clicker)
	control.AIAltClick(clicker)

	TEST_ASSERT(control.enabled != was_enabled, "Ctrl-клик ИИ должен переключить питание турелей")
	TEST_ASSERT(control.lethal != was_lethal, "Alt-клик ИИ должен переключить летальный режим")

/// Турель роя, сломанная уроном, удаляется сама и не трогает свои уже удалённые искры.
/datum/unit_test/swarmer_turret_break_deletes_cleanly/Run()
	for(var/i in 1 to 20)
		var/obj/machinery/porta_turret/swarmer/turret = allocate(/obj/machinery/porta_turret/swarmer)
		turret.take_damage(turret.max_integrity * 0.6, BRUTE, 0, 0)
		TEST_ASSERT(QDELETED(turret), "Турель роя ниже порога поломки должна удалиться")

/// Распарыватель МОД снимает с одежды битовую маску зоны, и починка возвращает покрытие как было.
/datum/unit_test/mod_thread_ripper_rips_and_mends_flags/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/under/color/grey/jumpsuit = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(patient.equip_to_slot_or_del(jumpsuit, ITEM_SLOT_ICLOTHING), "test premise: комбинезон должен надеться")
	var/covered_before = jumpsuit.body_parts_covered
	TEST_ASSERT(covered_before & CHEST, "test premise: комбинезон должен закрывать грудь")
	var/obj/item/mod/module/thread_ripper/ripper = allocate(/obj/item/mod/module/thread_ripper)

	ripper.rip_clothing(patient, BODY_ZONE_CHEST)

	TEST_ASSERT(isnum(ripper.ripped_clothing[jumpsuit]), "Распарыватель должен запомнить снятые флаги числом, а не списком")
	TEST_ASSERT(!(jumpsuit.body_parts_covered & CHEST), "Грудь должна открыться")
	TEST_ASSERT(!(jumpsuit.body_parts_covered & GROIN), "Зона груди открывает и пах")
	ripper.mend(jumpsuit)
	TEST_ASSERT_EQUAL(jumpsuit.body_parts_covered, covered_before, "Починка должна вернуть покрытие одежды")

/// Подробный осмотр диска моба без разума (призрак, НПС) не падает.
/datum/unit_test/nuke_disk_examine_more_without_mind/Run()
	var/obj/item/disk/nuclear/fake/obvious/disk = allocate(/obj/item/disk/nuclear/fake/obvious)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(viewer.mind, "test premise: у тестового моба нет разума")

	var/list/lines = disk.examine_more(viewer)

	TEST_ASSERT(length(lines), "Осмотр должен вернуть строку про серийный номер")

/// Волны маскировки киборга ставятся и снимаются через именованные фильтры, анимация идёт по живым фильтрам.
/datum/unit_test/borg_shapeshifter_startup_filters/Run()
	var/obj/item/borg_shapeshifter/shifter = allocate(/obj/item/borg_shapeshifter)
	var/mob/living/carbon/human/borg = allocate(/mob/living/carbon/human)

	shifter.start_startup_filters(borg)

	TEST_ASSERT_EQUAL(length(shifter.startup_filters), 7, "Должно встать семь волн")
	TEST_ASSERT_NOTNULL(borg.get_filter("borg_shapeshifter_wave_1"), "Волна должна лежать в фильтрах киборга")
	shifter.clear_startup_filters()
	TEST_ASSERT_NULL(borg.get_filter("borg_shapeshifter_wave_1"), "Снятие должно убрать волны")
	TEST_ASSERT_NULL(shifter.startup_user, "Снятие должно отпустить киборга")

/// Модуль, снятый с меха в клетку идущего взрыва, подрывается там и не падает на уже пустом chassis.
/datum/unit_test/mecha_equipment_detach_into_explosion/Run()
	var/obj/vehicle/sealed/mecha/working/ripley/mech = allocate(/obj/vehicle/sealed/mecha/working/ripley)
	var/obj/item/mecha_parts/mecha_equipment/drill/drill = new(mech)
	drill.attach(mech)
	TEST_ASSERT(drill in mech.equipment, "test premise: бур должен встать на мех")
	var/turf/blast = get_turf(mech)
	blast.explosion_level = EXPLODE_DEVASTATE
	blast.explosion_id = "unit_test_mecha_detach"

	drill.detach(blast)

	blast.explosion_level = 0
	blast.explosion_id = 0
	TEST_ASSERT(QDELETED(drill), "Модуль в клетке взрыва должен подорваться")
	TEST_ASSERT(!(drill in mech.equipment), "Подорванный модуль не должен остаться в списке меха")

/// Удаление МОД вне карты не роняет модуль сумки для руды на уже снятом mod.
/datum/unit_test/mod_orebag_deleted_in_nullspace/Run()
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control)
	var/obj/item/mod/module/orebag/module = allocate(/obj/item/mod/module/orebag)
	mod.install(module)
	TEST_ASSERT_EQUAL(module.mod, mod, "test premise: модуль должен установиться")
	var/obj/item/storage/bag/ore/bag = allocate(/obj/item/storage/bag/ore)
	bag.forceMove(module)
	module.stored = bag
	mod.moveToNullspace()

	qdel(mod)

	TEST_ASSERT(QDELETED(module), "Модуль удаляется вместе с костюмом")

/// Проверка обзора камер для цели вне карты отвечает "не видно", а не падает.
/datum/unit_test/cameranet_turf_vis_null/Run()
	TEST_ASSERT(!GLOB.cameranet.checkTurfVis(null), "Нет турфа - камерам не видно")

/// Парирование глефой некрополя не стреляет болтом в нападавшего, который уже ушёл с карты.
/datum/unit_test/glaive_parry_attacker_off_map/Run()
	var/obj/item/kinetic_crusher/glaive/glaive = allocate(/obj/item/kinetic_crusher/glaive)
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	attacker.moveToNullspace()

	glaive.on_active_parry(owner, attacker, 10, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, list(), 100, 0)

	TEST_ASSERT_NULL(locate(/obj/item/projectile/destabilizer) in get_turf(owner), "Болт без цели не должен появляться")
