/datum/eldritch_knowledge/capture_fx_probe
	name = "Проверочная отдача"
	route = PATH_GLASS

/// Все стейты, которые рисует отдача захвата и изнанки, есть в своих листах, и у каждого пути есть звуки для неё.
/datum/unit_test/heretic_capture_fx_states/Run()
	var/list/states = icon_states('modular_bluemoon/icons/obj/heretic_capture.dmi')
	for(var/state in list("hold_back", "hold_front", "hold_back_glow", "hold_front_glow"))
		TEST_ASSERT(state in states, "Стейт [state] есть в heretic_capture.dmi.")
	var/list/rift_states = icon_states('modular_bluemoon/icons/obj/heretic_pocket_rift.dmi')
	for(var/state in list("rift", "rift_open", "rift_close", "rift_inner", "rift_inner_open"))
		TEST_ASSERT(state in rift_states, "Стейт [state] есть в heretic_pocket_rift.dmi.")
		TEST_ASSERT("[state]_glow" in rift_states, "У стейта [state] есть маска кромки.")
	var/list/large_states = icon_states('modular_bluemoon/icons/obj/heretic_capture_large.dmi')
	for(var/state in list("door_grip", "blade_refusal"))
		TEST_ASSERT(state in large_states, "Стейт [state] есть в heretic_capture_large.dmi.")
		TEST_ASSERT("[state]_glow" in large_states, "У стейта [state] есть маска свечения.")
	for(var/path_id in GLOB.heretic_paths)
		for(var/key in list("deposit", "warning", "hit", "escape"))
			TEST_ASSERT(isfile(heretic_fx_theme_sound(path_id, key)), "У пути [path_id] есть звук [key] для отдачи.")
		TEST_ASSERT(ispath(heretic_fx_particles(path_id), /particles/heretic_ascension), "У пути [path_id] есть свои частицы.")

