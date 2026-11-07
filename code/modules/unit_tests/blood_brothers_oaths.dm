/datum/objective_item/blood_brothers_test
	name = "тестовая ценность."
	targetitem = /obj/item/bikehorn

/datum/objective_item/blood_brothers_test/second
	targetitem = /obj/item/pen

/datum/objective_item/blood_brothers_test/forbidden
	targetitem = /obj/item/clipboard
	excludefromjob = list("Assistant")

/// Свой экипаж, режим и пул краж; z теста считается станцией
/datum/unit_test/proc/blood_brothers_oath_world()
	var/datum/antag_opt_in_test_world/world_state = allocate(/datum/antag_opt_in_test_world)
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	GLOB.possible_items = list(
		allocate(/datum/objective_item/blood_brothers_test),
		allocate(/datum/objective_item/blood_brothers_test/second),
		allocate(/datum/objective_item/blood_brothers_test/forbidden),
	)
	return world_state

/// Член экипажа с игроком: тела без клиента клятвы целями не берут
/datum/unit_test/proc/blood_brothers_target(level, role = "Assistant")
	var/datum/mind/target = antag_opt_in_crew(level, role)
	target.current.mock_client = new /datum/client_interface()
	return target

/// Предложение до трёх клятв, подпись второго брата даёт клятву, обет и цели
/datum/unit_test/blood_brothers_oath_choice/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/list/crew = list()
	for(var/crew_number in 1 to 4)
		crew += blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(crew + team.members)
	team.offer_oaths()
	TEST_ASSERT(length(team.offered) >= 1, "Хоть одна клятва предложена")
	TEST_ASSERT(length(team.offered) <= BROTHER_OATH_OFFER_COUNT, "Не больше трёх")
	for(var/datum/blood_oath/offered_oath as anything in team.offered)
		TEST_ASSERT_NOTNULL(offered_oath.vow, "К предложению [offered_oath.key] привязан обет")
	var/datum/blood_oath/choice = team.offered[1]
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	TEST_ASSERT(team.propose_oath(first, choice.key), "Предложение принято")
	TEST_ASSERT_NULL(team.oath, "Одного предложения мало")
	TEST_ASSERT(!team.sign_oath(first), "Предложивший сам не подписывает")
	team.sign_oath(second)
	TEST_ASSERT_EQUAL(team.oath, choice, "Подпись второго даёт клятву")
	TEST_ASSERT_NOTNULL(team.vow, "Обет привязан")
	TEST_ASSERT(!length(team.offered), "Остальные предложения сняты")
	TEST_ASSERT(locate(/datum/objective/blood_oath) in team.objectives, "Цель клятвы у команды")
	TEST_ASSERT(locate(/datum/objective/blood_oath_escape) in team.objectives, "Финал у команды")
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT(locate(/datum/objective/blood_oath) in brother.objectives, "Цель клятвы видна брату")
	TEST_ASSERT(!team.propose_oath(first, choice.key), "После клятвы новых предложений нет")

/// Без подписи по таймеру клянутся предложенной
/datum/unit_test/blood_brothers_oath_timeout/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE))
	team.offer_oaths()
	TEST_ASSERT(team.oath_timer, "Таймер выбора заведён")
	TEST_ASSERT(length(team.offered) >= 2, "Готовы обе клятвы")
	var/datum/blood_oath/second_offer = team.offered[2]
	var/datum/mind/first = team.members[1]
	team.propose_oath(first, second_offer.key)
	team.oath_timeout()
	TEST_ASSERT_EQUAL(team.oath, second_offer, "Таймаут даёт предложенную клятву")
	TEST_ASSERT_NULL(team.oath_timer, "Таймер снят")

