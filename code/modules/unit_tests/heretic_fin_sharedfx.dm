/// Взрыв метки каждого старого пути создаёт свой стейт, не вспышку хватки того же пути.
/datum/unit_test/heretic_fin_mark_bursts/Run()
	var/list/feedback_states = icon_states('modular_bluemoon/icons/obj/heretic_feedback.dmi')
	var/list/marks = list(
		/datum/status_effect/eldritch/ash = /datum/eldritch_knowledge/base_ash,
		/datum/status_effect/eldritch/rust = /datum/eldritch_knowledge/base_rust,
		/datum/status_effect/eldritch/flesh = /datum/eldritch_knowledge/base_flesh,
		/datum/status_effect/eldritch/void = /datum/eldritch_knowledge/base_void,
	)
	var/list/burst_states = list()
	for(var/mark_type in marks)
		var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		var/datum/status_effect/eldritch/mark = victim.apply_status_effect(mark_type)
		TEST_ASSERT(mark, "[mark_type]: живая цель получает метку.")
		mark.on_effect()
		var/obj/effect/temp_visual/heretic_mark_burst/burst = locate() in victim.loc
		TEST_ASSERT_NOTNULL(burst, "[mark_type]: взрыв метки рисует свою вспышку.")
		TEST_ASSERT(burst.icon_state in feedback_states, "[mark_type]: стейт взрыва [burst.icon_state] есть в листе.")
		var/datum/eldritch_knowledge/knowledge = marks[mark_type]
		var/obj/effect/grasp_visual = initial(knowledge.grasp_visual)
		TEST_ASSERT_NOTEQUAL(burst.icon_state, initial(grasp_visual.icon_state), "[mark_type]: взрыв метки не повторяет вспышку хватки.")
		TEST_ASSERT(!(burst.icon_state in burst_states), "[mark_type]: взрыв не делит стейт с меткой другого пути.")
		burst_states += burst.icon_state
		qdel(burst)
		qdel(victim)

/// Метка Пустоты лопается своим ледяным хлопком, а не щелчком отражения бури.
/datum/unit_test/heretic_fin_void_mark_sound/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/status_effect/eldritch/void/mark = victim.apply_status_effect(/datum/status_effect/eldritch/void)
	TEST_ASSERT(mark, "Живая цель получает метку Пустоты.")
	TEST_ASSERT_EQUAL(length(GLOB.heretic_void_mark_burst_sounds), 2, "У хлопка два варианта.")
	mark.detonation_visual = null
	mark.on_effect()
	TEST_ASSERT(mark.detonation_sound in GLOB.heretic_void_mark_burst_sounds, "Взрыв звучит из набора ледяного хлопка.")
	TEST_ASSERT_NOTEQUAL("[mark.detonation_sound]", "[file("modular_bluemoon/sound/heretic/void_deflect3.ogg")]", "Взрыв не звучит отражением бури.")

/// Метки Плоти и Ржавчины рисуются поверх тела, знак Ржавчины опущен с лица на грудь.
/datum/unit_test/heretic_fin_marks_over_body/Run()
	for(var/mark_type in list(/datum/status_effect/eldritch/flesh, /datum/status_effect/eldritch/rust))
		var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		var/datum/status_effect/eldritch/mark = victim.apply_status_effect(mark_type)
		TEST_ASSERT(mark, "[mark_type]: живая цель получает метку.")
		TEST_ASSERT(mark.marked_underlay.layer > MOB_LAYER, "[mark_type]: тело не закрывает метку.")
		TEST_ASSERT(mark.marked_underlay.icon_state in icon_states(mark.marked_underlay.icon), "[mark_type]: стейт метки есть в листе.")
		if(mark_type == /datum/status_effect/eldritch/rust)
			TEST_ASSERT(mark.marked_underlay.pixel_y < 0, "Знак Ржавчины опущен ниже лица.")
		victim.remove_status_effect(mark_type)

