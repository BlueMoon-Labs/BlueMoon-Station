/datum/unit_test/proc/allocate_dance_heretic(turf/location)
	var/datum/antagonist/heretic/heretic = allocate_heretic(location)
	heretic.research_knowledge(/datum/eldritch_knowledge/base_dance, heretic.owner.current)
	return heretic

/datum/unit_test/proc/allocate_dance_victim(turf/location)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, location || run_loc_floor_bottom_left)
	victim.mind_initialize()
	return victim

/// Ставит часы так, чтобы сейчас была доля номер index со смещением offset в децисекундах.
/datum/unit_test/proc/set_dance_beat(datum/eldritch_knowledge/base_dance/dance, index, offset = 0)
	dance.beat_origin = world.time - index * dance.beat_ds - offset

/// Точность по доле: точно, в долю, мимо и сильная доля такта.
/datum/unit_test/heretic_dance_timing/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	TEST_ASSERT_EQUAL(dance.style_id, HERETIC_DANCE_STYLE_WALTZ, "Путь начинается с Вальса.")
	set_dance_beat(dance, 3)
	TEST_ASSERT_EQUAL(dance.timing(user), HERETIC_DANCE_PERFECT, "Клик ровно в долю - точно.")
	TEST_ASSERT(dance.last_timing_strong, "Третья доля Вальса - начало такта.")
	set_dance_beat(dance, 1, 2)
	TEST_ASSERT_EQUAL(dance.timing(user), HERETIC_DANCE_ON_BEAT, "Две десятых секунды от доли - в долю.")
	TEST_ASSERT(!dance.last_timing_strong, "Вторая доля не сильная.")
	set_dance_beat(dance, 1, 4)
	TEST_ASSERT_EQUAL(dance.timing(user), HERETIC_DANCE_MISS, "Между долями - мимо.")

/// Такт копится от любого удара, больше - в долю; с 4 работает пассивка, вне боя он тает.
/datum/unit_test/heretic_dance_takt/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	dance.register_strike(user, victim, HERETIC_DANCE_MISS, FALSE)
	TEST_ASSERT_EQUAL(dance.combat_resource, 1, "Удар мимо доли всё равно даёт Такт.")
	dance.register_strike(user, victim, HERETIC_DANCE_MISS, FALSE)
	TEST_ASSERT_EQUAL(dance.combat_resource, 1, "Удары мимо доли дают Такт не чаще раза в секунду.")
	dance.register_strike(user, victim, HERETIC_DANCE_ON_BEAT, FALSE)
	TEST_ASSERT_EQUAL(dance.combat_resource, 3, "Удар в долю даёт 2 Такта.")
	TEST_ASSERT(!dance.passive_active, "До 4 Такта пассивка стиля молчит.")
	dance.register_strike(user, victim, HERETIC_DANCE_PERFECT, FALSE)
	TEST_ASSERT_EQUAL(dance.combat_resource, 6, "Точный удар даёт 3 Такта.")
	TEST_ASSERT(dance.passive_active && user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz), "С 4 Такта Вальс ускоряет шаг.")
	dance.last_combat_at = world.time - HERETIC_DANCE_COMBAT_WINDOW - 1
	for(var/beat in 1 to 10)
		dance.decay_takt()
	TEST_ASSERT(dance.combat_resource < 6, "Вне боя Такт тает.")
	dance.combat_resource = 1
	dance.update_passive()
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz), "Растаявший Такт снимает пассивку.")

/// Смена стиля в сильную долю сохраняет Такт и удваивает акцент, мимо - делит Такт.
/datum/unit_test/heretic_dance_style_link/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	TEST_ASSERT(!dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO), "Танго закрыто до Хватки в долю.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	dance.combat_resource = 6
	dance.last_combat_at = world.time
	set_dance_beat(dance, 3)
	TEST_ASSERT(dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO), "Выученное Танго выбирается.")
	TEST_ASSERT_EQUAL(dance.combat_resource, 6, "Связка в сильную долю сохраняет Такт.")
	TEST_ASSERT(dance.link_bonus, "Связка удваивает следующий акцент.")
	TEST_ASSERT_EQUAL(dance.beat_ds, 7.5, "Часы идут в темпе Танго.")
	set_dance_beat(dance, 1, 3)
	TEST_ASSERT(dance.switch_style(user, HERETIC_DANCE_STYLE_WALTZ), "Обратно в Вальс.")
	TEST_ASSERT_EQUAL(dance.combat_resource, 3, "Смена мимо сильной доли делит Такт пополам.")