/// Добыча: шаг скрепляется только с ценностью у брата, печать поднимает ступень
/datum/unit_test/blood_brothers_oath_heist/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_oath/heist/oath = new
	TEST_ASSERT(oath.prepare(team), "Добыча подобрала ценности")
	for(var/datum/objective_item/loot_info as anything in oath.loot)
		TEST_ASSERT(!length(loot_info.excludefromjob), "Ценность, запрещённая должности брата, не выпадает")
	team.swear_oath(oath)
	TEST_ASSERT_EQUAL(team.oath, oath, "Добыча дана")
	var/datum/mind/first = team.members[1]
	TEST_ASSERT(istext(team.try_seal(first)), "Без ценности шаг не скрепить")
	var/datum/blood_oath_step/heist_item/first_step = oath.steps[1]
	var/obj/item/loot = allocate(first_step.item_type)
	first.current.put_in_hands(loot)
	TEST_ASSERT(team.try_seal(first) == TRUE, "С ценностью скрепляется")
	TEST_ASSERT_EQUAL(team.bond_tier, 1, "Ступень связи 1")
	TEST_ASSERT(first_step.sealed, "Шаг отмечен")
	TEST_ASSERT_EQUAL(first_step.sealed_by, first.name, "Скрепивший записан")

/// Схрон в техтоннелях скрепляет третий шаг; целый обет ускоряет связь, цель клятвы выполнена
/datum/unit_test/blood_brothers_oath_heist_stash/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_oath/heist/oath = new
	TEST_ASSERT(oath.prepare(team), "Добыча готова")
	oath.vow_type = /datum/blood_vow/shadow
	team.swear_oath(oath)
	var/datum/mind/first = team.members[1]
	var/mob/living/carbon/human/sealer = first.current
	var/list/obj/item/loot_items = list()
	for(var/step_index in 1 to 2)
		var/datum/blood_oath_step/heist_item/item_step = oath.steps[step_index]
		var/obj/item/loot = allocate(item_step.item_type)
		sealer.put_in_hands(loot)
		TEST_ASSERT(team.try_seal(first) == TRUE, "Ценность [step_index] скреплена")
		loot_items += loot
	var/obj/structure/closet/crate/stash = allocate(/obj/structure/closet/crate, get_step(run_loc_floor_bottom_left, EAST))
	for(var/obj/item/loot as anything in loot_items)
		sealer.transferItemToLoc(loot, stash)
	TEST_ASSERT(istext(team.try_seal(first)), "Схрон вне техтоннелей не годится")
	heretic_test_area(get_turf(stash), /area/maintenance)
	TEST_ASSERT(team.try_seal(first) == TRUE, "Схрон с добычей в техтоннелях скреплён")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Три печати - высшая ступень")
	TEST_ASSERT_EQUAL(team.cooldown_multiplier, BROTHER_FLAWLESS_COOLDOWN_MULT, "Целый обет ускоряет связь")
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	TEST_ASSERT_NOTNULL(brother.bond_actions[/datum/action/cooldown/blood_bond/capstone/stash], "Третья печать даёт венец клятвы")
	var/datum/objective/blood_oath/oath_objective = locate() in team.objectives
	TEST_ASSERT(oath_objective.check_completion(), "Все печати - цель клятвы выполнена")
	TEST_ASSERT_EQUAL(team.try_seal(first), "всё скреплено", "Четвёртой печати нет")
	var/report = team.roundend_report()
	TEST_ASSERT(findtext(report, "скреплено ([first.name])"), "В итогах видно, кто скрепил")
	TEST_ASSERT(findtext(report, "держится"), "В итогах обет цел")
	TEST_ASSERT(findtext(report, "Клятва не исполнена"), "Без побега клятва не исполнена")

/// Месть: Лайт без убийства, Хард - разовое убийство
/datum/unit_test/blood_brothers_oath_vendetta_violence/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/victim = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + victim)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/blood_oath/vendetta/light_oath = allocate(/datum/blood_oath/vendetta)
	TEST_ASSERT(light_oath.prepare(team), "Месть в Лайте подобрала цель")
	TEST_ASSERT_EQUAL(light_oath.target_mind, victim, "Цель - не брат")
	TEST_ASSERT(istype(light_oath.steps[3], /datum/blood_oath_step/vendetta_hold), "В Лайте шаг 3 - удержание")
	world_state.set_hard_round(src)
	var/datum/blood_oath/vendetta/hard_oath = allocate(/datum/blood_oath/vendetta)
	TEST_ASSERT(hard_oath.prepare(team), "Месть в Харде подобрала цель")
	TEST_ASSERT(istype(hard_oath.steps[3], /datum/blood_oath_step/vendetta_kill), "В Харде шаг 3 - разовое убийство")
	TEST_ASSERT_EQUAL(hard_oath.target_opt_in_level, ANTAG_OPT_IN_KILL, "Убийство требует согласия на убийство")

