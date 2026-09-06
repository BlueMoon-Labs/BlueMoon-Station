/// Генетическая паутина путает того, кто в ней застрял, а не третий аргумент CanPass.
/datum/unit_test/genetic_web_confuses_the_mover/Run()
	var/mob/living/carbon/human/spider = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/monkey/mover = allocate(/mob/living/carbon/monkey)
	var/obj/structure/spider/stickyweb/genetic/web = allocate(/obj/structure/spider/stickyweb/genetic, run_loc_floor_bottom_left, spider)

	var/blocked = FALSE
	for(var/attempt in 1 to 40)
		if(!web.CanPass(mover, run_loc_floor_bottom_left))
			blocked = TRUE
	TEST_ASSERT(blocked, "предпосылка: паутина ни разу не задержала чужака за 40 попыток")
	TEST_ASSERT(mover.get_confusion() > 0, "застрявший в паутине не получил дезориентацию")

/// Броня hank на любом раннем выходе run_block отдаёт флаги блока, а не строку bullet_act.
/datum/unit_test/hank_armor_run_block_returns_flags/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/suit/armor/hank/suit = allocate(/obj/item/clothing/suit/armor/hank)
	owner.Paralyze(10 SECONDS)
	TEST_ASSERT(owner.incapacitated(FALSE, TRUE), "предпосылка: владелец не обездвижен")

	var/result = suit.run_block(owner, null, 10, "удар", ATTACK_TYPE_MELEE, 0, null, BODY_ZONE_CHEST, 0, list())
	TEST_ASSERT(isnum(result), "run_block вернул не флаги: [result]")

/// Moved переживает источник света, чей атом уже удалён, и выкидывает его из light_sources.
/datum/unit_test/moved_drops_light_source_without_atom/Run()
	var/obj/item/holder = allocate(/obj/item)
	var/obj/item/flashlight/lamp = allocate(/obj/item/flashlight)
	var/datum/light_source/source = new(lamp, holder)
	TEST_ASSERT(source in holder.light_sources, "предпосылка: источник не встал на держателя")

	source.source_atom = null
	holder.forceMove(get_step(run_loc_floor_bottom_left, EAST))

	TEST_ASSERT(!(source in holder.light_sources), "осиротевший источник остался в light_sources держателя")
	qdel(source)

/// Vore-панель отдаёт данные и для хозяина без клиента.
/datum/unit_test/vore_panel_data_without_client/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human)
	var/datum/vore_look/panel = new(host)
	var/list/data = panel.ui_data(host)
	TEST_ASSERT(islist(data), "ui_data не вернул список")
	var/list/prefs = data["prefs"]
	TEST_ASSERT(islist(prefs) && ("vore_sounds" in prefs), "в данных нет vore_sounds")
	qdel(panel)

/// Дым падающего пода при удалении снимается со списка зоны посадки.
/datum/unit_test/supplypod_smoke_unlinks_from_landing_zone/Run()
	var/obj/structure/closet/supplypod/pod = allocate(/obj/structure/closet/supplypod)
	var/obj/effect/pod_landingzone/zone = allocate(/obj/effect/pod_landingzone, run_loc_floor_bottom_left, pod)
	zone.setupSmoke(0)
	var/obj/effect/supplypod_smoke/first = zone.smoke_effects[1]
	TEST_ASSERT_NOTNULL(first, "предпосылка: дым не создан")

	qdel(first)

	TEST_ASSERT(!(first in zone.smoke_effects), "удалённый дым остался в списке зоны посадки")