/// У каждого захвата пути свой звук защёлкивания, сон-захват звучит своим захватом, у изнанки, прижатия и отказа свои звуки.
/datum/unit_test/heretic_capture_fx_sounds/Run()
	var/list/latched = list()
	for(var/capture_id in list("sand", "cosmic", "lock", "tide", "spirit_hold", "glass", HERETIC_MOON_CAPTURE, "echo", "blood", "blade_throat", "wax"))
		var/latch = heretic_fx_latch_sound(capture_id)
		TEST_ASSERT(isfile(latch) && fexists("[latch]"), "У захвата [capture_id] есть свой звук защёлкивания.")
		TEST_ASSERT(!latched["[latch]"], "Захваты [capture_id] и [latched["[latch]"]] звучат одним файлом.")
		latched["[latch]"] = capture_id
	TEST_ASSERT_NULL(heretic_fx_latch_sound("probe"), "Чужая метка своего звука не даёт.")
	TEST_ASSERT_NULL(heretic_fx_latch_sound(HERETIC_POCKET_CAPTURE), "Удержание изнанки звучит её разрывом, а не защёлкиванием.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/capture_fx_probe/probe = allocate(/datum/eldritch_knowledge/capture_fx_probe)
	victim.Sleeping(10 SECONDS)
	var/datum/status_effect/heretic_capture_knockout/knockout = heretic_capture_knock_out(victim, probe, "wax", 10 SECONDS)
	TEST_ASSERT_EQUAL(heretic_fx_latch_sound(REF(knockout)), heretic_fx_latch_sound("wax"), "Сон по кукле звучит плавящимся воском.")
	qdel(knockout)
	for(var/name in list("pocket_open", "pocket_pull", "pocket_enter", "pocket_exit", "pocket_tear", "pocket_seal", "pocket_collapse", "heart_grip", "blade_refusal"))
		TEST_ASSERT(fexists("modular_bluemoon/sound/heretic/capture/[name].ogg"), "Звук [name] лежит рядом с остальными.")

/// Захват рисует у ног цели одну метку в чернилах пути: второй захват её не дублирует, снятие последнего гасит её.
/datum/unit_test/heretic_capture_mark/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	heretic_capture_hold(victim, "blade_oath")
	var/obj/effect/abstract/heretic_capture_mark/front/mark = victim.heretic_capture_mark
	TEST_ASSERT_NOTNULL(mark, "Захват рисует метку у ног цели.")
	TEST_ASSERT(mark in victim.vis_contents, "Щупальца висят на самой цели.")
	TEST_ASSERT(mark.back in victim.vis_contents, "Лужа под целью висит на ней же.")
	TEST_ASSERT(mark.back.vis_flags & VIS_UNDERLAY, "Лужа рисуется под целью.")
	TEST_ASSERT(mark.appearance_flags & RESET_TRANSFORM, "Метка не ложится вместе с целью.")
	TEST_ASSERT_EQUAL(mark.path_id, PATH_BLADE, "Метка знает путь захвата.")
	TEST_ASSERT_EQUAL(lowertext(mark.color), lowertext(heretic_path_ink(PATH_BLADE)), "Метка окрашена чернилами Клинка.")
	heretic_capture_hold(victim, "probe_second")
	TEST_ASSERT_EQUAL(victim.heretic_capture_mark, mark, "Второй захват не рисует вторую метку.")
	heretic_capture_unhold(victim, "blade_oath")
	TEST_ASSERT_EQUAL(victim.heretic_capture_mark, mark, "Пока держит второй захват, метка остаётся.")
	TEST_ASSERT(!mark.fading, "Метка не гаснет, пока цель держат.")
	heretic_capture_unhold(victim, "probe_second")
	TEST_ASSERT_NULL(victim.heretic_capture_mark, "Снятый захват отпускает метку.")
	TEST_ASSERT(mark.fading, "Отпущенная метка гаснет.")
	var/obj/effect/abstract/heretic_capture_mark/back = mark.back
	qdel(mark)
	TEST_ASSERT(!(mark in victim.vis_contents) && !(back in victim.vis_contents), "Угасшая метка уходит с цели целиком.")
	TEST_ASSERT(QDELETED(back), "Лужа удаляется вместе со щупальцами.")

/// Удалённая цель уносит обе части метки.
/datum/unit_test/heretic_capture_mark_host_deleted/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	heretic_capture_hold(victim, "sand")
	var/obj/effect/abstract/heretic_capture_mark/front/mark = victim.heretic_capture_mark
	var/obj/effect/abstract/heretic_capture_mark/back = mark.back
	qdel(victim)
	TEST_ASSERT(QDELETED(mark) && QDELETED(back), "Метка не переживает цель.")

/// Путь метки берётся из метки захвата, из знания усыпившего захвата и из изнанки; без них остаётся цвет сердца.
/datum/unit_test/heretic_capture_fx_path/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(heretic_fx_capture_path(victim, "spirit_hold"), PATH_SPIRIT, "Метка «spirit_hold» - захват Духа.")
	TEST_ASSERT_EQUAL(heretic_fx_capture_path(victim, "tide"), PATH_TIDE, "Метка «tide» - захват Пучины.")
	TEST_ASSERT_NULL(heretic_fx_capture_path(victim, "probe"), "Чужая метка пути не даёт.")
	var/datum/eldritch_knowledge/capture_fx_probe/probe = allocate(/datum/eldritch_knowledge/capture_fx_probe)
	probe.route = PATH_ECHO
	victim.Sleeping(10 SECONDS)
	var/datum/status_effect/heretic_capture_knockout/knockout = heretic_capture_knock_out(victim, probe, "probe", 10 SECONDS)
	TEST_ASSERT_EQUAL(heretic_fx_capture_path(victim, REF(knockout)), PATH_ECHO, "Сон-захват берёт путь своего знания.")
	TEST_ASSERT_EQUAL(victim.heretic_capture_mark?.path_id, PATH_ECHO, "Сон-захват красит метку чернилами своего пути.")
	qdel(knockout)
	TEST_ASSERT_NULL(victim.heretic_capture_mark, "Конец сна отпускает метку.")
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic_capture_hold(other, REF(probe))
	TEST_ASSERT_NULL(other.heretic_capture_mark?.path_id, "Захват без пути рисует метку без пути.")
	TEST_ASSERT(other.heretic_capture_mark?.ink, "Метка без пути всё равно окрашена.")
	heretic_capture_unhold(other, REF(probe))

/// Ремесло тихо вспыхивает на объекте, а нулевой жезл рассеивает его заметной вспышкой.
/datum/unit_test/heretic_craft_fx/Run()
	var/datum/eldritch_knowledge/capture_fx_probe/probe = allocate(/datum/eldritch_knowledge/capture_fx_probe)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(crew, EAST))
	window.AddComponent(/datum/component/heretic_craft, probe, "probe_pane", "В стекле отражается не эта комната.")
	TEST_ASSERT(window.get_filter(HERETIC_VFX_PULSE_FILTER), "Помеченный объект вспыхивает контуром.")
	window.remove_filter(HERETIC_VFX_PULSE_FILTER)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, crew)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, window)
	TEST_ASSERT_NULL(heretic_craft_on(window, "probe_pane"), "Жезл снимает ремесло.")
	TEST_ASSERT(window.get_filter(HERETIC_VFX_PULSE_FILTER), "Рассеянное ремесло вспыхивает на объекте.")

