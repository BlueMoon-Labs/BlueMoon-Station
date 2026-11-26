/// Обряд побочного знания на настоящей руне: компоненты расходуются, предмет ложится на руну.
/datum/unit_test/proc/heretic_side_craft(datum/antagonist/heretic/heretic, knowledge_type)
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(knowledge_type)
	var/datum/eldritch_knowledge/recipe = heretic.get_knowledge(knowledge_type)
	TEST_ASSERT(recipe, "Знание [knowledge_type] изучено.")
	recipe.ritual_time = 0
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
	var/list/ingredients = list()
	for(var/ingredient_type in recipe.required_atoms)
		ingredients += allocate(ingredient_type, get_turf(rune))
	TEST_ASSERT(rune.do_ritual(user, recipe), "Обряд [recipe.name] проходит с настоящими компонентами.")
	for(var/atom/ingredient as anything in ingredients)
		TEST_ASSERT(QDELETED(ingredient), "Обряд [recipe.name] расходует [ingredient.type].")
	var/result_type = recipe.result_atoms[1]
	var/atom/product = locate(result_type) in get_turf(rune)
	TEST_ASSERT(product, "Обряд [recipe.name] создаёт [result_type] на руне.")
	allocated += product
	return product

/datum/unit_test/proc/heretic_side_powered_door(turf/spot, door_type = /obj/machinery/door/airlock)
	var/obj/machinery/door/airlock/door = allocate(door_type, spot)
	door.machine_stat &= ~NOPOWER
	return door

/datum/unit_test/proc/heretic_side_spot(dx, dy)
	return locate(run_loc_floor_bottom_left.x + dx, run_loc_floor_bottom_left.y + dy, run_loc_floor_bottom_left.z)