/// Фигура Вальса из четырёх шагов в долю подхватывает соседа в вальс.
/datum/unit_test/heretic_dance_figure_lead/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/partner = allocate_dance_victim(get_step(user, WEST))
	var/index = 1
	for(var/direction in list(NORTH, EAST, SOUTH))
		set_dance_beat(dance, index++)
		dance.on_dance_step(user, direction)
	TEST_ASSERT(!partner.has_status_effect(/datum/status_effect/heretic_dance/lead), "Три шага ещё не фигура.")
	set_dance_beat(dance, index)
	dance.on_dance_step(user, WEST)
	TEST_ASSERT(partner.has_status_effect(/datum/status_effect/heretic_dance/lead), "Квадрат Вальса подхватывает соседа.")
	var/turf/before = get_turf(user)
	user.Move(get_step(user, EAST), EAST)
	TEST_ASSERT_EQUAL(get_turf(partner), before, "Ведомый заходит на прежнюю клетку ведущего.")
	TEST_ASSERT(dance.door_holds(user, partner), "Ведомый открывает дверь в изнанку.")

/// Шаг мимо доли и два шага в одну долю рвут рисунок фигуры.
/datum/unit_test/heretic_dance_figure_reset/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	set_dance_beat(dance, 1)
	dance.on_dance_step(user, NORTH)
	dance.on_dance_step(user, EAST)
	TEST_ASSERT_EQUAL(length(dance.figure_steps), 0, "Два шага в одну долю рвут рисунок.")
	set_dance_beat(dance, 2)
	dance.on_dance_step(user, NORTH)
	set_dance_beat(dance, 3, 4)
	dance.on_dance_step(user, EAST)
	TEST_ASSERT_EQUAL(length(dance.figure_steps), 0, "Шаг мимо доли рвёт рисунок.")

/// Хватка в «Помощи» заражает человека; дефибриллятор, святая вода, сон и жезл лечат, заражённых не больше шести.
/datum/unit_test/heretic_dance_earworm/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	user.a_intent = INTENT_HELP
	dance.on_mansus_grasp(victim, user, TRUE)
	var/datum/status_effect/heretic_dance_earworm/earworm = victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	TEST_ASSERT_NOTNULL(earworm, "Хватка в «Помощи» заражает человека.")
	SEND_SIGNAL(victim, COMSIG_LIVING_ELECTROCUTE_ACT, 10)
	TEST_ASSERT(QDELETED(earworm), "Разряд тока лечит навязчивый такт.")
	dance.infect(user, victim)
	earworm = victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	victim.reagents.add_reagent(/datum/reagent/water/holywater, 5)
	earworm.tick()
	TEST_ASSERT(QDELETED(earworm), "Святая вода лечит навязчивый такт.")
	victim.reagents.clear_reagents()
	dance.infect(user, victim)
	earworm = victim.has_status_effect(/datum/status_effect/heretic_dance_earworm)
	victim.SetSleeping(30 SECONDS)
	for(var/tick in 1 to 5)
		earworm.tick()
	TEST_ASSERT(QDELETED(earworm), "Десять секунд сна лечат навязчивый такт.")
	victim.SetSleeping(0)
	var/list/infected = list()
	for(var/count in 1 to HERETIC_DANCE_EARWORM_LIMIT + 1)
		var/mob/living/carbon/human/extra = allocate_dance_victim()
		dance.infect(user, extra)
		infected += extra
	TEST_ASSERT_EQUAL(length(dance.earworms), HERETIC_DANCE_EARWORM_LIMIT, "Заражённых не больше шести.")
	var/mob/living/carbon/human/first = infected[1]
	TEST_ASSERT(!first.has_status_effect(/datum/status_effect/heretic_dance_earworm), "Седьмое заражение вытесняет самое старое.")