/// Увод виден до канала и после: шов у цели, щель на выходе, ремесло рядом с выходом откликается, метка изнанки гаснет с ней.
/datum/unit_test/heretic_pocket_fx/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/entry = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, entry)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	heretic_pocket_pull_fx(user, victim, entry, HERETIC_POCKET_PULL_TIME, PATH_GLASS)
	var/obj/effect/temp_visual/heretic_vfx/pocket_seam/seam = locate() in entry
	TEST_ASSERT_NOTNULL(seam, "Перед уводом у цели прорезается шов.")
	TEST_ASSERT(seam.duration > HERETIC_POCKET_PULL_TIME && seam.timerid, "Шов держится весь канал и удаляется сам.")
	TEST_ASSERT(victim.get_filter(HERETIC_VFX_PULSE_FILTER), "Цель вспыхивает контуром в чернилах пути.")
	qdel(seam)
	var/turf/landing = locate(user.x + 3, user.y + 2, user.z)
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(landing, EAST))
	var/datum/eldritch_knowledge/capture_fx_probe/probe = allocate(/datum/eldritch_knowledge/capture_fx_probe)
	window.AddComponent(/datum/component/heretic_craft, probe, "probe_pane", "В стекле отражается не эта комната.")
	window.remove_filter(HERETIC_VFX_PULSE_FILTER)
	TEST_ASSERT(heretic.pocket_pull(user, victim, entry, pull_time = 0), "Цель уходит в изнанку.")
	var/datum/heretic_pocket/pocket = heretic.pocket
	TEST_ASSERT(locate(/obj/effect/temp_visual/heretic_vfx/ghost) in entry, "У входа остаётся тающий силуэт ушедшей цели.")
	TEST_ASSERT_EQUAL(victim.heretic_capture_mark?.path_id, PATH_GLASS, "Удержание в изнанке рисует метку в чернилах владельца.")
	TEST_ASSERT_EQUAL(pocket.rift.icon_state, "rift_open", "Разрыв сперва раскрывается из щели.")
	TEST_ASSERT_EQUAL(pocket.inner_rift.icon_state, "rift_inner_open", "Изнутри разрыв раскрывается своей стороной.")
	pocket.rift.settle()
	TEST_ASSERT_EQUAL(pocket.rift.icon_state, "rift", "Раскрытый разрыв переходит в покой.")
	pocket.warn()
	TEST_ASSERT(pocket.active, "Предупреждение не закрывает изнанку.")
	heretic_pocket_tear_fx(pocket.rift, HERETIC_POCKET_TEAR_TIME)
	TEST_ASSERT(pocket.rift.tear_crackle_timer, "Пока разрыв рвут, его треск нарастает.")
	heretic_pocket_tear_stop_fx(pocket.rift)
	TEST_ASSERT_NULL(pocket.rift.tear_crackle_timer, "Отпущенный разрыв перестаёт трещать.")
	TEST_ASSERT(pocket.leave(user, landing), "Еретик выходит у ремесла.")
	TEST_ASSERT(locate(/obj/effect/temp_visual/heretic_vfx/pocket_seam) in landing, "У выхода воздух расходится щелью.")
	TEST_ASSERT(window.get_filter(HERETIC_VFX_PULSE_FILTER), "Ремесло у выхода откликается.")
	TEST_ASSERT(locate(/obj/effect/temp_visual/heretic_vfx/pocket_seam) in entry, "Схлопнутый разрыв стягивается в щель у входа.")
	TEST_ASSERT(!victim.heretic_capture_mark || victim.heretic_capture_mark.fading, "Выпавшую цель изнанка больше не держит.")