/// Десять новых знаний стоят в общей прокачке на своих ступенях, а предметы обрядов видны в руках.
/datum/unit_test/heretic_side_lore_registry/Run()
	var/list/expected = list(
		/datum/eldritch_knowledge/eldritch_coin = 1,
		/datum/eldritch_knowledge/prophet_greaves = 1,
		/datum/eldritch_knowledge/spell/mansus_whisper = 2,
		/datum/eldritch_knowledge/amber_focus = 2,
		/datum/eldritch_knowledge/spell/wave_of_desperation = 3,
		/datum/eldritch_knowledge/newborn_ether = 3,
		/datum/eldritch_knowledge/backdoor_keys = 4,
		/datum/eldritch_knowledge/spell/lights_out = 5,
		/datum/eldritch_knowledge/spell/space_phase = 6,
		/datum/eldritch_knowledge/rust_sower = 7,
	)
	for(var/knowledge_type in expected)
		TEST_ASSERT_EQUAL(GLOB.heretic_side_knowledge[knowledge_type], expected[knowledge_type], "[knowledge_type] открывается на своей ступени.")
	var/list/facts = list(
		list(/datum/eldritch_knowledge/eldritch_coin, "раз в [HERETIC_COIN_COOLDOWN / (1 SECONDS)] секунды"),
		list(/datum/eldritch_knowledge/eldritch_coin, "[HERETIC_COIN_BRAIN_DAMAGE] урона мозгу"),
		list(/datum/eldritch_knowledge/newborn_ether, "Пить [HERETIC_ETHER_DRINK_TIME / (1 SECONDS)] секунды"),
		list(/datum/eldritch_knowledge/newborn_ether, "[HERETIC_ETHER_SLEEP / (1 SECONDS)] секунд вы спите"),
		list(/datum/eldritch_knowledge/newborn_ether, "[HERETIC_ETHER_HEATHEN_TOX] урона токсинами"),
		list(/datum/eldritch_knowledge/backdoor_keys, "держит [HERETIC_BACKDOOR_PAIRS] хода"),
		list(/datum/eldritch_knowledge/backdoor_keys, "[HERETIC_BACKDOOR_CARD_BURN] ожога"),
		list(/datum/eldritch_knowledge/rust_sower, "в [HERETIC_RUST_SOWER_RANGE] клетках"),
		list(/datum/eldritch_knowledge/rust_sower, "получают [HERETIC_RUST_SOWER_SILICON_DAMAGE] урона"),
		list(/datum/eldritch_knowledge/spell/mansus_whisper, "до [HERETIC_WHISPER_LEN] символов"),
		list(/datum/eldritch_knowledge/spell/mansus_whisper, "до [HERETIC_WHISPER_NAME_LEN] символов"),
		list(/datum/eldritch_knowledge/spell/mansus_whisper, "Перезарядка [HERETIC_WHISPER_COOLDOWN / (1 SECONDS)] секунд"),
		list(/datum/eldritch_knowledge/spell/wave_of_desperation, "на [HERETIC_WAVE_THROW] клетки"),
		list(/datum/eldritch_knowledge/spell/wave_of_desperation, "валит на [HERETIC_WAVE_KNOCKDOWN / (1 SECONDS)] секунды"),
		list(/datum/eldritch_knowledge/spell/wave_of_desperation, "Через [HERETIC_WAVE_GRACE / (1 SECONDS)] секунд"),
		list(/datum/eldritch_knowledge/spell/wave_of_desperation, "сон на [HERETIC_WAVE_SLEEP / (1 SECONDS)] секунды"),
		list(/datum/eldritch_knowledge/spell/wave_of_desperation, "Перезарядка [HERETIC_WAVE_COOLDOWN / (1 MINUTES)] минут"),
		list(/datum/eldritch_knowledge/spell/lights_out, "в [HERETIC_LIGHTS_OUT_RANGE] клетках"),
		list(/datum/eldritch_knowledge/spell/lights_out, "Перезарядка [HERETIC_LIGHTS_OUT_COOLDOWN / (1 SECONDS)] секунд"),
		list(/datum/eldritch_knowledge/spell/space_phase, "Перезарядка [HERETIC_SPACE_PHASE_COOLDOWN / (1 SECONDS)] секунд"),
	)
	for(var/list/fact as anything in facts)
		var/datum/eldritch_knowledge/knowledge = allocate(fact[1])
		TEST_ASSERT(findtext(knowledge.desc, fact[2]), "Описание [fact[1]] называет число из дефайна: [fact[2]].")
	var/list/spell_facts = list(
		/obj/effect/proc_holder/spell/self/wave_of_desperation = "Перезарядка [HERETIC_WAVE_COOLDOWN / (1 MINUTES)] минут",
		/obj/effect/proc_holder/spell/self/lights_out = "в [HERETIC_LIGHTS_OUT_RANGE] клетках",
		/obj/effect/proc_holder/spell/self/space_phase = "Перезарядка [HERETIC_SPACE_PHASE_COOLDOWN / (1 SECONDS)] секунд",
	)
	for(var/obj/effect/proc_holder/spell/spell_type as anything in spell_facts)
		TEST_ASSERT(findtext(initial(spell_type.desc), spell_facts[spell_type]), "Подсказка [spell_type] называет число из дефайна: [spell_facts[spell_type]].")
	TEST_ASSERT(icon_exists('modular_bluemoon/icons/obj/heretic_side_lore.dmi', "coin_heretic_flip"), "У монеты есть анимация подброса.")
	// Монеты на станции в руке не рисуются: у них нет своего inhand.
	for(var/obj/item/relic_type as anything in list(/obj/item/clothing/shoes/heretic_greaves, /obj/item/clothing/neck/heretic_focus, /obj/item/heretic_ether, /obj/item/heretic_backdoor_card, /obj/item/grenade/heretic_rust_sower))
		var/held_state = initial(relic_type.item_state)
		TEST_ASSERT(icon_exists(initial(relic_type.icon), initial(relic_type.icon_state)), "У [relic_type] есть свой спрайт.")
		TEST_ASSERT(held_state && icon_exists(initial(relic_type.lefthand_file), held_state) && icon_exists(initial(relic_type.righthand_file), held_state), "[relic_type] виден в обеих руках.")
	for(var/obj/item/clothing/worn_type as anything in list(/obj/item/clothing/shoes/heretic_greaves, /obj/item/clothing/neck/heretic_focus))
		TEST_ASSERT(icon_exists(initial(worn_type.mob_overlay_icon), initial(worn_type.icon_state)), "[worn_type] виден на теле.")

