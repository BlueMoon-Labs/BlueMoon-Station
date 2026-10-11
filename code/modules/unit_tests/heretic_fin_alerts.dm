#define HERETIC_FIN_ALERT_SHEET 'modular_bluemoon/icons/obj/heretic_alerts.dmi'

/// Новые и перенесённые алерты берут медальон из листа алертов, а их стейты в листе есть.
/datum/unit_test/heretic_fin_alert_sheet/Run()
	var/list/states = icon_states(HERETIC_FIN_ALERT_SHEET)
	var/list/alert_types = list(
		/atom/movable/screen/alert/status_effect/heretic_ash_shroud,
		/atom/movable/screen/alert/status_effect/heretic_flesh_latch,
		/atom/movable/screen/alert/status_effect/heretic_void_prison,
		/atom/movable/screen/alert/status_effect/heretic_blood_seal,
		/atom/movable/screen/alert/status_effect/heretic_blood_tether,
		/atom/movable/screen/alert/status_effect/heretic_spirit,
		/atom/movable/screen/alert/status_effect/heretic_cloudstruck,
		/atom/movable/screen/alert/status_effect/heretic_amok,
		/atom/movable/screen/alert/status_effect/heretic_corrosion_curse,
		/atom/movable/screen/alert/status_effect/heretic_corrosion_curse/lesser,
		/atom/movable/screen/alert/restrained/handcuffed/heretic_lock,
		/atom/movable/screen/alert/restrained/legcuffed/heretic_lock,
		/atom/movable/screen/alert/status_effect/heretic_dance_mired,
		/atom/movable/screen/alert/status_effect/heretic_blade_opening,
		/atom/movable/screen/alert/status_effect/heretic_blade_dance,
		/atom/movable/screen/alert/status_effect/heretic_cosmic_tether,
		/atom/movable/screen/alert/status_effect/heretic_cosmic_orbit,
		/atom/movable/screen/alert/status_effect/heretic_glass_fracture,
		/atom/movable/screen/alert/status_effect/heretic_wax_shell,
		/atom/movable/screen/alert/status_effect/heretic_wax_prick,
		/atom/movable/screen/alert/status_effect/heretic_wax_effigy,
		/atom/movable/screen/alert/status_effect/heretic_moon_parade,
	)
	for(var/atom/movable/screen/alert/alert_type as anything in alert_types)
		TEST_ASSERT_EQUAL(initial(alert_type.icon), HERETIC_FIN_ALERT_SHEET, "[alert_type] берёт значок из листа алертов.")
		TEST_ASSERT(initial(alert_type.icon_state) in states, "[alert_type]: стейта [initial(alert_type.icon_state)] нет в листе.")
	for(var/stage in 1 to HERETIC_GLASS_SHATTER_STACKS - 1)
		TEST_ASSERT("glass_fracture_[stage]" in states, "Стадия трещин [stage] есть в листе.")
	TEST_ASSERT(!("dance_bolero" in states), "Мёртвый стейт Болеро удалён.")