/// У захвата каждого пути свои частицы у ног; отпущенный захват перестаёт их порождать, удалённый уносит.
/datum/unit_test/heretic_fin_capture_accent/Run()
	var/list/seen = list()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		var/obj/effect/abstract/heretic_capture_mark/front/mark = new(null, victim, path_id)
		TEST_ASSERT_NOTNULL(mark.accent, "[path_id]: у захвата есть акцент пути.")
		TEST_ASSERT(istype(mark.accent.particles, path.vfx_particles), "[path_id]: акцент - частицы своего пути.")
		TEST_ASSERT(mark.accent in mark.vis_contents, "[path_id]: частицы висят на щупальцах.")
		TEST_ASSERT(!seen[path.vfx_particles], "[path_id] и [seen[path.vfx_particles]]: захваты различаются акцентом.")
		seen[path.vfx_particles] = path_id
		var/obj/effect/abstract/heretic_particle_holder/accent = mark.accent
		mark.fade_out()
		TEST_ASSERT_EQUAL(accent.particles.spawning, 0, "[path_id]: отпущенный захват не порождает новых частиц.")
		qdel(mark)
		TEST_ASSERT(QDELETED(accent), "[path_id]: частицы удаляются вместе с захватом.")
		qdel(victim)
	TEST_ASSERT_EQUAL(length(seen), length(GLOB.heretic_paths), "Акцент есть у захвата каждого пути.")

/// Хватка Пустоты - ледяная звезда в родном пикселе, побег клинком - шов изнанки с осколками, а не дым Пепла.
/datum/unit_test/heretic_fin_oldpath_visuals/Run()
	var/list/feedback_states = icon_states('modular_bluemoon/icons/obj/heretic_feedback.dmi')
	var/obj/effect/temp_visual/heretic_oldpath/void/grasp = allocate(/obj/effect/temp_visual/heretic_oldpath/void, run_loc_floor_bottom_left)
	TEST_ASSERT_NOTEQUAL(grasp.icon_state, "ring_leader_effect", "Хватка Пустоты не голое кольцо.")
	TEST_ASSERT(grasp.icon_state in feedback_states, "Стейт хватки Пустоты есть в листе.")
	TEST_ASSERT(grasp.transform ~= matrix(), "Хватка Пустоты не растягивается.")
	var/obj/effect/temp_visual/eldritch_smoke/shatter = /obj/effect/temp_visual/eldritch_smoke
	var/obj/effect/temp_visual/heretic_oldpath/ash/trail/ash_smoke = /obj/effect/temp_visual/heretic_oldpath/ash/trail
	TEST_ASSERT(initial(shatter.icon_state) in feedback_states, "Стейт побега клинком есть в листе.")
	TEST_ASSERT_NOTEQUAL(initial(shatter.icon_state), initial(ash_smoke.icon_state), "Побег клинком не делит дым следа Пепла.")
	TEST_ASSERT(!("emark1" in feedback_states), "Мёртвый стейт emark1 удалён.")

/// След перехода Стекла зациклен и лежит на стекле направленного окна, у полного окна - в центре.
/datum/unit_test/heretic_fin_glass_trace/Run()
	var/list/expected = list("[NORTH]" = list(0, 1), "[SOUTH]" = list(0, -1), "[EAST]" = list(1, 0), "[WEST]" = list(-1, 0))
	for(var/direction in GLOB.cardinals)
		var/obj/structure/window/pane = allocate(/obj/structure/window, run_loc_floor_bottom_left, direction)
		pane.AddComponent(/datum/component/heretic_glass_passage_trace)
		var/found = FALSE
		for(var/mutable_appearance/overlay as anything in pane.overlays)
			if(overlay.icon_state != "glass_pane_trace")
				continue
			found = TRUE
			var/list/sign = expected["[direction]"]
			TEST_ASSERT_EQUAL(SIGN(overlay.pixel_x), sign[1], "Окно [dir2text(direction)]: трещина у своей грани по горизонтали.")
			TEST_ASSERT_EQUAL(SIGN(overlay.pixel_y), sign[2], "Окно [dir2text(direction)]: трещина у своей грани по вертикали.")
		TEST_ASSERT(found, "Окно [dir2text(direction)]: на стекле есть след перехода.")
		qdel(pane)
	var/obj/structure/window/fulltile/full = allocate(/obj/structure/window/fulltile, run_loc_floor_bottom_left)
	full.AddComponent(/datum/component/heretic_glass_passage_trace)
	var/full_found = FALSE
	for(var/mutable_appearance/overlay as anything in full.overlays)
		if(overlay.icon_state == "glass_pane_trace")
			full_found = TRUE
			TEST_ASSERT(!overlay.pixel_x && !overlay.pixel_y, "У полного окна трещина в центре.")
	TEST_ASSERT(full_found, "На полном окне есть след перехода.")
	TEST_ASSERT("glass_pane_trace" in icon_states('modular_bluemoon/icons/obj/heretic_feedback.dmi'), "Стейт следа есть в листе.")
