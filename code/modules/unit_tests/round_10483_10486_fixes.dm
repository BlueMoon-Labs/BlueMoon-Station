/// Бан из панели игрока без загруженного легаси-банлиста не падает в AddBan.
/datum/unit_test/legacy_addban_without_banlist/Run()
	var/old_legacy_flag = CONFIG_GET(flag/ban_legacy_system)
	var/savefile/old_banlist = GLOB.Banlist
	CONFIG_SET(flag/ban_legacy_system, FALSE)
	GLOB.Banlist = null

	var/result = AddBan("unittestbanned", "0", "unit test", "unittest", TRUE, 10)

	CONFIG_SET(flag/ban_legacy_system, old_legacy_flag)
	GLOB.Banlist = old_banlist
	TEST_ASSERT(!result, "AddBan без банлиста должен отказать, а не продолжать")

/// Бот, удаляемый со вставленным pAI, возвращает разум в pAI.
/datum/unit_test/bot_destroy_returns_mind_to_pai/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/bot/secbot/bot = allocate(/mob/living/simple_animal/bot/secbot)
	var/mob/living/silicon/pai/pai = allocate(/mob/living/silicon/pai, run_loc_floor_bottom_left)
	var/obj/item/paicard/card = pai.card
	allocated += card
	pai.mind_initialize()
	var/datum/mind/pai_mind = pai.mind
	bot.locked = FALSE
	user.put_in_active_hand(card)
	TEST_ASSERT(bot.insertpai(user, card), "test premise: pAI не вставился в бота")
	TEST_ASSERT_EQUAL(pai_mind.current, bot, "test premise: разум pAI не перешёл в бота")

	qdel(bot)

	TEST_ASSERT_EQUAL(pai_mind.current, pai, "Разум pAI остался на удалённом боте")

/// Урон выстрела крашера с трофеями идёт в счётчик трофейного лута.
/datum/unit_test/crusher_shot_damage_counts_for_loot/Run()
	var/mob/living/carbon/human/miner = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/asteroid/goliath/beast = allocate(/mob/living/simple_animal/hostile/asteroid/goliath, run_loc_floor_top_right)
	var/datum/status_effect/crusher_damage/tracker = beast.has_status_effect(STATUS_EFFECT_CRUSHERDAMAGETRACKING)
	TEST_ASSERT_NOTNULL(tracker, "test premise: у голиафа нет счётчика урона крашера")
	var/obj/item/projectile/destabilizer/shot = allocate(/obj/item/projectile/destabilizer, run_loc_floor_bottom_left)
	shot.damage = 10
	shot.nodamage = FALSE
	shot.firer = miner
	shot.original = beast
	var/health_before = beast.health

	shot.prehit_pierce(beast)
	beast.bullet_act(shot)

	TEST_ASSERT(beast.health < health_before, "test premise: выстрел не нанёс урона")
	TEST_ASSERT_EQUAL(tracker.total_damage, health_before - beast.health, "Урон выстрела не попал в счётчик крашера")

/// Кофеварка Impressa заводит и гасит пар без рантайма.
/datum/unit_test/impressa_steam_toggle/Run()
	var/obj/machinery/coffeemaker/impressa/maker = allocate(/obj/machinery/coffeemaker/impressa)
	maker.brewing = TRUE
	maker.toggle_steam()
	maker.brewing = FALSE
	maker.toggle_steam()
	TEST_ASSERT_NULL(maker.particles, "Пар остался после окончания варки")