/// Месть уважает согласие и не берёт охрану
/datum/unit_test/blood_brothers_oath_vendetta_opt_in/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_NOT_TARGET))
	var/datum/blood_oath/vendetta/oath = allocate(/datum/blood_oath/vendetta)
	TEST_ASSERT(!oath.prepare(team), "Без согласных Мести нет")
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE, "Security Officer"))
	TEST_ASSERT(!oath.prepare(team), "Охрана целью Мести не выпадает")
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE, "Captain"))
	TEST_ASSERT(!oath.prepare(team), "Капитан целью Мести не выпадает")
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE, "Prisoner"))
	TEST_ASSERT(!oath.prepare(team), "Заключённый уже в бриге - целью Мести не выпадает")
	world_state.set_crew(team.members + antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE))
	TEST_ASSERT(!oath.prepare(team), "Тело без игрока целью не выпадает")
	var/datum/mind/heavy = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	heavy.current.mob_weight = MOB_WEIGHT_HEAVY_SUPER
	world_state.set_crew(team.members + heavy)
	TEST_ASSERT(!oath.prepare(team), "Сверхтяжёлого не удержать - Месть с удержанием его не берёт")
	var/datum/mind/temporary = blood_brothers_target(ANTAG_OPT_IN_TEMPORARY)
	world_state.set_crew(team.members + temporary)
	TEST_ASSERT(oath.prepare(team), "Цель без убийства годится для Мести в Лайте")
	TEST_ASSERT_EQUAL(oath.target_mind, temporary, "Выбрана согласная цель")
	world_state.set_hard_round(src)
	TEST_ASSERT(!oath.prepare(team), "В Харде Месть ждёт согласия на убийство")
	heavy.antag_opt_in_level = ANTAG_OPT_IN_KILL
	world_state.set_crew(team.members + heavy)
	TEST_ASSERT(oath.prepare(team), "Для разового убийства вес не помеха")
	TEST_ASSERT_EQUAL(oath.target_mind, heavy, "Сверхтяжёлый - цель убийства")

/// Месть в Лайте: ID-карта, бриг и удержание в техтоннелях скрепляют шаги по порядку
/datum/unit_test/blood_brothers_oath_vendetta_steps/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/victim = blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + victim)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	oath.vow_type = /datum/blood_vow/shadow
	team.swear_oath(oath)
	var/datum/mind/first = team.members[1]
	var/mob/living/carbon/human/sealer = first.current
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = "Чужое Имя"
	sealer.put_in_hands(card)
	TEST_ASSERT(istext(team.try_seal(first)), "Чужая ID-карта не годится")
	card.registered_name = victim.name
	TEST_ASSERT(team.try_seal(first) == TRUE, "ID-карта цели скрепляет первый шаг")
	TEST_ASSERT(istext(team.try_seal(first)), "Цель на свободе")
	var/mob/living/carbon/human/victim_body = victim.current
	var/turf/cell = get_step(run_loc_floor_bottom_left, NORTH)
	heretic_test_area(cell, /area/security/brig)
	victim_body.forceMove(cell)
	TEST_ASSERT(team.try_seal(first) == TRUE, "Цель в бриге скрепляет второй шаг")
	var/datum/blood_oath_step/vendetta_hold/hold_step = oath.steps[3]
	var/turf/tunnel = get_step(run_loc_floor_bottom_left, EAST)
	heretic_test_area(tunnel, /area/maintenance)
	victim_body.forceMove(tunnel)
	oath.on_team_tick()
	TEST_ASSERT_EQUAL(hold_step.held_time, 0, "Без наручников удержание не идёт")
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs)
	sealer.put_in_hands(cuffs)
	cuffs.apply_cuffs(victim_body, sealer)
	TEST_ASSERT(victim_body.handcuffed, "Цель в наручниках")
	team.process()
	TEST_ASSERT_EQUAL(hold_step.held_time, BROTHER_SENSE_INTERVAL, "Обход команды копит удержание")
	TEST_ASSERT(findtext(hold_step.condition_text(sealer), "0:02"), "Условие показывает время: [hold_step.condition_text(sealer)]")
	TEST_ASSERT(findtext(hold_step.desc, DisplayTimeText(BROTHER_VENDETTA_HOLD_TIME)), "Описание называет время словами: [hold_step.desc]")
	TEST_ASSERT(istext(team.try_seal(first)), "Мало удержано")
	for(var/tick in 1 to round(BROTHER_VENDETTA_HOLD_TIME / BROTHER_SENSE_INTERVAL))
		oath.on_team_tick()
	TEST_ASSERT(team.try_seal(first) == TRUE, "Удержание скрепляет третий шаг")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Три печати")