/// Статусы, которые раньше молчали или показывали tg-заглушку, выдают свой медальон и снимают его вместе с собой.
/datum/unit_test/heretic_fin_alert_statuses/Run()
	var/list/expected = list(
		/datum/status_effect/cloudstruck = /atom/movable/screen/alert/status_effect/heretic_cloudstruck,
		/datum/status_effect/amok = /atom/movable/screen/alert/status_effect/heretic_amok,
		/datum/status_effect/corrosion_curse = /atom/movable/screen/alert/status_effect/heretic_corrosion_curse,
		/datum/status_effect/corrosion_curse/lesser = /atom/movable/screen/alert/status_effect/heretic_corrosion_curse/lesser,
		/datum/status_effect/heretic_dance_dread = /atom/movable/screen/alert/status_effect/heretic_dance_mired/dread,
		/datum/status_effect/heretic_dance_dirge = /atom/movable/screen/alert/status_effect/heretic_dance_mired/dirge,
		/datum/status_effect/heretic_dance_stumble = /atom/movable/screen/alert/status_effect/heretic_dance_mired/stumble,
		/datum/status_effect/heretic_blade_opening = /atom/movable/screen/alert/status_effect/heretic_blade_opening,
		/datum/status_effect/heretic_blade_dance = /atom/movable/screen/alert/status_effect/heretic_blade_dance,
		/datum/status_effect/cosmic_tether = /atom/movable/screen/alert/status_effect/heretic_cosmic_tether,
		/datum/status_effect/heretic_wax/shell = /atom/movable/screen/alert/status_effect/heretic_wax_shell,
		/datum/status_effect/heretic_wax_prick/dizzy = /atom/movable/screen/alert/status_effect/heretic_wax_prick/dizzy,
		/datum/status_effect/heretic_wax_prick/hush = /atom/movable/screen/alert/status_effect/heretic_wax_prick/hush,
		/datum/status_effect/heretic_moon_parade = /atom/movable/screen/alert/status_effect/heretic_moon_parade,
	)
	for(var/datum/status_effect/status_type as anything in expected)
		TEST_ASSERT_EQUAL(initial(status_type.alert_type), expected[status_type], "[status_type] выдаёт свой алерт.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	for(var/status_type in list(/datum/status_effect/cloudstruck, /datum/status_effect/amok, /datum/status_effect/corrosion_curse/lesser, /datum/status_effect/heretic_dance_dirge, /datum/status_effect/cosmic_tether, /datum/status_effect/heretic_wax_prick/hush, /datum/status_effect/heretic_blade_opening))
		var/datum/status_effect/effect = victim.apply_status_effect(status_type)
		TEST_ASSERT_NOTNULL(effect, "[status_type] накладывается.")
		var/atom/movable/screen/alert/shown = victim.alerts[effect.id]
		TEST_ASSERT_EQUAL(shown?.type, expected[status_type], "[status_type] показывает свой алерт.")
		TEST_ASSERT_EQUAL(shown?.icon, HERETIC_FIN_ALERT_SHEET, "Алерт [status_type] из листа алертов.")
		var/alert_id = effect.id
		qdel(effect)
		TEST_ASSERT_NULL(victim.alerts[alert_id], "Алерт [status_type] уходит вместе со статусом.")

/// Ни один статус еретика не показывает tg-заглушку «Curse of Mundanity»; промежуточные пути без своего id не в счёт.
/datum/unit_test/heretic_fin_no_default_alert/Run()
	var/datum/status_effect/root = /datum/status_effect
	var/list/statuses = list(/datum/status_effect/cloudstruck, /datum/status_effect/amok) + typesof(/datum/status_effect/corrosion_curse)
	for(var/datum/status_effect/status_type as anything in subtypesof(/datum/status_effect))
		if(findtext("[status_type]", "heretic") && initial(status_type.id) != initial(root.id))
			statuses += status_type
	for(var/datum/status_effect/status_type as anything in statuses)
		TEST_ASSERT_NOTEQUAL(initial(status_type.alert_type), /atom/movable/screen/alert/status_effect, "[status_type] показывает tg-заглушку вместо своего алерта.")

/// Отсчёт просвета в защите виден на алерте жертвы.
/datum/unit_test/heretic_fin_blade_opening_countdown/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/status_effect/heretic_blade_opening/opening = victim.apply_status_effect(/datum/status_effect/heretic_blade_opening, null, TRUE)
	TEST_ASSERT_NOTNULL(opening?.linked_alert, "Финт показывает просвет алертом.")
	TEST_ASSERT(findtext(opening.linked_alert.maptext, "4с"), "Отсчёт финта начинается с 4 секунд: [opening.linked_alert.maptext]")
	TEST_ASSERT(findtext(opening.linked_alert.desc, "Финт"), "Описание финта говорит о финте.")
	qdel(opening)

/// Стадии трещин Стекла различаются значком: вторая трещина меняет медальон.
/datum/unit_test/heretic_fin_glass_fracture_stages/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	var/datum/status_effect/heretic_glass_fracture/fracture = victim.apply_status_effect(/datum/status_effect/heretic_glass_fracture, glass)
	TEST_ASSERT_EQUAL(fracture?.linked_alert?.icon_state, "glass_fracture_1", "Первая трещина - первая стадия.")
	fracture.add_crack()
	TEST_ASSERT_EQUAL(fracture.linked_alert?.icon_state, "glass_fracture_2", "Вторая трещина меняет значок.")
	TEST_ASSERT(findtext(fracture.linked_alert.name, "2"), "Имя алерта называет число трещин: [fracture.linked_alert.name]")
	qdel(fracture)

/// Призрачные оковы Замка показывают медальон вместо tg «Handcuffed»/«Legcuffed», и перерисовка тела его не сбрасывает.
/datum/unit_test/heretic_fin_lock_restraint_alerts/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_LOCK
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lock_shackles)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/turf/origin = get_turf(heretic.owner.current)
	var/mob/living/carbon/human/quarry = allocate_hunt_victim(heretic, locate(origin.x + 2, origin.y + 2, origin.z))
	var/datum/status_effect/heretic_lock_shackles/hands = quarry.apply_status_effect(/datum/status_effect/heretic_lock_shackles, knowledge)
	TEST_ASSERT_NOTNULL(hands, "Цель охоты скована.")
	var/atom/movable/screen/alert/cuffs_alert = quarry.alerts["handcuffed"]
	TEST_ASSERT_EQUAL(cuffs_alert?.type, /atom/movable/screen/alert/restrained/handcuffed/heretic_lock, "Наручники Замка показывают свой алерт.")
	TEST_ASSERT_EQUAL(cuffs_alert?.icon, HERETIC_FIN_ALERT_SHEET, "Алерт наручников - медальон из листа алертов.")
	qdel(hands)
	TEST_ASSERT_NULL(quarry.alerts["handcuffed"], "Снятые наручники уносят алерт.")
	var/mob/living/carbon/human/passerby = allocate(/mob/living/carbon/human, locate(origin.x + 2, origin.y, origin.z))
	var/datum/status_effect/heretic_lock_shackles/legs = passerby.apply_status_effect(/datum/status_effect/heretic_lock_shackles, knowledge)
	TEST_ASSERT_NOTNULL(legs, "Прохожему спутаны ноги.")
	passerby.regenerate_icons()
	var/atom/movable/screen/alert/fetters_alert = passerby.alerts["legcuffed"]
	TEST_ASSERT_EQUAL(fetters_alert?.type, /atom/movable/screen/alert/restrained/legcuffed/heretic_lock, "Путы Замка держат свой алерт и после перерисовки.")
	qdel(legs)
	TEST_ASSERT_NULL(passerby.alerts["legcuffed"], "Снятые путы уносят алерт.")

#undef HERETIC_FIN_ALERT_SHEET