/// Схема шагов идёт в дело, заражает прошедших, блёкнет после трёх и стирается шваброй; к ней ведёт выход изнанки.
/datum/unit_test/heretic_dance_diagram/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/turf/spot = get_step(user, EAST)
	user.a_intent = INTENT_HELP
	var/progress = heretic.deed.progress
	TEST_ASSERT(dance.on_mansus_grasp(spot, user, TRUE), "Хватка в «Помощи» по полу рисует схему.")
	var/obj/effect/heretic_dance_diagram/diagram = locate() in spot
	TEST_ASSERT_NOTNULL(diagram, "Схема лежит на полу.")
	TEST_ASSERT(heretic.deed.progress > progress || heretic.deed.tier > 0, "Новый отдел продвигает дело.")
	TEST_ASSERT(length(dance.pocket_exits(user)), "Схема - выход из изнанки.")
	for(var/count in 1 to HERETIC_DANCE_DIAGRAM_CHARGES)
		var/mob/living/carbon/human/walker = allocate_dance_victim(get_step(spot, NORTH))
		walker.forceMove(spot)
		TEST_ASSERT(walker.has_status_effect(/datum/status_effect/heretic_dance_earworm), "Прошедший по схеме подхватывает мелодию.")
	TEST_ASSERT(QDELETED(diagram), "После трёх заражений схема блёкнет.")
	TEST_ASSERT(dance.draw_diagram(user, spot), "На месте поблёкшей можно нарисовать новую.")
	diagram = locate() in spot
	SEND_SIGNAL(diagram, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
	TEST_ASSERT(QDELETED(diagram), "Швабра стирает схему.")

/// Слух: наушники-заглушки и глухота закрывают от музыки, шлем - нет.
/datum/unit_test/heretic_dance_hearing/Run()
	var/mob/living/carbon/human/listener = allocate_dance_victim()
	TEST_ASSERT(heretic_dance_can_hear(listener), "Обычный человек слышит музыку.")
	var/obj/item/clothing/head/helmet/sec/helmet = allocate(/obj/item/clothing/head/helmet/sec)
	listener.equip_to_slot_or_del(helmet, ITEM_SLOT_HEAD)
	TEST_ASSERT(heretic_dance_can_hear(listener), "Шлем СБ музыку не глушит.")
	var/obj/item/clothing/ears/earmuffs/muffs = allocate(/obj/item/clothing/ears/earmuffs)
	listener.equip_to_slot_or_del(muffs, ITEM_SLOT_EARS_LEFT)
	TEST_ASSERT(!heretic_dance_can_hear(listener), "Наушники-заглушки глушат музыку.")
	listener.dropItemToGround(muffs)
	ADD_TRAIT(listener, TRAIT_DEAF, "test")
	TEST_ASSERT(!heretic_dance_can_hear(listener), "Глухой музыку не слышит.")

/// Танго-приглашение рывком приводит заражённого, партнёр открывает дверь; заглушки и чужая хватка срывают.
/datum/unit_test/heretic_dance_invite/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_invite)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(get_step(user, EAST), EAST))
	TEST_ASSERT_NOTNULL(dance.invite_block_reason(user, victim), "Незаражённого не пригласить.")
	dance.infect(user, victim)
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT(dance.invite(user, victim), "Заражённого в 2 клетках можно пригласить.")
	var/datum/status_effect/heretic_dance/invited/invite = victim.has_status_effect(/datum/status_effect/heretic_dance/invited)
	TEST_ASSERT_NOTNULL(invite, "Приглашение держит цель.")
	invite.on_dance_beat(dance, 1, FALSE)
	TEST_ASSERT(get_dist(user, victim) > 1, "Первая доля Танго - только телеграф.")
	invite.on_dance_beat(dance, 2, FALSE)
	TEST_ASSERT(get_dist(user, victim) <= 1, "Танго рывком приводит цель вплотную.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_dance/partner), "Дошедшая цель - партнёр.")
	TEST_ASSERT(dance.door_holds(user, victim), "Партнёр открывает дверь в изнанку.")
	var/mob/living/carbon/human/muffled = allocate_dance_victim(get_step(user, NORTH))
	dance.infect(user, muffled)
	var/obj/item/clothing/ears/earmuffs/muffs = allocate(/obj/item/clothing/ears/earmuffs)
	muffled.equip_to_slot_or_del(muffs, ITEM_SLOT_EARS_LEFT)
	TEST_ASSERT_NOTNULL(dance.invite_block_reason(user, muffled), "Заглушки закрывают от Приглашения.")

/// Срыв приглашения чужой хваткой на телеграфе возвращает перезарядку.
/datum/unit_test/heretic_dance_invite_break/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_invite)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(get_step(user, EAST), EAST))
	var/mob/living/carbon/human/helper = allocate_dance_victim(get_step(victim, NORTH))
	dance.infect(user, victim)
	TEST_ASSERT(dance.invite(user, victim), "Приглашение начинается.")
	var/datum/status_effect/heretic_dance/invited/invite = victim.has_status_effect(/datum/status_effect/heretic_dance/invited)
	helper.start_pulling(victim)
	TEST_ASSERT_NOTNULL(invite.hold_reason(), "Чужая хватка держит цель.")
	invite.on_dance_beat(dance, 1, FALSE)
	TEST_ASSERT(QDELETED(invite), "Удержанная цель выходит из танца.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_capture_immunity) == null, "Несостоявшийся захват не даёт невосприимчивости.")

/// Маскарад надевает одну маску на еретика и заражённых рядом; попадание разбивает маску.
/datum/unit_test/heretic_dance_masquerade/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_masquerade)
	var/mob/living/carbon/human/dancer = allocate_dance_victim(get_step(user, EAST))
	dance.infect(user, dancer)
	TEST_ASSERT(dance.start_masquerade(user), "Маскарад начинается.")
	TEST_ASSERT_EQUAL(user.name_override, "танцор в маске", "Имя еретика скрыто.")
	TEST_ASSERT(dancer.has_status_effect(/datum/status_effect/heretic_dance/masked), "Заражённый рядом тоже под маской.")
	TEST_ASSERT_EQUAL(dancer.name_override, "танцор в маске", "Имя заражённого скрыто.")
	TEST_ASSERT(!dance.start_masquerade(user), "Второй маскарад поверх первого не начинается.")
	dancer.apply_damage(5, BRUTE)
	TEST_ASSERT(!dancer.has_status_effect(/datum/status_effect/heretic_dance/masked), "Попадание разбивает маску.")
	TEST_ASSERT_NULL(dancer.name_override, "Разбитая маска возвращает имя.")
	user.remove_status_effect(/datum/status_effect/heretic_dance/masquerade)
	TEST_ASSERT_NULL(user.name_override, "Конец маскарада возвращает имя еретику.")