/// Цель клятвы нельзя позвать в братья
/datum/unit_test/blood_brothers_oath_target_not_recruitable/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/victim = antag_opt_in_crew(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(team.members + victim)
	GLOB.round_type = ROUNDTYPE_DYNAMIC_LIGHT
	var/datum/mind/first = team.members[1]
	victim.current.mock_client = new /datum/client_interface()
	var/before_oath = team.can_recruit(first, victim.current)
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	team.swear_oath(oath)
	var/after_oath = team.can_recruit(first, victim.current)
	victim.current.mock_client = null
	TEST_ASSERT(before_oath == TRUE, "До клятвы человека можно позвать: [before_oath]")
	TEST_ASSERT_EQUAL(after_oath, "цель клятвы не позвать", "Цель Мести не зовут в братья")

/// Тихий третий брат переводит неисполненное убийство Мести в удержание
/datum/unit_test/blood_brothers_oath_vendetta_quiet_third
	var/datum/preferences/quiet_prefs

/datum/unit_test/blood_brothers_oath_vendetta_quiet_third/Destroy()
	GLOB.preferences_datums -= "bloodbrotherquiet"
	QDEL_NULL(quiet_prefs)
	return ..()

/datum/unit_test/blood_brothers_oath_vendetta_quiet_third/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE))
	world_state.set_hard_round(src)
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть в Харде готова")
	team.swear_oath(oath)
	TEST_ASSERT(istype(oath.steps[3], /datum/blood_oath_step/vendetta_kill), "В Харде шаг 3 - разовое убийство")
	var/datum/mind/quiet = allocate_brother_mind(src)
	quiet.key = "BloodBrotherQuiet"
	quiet_prefs = new
	quiet_prefs.antag_objective_style = ANTAG_OBJECTIVE_STYLE_QUIET
	GLOB.preferences_datums["bloodbrotherquiet"] = quiet_prefs
	var/datum/antagonist/brother/third = new
	third.silent = TRUE
	quiet.add_antag_datum(third, team)
	TEST_ASSERT_EQUAL(length(oath.steps), 3, "Шагов по-прежнему три")
	TEST_ASSERT(istype(oath.steps[3], /datum/blood_oath_step/vendetta_hold), "Тихий брат переводит убийство в удержание")
	var/datum/blood_oath_step/vendetta_hold/hold_step = oath.steps[3]
	TEST_ASSERT_EQUAL(hold_step.oath, oath, "Новый шаг привязан к клятве")
	TEST_ASSERT_EQUAL(oath.target_opt_in_level, ANTAG_OPT_IN_TEMPORARY, "Для удержания хватает согласия без убийства")

/// Обет «Плечом к плечу» ломается при печати в одиночку
/datum/unit_test/blood_brothers_oath_vow_shoulder/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_oath/heist/oath = new
	TEST_ASSERT(oath.prepare(team), "Добыча готова")
	oath.vow_type = /datum/blood_vow/shoulder
	team.swear_oath(oath)
	TEST_ASSERT(istype(team.vow, /datum/blood_vow/shoulder), "Обет из предложения")
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/blood_oath_step/heist_item/first_step = oath.steps[1]
	first.current.put_in_hands(allocate(first_step.item_type))
	TEST_ASSERT(team.try_seal(first) == TRUE, "Печать рядом с братом прошла")
	TEST_ASSERT(!team.vow.broken, "Брат рядом - обет цел")
	second.current.forceMove(run_loc_floor_top_right)
	var/datum/blood_oath_step/heist_item/second_step = oath.steps[2]
	first.current.put_in_hands(allocate(second_step.item_type))
	TEST_ASSERT(team.try_seal(first) == TRUE, "Печать в одиночку прошла")
	TEST_ASSERT(team.vow.broken, "Печать в одиночку ломает обет")

