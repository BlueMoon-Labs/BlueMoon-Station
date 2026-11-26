/proc/heretic_lead_test_patina_unseen(datum/atom_hud/hud, mob/viewer)
	return !hud.hudusers[viewer]

/// Слух стрелка не целится сквозь стену: Пристрелку даёт выстрел в сторону еретика или стрелок у него на виду.
/datum/unit_test/heretic_lead_ear_zeroing_sight/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	var/mob/living/carbon/human/crew = heretic_lead_test_armed(heretic_lead_test_spot(4, 2))
	var/obj/item/gun/ballistic/automatic/pistol/gun = locate() in crew.held_items
	var/obj/structure/chair/screen = allocate(/obj/structure/chair, heretic_lead_test_spot(2, 2))
	screen.opacity = TRUE
	gun.process_fire(heretic_lead_test_spot(4, 6), crew)
	TEST_ASSERT_NULL(crew.has_status_effect(/datum/status_effect/heretic_lead_zeroed), "Выстрел в сторону за стеной Пристрелку не даёт.")
	gun.fire_delay = 0
	gun.last_fire = 0
	gun.process_fire(heretic_lead_test_spot(0, 2), crew)
	TEST_ASSERT_NOTNULL(crew.has_status_effect(/datum/status_effect/heretic_lead_zeroed), "Выстрел в еретика даёт Пристрелку и из-за укрытия.")
	crew.remove_status_effect(/datum/status_effect/heretic_lead_zeroed)
	screen.opacity = FALSE
	gun.fire_delay = 0
	gun.last_fire = 0
	gun.process_fire(heretic_lead_test_spot(4, 6), crew)
	TEST_ASSERT_NOTNULL(crew.has_status_effect(/datum/status_effect/heretic_lead_zeroed), "Стрелок на виду получает Пристрелку, куда бы ни стрелял.")
	var/datum/eldritch_knowledge/lead_ear/ear = heretic.get_knowledge(/datum/eldritch_knowledge/lead_ear)
	TEST_ASSERT(findtext(ear.passive_desc, "на виду") && !findtext(ear.passive_desc, "в 7 клетках от вас получает"), "Слух стрелка описывает условие видимости.")

/// Палец-ствол не находит невидимых, а поднятые турели и мехи берёт и ранит.
/datum/unit_test/heretic_lead_finger_unseen_and_machines/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	user.a_intent = INTENT_HARM
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/ghostly = heretic_lead_test_crew(heretic_lead_test_spot(2, 4))
	ghostly.invisibility = INVISIBILITY_OBSERVER
	TEST_ASSERT_NULL(heretic_lead_finger_target(get_turf(ghostly), user), "Невидимого на клетке Палец-ствол не находит.")
	ghostly.invisibility = 0
	TEST_ASSERT_EQUAL(heretic_lead_finger_target(get_turf(ghostly), user), ghostly, "Видимого на клетке находит.")
	var/obj/machinery/porta_turret/turret = allocate(/obj/machinery/porta_turret, heretic_lead_test_spot(4, 2))
	turret.on = FALSE
	TEST_ASSERT_NULL(heretic_lead_finger_target(get_turf(turret), user), "Закрытая турель спрятана под кожухом.")
	turret.invisibility = 0
	TEST_ASSERT_EQUAL(heretic_lead_finger_target(get_turf(turret), user), turret, "Поднятая турель - цель Пальца-ствола.")
	if(turret.cover)
		TEST_ASSERT_EQUAL(heretic_lead_finger_target(turret.cover, user), turret, "Клик по кожуху поднятой турели целит в турель.")
	var/obj/item/projectile/projectile = lead.finger_gun(user, turret)
	TEST_ASSERT_NOTNULL(projectile, "Палец-ствол стреляет в турель: [lead.lead_failure]")
	heretic_lead_test_fly(projectile)
	TEST_ASSERT(turret.obj_integrity < turret.max_integrity, "Дробина ранит турель.")
	var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, heretic_lead_test_spot(4, 0))
	mech.deflect_chance = 0
	TEST_ASSERT_EQUAL(heretic_lead_finger_target(get_turf(mech), user), mech, "Мех - цель Пальца-ствола.")
	projectile = lead.finger_gun(user, mech)
	TEST_ASSERT_NOTNULL(projectile, "Палец-ствол стреляет в мех: [lead.lead_failure]")
	heretic_lead_test_fly(projectile)
	TEST_ASSERT(mech.obj_integrity < mech.max_integrity, "Дробина ранит мех.")