/// Сердце прижимает цель: вспышка контура, кольцо и когти из лужи под ней; всё исчезает само.
/datum/unit_test/heretic_door_grip_fx/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/turf/place = get_turf(victim)
	heretic_door_grip_fx(victim)
	TEST_ASSERT(victim.get_filter(HERETIC_VFX_PULSE_FILTER), "Прижатая цель вспыхивает контуром.")
	var/obj/effect/temp_visual/heretic_vfx/gather/ring = locate() in place
	TEST_ASSERT(ring?.timerid, "Кольцо сходится на цели и удаляется само.")
	var/obj/effect/temp_visual/heretic_large_fx/door_grip/claws = locate() in place
	TEST_ASSERT(claws?.timerid, "Когти смыкаются под целью и гаснут сами.")
	TEST_ASSERT(claws.layer < victim.layer, "Когти рисуются под целью.")

/// Отказ от дуэли: призрачный клинок плашмя падает на цель и гаснет, цель вспыхивает.
/datum/unit_test/heretic_blade_refusal_fx/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/turf/place = get_turf(target)
	heretic_blade_refusal_fx(target)
	var/obj/effect/temp_visual/heretic_large_fx/blade_refusal/blade = locate() in place
	TEST_ASSERT(blade?.timerid, "Призрачный клинок появляется над целью и гаснет сам.")
	TEST_ASSERT(blade.layer > target.layer, "Клинок бьёт поверх цели.")
	TEST_ASSERT(target.get_filter(HERETIC_VFX_PULSE_FILTER), "Сбитая с ног цель вспыхивает контуром.")

/// Замах к горлу и тающая кукла видны у цели и у еретика.
/datum/unit_test/heretic_capture_telegraph_fx/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/caster = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic_blade_throat_fx(victim, HERETIC_BLADE_THROAT_TELEGRAPH)
	TEST_ASSERT(locate(/obj/effect/temp_visual/heretic_vfx/gather) in get_turf(victim), "Кольцо клинка сходится на горле цели.")
	heretic_wax_melt_fx(victim, caster)
	TEST_ASSERT(caster.get_filter(HERETIC_VFX_PULSE_FILTER), "Рука с тающей куклой светится.")
	TEST_ASSERT(locate(/obj/effect/temp_visual/heretic_vfx/burst) in get_turf(caster), "С куклы капает воск.")

/// Заклинание в оковах гаснет у рук заметно для всех, но только при настоящей попытке и не чаще раза в пару секунд.
/datum/unit_test/heretic_spell_fizzle_fx/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ASH
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/grasp = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	heretic.owner.AddSpell(grasp)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!grasp.can_cast(user, TRUE, TRUE), "В наручниках хватка не колдуется.")
	TEST_ASSERT(COOLDOWN_FINISHED(grasp, heretic_fizzle_cooldown), "Тихая проверка кнопки знаки не гасит.")
	TEST_ASSERT_NULL(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Без попытки руки не вспыхивают.")
	TEST_ASSERT(!grasp.can_cast(user, TRUE, FALSE), "Попытка в наручниках отклонена.")
	TEST_ASSERT(!COOLDOWN_FINISHED(grasp, heretic_fizzle_cooldown), "Попытка гасит знаки у рук.")
	TEST_ASSERT(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Сорванные знаки видны вспышкой.")
	user.uncuff()