/// Обет «Без крови» ломает только смерть разумного, которого брат бил недавно; цель клятвы не в счёт
/datum/unit_test/blood_brothers_oath_vow_bloodless/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/victim_mind = blood_brothers_target(ANTAG_OPT_IN_KILL)
	world_state.set_crew(team.members + victim_mind)
	world_state.set_hard_round(src)
	var/datum/blood_oath/vendetta/oath = new
	TEST_ASSERT(oath.prepare(team), "Месть готова")
	oath.vow_type = /datum/blood_vow/bloodless
	team.swear_oath(oath)
	var/datum/blood_vow/bloodless/vow = team.vow
	var/datum/mind/killer = team.members[1]
	var/mob/living/carbon/human/killer_body = killer.current
	var/obj/item/kitchen/rollingpin/weapon = allocate(/obj/item/kitchen/rollingpin)
	killer_body.put_in_hands(weapon)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(killer_body, EAST))
	bystander.mind_initialize()
	bystander.lastattackerckey = "someoneelse"
	bystander.death()
	TEST_ASSERT(!vow.broken, "Чужая кровь обет не ломает")
	var/mob/living/carbon/human/old_victim = allocate(/mob/living/carbon/human, get_step(killer_body, EAST))
	old_victim.mind_initialize()
	weapon.attack(old_victim, killer_body)
	var/list/old_hit = vow.recent_hits[WEAKREF(old_victim)]
	TEST_ASSERT_NOTNULL(old_hit, "Удар брата запомнен")
	old_hit[1] -= BROTHER_VOW_BLOODLESS_WINDOW + 1
	old_victim.death()
	TEST_ASSERT(!vow.broken, "Давний удар обет не ломает")
	var/mob/living/carbon/human/target_body = victim_mind.current
	target_body.forceMove(get_step(killer_body, EAST))
	weapon.attack(target_body, killer_body)
	target_body.death()
	TEST_ASSERT(!vow.broken, "Смерть цели клятвы обет не ломает")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(killer_body, EAST))
	victim.mind_initialize()
	weapon.attack(victim, killer_body)
	victim.death()
	TEST_ASSERT(vow.broken, "Свежий удар брата перед смертью ломает обет")
	TEST_ASSERT(findtext(vow.desc, "[BROTHER_VOW_BLOODLESS_WINDOW / (1 SECONDS)] секунд"), "Окно обета в описании совпадает с дефайном")

/// Обет «Тень» ломается, если брат слишком долго в наручниках
/datum/unit_test/blood_brothers_oath_vow_shadow/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_oath/heist/oath = new
	TEST_ASSERT(oath.prepare(team), "Добыча готова")
	oath.vow_type = /datum/blood_vow/shadow
	team.swear_oath(oath)
	var/datum/blood_vow/shadow/vow = team.vow
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs)
	second.current.put_in_hands(cuffs)
	cuffs.apply_cuffs(first.current, second.current)
	team.process()
	TEST_ASSERT(vow.cuffed_since[first], "Наручники замечены")
	TEST_ASSERT(!vow.broken, "Короткие наручники обет не ломают")
	var/cuffed_at = vow.cuffed_since[first]
	vow.cuffed_since[first] = cuffed_at - BROTHER_VOW_SHADOW_LIMIT - 1
	vow.on_team_tick()
	TEST_ASSERT(vow.broken, "Дольше предела в наручниках - обет нарушен")