/// Монета у шлюза: «Вред» болтирует, иначе открывает; хранилище и высокая защита не слушаются, скованному и неверному она не помогает.
/datum/unit_test/heretic_side_coin/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/coin/eldritch/coin = heretic_side_craft(heretic, /datum/eldritch_knowledge/eldritch_coin)
	if(!coin)
		return
	user.put_in_hands(coin)
	var/obj/machinery/door/airlock/door = heretic_side_powered_door(heretic_side_spot(1, 0))
	var/obj/machinery/door/airlock/highsecurity/vault = heretic_side_powered_door(heretic_side_spot(0, 1), /obj/machinery/door/airlock/highsecurity)
	user.a_intent = INTENT_HARM
	TEST_ASSERT_EQUAL(coin.heretic_flip(user), 1, "На «Вреде» монета болтирует один шлюз.")
	TEST_ASSERT(door.locked, "Обычный шлюз на болтах.")
	TEST_ASSERT(!vault.locked, "Дверь высокой защиты монету не слушается.")
	TEST_ASSERT_EQUAL(coin.heretic_flip(user), 0, "Повторный подброс ждёт перезарядки.")
	COOLDOWN_RESET(coin, door_cooldown)
	coin.heretic_flip(user)
	TEST_ASSERT(!door.locked, "Второй подброс на «Вреде» поднимает болты.")
	COOLDOWN_RESET(coin, door_cooldown)
	user.a_intent = INTENT_HELP
	TEST_ASSERT_EQUAL(coin.heretic_flip(user), 1, "На «Помощи» монета открывает шлюз.")
	TEST_ASSERT(wait_for_var(door, "density", FALSE, 3 SECONDS), "Шлюз открылся.")
	COOLDOWN_RESET(coin, door_cooldown)
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs, user)
	user.handcuffed = cuffs
	user.update_handcuffed()
	TEST_ASSERT_EQUAL(coin.heretic_flip(user), 0, "Скованному монета не помогает.")
	user.uncuff()
	var/mob/living/carbon/human/heathen = allocate(/mob/living/carbon/human, heretic_side_spot(2, 2))
	var/brain_before = heathen.getOrganLoss(ORGAN_SLOT_BRAIN)
	coin.after_coin_flip_success(heathen)
	TEST_ASSERT_EQUAL(heathen.getOrganLoss(ORGAN_SLOT_BRAIN) - brain_before, HERETIC_COIN_BRAIN_DAMAGE, "Неверный платит мозгом за подброс.")

/// Поножи на еретике держат на скользком и от толчка; неверного только замедляют.
/datum/unit_test/heretic_side_greaves/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/clothing/shoes/heretic_greaves/greaves = heretic_side_craft(heretic, /datum/eldritch_knowledge/prophet_greaves)
	if(!greaves)
		return
	TEST_ASSERT(user.equip_to_slot_if_possible(greaves, ITEM_SLOT_FEET, disable_warning = TRUE), "Еретик обувает поножи.")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_NOSLIPALL), "В поножах еретик не поскальзывается даже на смазке.")
	TEST_ASSERT(user.is_shove_knockdown_blocked(), "Толчок не валит еретика в поножах.")
	TEST_ASSERT_EQUAL(greaves.slowdown, 0, "Еретика поножи не замедляют.")
	user.dropItemToGround(greaves)
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOSLIPALL) && !user.is_shove_knockdown_blocked(), "Снятые поножи больше не держат.")
	var/mob/living/carbon/human/heathen = allocate(/mob/living/carbon/human, heretic_side_spot(2, 2))
	TEST_ASSERT(heathen.equip_to_slot_if_possible(greaves, ITEM_SLOT_FEET, disable_warning = TRUE), "Неверный обувает поножи.")
	TEST_ASSERT_EQUAL(greaves.slowdown, HERETIC_GREAVES_HEATHEN_SLOWDOWN, "Неверного поножи замедляют.")
	TEST_ASSERT(!HAS_TRAIT(heathen, TRAIT_NOSLIPALL) && !heathen.is_shove_knockdown_blocked(), "Неверному поножи не помогают.")

/// Янтарь на шее еретика гасит вспышку; неверному мутит взгляд и не бережёт.
/datum/unit_test/heretic_side_focus/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/clothing/neck/heretic_focus/focus = heretic_side_craft(heretic, /datum/eldritch_knowledge/amber_focus)
	if(!focus)
		return
	TEST_ASSERT(user.equip_to_slot_if_possible(focus, ITEM_SLOT_NECK, disable_warning = TRUE), "Еретик надевает подвеску.")
	TEST_ASSERT(!user.flash_act(1), "Вспышка не слепит еретика с янтарём.")
	user.dropItemToGround(focus)
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOFLASH), "Снятая подвеска больше не бережёт.")
	var/mob/living/carbon/human/heathen = allocate(/mob/living/carbon/human, heretic_side_spot(2, 2))
	TEST_ASSERT(heathen.equip_to_slot_if_possible(focus, ITEM_SLOT_NECK, disable_warning = TRUE), "Неверный надевает подвеску.")
	TEST_ASSERT(heathen.eye_blurry > 0, "Неверному янтарь мутит взгляд.")
	TEST_ASSERT(heathen.flash_act(1), "Неверного подвеска от вспышки не бережёт.")