/// Мгновение продлевает уже открытую Ловлю пули, а не молча её пропускает.
/datum/unit_test/heretic_lead_standoff_extends_catch/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/datum/status_effect/heretic_lead_catch/window = user.apply_status_effect(/datum/status_effect/heretic_lead_catch, lead, 0.5 SECONDS)
	TEST_ASSERT_NOTNULL(window, "Ручная Ловля открыта.")
	user.apply_status_effect(/datum/status_effect/heretic_lead_standoff, lead)
	TEST_ASSERT_EQUAL(user.has_status_effect(/datum/status_effect/heretic_lead_catch), window, "Окно Ловли то же самое.")
	TEST_ASSERT(window.duration >= world.time + HERETIC_LEAD_STANDOFF_TIME - 1, "Мгновение продлевает Ловлю на своё время.")
	user.remove_status_effect(/datum/status_effect/heretic_lead_standoff)
	user.remove_status_effect(/datum/status_effect/heretic_lead_catch)

/// Призыв: из своих вещей без отката, из пакета улик без фантома, жезл и святая вода срывают призыв издалека даром, с ЦК и из зон без телепортации - честный отказ; кнопка на горячей клавише.
/datum/unit_test/heretic_lead_recall_review/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/datum/eldritch_knowledge/lead_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lead_relic)
	var/obj/effect/proc_holder/spell/self/heretic_lead/recall/recall = recipe.recall_power
	var/list/spells = list()
	heretic.collect_combat_spells(spells)
	TEST_ASSERT((recall in spells) && (recall.type in heretic.ability_hotkey_types), "«Призвать Шестизарядник» на горячей клавише и в способностях кодекса.")
	var/obj/item/storage/box/box = allocate(/obj/item/storage/box, get_turf(user))
	user.dropItemToGround(revolver)
	revolver.forceMove(box)
	user.put_in_hands(box)
	recall.charge_counter = recall.charge_max
	TEST_ASSERT(recall.cast_check(FALSE, user), "Призыв из сумки доступен: [recall.heretic_failure_reason]")
	recall.choose_targets(user)
	TEST_ASSERT(user.is_holding(revolver), "Из сумки сразу в руку.")
	TEST_ASSERT_EQUAL(recall.charge_counter, recall.charge_max, "Призыв из своих вещей не уходит на перезарядку.")
	user.dropItemToGround(box)
	var/obj/item/evidencebag/bag = allocate(/obj/item/evidencebag, heretic_lead_test_spot(3, 3))
	bag.evidencebagEquip(revolver, user)
	TEST_ASSERT_EQUAL(revolver.loc, bag, "Револьвер в пакете улик.")
	lead.combat_resource = 2
	recall.choose_targets(user)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_holding), user, revolver), 3 SECONDS, "призыв из пакета улик"), "Револьвер вырвался из пакета улик.")
	TEST_ASSERT(bag.desc == initial(bag.desc) && bag.icon_state == initial(bag.icon_state) && bag.w_class == initial(bag.w_class), "Пустой пакет улик не показывает фантом револьвера.")
	GLOB.unit_test_chat_capture = list()
	var/mob/living/carbon/human/thief = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	user.dropItemToGround(revolver)
	thief.put_in_hands(revolver)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, get_turf(thief))
	thief.put_in_hands(rod)
	lead.combat_resource = 2
	recall.charge_counter = recall.charge_max
	TEST_ASSERT(recall.cast_check(FALSE, user), "Призыв из руки с жезлом начинается: [recall.heretic_failure_reason]")
	recall.choose_targets(user)
	TEST_ASSERT(thief.is_holding(revolver) && !lead.recall_timer, "Нулевой жезл держит револьвер.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 2, "Сорванный призыв не тратит Свинец.")
	TEST_ASSERT(heretic_lead_comfort_told(user, "нулевой жезл") && heretic_lead_comfort_told(thief, "нулевой жезл"), "Срыв жезлом видят обе стороны.")
	thief.dropItemToGround(rod)
	var/datum/reagents/holy = new(10)
	holy.add_reagent(/datum/reagent/water/holywater, 10)
	holy.reaction(revolver, TOUCH)
	qdel(holy)
	recall.charge_counter = recall.charge_max
	recall.choose_targets(user)
	TEST_ASSERT(thief.is_holding(revolver) && !lead.recall_timer, "Святая вода на металле срывает призыв.")
	TEST_ASSERT_EQUAL(lead.combat_resource, 2, "Срыв святой водой не тратит Свинец.")
	TEST_ASSERT(heretic_lead_comfort_told(user, "святая вода") && heretic_lead_comfort_told(thief, "святая вода"), "Срыв святой водой видят обе стороны.")
	GLOB.unit_test_chat_capture = null
	revolver.hallowed_until = 0
	thief.dropItemToGround(revolver)
	var/area/place_area = get_area(revolver)
	var/old_flags = place_area.area_flags
	place_area.area_flags |= NOTELEPORT
	var/reason = lead.recall_block_reason(user, revolver, recall.recall_cost)
	place_area.area_flags = old_flags
	TEST_ASSERT(findtext(reason, "телепортации"), "Из зоны без телепортации - честный отказ: [reason]")
	var/list/centcom_levels = SSmapping.levels_by_trait(ZTRAIT_CENTCOM)
	if(length(centcom_levels))
		var/turf/old_place = get_turf(revolver)
		revolver.forceMove(locate(round(world.maxx / 2), round(world.maxy / 2), centcom_levels[1]))
		reason = lead.recall_block_reason(user, revolver, recall.recall_cost)
		revolver.forceMove(old_place)
		TEST_ASSERT(findtext(reason, "Центральном"), "С ЦК - честный отказ: [reason]")

/// Взведённая Шестая камора не переживает смерть и смену тела.
/datum/unit_test/heretic_lead_sixth_reset/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	lead.combat_resource = lead.combat_resource_max
	TEST_ASSERT(heretic_lead_test_arm_sixth(revolver, user), "Шестая взведена.")
	lead.on_death(user)
	TEST_ASSERT(!lead.sixth_armed, "Смерть снимает Шестую камору с курка.")
	lead.sixth_armed = TRUE
	lead.clear_lead()
	TEST_ASSERT(!lead.sixth_armed, "Смена тела снимает Шестую камору с курка.")

/// Подаренная барабаном Шестая камора описана как подарок, а не как полный барабан.
/datum/unit_test/heretic_lead_free_sixth_text/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/lead_ear)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	lead.combat_resource = 1
	lead.free_last_round = TRUE
	var/state = lead.drum_state()
	TEST_ASSERT(findtext(state, "подарок барабана") && !findtext(state, "Барабан полон"), "Подсказка барабана называет подарок: [state]")
	GLOB.unit_test_chat_capture = list()
	TEST_ASSERT(revolver.select_chamber(user, HERETIC_LEAD_CAPACITY), "Подаренная Шестая взводится.")
	TEST_ASSERT(heretic_lead_comfort_told(user, "Свинец в барабане останется") && !heretic_lead_comfort_told(user, "за весь Свинец"), "Сообщение взвода не обещает траты всего Свинца.")
	GLOB.unit_test_chat_capture = null