/// Колокол за 4 Такта тянет стоящих соседей в хоровод, лежачих - нет; втянутые повторяют шаги и выматываются.
/datum/unit_test/heretic_dance_bell/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_bell)
	var/mob/living/carbon/human/stander = allocate_dance_victim(get_step(user, NORTH))
	var/mob/living/carbon/human/lier = allocate_dance_victim(get_step(user, SOUTH))
	lier.set_resting(TRUE, TRUE)
	dance.combat_resource = 3
	TEST_ASSERT(!dance.ring_bell(user), "Без 4 Такта колокол не звонит.")
	dance.combat_resource = 4
	TEST_ASSERT(dance.ring_bell(user), "Колокол звонит за 4 Такта.")
	TEST_ASSERT_EQUAL(dance.combat_resource, 0, "Колокол тратит 4 Такта.")
	TEST_ASSERT(stander.has_status_effect(/datum/status_effect/heretic_dance/horovod), "Стоящий втянут в хоровод.")
	TEST_ASSERT(!lier.has_status_effect(/datum/status_effect/heretic_dance/horovod), "Лежачий не пляшет.")
	var/turf/expected = get_step(stander, EAST)
	user.Move(get_step(user, EAST), EAST)
	TEST_ASSERT(wait_for_var(stander, NAMEOF(stander, loc), expected), "Втянутый повторяет шаг еретика.")
	TEST_ASSERT_EQUAL(stander.getStaminaLoss(), HERETIC_DANCE_HOROVOD_STAMINA, "Каждый шаг хоровода выматывает.")

/// Тарантелла: пять укусов срывают цель в неконтролируемую пляску.
/datum/unit_test/heretic_dance_tarantism/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	for(var/bite in 1 to 4)
		victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
	var/datum/status_effect/heretic_dance/tarantism/stacks = victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism)
	TEST_ASSERT_EQUAL(stacks?.stacks, 4, "Укусы копят тарантизм.")
	stacks.on_dance_beat(dance, 1, FALSE)
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "Слабая доля не выматывает.")
	stacks.on_dance_beat(dance, 0, TRUE)
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 16, "Сильная доля выматывает по 4 за стак.")
	victim.apply_status_effect(/datum/status_effect/heretic_dance/tarantism, dance)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_dance/frenzy), "Пятый укус срывает в пляску.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism), "Сорвавшийся в пляску сбрасывает стаки.")