/// Эфир исцеляет еретика до конца и усыпляет; неверного травит.
/datum/unit_test/heretic_side_ether/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/heretic_ether/ether = heretic_side_craft(heretic, /datum/eldritch_knowledge/newborn_ether)
	if(!ether)
		return
	user.adjustBruteLoss(60)
	user.adjustFireLoss(30)
	ether.drink(user)
	TEST_ASSERT_EQUAL(user.getBruteLoss() + user.getFireLoss(), 0, "Эфир снимает весь урон.")
	TEST_ASSERT(user.IsSleeping(), "После эфира еретик засыпает.")
	TEST_ASSERT(QDELETED(ether), "Флакон выпит до дна.")
	var/mob/living/carbon/human/heathen = allocate(/mob/living/carbon/human, heretic_side_spot(2, 2))
	var/obj/item/heretic_ether/poison = allocate(/obj/item/heretic_ether, heathen)
	heathen.adjustBruteLoss(20)
	poison.drink(heathen)
	TEST_ASSERT(heathen.getToxLoss() > HERETIC_ETHER_HEATHEN_TOX / 2, "Неверному эфир - яд: [heathen.getToxLoss()] токсинов.")
	TEST_ASSERT_EQUAL(heathen.getBruteLoss(), 20, "Неверного эфир не лечит.")
	TEST_ASSERT(!heathen.IsSleeping(), "Неверного эфир не усыпляет.")

/// Карта связывает два шлюза: касание или шаг в проём переносит еретика, бег - нет; ходов не больше двух; Библия, снос двери и неверный.
/datum/unit_test/heretic_side_backdoor/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(heretic_side_spot(0, 2))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/heretic_backdoor_card/card = heretic_side_craft(heretic, /datum/eldritch_knowledge/backdoor_keys)
	if(!card)
		return
	var/obj/machinery/door/airlock/first = heretic_side_powered_door(heretic_side_spot(1, 2))
	var/obj/machinery/door/airlock/second = heretic_side_powered_door(heretic_side_spot(3, 2))
	card.melee_attack_chain(user, first)
	TEST_ASSERT_EQUAL(card.pending_door?.resolve(), first, "Касание картой отмечает первую дверь.")
	user.forceMove(heretic_side_spot(4, 2))
	TEST_ASSERT(card.use_on_door(second, user), "Вторая дверь связывается с первой.")
	TEST_ASSERT_EQUAL(length(card.portals), 2, "Ход - два знака скважины.")
	TEST_ASSERT(card.use_on_door(second, user), "Касание связанной двери переносит.")
	TEST_ASSERT_EQUAL(get_turf(user), heretic_side_spot(0, 2), "Еретик выходит там, где стоял у первой двери.")
	user.heretic_backdoor_ready = 0
	user.m_intent = MOVE_INTENT_RUN
	user.forceMove(get_turf(first))
	TEST_ASSERT_EQUAL(get_turf(user), get_turf(first), "Бегом через проём еретик просто проходит дверь.")
	user.m_intent = MOVE_INTENT_WALK
	user.forceMove(heretic_side_spot(0, 2))
	user.forceMove(get_turf(first))
	TEST_ASSERT_EQUAL(get_turf(user), heretic_side_spot(4, 2), "Шагом через связанный проём еретик выходит у второй двери.")
	var/list/doors = list()
	for(var/dx in 0 to 3)
		doors += heretic_side_powered_door(heretic_side_spot(dx, 4))
	card.link_doors(doors[1], NORTH, doors[2], NORTH, user)
	card.link_doors(doors[3], NORTH, doors[4], NORTH, user)
	TEST_ASSERT_EQUAL(length(card.portals), HERETIC_BACKDOOR_PAIRS * 2, "Карта держит не больше [HERETIC_BACKDOOR_PAIRS] ходов.")
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_backdoor) in get_turf(first), "Новый ход стирает самый старый.")
	var/mob/living/carbon/human/chaplain = allocate(/mob/living/carbon/human, heretic_side_spot(4, 3))
	var/obj/item/storage/book/bible/bible = allocate(/obj/item/storage/book/bible, chaplain)
	var/obj/machinery/door/airlock/sealed = doors[1]
	var/list/examine_lines = sealed.examine(chaplain)
	TEST_ASSERT(findtext(jointext(examine_lines, " "), "нулевым жезлом"), "Осмотр двери подсказывает, как стереть ход.")
	chaplain.forceMove(heretic_side_spot(0, 3))
	chaplain.a_intent = INTENT_HARM
	bible.melee_attack_chain(chaplain, sealed)
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_backdoor) in get_turf(doors[2]), "Библия о дверь стирает ход с обоих концов.")
	qdel(doors[4])
	TEST_ASSERT_EQUAL(length(card.portals), 0, "Снесённая дверь закрывает свой ход.")
	var/burn_before = chaplain.getFireLoss()
	TEST_ASSERT(!card.use_on_door(first, chaplain), "Неверному карта не открывает ход.")
	TEST_ASSERT_EQUAL(chaplain.getFireLoss() - burn_before, HERETIC_BACKDOOR_CARD_BURN, "Неверного карта обжигает.")

