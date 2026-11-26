/datum/unit_test/proc/lantern_alert_state(mob/living/user)
	var/atom/movable/screen/alert/shown = user.alerts[HERETIC_ASH_LANTERN_ALERT]
	return shown?.icon_state

/// Обряд вознесения Пепла зажигает фонарь на клетке руны, а над космосом - у ног еретика.
/datum/unit_test/heretic_ash_lantern_ritual/Run()
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	var/turf/rune_turf = get_step(run_loc_floor_bottom_left, NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(rune_turf)
	heretic.ascension_notice_sent = TRUE
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_ASH
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, rune_turf)
	var/datum/eldritch_knowledge/final_eldritch/ash_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/ash_final)
	finale.ritual_time = 0
	heretic.researched_knowledge[finale.type] = finale
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, rune_turf)
		body.last_mind = allocate_mind()
		body.stat = DEAD
	TEST_ASSERT(rune.do_ritual(user, finale), "Обряд вознесения Пепла завершается.")
	var/obj/structure/heretic_ash_lantern/lantern = finale.lantern
	TEST_ASSERT_NOTNULL(lantern, "Вознесение зажигает Пепельный фонарь.")
	allocated += lantern
	TEST_ASSERT_EQUAL(lantern.loc, rune_turf, "Фонарь встаёт на клетке руны.")
	TEST_ASSERT_EQUAL(lantern.max_integrity, HERETIC_ASH_LANTERN_INTEGRITY, "Прочность фонаря из дефайна.")
	TEST_ASSERT(finale.lantern_lit(), "Новый фонарь горит.")
	TEST_ASSERT(lantern.light_range > 0, "Горящий фонарь светит.")
	var/turf/space = get_step(run_loc_floor_top_right, NORTH)
	var/original_type = space.type
	space = space.ChangeTurf(/turf/open/space)
	qdel(lantern)
	finale.plant_lantern(space, user)
	TEST_ASSERT_EQUAL(finale.lantern?.loc, get_turf(user), "Над космосом фонарь встаёт у ног еретика.")
	space.ChangeTurf(original_type)