/// Барабан в долю отыгрывает ослабленный акцент стиля по заражённым; не чаще раза в 4 доли.
/datum/unit_test/heretic_dance_drum/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_drum)
	var/obj/item/heretic_path_relic/dance/drum = allocate(/obj/item/heretic_path_relic/dance, get_turf(user))
	drum.creator = WEAKREF(heretic.owner)
	drum.knowledge_ref = WEAKREF(heretic.get_knowledge(/datum/eldritch_knowledge/spell/dance_drum))
	TEST_ASSERT(user.put_in_hands(drum), "Барабан берётся в руку.")
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(get_step(user, EAST), EAST))
	dance.infect(user, victim)
	set_dance_beat(dance, 1, 4)
	TEST_ASSERT(drum.beat(user), "Барабан бьёт.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 5, "Вне доли барабан лишь выматывает.")
	TEST_ASSERT(!drum.beat(user), "Барабан ждёт 4 доли.")
	drum.ready_beat = 0
	set_dance_beat(dance, 2)
	victim.confused = 0
	TEST_ASSERT(drum.beat(user), "Барабан в долю бьёт снова.")
	TEST_ASSERT(victim.confused > 0, "Ослабленный акцент Вальса путает заражённого.")

/// Сердце не останавливается: с 4 Такта сбивание с ног короче.
/datum/unit_test/heretic_dance_heart/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_heart)
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_STABLEHEART), "Сердце еретика не встаёт.")
	user.Knockdown(4 SECONDS)
	TEST_ASSERT(user.AmountKnockdown() > 3.9 SECONDS, "Без Такта сбивание полное.")
	user.SetKnockdown(0)
	dance.combat_resource = HERETIC_DANCE_PASSIVE_TAKT
	user.Knockdown(4 SECONDS)
	TEST_ASSERT(user.AmountKnockdown() <= 3 SECONDS + 1, "С 4 Такта сбивание короче на четверть.")

/// Болеро поднимает ступень со временем, фальшивая нота сбивает её и глушит музыку, но не чаще раза в 15 секунд.
/datum/unit_test/heretic_dance_bolero/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	dance.start_bolero()
	TEST_ASSERT(dance.bolero_active(), "Болеро играет.")
	dance.bolero_next_at = world.time
	dance.bolero_beat(FALSE)
	TEST_ASSERT_EQUAL(dance.bolero_stage, 1, "Ступень растёт со временем.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz), "Первая ступень навсегда даёт пассивку Вальса.")
	heretic_dance_false_note(get_turf(user))
	TEST_ASSERT_EQUAL(dance.bolero_stage, 0, "Фальшивая нота сбивает ступень.")
	TEST_ASSERT(!dance.bolero_active(), "Фальшивая нота глушит Болеро.")
	dance.bolero_silent_until = 0
	dance.bolero_next_at = world.time
	dance.bolero_beat(FALSE)
	heretic_dance_false_note(get_turf(user))
	TEST_ASSERT_EQUAL(dance.bolero_stage, 1, "Вторая нота подряд Болеро не сбивает.")
	dance.stop_bolero()
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_dance_waltz), "Конец Болеро снимает его пассивки.")

/// Связка в бою даёт вход стиля, три разных стиля за 20 секунд - Попурри; пассивка стиля включает ауру, значок показывает стиль.
/datum/unit_test/heretic_dance_entrances/Run()
	var/datum/antagonist/heretic/heretic = allocate_dance_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_dance/dance = heretic.get_knowledge(/datum/eldritch_knowledge/base_dance)
	heretic.gain_knowledge(/datum/eldritch_knowledge/dance_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/dance_drum)
	var/mob/living/carbon/human/victim = allocate_dance_victim(get_step(user, EAST))
	var/datum/status_effect/heretic_dance_style/status = user.has_status_effect(/datum/status_effect/heretic_dance_style)
	TEST_ASSERT_NOTNULL(status, "Значок стиля появляется с путём.")
	dance.combat_resource = 6
	dance.update_passive()
	TEST_ASSERT_NOTNULL(dance.aura, "Пассивка стиля включает ауру.")
	dance.last_combat_at = world.time
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT(dance.entrance_strike_until >= world.time, "Вход в Танго усиливает следующий удар.")
	TEST_ASSERT_EQUAL(status.linked_alert.icon_state, "dance_style_tango", "Значок показывает Танго.")
	dance.last_combat_at = world.time
	set_dance_beat(dance, 4)
	dance.switch_style(user, HERETIC_DANCE_STYLE_WALTZ)
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_dance_glide), "Вход в Вальс ускоряет.")
	dance.last_combat_at = world.time
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TARANTELLA)
	var/datum/status_effect/heretic_dance/tarantism/bite = victim.has_status_effect(/datum/status_effect/heretic_dance/tarantism)
	TEST_ASSERT_EQUAL(bite?.stacks, 2, "Третий стиль за 20 секунд - Попурри: вход Тарантеллы вдвойне.")
	dance.last_combat_at = -INFINITY
	set_dance_beat(dance, 6)
	dance.switch_style(user, HERETIC_DANCE_STYLE_WALTZ)
	user.remove_status_effect(/datum/status_effect/heretic_dance_glide)
	set_dance_beat(dance, 3)
	dance.switch_style(user, HERETIC_DANCE_STYLE_TANGO)
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_dance_glide), "Вне боя входов нет.")
