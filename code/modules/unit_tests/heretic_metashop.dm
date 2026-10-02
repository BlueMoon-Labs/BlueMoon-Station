/// Проверяет каталог, ограничения и полную выдачу роли через жетон еретика.
/datum/unit_test/heretic_metashop
	var/datum/game_mode/saved_mode
	var/saved_game_state
	var/saved_protect_roles
	var/saved_protect_assistant

/datum/unit_test/heretic_metashop/New()
	..()
	saved_mode = SSticker.mode
	saved_game_state = SSticker.current_state
	saved_protect_roles = CONFIG_GET(flag/protect_roles_from_antagonist)
	saved_protect_assistant = CONFIG_GET(flag/protect_assistant_from_antagonist)

/datum/unit_test/heretic_metashop/Destroy()
	SSticker.mode = saved_mode
	SSticker.current_state = saved_game_state
	CONFIG_SET(flag/protect_roles_from_antagonist, saved_protect_roles)
	CONFIG_SET(flag/protect_assistant_from_antagonist, saved_protect_assistant)
	return ..()

/datum/unit_test/heretic_metashop/Run()
	var/datum/game_mode/dynamic/test_mode = allocate(/datum/game_mode/dynamic)
	SSticker.mode = test_mode
	SSticker.current_state = GAME_STATE_PLAYING
	CONFIG_SET(flag/protect_roles_from_antagonist, TRUE)
	CONFIG_SET(flag/protect_assistant_from_antagonist, FALSE)
	var/datum/metadollar_shop/shop = new(null)
	allocated += shop
	var/datum/metadollar_shop_item/item/heretic_token/entry = allocate(/datum/metadollar_shop_item/item/heretic_token)
	var/list/catalog = shop.build_catalog_list(entry.catalog)
	var/list/token_entry
	for(var/list/catalog_entry as anything in catalog)
		if(catalog_entry["id"] == "[entry.type]")
			token_entry = catalog_entry
			break
	TEST_ASSERT_NOTNULL(token_entry, "Жетон еретика должен присутствовать в подпольном каталоге")

	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	allocated += user.mind
	user.job = "Scientist"
	var/obj/item/coin/antagtoken/metashop/heretic/token = allocate(entry.token_spawn_type, user)
	TEST_ASSERT_EQUAL(token_entry["cost"], token.metashop_refund_amount, "Возврат жетона должен полностью покрывать цену покупки")
	var/datum/game_mode/extended/extended_mode = allocate(/datum/game_mode/extended)
	SSticker.mode = extended_mode
	TEST_ASSERT(!entry.is_visible(shop), "В Extended жетон должен быть скрыт из каталога")
	TEST_ASSERT(!token.try_activate(user), "Купленный ранее жетон не должен активироваться в Extended")
	TEST_ASSERT(!QDELETED(token), "Отказ в Extended должен сохранять жетон для возврата")
	SSticker.mode = test_mode
	user.job = "Captain"
	TEST_ASSERT(!token.try_activate(user), "Защищённая должность не должна получать роль через жетон")
	TEST_ASSERT(!QDELETED(token), "Отказ по должности должен сохранять жетон")
	user.job = "Scientist"
	TEST_ASSERT(token.try_activate(user), "Подходящий член экипажа должен активировать жетон")
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	TEST_ASSERT_NOTNULL(heretic, "Активация должна выдавать роль еретика")
	allocated += heretic
	TEST_ASSERT_EQUAL(user.mind.special_role, ROLE_HERETIC, "Разум должен получить флаг еретика")
	TEST_ASSERT(heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic), "Еретик должен получить начальные знания")
	TEST_ASSERT(locate(/obj/item/forbidden_book) in heretic.summon_items, "Еретику должен быть доступен кодекс")
	TEST_ASSERT(locate(/obj/item/living_heart) in heretic.summon_items, "Еретику должно быть доступно живое сердце")
	TEST_ASSERT(QDELETED(token), "Успешная активация должна расходовать жетон")
	var/obj/item/coin/antagtoken/metashop/heretic/duplicate_token = allocate(entry.token_spawn_type, user)
	TEST_ASSERT(!duplicate_token.try_activate(user), "Повторная активация не должна выдавать вторую роль еретика")
	TEST_ASSERT(!QDELETED(duplicate_token), "Повторная активация должна сохранять жетон для возврата")