/// Погасший фонарь ослабляет лечение и след владыки; разжечь его можно только самому еретику и только после просушки.
/datum/unit_test/heretic_ash_lantern_douse/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/ash_final/finale = fixture["finale"]
	var/datum/component/heretic_ash_lord/lord = user.GetComponent(/datum/component/heretic_ash_lord)
	var/obj/structure/heretic_ash_lantern/lantern = finale.lantern
	TEST_ASSERT_EQUAL(lantern_alert_state(user), "ash_lantern_alert", "Владыка видит алерт горящего фонаря.")
	douse_with_water(lantern)
	TEST_ASSERT(!finale.lantern_lit(), "Вода гасит фонарь.")
	TEST_ASSERT_EQUAL(lantern.light_range, 0, "Погасший фонарь не светит.")
	TEST_ASSERT_EQUAL(lantern_alert_state(user), "ash_lantern_alert_out", "Алерт показывает погасший фонарь.")
	user.adjustFireLoss(20)
	var/burn_before = user.getFireLoss()
	lord.on_life(user)
	TEST_ASSERT(abs(burn_before - user.getFireLoss() - HERETIC_ASH_LORD_DIM_HEAL) < DAMAGE_PRECISION, "С погасшим фонарём пламя лечит слабее.")
	var/turf/start = get_turf(user)
	user.forceMove(get_step(user, EAST))
	var/obj/effect/heretic_combat_zone/ash/lord_trail/trail = locate() in start
	TEST_ASSERT_NOTNULL(trail, "След остаётся и с погасшим фонарём.")
	TEST_ASSERT(abs(trail.expires_at - world.time - HERETIC_ASH_TRAIL_DIM_DURATION) < 1, "С погасшим фонарём след короче.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_step(lantern, NORTH))
	TEST_ASSERT(!lantern.can_relight(stranger), "Чужой фонарь не разжечь.")
	user.forceMove(get_step(lantern, EAST))
	TEST_ASSERT(!lantern.can_relight(user), "Мокрый фитиль не разжечь сразу.")
	lantern.soaked_until = world.time + 1 SECONDS
	var/soaked = lantern.soaked_until
	douse_with_water(lantern)
	TEST_ASSERT_EQUAL(lantern.soaked_until, soaked, "Вода по уже погасшему фонарю не продлевает сырость.")
	TEST_ASSERT(findtext(lantern.censer_block_reason(user), "сырой"), "Кадильница объясняет, что фитиль ещё сырой.")
	lantern.soaked_until = world.time
	TEST_ASSERT(lantern.can_relight(user), "Просохший фонарь еретик разжигает.")
	TEST_ASSERT(lantern.relight(user), "Фонарь разгорается.")
	TEST_ASSERT(finale.lantern_lit(), "Разожжённый фонарь снова горит.")
	TEST_ASSERT_EQUAL(lantern_alert_state(user), "ash_lantern_alert", "Алерт снова горит.")
	burn_before = user.getFireLoss()
	lord.on_life(user)
	TEST_ASSERT(abs(burn_before - user.getFireLoss() - HERETIC_ASH_LORD_HEAL) < DAMAGE_PRECISION, "Горящий фонарь возвращает полное лечение.")

/// Разбитый фонарь не вернуть: лечение остаётся слабым, а знание освобождает ссылку.
/datum/unit_test/heretic_ash_lantern_broken/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/ash_final/finale = fixture["finale"]
	var/datum/component/heretic_ash_lord/lord = user.GetComponent(/datum/component/heretic_ash_lord)
	var/obj/structure/heretic_ash_lantern/lantern = finale.lantern
	lantern.take_damage(HERETIC_ASH_LANTERN_INTEGRITY, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(lantern), "Фонарь разбивается оружием.")
	TEST_ASSERT_NULL(finale.lantern, "Знание отпускает разбитый фонарь.")
	TEST_ASSERT(!finale.lantern_lit(), "Разбитый фонарь не горит.")
	TEST_ASSERT_EQUAL(lantern_alert_state(user), "ash_lantern_alert_out", "Алерт показывает потерю фонаря.")
	user.adjustFireLoss(20)
	var/burn_before = user.getFireLoss()
	lord.on_life(user)
	TEST_ASSERT(abs(burn_before - user.getFireLoss() - HERETIC_ASH_LORD_DIM_HEAL) < DAMAGE_PRECISION, "Без фонаря пламя лечит слабее.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.alerts[HERETIC_ASH_LANTERN_ALERT], "Потеря тела снимает алерт фонаря.")

/// Кадильница с зарядом разжигает просохший фонарь сразу, за один заряд.
/datum/unit_test/heretic_ash_lantern_censer/Run()
	var/list/fixture = ascend_ash_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/final_eldritch/ash_final/finale = fixture["finale"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	var/obj/structure/heretic_ash_lantern/lantern = finale.lantern
	user.forceMove(get_step(lantern, EAST))
	var/obj/item/heretic_relic/censer/censer = allocate(/obj/item/heretic_relic/censer)
	user.put_in_hands(censer)
	douse_with_water(lantern)
	lantern.soaked_until = world.time
	censer.afterattack(lantern, user, TRUE)
	TEST_ASSERT(!finale.lantern_lit(), "Пустая кадильница фонарь не разжигает.")
	censer.stored_fire = 2
	censer.afterattack(lantern, user, TRUE)
	TEST_ASSERT(finale.lantern_lit(), "Кадильница с зарядом разжигает фонарь.")
	TEST_ASSERT(findtext(lantern.censer_block_reason(user), "горит"), "По горящему фонарю кадильница объясняет отказ.")
	TEST_ASSERT_EQUAL(censer.stored_fire, 1, "Разжигание стоит один заряд.")

/// Жар перестаёт ранить уже со Власти Пепла, а не загораться вовсе - с Благословения ночного стража.
/datum/unit_test/heretic_ash_heat_resist_early/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_ASH]
	TEST_ASSERT_EQUAL(path.knowledge.Find(/datum/eldritch_knowledge/ashen_grasp), 2, "Власть Пепла - вторая ступень.")
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/ashen_grasp)
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_RESISTHEAT), "Власть Пепла снимает урон от жара.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOFIRE), "Загореться всё ещё можно.")
	var/datum/eldritch_knowledge/ashen_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/ashen_grasp)
	grasp.on_body_lose(user)
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_RESISTHEAT), "Смена тела уносит защиту от жара.")
	grasp.on_body_gain(user)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flame_immunity)
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_NOFIRE), "Благословение ночного стража не даёт загореться.")
	TEST_ASSERT(findtext(jointext(grasp.details, " "), "Жар и пожар не ранят тело") && findtext(grasp.summary, "жар и пожар не ранят тело"), "Власть Пепла прямо говорит, что жар и пожар не ранят тело.")