/// Ржавая граната ржавит пол и мутит неверного, но не еретика; неверный её не взведёт.
/datum/unit_test/heretic_side_rust_sower/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/grenade/heretic_rust_sower/sower = heretic_side_craft(heretic, /datum/eldritch_knowledge/rust_sower)
	if(!sower)
		return
	var/mob/living/carbon/human/heathen = allocate(/mob/living/carbon/human, heretic_side_spot(2, 2))
	var/obj/item/grenade/heretic_rust_sower/spare = allocate(/obj/item/grenade/heretic_rust_sower, heathen)
	spare.attack_self(heathen)
	TEST_ASSERT(!spare.active, "Неверный гранату не взводит.")
	TEST_ASSERT(heathen.disgust > 0, "Неверного мутит от ржавой чеки.")
	heathen.set_disgust(0)
	sower.forceMove(heretic_side_spot(2, 1))
	sower.primed_by = user
	sower.prime()
	TEST_ASSERT(QDELETED(sower), "Граната рвётся и исчезает.")
	TEST_ASSERT(istype(heretic_side_spot(2, 1), /turf/open/floor/plating/rust), "Взрыв ржавит пол.")
	TEST_ASSERT(heathen.disgust >= HERETIC_RUST_SOWER_DISGUST, "Неверного рядом тошнит.")
	TEST_ASSERT(heathen.eye_blurry > 0, "У неверного мутнеет взгляд.")
	TEST_ASSERT_EQUAL(user.disgust, 0, "Еретика ржавчина не трогает.")

/// Шёпот приходит адресату под выбранным именем; фольга глушит, скованный и с запрещённой подписью не шепчет.
/datum/unit_test/heretic_side_whisper/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/mansus_whisper)
	var/datum/eldritch_knowledge/spell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/mansus_whisper)
	TEST_ASSERT(istype(knowledge.granted_spell, /obj/effect/proc_holder/spell/self/mansus_whisper), "Знание даёт Шёпот изнанки.")
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, heretic_side_spot(4, 4))
	target.real_name = "Side Lore Listener"
	target.name = target.real_name
	GLOB.unit_test_chat_capture = list()
	TEST_ASSERT_NULL(heretic_whisper_send(user, target.real_name, "Капитан", "side-lore-whisper-1"), "Шёпот уходит.")
	TEST_ASSERT(antag_training_heard(target, "side-lore-whisper-1"), "Адресат слышит шёпот.")
	TEST_ASSERT(antag_training_heard(target, "Капитан"), "Шёпот подписан выбранным именем.")
	TEST_ASSERT(heretic_whisper_send(user, target.real_name, "<b>x</b>", "side-lore-whisper-2"), "Подпись с разметкой отклоняется.")
	var/obj/item/clothing/head/foilhat/foil = allocate(/obj/item/clothing/head/foilhat)
	target.equip_to_slot_if_possible(foil, ITEM_SLOT_HEAD, disable_warning = TRUE)
	TEST_ASSERT_NULL(heretic_whisper_send(user, target.real_name, "", "side-lore-whisper-3"), "Шёпот под фольгу уходит без отказа.")
	TEST_ASSERT(!antag_training_heard(target, "side-lore-whisper-3"), "Фольга глушит шёпот.")
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs, user)
	user.handcuffed = cuffs
	user.update_handcuffed()
	TEST_ASSERT(heretic_whisper_send(user, target.real_name, "", "side-lore-whisper-4"), "Скованный не шепчет.")
	TEST_ASSERT(!antag_training_heard(target, "side-lore-whisper-4"), "Шёпот скованного не доходит.")

