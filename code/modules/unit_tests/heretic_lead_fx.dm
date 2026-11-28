/proc/heretic_lead_test_beam_from(turf/start, state)
	for(var/obj/effect/ebeam/segment in start)
		if(segment.owner?.icon_state == state)
			return segment.owner
	return null

/// Патину видят только детектив, капеллан и еретики: им ствол - матовый свинец с кантом, остальным - обычное оружие; пришедший позже видит её с осмотра; последняя осечка и снятый заговор её уносят.
/datum/unit_test/heretic_lead_patina_filters/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/detective = heretic_lead_test_crew(heretic_lead_test_spot(3, 3), "Detective")
	var/mob/living/carbon/human/assistant = heretic_lead_test_crew(heretic_lead_test_spot(3, 4), "Assistant")
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol, heretic_lead_test_spot(1, 1))
	var/datum/component/heretic_lead_curse/curse = gun.AddComponent(/datum/component/heretic_lead_curse, lead, 1)
	TEST_ASSERT(!length(gun.filters), "Посторонним заговорённый ствол кажется обычным.")
	var/datum/atom_hud/alternate_appearance/basic/patina = curse.patina_hud(gun)
	TEST_ASSERT(patina?.theImage?.override && length(patina.theImage.filters) == 2, "Патина - картинка поверх ствола: матовый свинец и кант.")
	TEST_ASSERT(patina.hudusers[detective] && patina.hudusers[heretic.owner.current], "Патину видят детектив и еретик.")
	TEST_ASSERT(!patina.hudusers[assistant], "Ассистент патины не видит.")
	gun.update_icon()
	TEST_ASSERT_EQUAL(patina.theImage.icon_state, gun.icon_state, "Патина повторяет облик ствола.")
	curse.spend()
	TEST_ASSERT_NULL(curse.patina_hud(gun), "Последняя осечка снимает патину.")
	var/obj/item/ammo_box/magazine/m10mm/magazine = allocate(/obj/item/ammo_box/magazine/m10mm, heretic_lead_test_spot(2, 1))
	var/datum/component/heretic_lead_curse/magazine_curse = magazine.AddComponent(/datum/component/heretic_lead_curse, lead)
	var/mob/living/carbon/human/chaplain = heretic_lead_test_crew(heretic_lead_test_spot(2, 2), "Chaplain")
	patina = magazine_curse.patina_hud(magazine)
	TEST_ASSERT(patina && !patina.hudusers[chaplain], "Капеллан, пришедший после заговора, патину сразу не видит.")
	magazine.examine(chaplain)
	TEST_ASSERT(patina.hudusers[chaplain], "Осмотр показывает патину и пришедшему позже капеллану.")
	magazine.examine(assistant)
	TEST_ASSERT(!patina.hudusers[assistant], "Осмотр ассистенту патину не открывает.")
	qdel(magazine_curse)
	TEST_ASSERT(QDELETED(patina) && !LAZYACCESS(magazine.alternate_appearances, "heretic_lead_patina"), "Снятый заговор уносит кант.")

/// Последний патрон: к цели тянется линия огня, она гаснет вместе с прицелом; остановившаяся пуля оставляет сквозной след от ствола.
/datum/unit_test/heretic_lead_last_round_line/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/heretic_path_relic/lead_revolver/revolver = heretic_lead_test_revolver(heretic, user)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	revolver.start_last_round(victim, user)
	TEST_ASSERT(revolver.aim_beam?.target == victim && revolver.aim_beam.icon_state == "lead_aim_line", "От ствола к цели тянется линия огня.")
	var/datum/beam/line = revolver.aim_beam
	revolver.clear_aim()
	TEST_ASSERT(QDELETED(line) && !revolver.aim_beam, "Линия гаснет вместе с прицелом.")
	var/turf/start = heretic_lead_test_spot(0, 3)
	var/obj/item/projectile/bullet/heretic_lead/last_round/bullet = new(start)
	bullet.starting = start
	bullet.forceMove(heretic_lead_test_spot(4, 3))
	qdel(bullet)
	TEST_ASSERT_NOTNULL(heretic_lead_test_beam_from(start, "lead_last_tracer"), "Пуля оставляет след от ствола до места остановки.")