/// Числа фонаря и маски в кодексе совпадают с дефайнами.
/datum/unit_test/heretic_ash_lantern_texts/Run()
	var/datum/eldritch_knowledge/final_eldritch/ash_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/ash_final)
	var/final_text = jointext(finale.details, " ")
	TEST_ASSERT(findtext(final_text, "Пепельный фонарь на [HERETIC_ASH_LANTERN_INTEGRITY] прочности"), "Вознесение называет прочность фонаря.")
	TEST_ASSERT(findtext(final_text, "С горящим фонарём - [HERETIC_ASH_LORD_HEAL] ожога и след на [HERETIC_ASH_TRAIL_DURATION / (1 SECONDS)] секунды; без него - [HERETIC_ASH_LORD_DIM_HEAL] ожог и [HERETIC_ASH_TRAIL_DIM_DURATION / (1 SECONDS)] секунды."), "Вознесение называет силу пламени с фонарём и без.")
	var/list/states = icon_states('modular_bluemoon/icons/obj/heretic_ash_lantern.dmi')
	for(var/state in list("ash_lantern", "ash_lantern_glow", "ash_lantern_out", "ash_lantern_alert", "ash_lantern_alert_out"))
		TEST_ASSERT(state in states, "Стейт [state] есть в листе фонаря.")
	var/datum/eldritch_knowledge/mad_mask/mask = allocate(/datum/eldritch_knowledge/mad_mask)
	TEST_ASSERT(findtext(jointext(mask.details, " "), "[HERETIC_ASH_MASK_GRIP / (1 SECONDS)] секунд не снимет сам"), "Маска называет срок хватки.")

/// Маска безумия держится на лице согласного неверного ограниченный срок, другой человек может её сорвать, а несогласного она не держит.
/datum/unit_test/heretic_ash_mask_grip/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/victim_mind = allocate_mind()
	victim_mind.current = victim
	victim.mind = victim_mind
	victim_mind.antag_opt_in_level = ANTAG_OPT_IN_KILL
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(victim, EAST))
	var/obj/item/clothing/mask/gas/void_mask/mask = allocate(/obj/item/clothing/mask/gas/void_mask)
	TEST_ASSERT(victim.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Маска надевается на неверного.")
	TEST_ASSERT(HAS_TRAIT(mask, TRAIT_NODROP), "Маска вцепляется в лицо согласного.")
	TEST_ASSERT(abs(timeleft(mask.grip_timer) - HERETIC_ASH_MASK_GRIP) < 1, "Хватка маски держится срок из дефайна.")
	var/mask_examine = jointext(mask.examine(helper), " ")
	TEST_ASSERT(findtext(mask_examine, "[HERETIC_ASH_MASK_GRIP / (1 SECONDS)] секунд") && findtext(mask_examine, "не согласен"), "Осмотр маски называет срок хватки и оговорку про несогласных.")
	TEST_ASSERT(mask.canStrip(helper, victim), "Другой человек может сорвать вцепившуюся маску.")
	mask.release_grip()
	TEST_ASSERT(!HAS_TRAIT(mask, TRAIT_NODROP), "По истечении срока маска отпускает.")
	TEST_ASSERT(victim.dropItemToGround(mask), "Ослабшую маску снимают сами.")
	TEST_ASSERT(victim.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Маску надевают снова.")
	TEST_ASSERT(mask.doStrip(helper, victim), "Помощник срывает маску.")
	TEST_ASSERT(victim.wear_mask != mask, "Сорванная маска не на лице.")
	TEST_ASSERT_NULL(mask.grip_timer, "Сорванная маска не держит таймер хватки.")
	victim_mind.antag_opt_in_level = ANTAG_OPT_IN_NOT_TARGET
	TEST_ASSERT(victim.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Маска надевается на несогласного.")
	TEST_ASSERT(!HAS_TRAIT(mask, TRAIT_NODROP), "Несогласного маска не держит.")

/// Рассечение режет и не-людей: животному 20 ушибов, человеку рана; мёртвых не выбирает.
/datum/unit_test/heretic_ash_cleave_any_living/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/effect/proc_holder/spell/pointed/cleave/cleave = allocate(/obj/effect/proc_holder/spell/pointed/cleave)
	var/turf/spot = get_step(get_step(user, EAST), EAST)
	var/mob/living/simple_animal/pet/dog/corgi/dog = allocate(/mob/living/simple_animal/pet/dog/corgi, spot)
	TEST_ASSERT(cleave.can_target(dog, user, TRUE), "Рассечение выбирает животное.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	var/dog_before = dog.health
	cleave.cast(list(dog), user)
	TEST_ASSERT(dog_before - dog.health >= 20, "Животное получает 20 ушибов.")
	TEST_ASSERT(length(victim.all_wounds), "Человек рядом получает рану.")
	TEST_ASSERT(victim.getBruteLoss() >= 20, "Человек рядом получает 20 ушибов.")
	dog.death()
	TEST_ASSERT(!cleave.can_target(dog, user, TRUE), "Мёртвых Рассечение не выбирает.")