/datum/unit_test/heretic_side_whisper/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/// Волна рвёт стяжки, роняет наручники и отбрасывает неверного, но не союзника; без отчаяния, в рубашке и оглушённым не колдуется.
/datum/unit_test/heretic_side_wave/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(heretic_side_spot(2, 2))
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wave_of_desperation)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/mansus_whisper)
	var/datum/eldritch_knowledge/spell/wave_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/wave_of_desperation)
	var/datum/eldritch_knowledge/spell/whisper_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/mansus_whisper)
	var/obj/effect/proc_holder/spell/wave = wave_knowledge.granted_spell
	var/obj/effect/proc_holder/spell/whisper = whisper_knowledge.granted_spell
	var/mob/living/carbon/human/heathen = allocate(/mob/living/carbon/human, heretic_side_spot(3, 2))
	var/datum/antagonist/heretic/ally_heretic = allocate_heretic(heretic_side_spot(1, 2))
	var/mob/living/carbon/human/ally = ally_heretic.owner.current
	TEST_ASSERT(!wave.can_cast(user, FALSE, TRUE), "На ногах и без оков Волна не колдуется.")
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs, user)
	user.handcuffed = cuffs
	user.update_handcuffed()
	TEST_ASSERT(!whisper.can_cast(user, FALSE, TRUE), "Прочие способности в наручниках молчат.")
	var/obj/item/clothing/suit/straight_jacket/jacket = allocate(/obj/item/clothing/suit/straight_jacket)
	user.equip_to_slot(jacket, ITEM_SLOT_OCLOTHING)
	TEST_ASSERT_EQUAL(user.wear_suit, jacket, "На еретика надета смирительная рубашка.")
	TEST_ASSERT(!wave.can_cast(user, FALSE, TRUE), "Смирительная рубашка держит и против Волны.")
	user.dropItemToGround(jacket, TRUE)
	user.Paralyze(5 SECONDS)
	TEST_ASSERT(!wave.can_cast(user, FALSE, TRUE), "Оглушённый Волну не соберёт.")
	user.SetParalyzed(0)
	TEST_ASSERT(wave.can_cast(user, FALSE, TRUE), "Скованный еретик может выпустить Волну.")
	wave.Trigger(user, FALSE)
	TEST_ASSERT_NULL(user.handcuffed, "Наручники сорваны.")
	TEST_ASSERT_EQUAL(cuffs.loc, get_turf(user), "Металлические наручники падают на пол.")
	TEST_ASSERT(heathen.IsKnockdown(), "Неверного рядом валит волной.")
	TEST_ASSERT(heathen.throwing, "Неверного отбрасывает.")
	TEST_ASSERT(!ally.IsKnockdown() && !ally.throwing, "Союзника волна не трогает.")
	TEST_ASSERT(wave.charge_counter < wave.charge_max, "Волна ушла на перезарядку.")
	var/collapse_timer = FALSE
	for(var/datum/timedevent/timer as anything in user.active_timers)
		if(findtext("[timer.callBack?.delegate]", "heretic_wave_collapse"))
			collapse_timer = TRUE
	TEST_ASSERT(collapse_timer, "После Волны еретика ждёт сон.")
	user.heretic_wave_collapse()
	TEST_ASSERT(user.IsSleeping(), "Сон после Волны наступает.")
	var/obj/item/restraints/handcuffs/cable/zipties/ties = allocate(/obj/item/restraints/handcuffs/cable/zipties, user)
	user.SetSleeping(0)
	user.handcuffed = ties
	user.update_handcuffed()
	wave.charge_counter = wave.charge_max
	wave.Trigger(user, FALSE)
	TEST_ASSERT(QDELETED(ties), "Стяжки рвутся.")