/// Окно: предложение и подпись идут через ui_act, чужое окно не действует, данные отражают клятву
/datum/unit_test/blood_brothers_oath_ui/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	world_state.set_crew(team.members + blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE))
	team.offer_oaths()
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/antagonist/brother/first_brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/antagonist/brother/second_brother = second.has_antag_datum(/datum/antagonist/brother)
	var/list/static_data = first_brother.ui_static_data(first.current)
	TEST_ASSERT_EQUAL(length(static_data["brothers"]), 2, "В шапке оба брата")
	TEST_ASSERT(length(static_data["rules"]), "Памятка правил передана")
	var/list/data = first_brother.ui_data(first.current)
	TEST_ASSERT_EQUAL(data["state"], "choosing", "До клятвы - выбор")
	TEST_ASSERT_EQUAL(length(data["offered"]), length(team.offered), "Все предложения в окне")
	TEST_ASSERT(data["deadline_left"] > 0, "Таймер выбора идёт")
	var/datum/blood_oath/choice = team.offered[1]
	var/datum/tgui/stranger_ui = allocate(/datum/tgui, second.current, first_brother, "AntagInfoBloodBrother")
	stranger_ui.status = UI_INTERACTIVE
	TEST_ASSERT(!first_brother.ui_act("propose", list("key" = choice.key), stranger_ui), "Чужое окно не предлагает клятву")
	TEST_ASSERT_NULL(team.proposed, "Предложения нет")
	var/datum/tgui/first_ui = allocate(/datum/tgui, first.current, first_brother, "AntagInfoBloodBrother")
	first_ui.status = UI_INTERACTIVE
	TEST_ASSERT(first_brother.ui_act("propose", list("key" = choice.key), first_ui), "Предложение из окна")
	TEST_ASSERT_EQUAL(team.proposed, choice, "Предложена выбранная клятва")
	data = second_brother.ui_data(second.current)
	TEST_ASSERT_EQUAL(data["proposed_key"], choice.key, "Второй видит предложение")
	TEST_ASSERT_EQUAL(data["proposed_by"], first.name, "И кто предложил")
	var/datum/tgui/second_ui = allocate(/datum/tgui, second.current, second_brother, "AntagInfoBloodBrother")
	second_ui.status = UI_INTERACTIVE
	TEST_ASSERT(second_brother.ui_act("sign", list(), second_ui), "Подпись из окна")
	TEST_ASSERT_EQUAL(team.oath, choice, "Клятва дана")
	data = first_brother.ui_data(first.current)
	TEST_ASSERT_EQUAL(data["state"], "sworn", "После подписи - клятва")
	TEST_ASSERT_EQUAL(data["current_step"], 1, "Текущий шаг первый")
	TEST_ASSERT(istext(data["can_seal"]), "Невыполненное условие приходит причиной")
	var/list/oath_data = data["oath"]
	var/list/steps_data = oath_data["steps"]
	var/list/first_step_data = steps_data[1]
	TEST_ASSERT(istext(first_step_data["condition"]), "У текущего шага строка условия")
	var/list/capstone_data = first_brother.ui_static_data(first.current)["oath_texts"]["capstone"]
	var/datum/action/cooldown/blood_bond/capstone = choice.capstone_type
	TEST_ASSERT_NOTNULL(capstone_data, "Венец клятвы в данных")
	TEST_ASSERT_EQUAL(capstone_data["name"], initial(capstone.name), "Венец назван как кнопка")
	TEST_ASSERT_EQUAL(length(data["brother_states"]), 2, "Состояния обоих братьев")
	TEST_ASSERT(first_brother.ui_act("seal", list(), first_ui), "Скрепление из окна отвечает")
	TEST_ASSERT_EQUAL(team.bond_tier, 0, "Без условия печати нет")

/// Обет «Без крови» отпускает удалённый разум брата: его нет ни в слежке, ни в памяти ударов
/datum/unit_test/blood_brothers_oath_vow_bloodless_mind_deleted/Run()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/blood_vow/bloodless/vow = new
	team.vow = vow
	vow.attach(team)
	var/datum/mind/doomed = team.members[1]
	var/mob/living/carbon/human/doomed_body = doomed.current
	var/obj/item/kitchen/rollingpin/weapon = allocate(/obj/item/kitchen/rollingpin)
	doomed_body.put_in_hands(weapon)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(doomed_body, EAST))
	victim.mind_initialize()
	weapon.attack(victim, doomed_body)
	TEST_ASSERT_NOTNULL(vow.recent_hits[WEAKREF(victim)], "Удар брата запомнен")
	TEST_ASSERT(doomed in vow.watched_minds, "Разум брата под слежкой")
	qdel(doomed)
	TEST_ASSERT(!(doomed in vow.watched_minds), "Удалённый разум снят со слежки")
	TEST_ASSERT_NULL(vow.recent_hits[WEAKREF(victim)], "Удары удалённого разума забыты")