/// Патина видна ставшим еретиком без нового входа, гаснет у потерявшего роль, видна мёртвому детективу и лежит на слое предмета.
/datum/unit_test/heretic_lead_patina_late_viewers/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/detective = heretic_lead_test_crew(heretic_lead_test_spot(3, 3), "Detective")
	detective.death()
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, heretic_lead_test_spot(1, 1))
	var/datum/component/heretic_lead_curse/curse = lead.place_curse(user, gun)
	var/datum/atom_hud/alternate_appearance/basic/hud = curse.patina_hud(gun)
	TEST_ASSERT_NOTNULL(hud, "Патина на ружье.")
	var/image/patina = hud.theImage
	TEST_ASSERT(patina.layer == gun.layer && patina.plane == gun.plane, "На полу патина лежит на слое самого ствола: [patina.layer]/[patina.plane] против [gun.layer]/[gun.plane].")
	TEST_ASSERT(patina in gun.update_on_z, "Патина переезжает на плоскость нового этажа вместе со стволом.")
	TEST_ASSERT(user.put_in_hands(gun), "Ствол в руке.")
	TEST_ASSERT(patina.layer == gun.layer && patina.plane == ABOVE_HUD_PLANE, "В руке патина поверх интерфейса, как сам ствол: [patina.layer]/[patina.plane].")
	user.dropItemToGround(gun, TRUE)
	TEST_ASSERT(isturf(gun.loc) && patina.layer == gun.layer && patina.plane == gun.plane, "Брошенный ствол снова под людьми: [patina.layer]/[patina.plane] против [gun.layer]/[gun.plane].")
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, heretic_lead_test_spot(1, 2))
	TEST_ASSERT(SEND_SIGNAL(bag, COMSIG_TRY_STORAGE_INSERT, gun, null, TRUE, TRUE), "Ствол в сумке.")
	TEST_ASSERT(patina.layer == ABOVE_HUD_LAYER && patina.plane == ABOVE_HUD_PLANE, "В открытой сумке патина поверх интерфейса: [patina.layer]/[patina.plane].")
	gun.forceMove(heretic_lead_test_spot(1, 1))
	TEST_ASSERT(patina.layer == gun.layer && patina.plane == gun.plane, "Вынутый из сумки ствол снова на полу: [patina.layer]/[patina.plane].")
	TEST_ASSERT(hud.hudusers[detective], "Мёртвый детектив увидит патину, когда его поднимут.")
	var/mob/living/carbon/human/convert = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	allocated += convert.mind
	TEST_ASSERT(!hud.hudusers[convert], "Член экипажа патину не видит.")
	convert.mind.add_antag_datum(/datum/antagonist/heretic)
	TEST_ASSERT(hud.hudusers[convert], "Ставший еретиком видит патину сразу.")
	convert.mind.remove_antag_datum(/datum/antagonist/heretic)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_patina_unseen), hud, convert), 1 SECONDS, "патина у бывшего еретика"), "Потерявший роль патину больше не видит.")
	qdel(curse)
	TEST_ASSERT(!LAZYLEN(gun.update_on_z), "Снятый заговор не оставляет патину в списке этажа ствола.")