/// Лампы на виду перегорают, фонарики неверных гаснут, свет союзника остаётся.
/datum/unit_test/heretic_side_lights_out/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(heretic_side_spot(2, 2))
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lights_out)
	var/datum/eldritch_knowledge/spell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lights_out)
	var/obj/effect/proc_holder/spell/spell = knowledge.granted_spell
	var/obj/machinery/light/lamp = allocate(/obj/machinery/light, heretic_side_spot(4, 4))
	lamp.status = LIGHT_OK
	lamp.on = TRUE
	var/mob/living/carbon/human/heathen = allocate(/mob/living/carbon/human, heretic_side_spot(4, 2))
	var/obj/item/flashlight/heathen_torch = allocate(/obj/item/flashlight, heathen)
	heathen.put_in_hands(heathen_torch)
	heathen_torch.on = TRUE
	heathen_torch.update_brightness(heathen)
	var/obj/item/flashlight/floor_torch = allocate(/obj/item/flashlight, heretic_side_spot(0, 0))
	floor_torch.on = TRUE
	floor_torch.update_brightness()
	var/datum/antagonist/heretic/ally_heretic = allocate_heretic(heretic_side_spot(0, 4))
	var/mob/living/carbon/human/ally = ally_heretic.owner.current
	var/obj/item/flashlight/ally_torch = allocate(/obj/item/flashlight, ally)
	ally.put_in_hands(ally_torch)
	ally_torch.on = TRUE
	ally_torch.update_brightness(ally)
	spell.Trigger(user, FALSE)
	TEST_ASSERT_EQUAL(lamp.status, LIGHT_BURNED, "Лампа на виду перегорает.")
	TEST_ASSERT(!heathen_torch.on, "Фонарик неверного гаснет.")
	TEST_ASSERT(!floor_torch.on, "Фонарик на полу гаснет.")
	TEST_ASSERT(ally_torch.on, "Свет союзника не трогается.")
	TEST_ASSERT(spell.charge_counter < spell.charge_max, "Задуть огни ушло на перезарядку.")

/// В пустоту шагают только с космоса, плывут только по нему, выходят наружу; потеря знания выбрасывает.
/datum/unit_test/heretic_side_space_phase/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(heretic_side_spot(0, 0))
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/space_phase)
	var/datum/eldritch_knowledge/spell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/space_phase)
	var/obj/effect/proc_holder/spell/spell = knowledge.granted_spell
	TEST_ASSERT(!spell.can_cast(user, FALSE, TRUE), "С пола в пустоту не шагнуть.")
	for(var/dx in 0 to 2)
		var/turf/void = heretic_side_spot(dx, 0)
		void.ChangeTurf(/turf/open/space)
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "С клетки космоса шагнуть можно.")
	spell.Trigger(user, FALSE)
	var/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/holder = user.loc
	TEST_ASSERT(istype(holder), "Еретик растворился в пустоте.")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_NOBREATH) && HAS_TRAIT(user, TRAIT_RESISTLOWPRESSURE) && HAS_TRAIT(user, TRAIT_RESISTCOLD), "В пустоте еретик не дышит и не страдает от вакуума.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Вход не тратит перезарядку.")
	holder.relaymove(user, EAST)
	TEST_ASSERT_EQUAL(get_turf(holder), heretic_side_spot(1, 0), "По космосу еретик плывёт.")
	holder.movedelay = 0
	holder.relaymove(user, NORTH)
	TEST_ASSERT_EQUAL(get_turf(holder), heretic_side_spot(1, 0), "На пол из пустоты не проплыть.")
	spell.Trigger(user, FALSE)
	TEST_ASSERT(QDELETED(holder), "Повторное применение выводит наружу.")
	TEST_ASSERT_EQUAL(user.loc, heretic_side_spot(1, 0), "Еретик выходит там, где плыл.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOBREATH), "Снаружи еретик снова дышит.")
	TEST_ASSERT(spell.charge_counter < spell.charge_max, "Выход запускает перезарядку.")
	var/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/second = new(get_turf(user))
	second.take(user)
	knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(second) && isturf(user.loc), "Потеря знания выбрасывает из пустоты.")
	var/mob/living/carbon/human/doomed = allocate(/mob/living/carbon/human, heretic_side_spot(2, 0))
	var/obj/effect/dummy/phased_mob/spell_jaunt/heretic_void/third = new(get_turf(doomed))
	third.take(doomed)
	qdel(doomed)
	sleep(2)
	TEST_ASSERT(QDELETED(third), "Оболочка уходит вслед за удалённым пассажиром.")