/datum/blood_oath_step/blood_brothers_open
	name = "Открытый шаг"

/datum/blood_oath_step/blood_brothers_open/can_seal(mob/living/sealer)
	return TRUE

/// Исполненная клятва открывает следующие без срока и с прежним обетом; её венец остаётся, венец следующей - с последней печатью
/datum/unit_test/blood_brothers_next_oath/Run()
	var/datum/antag_opt_in_test_world/world_state = blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/list/crew = list()
	for(var/crew_number in 1 to 4)
		crew += blood_brothers_target(ANTAG_OPT_IN_ROUND_REMOVE)
	world_state.set_crew(crew + team.members)
	var/mob/living/carbon/human/admin = allocate(/mob/living/carbon/human)
	var/datum/mind/first = team.members[1]
	var/datum/mind/second = team.members[2]
	var/datum/antagonist/brother/brother = first.has_antag_datum(/datum/antagonist/brother)
	var/datum/blood_oath/blood_brothers_capstone_test/first_oath = new
	first_oath.capstone_type = /datum/action/cooldown/blood_bond/capstone/stash
	first_oath.vow_type = /datum/blood_vow/shadow
	for(var/step_number in 1 to BLOOD_BOND_TIER_MAX)
		first_oath.add_step(new /datum/blood_oath_step/blood_brothers_open)
	team.swear_oath(first_oath)
	var/datum/blood_vow/kept_vow = team.vow
	for(var/step_number in 1 to BLOOD_BOND_TIER_MAX - 1)
		TEST_ASSERT(team.try_seal(first) == TRUE, "Печать [step_number]")
	TEST_ASSERT(!length(team.offered), "До последней печати новых клятв нет")
	TEST_ASSERT(team.try_seal(first) == TRUE, "Последняя печать")
	TEST_ASSERT(length(team.offered), "Исполненная клятва открыла выбор следующей")
	TEST_ASSERT_NULL(team.oath_timer, "Следующую клятву не навязывают по таймеру")
	for(var/datum/blood_oath/offer as anything in team.offered)
		TEST_ASSERT_EQUAL(offer.vow_type, kept_vow.type, "Следующая клятва [offer.key] - с прежним обетом")
	TEST_ASSERT_EQUAL(brother.ui_data(first.current)["state"], "next", "Окно предлагает следующую")
	TEST_ASSERT(first_oath.name in brother.ui_static_data(first.current)["fulfilled"], "Окно числит клятву исполненной")
	var/datum/blood_oath/next_oath
	for(var/datum/blood_oath/offer as anything in team.offered)
		if(offer.capstone_type && offer.capstone_type != first_oath.capstone_type)
			next_oath = offer
			break
	TEST_ASSERT_NOTNULL(next_oath, "Среди следующих есть клятва с другим венцом")
	TEST_ASSERT(team.propose_oath(first, next_oath.key), "Следующую можно предложить")
	TEST_ASSERT(team.sign_oath(second), "И подписать")
	TEST_ASSERT_EQUAL(team.oath, next_oath, "Следующая клятва дана")
	TEST_ASSERT(first_oath in team.fulfilled_oaths, "Исполненная клятва в зачёте")
	TEST_ASSERT(!QDELETED(first_oath), "Исполненная клятва цела")
	TEST_ASSERT_EQUAL(team.vow, kept_vow, "Обет прежний")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Ступень высшая")
	TEST_ASSERT(team.has_stash_capstone(), "Венец исполненной клятвы остался")
	TEST_ASSERT_NOTNULL(brother.bond_actions[/datum/action/cooldown/blood_bond/capstone/stash], "Кнопка венца на месте")
	TEST_ASSERT(!team.holds_capstone(next_oath.capstone_type), "Венец следующей клятвы до её печатей закрыт")
	var/datum/objective/blood_oath/oath_objective = locate() in team.objectives
	TEST_ASSERT(oath_objective.check_completion(), "Цель клятвы выполнена исполненной")
	TEST_ASSERT(findtext(oath_objective.explanation_text, "Исполнено: «[first_oath.name]»"), "Цель называет исполненную: [oath_objective.explanation_text]")
	TEST_ASSERT(findtext(team.roundend_report(), "Клятва «[first_oath.name]»"), "Итоги называют исполненную")
	TEST_ASSERT(brother.admin_flip_step(admin, 1), "Админ скрепил шаг следующей клятвы")
	TEST_ASSERT_EQUAL(team.bond_tier, BLOOD_BOND_TIER_MAX, "Печать следующей клятвы не сбрасывает ступень")
	for(var/step_index in 2 to length(next_oath.steps))
		brother.admin_flip_step(admin, step_index)
	TEST_ASSERT(team.holds_capstone(next_oath.capstone_type), "Последняя печать открыла венец следующей клятвы")
	for(var/datum/blood_oath/offer as anything in team.offered)
		TEST_ASSERT(offer.key != next_oath.key, "Исполненную клятву [offer.key] снова не предлагают")
	TEST_ASSERT(brother.admin_apply_oath(admin, /datum/blood_oath/blood_brothers_capstone_test), "Админ дал новую клятву после исполненной")
	TEST_ASSERT(next_oath in team.fulfilled_oaths, "Смена клятвы оставила исполненную в зачёте")
	TEST_ASSERT(!length(team.offered), "Предложения сняты")