/// Палец-ствол оставляет след от стрелка до удара, гильза у удара своя, заметная на полу.
/datum/unit_test/heretic_lead_finger_trace/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HARM
	fist.afterattack(victim, user, FALSE)
	var/obj/item/projectile/bullet/heretic_lead_pellet/pellet = locate() in range(5, user)
	TEST_ASSERT_NOTNULL(pellet, "Палец-ствол выпускает дробину.")
	heretic_lead_test_fly(pellet)
	TEST_ASSERT_NOTNULL(heretic_lead_test_beam_from(get_turf(user), "lead_finger_tracer"), "От руки к удару тянется след дробины.")
	var/obj/item/ammo_casing/heretic_lead/casing = locate() in range(1, victim)
	TEST_ASSERT(casing?.icon == HERETIC_LEAD_FX_ICON && casing.icon_state == "lead_casing", "Гильза у удара своя, а не мелкая общая.")

/// Переплавка светится расплавом, искры летят от металла к еретику.
/datum/unit_test/heretic_lead_smelt_glow/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(2, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	lead.combat_resource = 0
	var/obj/item/stack/sheet/metal/sheets = allocate(/obj/item/stack/sheet/metal, heretic_lead_test_spot(4, 2), HERETIC_LEAD_SMELT_SHEETS)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HELP
	user.forceMove(heretic_lead_test_spot(3, 2))
	INVOKE_ASYNC(fist, TYPE_PROC_REF(/obj/item, afterattack), sheets, user, TRUE)
	var/turf/place = get_turf(sheets)
	var/obj/effect/temp_visual/heretic_lead/smelt/glow = locate() in place
	TEST_ASSERT(glow?.icon_state == "lead_smelt", "Металл светится расплавом, а не дымит.")
	var/obj/effect/temp_visual/heretic_vfx/burst/sparks = locate() in place
	TEST_ASSERT(istype(sparks?.particles, /particles/heretic_ascension/lead_smelt), "Искры Переплавки летят от металла.")
	var/particles/flow = sparks.particles
	TEST_ASSERT(flow.velocity[1] < 0, "Искры летят к еретику.")
	TEST_ASSERT(wait_for_var(lead, NAMEOF(lead, combat_resource), 1, HERETIC_LEAD_SMELT_TIME + 2 SECONDS), "Переплавка завершается.")

/// Вознесение Свинца: эхо нимба не раздувается и уходит за спину, а частицы явления - гильзы и искры без дымных комьев.
/datum/unit_test/heretic_lead_ascension_echo/Run()
	var/list/fixture = heretic_lead_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/lead_final/finale = fixture["finale"]
	finale.simulated = TRUE
	finale.announce_ascension(user)
	var/obj/effect/temp_visual/heretic_ascension_echo/echo = locate() in get_turf(user)
	TEST_ASSERT_NOTNULL(echo, "Вознесение оставляет эхо нимба.")
	TEST_ASSERT_EQUAL(echo.layer, BELOW_MOB_LAYER, "Эхо барабана за спиной, тело видно.")
	var/matrix/shape = echo.transform
	TEST_ASSERT(shape.a == 2 && shape.e == 2, "Эхо крупное, вдвое ровно, без мыла.")
	var/particles/heretic_ascension/lead/motes = new
	var/list/states = motes.icon_state
	TEST_ASSERT(!("lead_p_smoke" in states), "Явление не закрывает тело дымными комьями.")
	TEST_ASSERT(("lead_p_casing" in states) && ("lead_p_spark" in states), "Частицы явления - гильзы и искры.")

/// Новые стейты эффектов нарисованы, призрачный ствол непрозрачен и висит над телом.
/datum/unit_test/heretic_lead_fx_states/Run()
	var/list/effects = icon_states(HERETIC_LEAD_FX_ICON)
	for(var/state in list("lead_last_tracer", "lead_finger_tracer", "lead_smelt", "lead_casing", "lead_laser_dot", "lead_rain_marker"))
		TEST_ASSERT(state in effects, "Эффект [state] нарисован.")
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/obj/structure/heretic_lead_phantom_gun/phantom = allocate(/obj/structure/heretic_lead_phantom_gun, heretic_lead_test_spot(2, 2), lead)
	TEST_ASSERT_EQUAL(phantom.alpha, 255, "Призрачный ствол не сливается с полом.")
	TEST_ASSERT(phantom.pixel_y >= 8, "Ствол висит над телом павшего.")