/// Клятва даёт узелок с вещами каждому живому брату, мёртвому - нет
/datum/unit_test/blood_brothers_oath_kit/Run()
	blood_brothers_oath_world()
	var/datum/team/brother_team/team = allocate_brother_team(src)
	var/datum/mind/living_member = team.members[1]
	var/datum/mind/dead_member = team.members[2]
	dead_member.current.death()
	var/datum/blood_oath/brother_sign/oath = new
	TEST_ASSERT(oath.prepare(team), "Знак братства готов")
	var/mob/living/carbon/human/living_body = living_member.current
	var/obj/item/storage/backpack/backpack = allocate(/obj/item/storage/backpack)
	living_body.equip_to_slot(backpack, ITEM_SLOT_BACK)
	TEST_ASSERT(team.swear_oath(oath), "Клятва дана")
	var/obj/item/storage/box/papersack/kit = locate() in backpack
	TEST_ASSERT_NOTNULL(kit, "Живой брат получил узелок в рюкзак")
	for(var/item_type in oath.kit_items)
		TEST_ASSERT(locate(item_type) in kit, "В узелке есть [item_type]")
	TEST_ASSERT(!length(dead_member.current.GetAllContents(/obj/item/storage/box/papersack)), "Мёртвому узелок не положен")
	TEST_ASSERT_NULL(locate(/obj/item/storage/box/papersack) in get_turf(dead_member.current), "Под мёртвым узелка нет")

/// У каждой клятвы есть узелок, его вещи подписаны и честно влезают в бумажный пакет
/datum/unit_test/blood_brothers_oath_kit_contents/Run()
	for(var/datum/blood_oath/oath_type as anything in GLOB.blood_oath_types)
		var/datum/blood_oath/oath = new oath_type
		TEST_ASSERT(length(oath.kit_items), "У [oath_type] нет узелка")
		var/obj/item/storage/box/papersack/sack = allocate(/obj/item/storage/box/papersack)
		for(var/item_type in oath.kit_items)
			TEST_ASSERT(GLOB.brother_kit_labels[item_type], "[item_type] без подписи")
			var/obj/item/kit_item = allocate(item_type)
			TEST_ASSERT(SEND_SIGNAL(sack, COMSIG_TRY_STORAGE_INSERT, kit_item, null, TRUE, FALSE), "[item_type] не влезает в узелок [oath_type]")
		TEST_ASSERT(length(oath.kit_text()), "У [oath_type] пустая подпись узелка")
		qdel(oath)
