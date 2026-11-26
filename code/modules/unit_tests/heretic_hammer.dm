/// Еретик Молота с выбранным путём и знаниями extra на клетке (1, 2).
/datum/unit_test/proc/hammer_test_heretic(list/extra)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_HAMMER)
	for(var/knowledge_type in extra)
		heretic.gain_knowledge(knowledge_type)
	heretic.owner.current.forceMove(heretic_lead_test_spot(1, 2))
	return heretic

/datum/unit_test/proc/hammer_test_knowledge(datum/antagonist/heretic/heretic)
	return heretic.get_knowledge(/datum/eldritch_knowledge/base_hammer)

/datum/unit_test/proc/hammer_test_hammer(mob/living/carbon/human/user, wield = TRUE, hammer_type = /obj/item/melee/sickly_blade/hammer)
	var/obj/item/melee/sickly_blade/hammer/hammer = allocate(hammer_type, get_turf(user))
	// Рана от удара множит следующий урон по той же части тела и сбивает точный счёт бонусов Молота.
	hammer.wound_bonus = CANT_WOUND
	user.put_in_hands(hammer)
	if(wield)
		hammer.attack_self(user)
	return hammer

/datum/unit_test/proc/hammer_test_inhand(obj/item/melee/sickly_blade/hammer/hammer, expected_state)
	TEST_ASSERT_EQUAL(hammer.item_state, expected_state, "[hammer] в руках - [expected_state].")
	TEST_ASSERT_EQUAL("[hammer.lefthand_file]", "modular_bluemoon/icons/obj/heretic_blades_hammer_lefthand.dmi", "Левая рука держит Молот из файла рук Молота.")
	TEST_ASSERT_EQUAL("[hammer.righthand_file]", "modular_bluemoon/icons/obj/heretic_blades_hammer_righthand.dmi", "Правая рука держит Молот из файла рук Молота.")
	TEST_ASSERT(hammer.inhand_x_dimension == 64 && hammer.inhand_y_dimension == 64, "Молот в руках рисуется на холсте 64x64.")
	var/mob/living/carbon/holder = hammer.loc
	var/list/hands = holder.overlays_standing[HANDS_LAYER]
	var/shown = FALSE
	for(var/mutable_appearance/held as anything in hands)
		if(held.icon_state == expected_state && (held.icon_state in icon_states(held.icon)))
			TEST_ASSERT(held.pixel_x == -16 && held.pixel_y == -16, "Кукла Молота стоит по центру холста 64: [held.pixel_x],[held.pixel_y].")
			shown = TRUE
	TEST_ASSERT(shown, "Руки сразу перерисованы под [expected_state].")

/datum/unit_test/proc/hammer_test_hit(mob/living/carbon/human/user, obj/item/melee/sickly_blade/hammer/hammer, mob/living/target, intent = INTENT_HARM)
	user.a_intent = intent
	user.adjustStaminaLoss(-user.getStaminaLoss())
	user.stamina_buffer = 100
	hammer.attack(target, user)

/datum/unit_test/proc/hammer_test_douse(atom/target, amount)
	var/datum/reagents/water = new(amount)
	water.add_reagent(/datum/reagent/water, amount)
	water.reaction(target, TOUCH)
	qdel(water)

/datum/unit_test/proc/hammer_test_heal(mob/living/target)
	target.adjustBruteLoss(-target.getBruteLoss())
	target.SetKnockdown(0)

/datum/unit_test/proc/hammer_test_pinned(datum/eldritch_knowledge/base_hammer/hammer_k, turf/spot)
	var/mob/living/carbon/human/victim = heretic_lead_test_crew(spot)
	victim.Knockdown(HERETIC_HAMMER_NAIL_TIME)
	TEST_ASSERT(victim.apply_status_effect(/datum/status_effect/heretic_hammer_nailed, hammer_k), "Цель вбита в пол.")
	return victim

/// Резерв тестов лежит в зоне космоса, а у космоса Таран стен не ломает: комната должна быть внутренней.
/datum/unit_test/proc/hammer_test_indoors()
	for(var/dx in -2 to 6)
		for(var/dy in -2 to 6)
			heretic_test_area(heretic_lead_test_spot(dx, dy), /area/testroom)

/proc/heretic_hammer_test_landed(mob/living/target)
	return !target.throwing && heretic_capture_downed(target)

/// Клетка резерва, заменённая на время теста; при удалении возвращает прежний тип.
/datum/heretic_hammer_test_turf
	var/turf/spot
	var/original_type

/datum/heretic_hammer_test_turf/New(turf/spot, new_type)
	src.spot = spot
	original_type = spot.type
	spot.ChangeTurf(new_type)

/datum/heretic_hammer_test_turf/Destroy()
	spot?.ChangeTurf(original_type)
	spot = null
	return ..()

/// Молот берут в две руки активацией: сила, пробой, скорость и спрайт меняются, а побег уходит на кнопку «Расколоть молот».
/datum/unit_test/heretic_hammer_wield/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/origin = get_turf(user)
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	TEST_ASSERT_EQUAL(hammer.force, HERETIC_HAMMER_FORCE, "Одной рукой Молот бьёт без силы пути.")
	GLOB.unit_test_chat_capture = list()
	hammer.attack_self(user)
	var/wield_text = ""
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		if(entry[1] == user)
			wield_text += entry[2]
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(findtext(wield_text, "[initial(hammer.name)] в обе руки") && !findtext(wield_text, "(Wielded)"), "Взяв Молот в две руки, видят его имя без пометки: [wield_text]")
	TEST_ASSERT(!QDELETED(hammer) && ISWIELDED(hammer), "Активация в руке берёт Молот в две руки, а не раскалывает его.")
	var/atom/movable/screen/alert/heretic_resource/indicator = user.alerts["heretic_path_resource"]
	TEST_ASSERT(indicator && !findtext(indicator.desc, "не в двух руках"), "Панель ресурса знает, что Молот взят в две руки: [indicator?.desc]")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Активация Молота не уводит в побег.")
	TEST_ASSERT_EQUAL(hammer.force, HERETIC_HAMMER_WIELDED_FORCE, "В двух руках Молот бьёт в полную силу.")
	TEST_ASSERT_EQUAL(hammer.armour_penetration, HERETIC_HAMMER_WIELDED_AP, "В двух руках Молот пробивает броню.")
	TEST_ASSERT_EQUAL(hammer.attack_speed, HERETIC_HAMMER_ATTACK_SPEED, "В двух руках Молот бьёт медленнее.")
	TEST_ASSERT_EQUAL(hammer.icon_state, "hammer_blade_wielded", "У Молота в двух руках свой спрайт.")
	TEST_ASSERT_EQUAL(hammer.item_state, "hammer_blade_wielded", "В руках Молот держат двумя руками.")
	hammer_test_inhand(hammer, "hammer_blade_wielded")
	var/obj/structure/table/table = allocate(/obj/structure/table, heretic_lead_test_spot(2, 2))
	TEST_ASSERT_EQUAL(hammer.get_damage_to_obj(table, user), HERETIC_HAMMER_WIELDED_FORCE * HERETIC_HAMMER_OBJECT_MULT, "Постройки Молот в двух руках бьёт в [HERETIC_HAMMER_OBJECT_MULT] раза сильнее.")
	hammer.attack_self(user)
	TEST_ASSERT(!ISWIELDED(hammer), "Повторная активация отпускает вторую руку.")
	TEST_ASSERT_EQUAL(hammer.force, HERETIC_HAMMER_FORCE, "Отпущенный Молот снова слаб.")
	TEST_ASSERT_EQUAL(hammer.armour_penetration, HERETIC_HAMMER_ONEHAND_AP, "Одной рукой Молот пробивает броню вдвое слабее.")
	TEST_ASSERT_EQUAL(hammer.item_state, "hammer_blade", "Отпущенный Молот держат одной рукой.")
	hammer_test_inhand(hammer, "hammer_blade")
	TEST_ASSERT_EQUAL(hammer.get_damage_to_obj(table, user), HERETIC_HAMMER_FORCE, "Одной рукой постройки - без множителя.")
	var/datum/action/item_action/heretic_escape/hammer/escape
	for(var/datum/action/action as anything in hammer.actions)
		if(istype(action, /datum/action/item_action/heretic_escape/hammer))
			escape = action
	TEST_ASSERT_NOTNULL(escape, "У Молота есть кнопка побега.")
	TEST_ASSERT(findtext(escape.name, "Расколоть молот"), "Кнопка побега зовётся «Расколоть молот»: [escape.name]")
	ADD_TRAIT(user, TRAIT_HERETIC_ASCENDED, TRAIT_GENERIC)
	escape.Trigger()
	TEST_ASSERT(!QDELETED(hammer) && (hammer in user.held_items), "Вознёсшийся не раскалывает Молот.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Отказ побега оставляет на месте.")
	REMOVE_TRAIT(user, TRAIT_HERETIC_ASCENDED, TRAIT_GENERIC)
	TEST_ASSERT(findtext(hammer.escape_examine(), "«Расколоть молот»"), "Осмотр называет кнопку побега Молота.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/obj/item/melee/sickly_blade/hammer/seized = allocate(/obj/item/melee/sickly_blade/hammer, get_turf(crew))
	crew.put_in_hands(seized)
	seized.attack_self(crew)
	TEST_ASSERT(QDELETED(seized), "Экипаж, перехватив Молот второй рукой, раскалывает его.")

/// Молот сильнее простого клинка пути: в двух руках больше урона в секунду при той же бронебойности и сильнее ранит, одной рукой бьёт ощутимо.
/datum/unit_test/heretic_hammer_outclasses_blade/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	var/obj/item/melee/sickly_blade/blade = allocate(/obj/item/melee/sickly_blade)
	var/mob/living/carbon/human/target = hammer_test_exact_crew(heretic_lead_test_spot(2, 2))
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(target.getBruteLoss(), HERETIC_HAMMER_FORCE, "Одной рукой Молот бьёт на [HERETIC_HAMMER_FORCE].")
	TEST_ASSERT_EQUAL(hammer.armour_penetration * 2, HERETIC_HAMMER_WIELDED_AP, "Одной рукой Молот пробивает броню вдвое слабее, чем двумя.")
	hammer_test_heal(target)
	hammer.attack_self(user)
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(target.getBruteLoss(), HERETIC_HAMMER_WIELDED_FORCE, "В двух руках Молот бьёт на [HERETIC_HAMMER_WIELDED_FORCE].")
	TEST_ASSERT(hammer.force / hammer.attack_speed > blade.force / blade.attack_speed, "В двух руках Молот даёт больше урона в секунду, чем клинок пути: [hammer.force]/[hammer.attack_speed] против [blade.force]/[blade.attack_speed].")
	TEST_ASSERT(hammer.armour_penetration >= blade.armour_penetration, "В двух руках Молот пробивает броню не хуже клинка пути.")
	TEST_ASSERT(hammer.bare_wound_bonus > blade.bare_wound_bonus, "В двух руках Молот ранит открытое тело сильнее клинка пути.")
	hammer.attack_self(user)
	TEST_ASSERT_EQUAL(hammer.bare_wound_bonus, initial(hammer.bare_wound_bonus), "Отпущенный Молот ранит как прежде.")

/// Стойка кузнеца: в двух руках ушибы от ударов и снарядов слабее, выносливость - нет, удар по врагу лечит; одной рукой и остуженным Молотом - ничего.
/datum/unit_test/heretic_hammer_stance/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	ADD_TRAIT(user, TRAIT_NOHUNGER, "heretic_hammer_test")
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox, get_turf(crew))
	crew.put_in_hands(toolbox)
	var/list/open = hammer_test_take_hits(user, crew, toolbox)
	hammer.attack_self(user)
	var/list/braced = hammer_test_take_hits(user, crew, toolbox)
	TEST_ASSERT(open["melee"] > 0 && abs(braced["melee"] - open["melee"] * (1 - HERETIC_HAMMER_STANCE_CUT / 100)) < 0.1, "В стойке удар ящиком слабее на [HERETIC_HAMMER_STANCE_CUT]%: [braced["melee"]] против [open["melee"]].")
	TEST_ASSERT(abs(braced["bullet"] - open["bullet"] * (1 - HERETIC_HAMMER_STANCE_CUT / 100)) < 0.1, "В стойке пуля слабее на [HERETIC_HAMMER_STANCE_CUT]%: [braced["bullet"]] против [open["bullet"]].")
	TEST_ASSERT_EQUAL(braced["stamina"], open["stamina"], "Урон выносливости стойка не режет.")
	user.adjustBruteLoss(10)
	user.adjustFireLoss(10)
	COOLDOWN_RESET(hammer_k, hit_gain)
	hammer_test_hit(user, hammer, crew)
	TEST_ASSERT(abs(user.getBruteLoss() + user.getFireLoss() - (20 - HERETIC_HAMMER_FORGE_HEAL)) < 0.1 && abs(user.getBruteLoss() - user.getFireLoss()) < 0.1, "Удар по врагу лечит ушибы и ожоги поровну: [user.getBruteLoss()] и [user.getFireLoss()].")
	hammer_test_heal(crew)
	hammer_test_hit(user, hammer, crew)
	TEST_ASSERT(abs(user.getBruteLoss() + user.getFireLoss() - (20 - HERETIC_HAMMER_FORGE_HEAL)) < 0.1, "Жар горна - не чаще раза в секунду.")
	COOLDOWN_RESET(hammer_k, hit_gain)
	hammer_k.quench("вода")
	hammer_test_hit(user, hammer, crew)
	TEST_ASSERT(abs(user.getBruteLoss() + user.getFireLoss() - (20 - HERETIC_HAMMER_FORGE_HEAL)) < 0.1, "Остуженный Молот не лечит.")
	hammer_k.quenched_until = 0
	COOLDOWN_RESET(hammer_k, hit_gain)
	hammer.attack_self(user)
	hammer_test_heal(crew)
	hammer_test_hit(user, hammer, crew)
	TEST_ASSERT(abs(user.getBruteLoss() + user.getFireLoss() - (20 - HERETIC_HAMMER_FORGE_HEAL)) < 0.1, "Одной рукой удар не лечит.")

/// Стойка укорачивает падение и оглушение, Несокрушимый - сильнее; одной рукой срок полный.
/datum/unit_test/heretic_hammer_stance_stun/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	user.Knockdown(10 SECONDS)
	TEST_ASSERT(abs(user.AmountKnockdown() - 10 SECONDS) < 1, "Одной рукой падение полное: [user.AmountKnockdown()].")
	user.SetKnockdown(0)
	hammer.attack_self(user)
	user.Knockdown(10 SECONDS)
	TEST_ASSERT(abs(user.AmountKnockdown() - 10 SECONDS * (1 - HERETIC_HAMMER_STANCE_STUN_CUT / 100)) < 1, "В стойке падение на [HERETIC_HAMMER_STANCE_STUN_CUT]% короче: [user.AmountKnockdown()].")
	user.SetKnockdown(0)
	heretic.gain_knowledge(/datum/eldritch_knowledge/hammer_unbroken)
	TEST_ASSERT(hammer_k.braced, "Несокрушимый держится, пока Молот в двух руках.")
	COOLDOWN_START(hammer_k, rage, 1 MINUTES)
	user.Knockdown(10 SECONDS)
	TEST_ASSERT(abs(user.AmountKnockdown() - 10 SECONDS * (1 - HERETIC_HAMMER_UNBROKEN_STUN_CUT / 100)) < 1, "С Несокрушимым падение на [HERETIC_HAMMER_UNBROKEN_STUN_CUT]% короче: [user.AmountKnockdown()].")
	user.SetKnockdown(0)
	user.Stun(10 SECONDS)
	TEST_ASSERT(abs(user.AmountStun() - 10 SECONDS * (1 - HERETIC_HAMMER_UNBROKEN_STUN_CUT / 100)) < 1, "С Несокрушимым оглушение на [HERETIC_HAMMER_UNBROKEN_STUN_CUT]% короче: [user.AmountStun()].")
	user.SetStun(0)

/// Член экипажа бьёт еретика ящиком, стреляет пулей и снарядом выносливости; возвращает урон каждого.
/datum/unit_test/proc/hammer_test_take_hits(mob/living/carbon/human/user, mob/living/carbon/human/crew, obj/item/weapon)
	. = list()
	crew.a_intent = INTENT_HARM
	crew.adjustStaminaLoss(-crew.getStaminaLoss())
	crew.stamina_buffer = 100
	weapon.attack(user, crew)
	.["melee"] = user.getBruteLoss()
	user.adjustBruteLoss(-user.getBruteLoss())
	var/obj/item/projectile/bullet = blade_test_shot(crew, user, /obj/item/projectile)
	bullet.damage = 10
	user.bullet_act(bullet, BODY_ZONE_CHEST)
	.["bullet"] = user.getBruteLoss()
	user.adjustBruteLoss(-user.getBruteLoss())
	var/obj/item/projectile/numbing = blade_test_shot(crew, user, /obj/item/projectile)
	numbing.damage = 10
	numbing.damage_type = STAMINA
	user.adjustStaminaLoss(-user.getStaminaLoss())
	user.bullet_act(numbing, BODY_ZONE_CHEST)
	.["stamina"] = user.getStaminaLoss()
	user.adjustStaminaLoss(-user.getStaminaLoss())

/// Накал копят только удары Молотом в двух руках не чаще раза в секунду; без ударов он стынет, вода и душ гасят его в ноль, смерть обнуляет.
/datum/unit_test/heretic_hammer_heat/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START, "Путь начинается с запаса Накала.")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource_max, HERETIC_HAMMER_CAPACITY, "Накал копится до потолка пути.")
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT(target.getBruteLoss() > 0, "Удар одной рукой ранит.")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START + 1, "Удар одной рукой тоже копит Накал.")
	TEST_ASSERT(COOLDOWN_TIMELEFT(hammer_k, hit_gain) > HERETIC_HAMMER_HIT_GAIN_GAP, "Одной рукой Накал копится вдвое реже.")
	TEST_ASSERT_EQUAL(get_turf(target), heretic_lead_test_spot(2, 2), "Одной рукой Молот не отбрасывает.")
	COOLDOWN_RESET(hammer_k, hit_gain)
	hammer.attack_self(user)
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START + 2, "Удар в двух руках даёт единицу Накала.")
	TEST_ASSERT(COOLDOWN_TIMELEFT(hammer_k, hit_gain) <= HERETIC_HAMMER_HIT_GAIN_GAP, "В двух руках Накал копится раз в секунду.")
	TEST_ASSERT_EQUAL(get_turf(target), heretic_lead_test_spot(3, 2), "Удар в двух руках отбрасывает на клетку.")
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START + 2, "Накал от ударов - не чаще раза в секунду.")
	hammer_test_heal(target)
	hammer_k.cool_at = 0
	hammer_k.on_life(user)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START + 1, "Без ударов Накал стынет.")
	hammer_k.on_life(user)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START + 1, "Накал стынет на единицу раз в [HERETIC_HAMMER_COOL_TIME / (1 SECONDS)] секунд.")
	hammer_test_douse(user, 10)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Вода на теле гасит Накал в ноль.")
	TEST_ASSERT(hammer_k.quenched_until > world.time, "Остуженный Молот какое-то время не копит Накал.")
	TEST_ASSERT(findtext(hammer_k.combat_resource_state(), "остужен"), "Панель ресурса говорит, что Молот остужен.")
	COOLDOWN_RESET(hammer_k, hit_gain)
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Остуженный Молот ударом Накал не копит.")
	hammer_k.quenched_until = 0
	COOLDOWN_RESET(hammer_k, hit_gain)
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 1, "Остывший Молот снова копит Накал.")
	SEND_SIGNAL(user, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 1, "Мыло и уборщик Накал не гасят.")
	var/obj/machinery/shower/shower = allocate(/obj/machinery/shower, get_turf(user))
	shower.interact(user)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Включённый душ гасит Накал.")
	shower.interact(user)
	hammer_k.quenched_until = 0
	hammer_k.combat_resource = 2
	var/obj/effect/particle_effect/foam/firefighting/foam = allocate(/obj/effect/particle_effect/foam/firefighting, get_turf(user))
	hammer_k.on_life(user)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Пена под ногами гасит Накал.")
	qdel(foam)
	hammer_k.quenched_until = 0
	hammer_k.combat_resource = 3
	hammer_k.on_death(user)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Смерть обнуляет Накал.")
	hammer_k.ascension_active = TRUE
	hammer_k.gain_combat_resource(HERETIC_HAMMER_ASCENDED_CAPACITY * 2)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_ASCENDED_CAPACITY, "Вознёсшийся копит Накал до [HERETIC_HAMMER_ASCENDED_CAPACITY].")
	hammer_k.cool_at = 0
	hammer_k.on_life(user)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_ASCENDED_CAPACITY, "У вознёсшегося Накал не стынет.")

/// Замах готовит Сокрушающий удар: урон, Накал и полёт, удар о стену или о другого валит; опущенный Молот срывает замах.
/datum/unit_test/heretic_hammer_crush/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	user.forceMove(heretic_lead_test_spot(3, 2))
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	TEST_ASSERT(findtext(hammer_k.swing_block_reason(user), "двух руках"), "Замах - только Молотом в двух руках.")
	hammer.attack_self(user)
	TEST_ASSERT(hammer_k.swing(user), "Замах: [hammer_k.swing_block_reason(user)]")
	var/datum/status_effect/heretic_hammer_swing/swing = user.has_status_effect(/datum/status_effect/heretic_hammer_swing)
	TEST_ASSERT(swing && !swing.ready, "Первую секунду Молот только занесён.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_hammer_swing), "С занесённым Молотом идут медленнее.")
	TEST_ASSERT(!hammer_k.swing(user), "Занесённый Молот второй раз не заносят.")
	TEST_ASSERT(wait_for_var(swing, NAMEOF(swing, ready), TRUE, HERETIC_HAMMER_SWING_WINDUP + 2 SECONDS), "Через секунду замах готов.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_hammer_swing), "Готовый замах не замедляет.")
	var/mob/living/carbon/human/target = hammer_test_exact_crew(heretic_lead_test_spot(4, 2))
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT(QDELETED(swing), "Сокрушающий удар расходует замах.")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START + 2, "Сокрушающий удар даёт ещё единицу Накала.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_hammer_test_landed), target), 3 SECONDS, "удар о стену"), "Врезавшись в стену, сокрушённый падает.")
	TEST_ASSERT_EQUAL(get_turf(target), heretic_lead_test_spot(5, 2), "Сокрушённый летит до стены.")
	TEST_ASSERT(heretic_hammer_test_slam_once(target.getBruteLoss()), "Сокрушающий удар о стену: удар, +[HERETIC_HAMMER_CRUSH_DAMAGE] и ещё [HERETIC_HAMMER_SLAM_DAMAGE] о стену, без двойного счёта: [target.getBruteLoss()].")
	hammer_test_heal(target)
	TEST_ASSERT(hammer_k.swing(user), "Второй замах.")
	swing = user.has_status_effect(/datum/status_effect/heretic_hammer_swing)
	TEST_ASSERT(wait_for_var(swing, NAMEOF(swing, ready), TRUE, HERETIC_HAMMER_SWING_WINDUP + 2 SECONDS), "Второй замах готов.")
	// Расставляем после замаха: за секунду ожидания лежащую цель в общем прогоне сносит по резерву.
	user.forceMove(heretic_lead_test_spot(1, 2))
	target.forceMove(heretic_lead_test_spot(2, 2))
	var/mob/living/carbon/human/bystander = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT(QDELETED(swing), "Второй сокрушающий удар расходует замах.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(bystander, TYPE_PROC_REF(/mob/living, IsKnockdown)), 3 SECONDS, "удар о другого"), "Сокрушённый валит того, в кого врезался; цель на [target.x - run_loc_floor_bottom_left.x],[target.y - run_loc_floor_bottom_left.y].")
	TEST_ASSERT(target.IsKnockdown(), "Врезавшись в другого, сокрушённый падает и сам.")
	TEST_ASSERT(hammer_k.swing(user), "Третий замах.")
	hammer.attack_self(user)
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_hammer_swing), "Опущенный Молот срывает замах.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_hammer_swing), "Сорванный замах не замедляет.")

/// Хватка даёт Накал, а Хватка кузни отбрасывает и открывает подхват; Звон наковальни трескается от ударов в двух руках и на третьей трещине раскалывает броню.
/datum/unit_test/heretic_hammer_grasp_mark/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/hammer_grasp, /datum/eldritch_knowledge/hammer_mark))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	var/mob/living/carbon/human/target = hammer_test_exact_crew(heretic_lead_test_spot(2, 2))
	user.a_intent = INTENT_HARM
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(target, user, TRUE)
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START + HERETIC_HAMMER_GRASP_HEAT, "Хватка по врагу даёт Накал.")
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_hammer_catch), "После Хватки кузни открыт подхват.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_lead_test_far_enough), user, target, 1 + HERETIC_HAMMER_GRASP_THROW), 3 SECONDS, "отброс Хваткой"), "Хватка кузни отбрасывает врага.")
	var/datum/status_effect/eldritch/hammer/mark = target.has_status_effect(/datum/status_effect/eldritch/hammer)
	TEST_ASSERT_NOTNULL(mark, "Хватка вешает Звон наковальни.")
	hammer.attack_self(user)
	var/datum/status_effect/heretic_hammer_catch/catching = user.has_status_effect(/datum/status_effect/heretic_hammer_catch)
	TEST_ASSERT(catching?.primed, "Снова взяв Молот в две руки после Хватки, вы ловите подхват.")
	var/before_catch = target.getBruteLoss()
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT(QDELETED(catching), "Подхват делает удар Сокрушающим.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_hammer_test_landed), target), 3 SECONDS, "удар с подхвата о стену"), "Удар с подхвата отбрасывает в стену.")
	TEST_ASSERT(heretic_hammer_test_slam_once(target.getBruteLoss() - before_catch), "Удар с подхвата бьёт как Сокрушающий, стена добавляет [HERETIC_HAMMER_SLAM_DAMAGE] один раз: [target.getBruteLoss() - before_catch].")
	TEST_ASSERT_EQUAL(mark.cracks, 1, "Удар в двух руках - трещина.")
	hammer_test_heal(target)
	hammer.attack_self(user)
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(mark.cracks, 1, "Удар одной рукой трещин не даёт.")
	hammer.attack_self(user)
	var/armor_before = target.physiology.armor.getRating(MELEE)
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(mark.cracks, 2, "Вторая трещина.")
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT(QDELETED(mark), "Третья трещина раскалывает Звон.")
	TEST_ASSERT_NOTNULL(target.has_status_effect(/datum/status_effect/heretic_hammer_shattered), "Броня цели разбита.")
	TEST_ASSERT(target.IsKnockdown(), "Раскол брони сбивает с ног.")
	TEST_ASSERT_EQUAL(target.physiology.armor.getRating(MELEE), armor_before - HERETIC_HAMMER_SHATTER_ARMOR, "Разбитая броня держит удары на [HERETIC_HAMMER_SHATTER_ARMOR] хуже.")
	target.remove_status_effect(/datum/status_effect/heretic_hammer_shattered)
	TEST_ASSERT_EQUAL(target.physiology.armor.getRating(MELEE), armor_before, "Броня возвращается.")

/// Молот в «Схватить» бьёт стоящего как обычно, а лежащего за Накал вбивает в пол: не встать, не уйти, экипажу не утащить; член экипажа с ломом выдёргивает его.
/datum/unit_test/heretic_hammer_nail/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/hammer_nail))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	hammer_test_hit(user, hammer, target, INTENT_GRAB)
	TEST_ASSERT(target.getBruteLoss() > 0, "Стоящего Молот в «Схватить» бьёт как обычно.")
	TEST_ASSERT_NULL(target.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Стоящего в пол не вбить.")
	target.forceMove(heretic_lead_test_spot(2, 2))
	target.Knockdown(HERETIC_HAMMER_NAIL_TIME)
	hammer_k.combat_resource = HERETIC_HAMMER_NAIL_COST - 1
	hammer_test_hit(user, hammer, target, INTENT_GRAB)
	TEST_ASSERT_NULL(target.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Без Накала в пол не вбить.")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_NAIL_COST - 1, "Отказ Накал не тратит.")
	hammer_k.combat_resource = HERETIC_HAMMER_NAIL_COST
	hammer_test_hit(user, hammer, target, INTENT_GRAB)
	var/datum/status_effect/heretic_hammer_nailed/nail = target.has_status_effect(/datum/status_effect/heretic_hammer_nailed)
	TEST_ASSERT_NOTNULL(nail, "Лежащий вбит в пол.")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Вбить в пол стоит [HERETIC_HAMMER_NAIL_COST] Накала.")
	TEST_ASSERT(nail in hammer_k.nailed, "Путь помнит вбитого.")
	TEST_ASSERT_EQUAL(get_turf(nail.crack), get_turf(target), "Под вбитым проломлен пол.")
	target.SetKnockdown(0)
	TEST_ASSERT(HAS_TRAIT(target, TRAIT_FLOORED), "Вбитый не встаёт.")
	TEST_ASSERT(!CHECK_MOBILITY(target, MOBILITY_MOVE), "Вбитый не уходит.")
	user.start_pulling(target)
	user.Move(heretic_lead_test_spot(0, 2), WEST)
	TEST_ASSERT_EQUAL(get_turf(target), heretic_lead_test_spot(1, 2), "Еретик тащит вбитого за собой.")
	TEST_ASSERT(!QDELETED(nail) && get_turf(nail.crack) == get_turf(target), "Вбивка держится, пролом едет следом.")
	user.stop_pulling()
	var/obj/item/crowbar/own = allocate(/obj/item/crowbar)
	target.put_in_hands(own)
	target.a_intent = INTENT_HELP
	own.melee_attack_chain(target, target)
	TEST_ASSERT(!LAZYFIND(target.do_afters, target), "Вбитый не выдёргивает себя ломом сам.")
	target.dropItemToGround(own)
	var/nailed_until = nail.duration
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(nail.duration, nailed_until - HERETIC_HAMMER_NAIL_HIT_CUT, "Удар Молотом сокращает вбивку на [HERETIC_HAMMER_NAIL_HIT_CUT / (1 SECONDS)] секунды.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	crew.start_pulling(target)
	TEST_ASSERT(target.pulledby != crew, "Вбитого экипажу не утащить.")
	var/obj/item/crowbar/bar = allocate(/obj/item/crowbar)
	crew.put_in_hands(bar)
	crew.a_intent = INTENT_HELP
	bar.melee_attack_chain(crew, target)
	TEST_ASSERT(!QDELETED(nail), "Лом выдёргивает не сразу.")
	TEST_ASSERT(wait_for_qdeleted(nail, HERETIC_HAMMER_NAIL_PRY_TIME + 2 SECONDS), "Член экипажа с ломом выдёргивает вбитого.")
	TEST_ASSERT(!HAS_TRAIT_FROM(target, TRAIT_FLOORED, "heretic_hammer_nailed"), "Выдернутый может встать.")
	TEST_ASSERT(!length(hammer_k.nailed), "Путь забывает выдернутого.")

/// Вбитого освобождают нулевой жезл, взрыв, расталкивание и смерть, а смена тела еретика отпускает всех.
/datum/unit_test/heretic_hammer_nail_release/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/hammer_nail))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/mob/living/carbon/human/rodded = hammer_test_pinned(hammer_k, heretic_lead_test_spot(3, 0))
	var/mob/living/carbon/human/blasted = hammer_test_pinned(hammer_k, heretic_lead_test_spot(3, 1))
	var/mob/living/carbon/human/shaken = hammer_test_pinned(hammer_k, heretic_lead_test_spot(3, 2))
	var/mob/living/carbon/human/dead = hammer_test_pinned(hammer_k, heretic_lead_test_spot(3, 3))
	var/mob/living/carbon/human/left = hammer_test_pinned(hammer_k, heretic_lead_test_spot(3, 4))
	var/mob/living/carbon/human/shoved = hammer_test_pinned(hammer_k, heretic_lead_test_spot(3, -1))
	var/datum/status_effect/heretic_hammer_nailed/shoved_nail = shoved.has_status_effect(/datum/status_effect/heretic_hammer_nailed)
	var/obj/effect/heretic_hammer_nail_crack/shoved_crack = shoved_nail.crack
	shoved.forceMove(heretic_lead_test_spot(4, -1))
	TEST_ASSERT(!shoved.has_status_effect(/datum/status_effect/heretic_hammer_nailed) && QDELETED(shoved_crack), "Сдвинутый чужой силой вбитый свободен, пролом остаётся пустым.")
	var/mob/living/carbon/human/chaplain = heretic_lead_test_crew(heretic_lead_test_spot(4, 1))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	chaplain.put_in_hands(rod)
	chaplain.a_intent = INTENT_HELP
	rod.melee_attack_chain(chaplain, rodded)
	TEST_ASSERT_NULL(rodded.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Нулевой жезл освобождает вбитого.")
	blasted.ex_act(EXPLODE_LIGHT)
	TEST_ASSERT_NULL(blasted.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Взрыв выбивает вбитого из пола.")
	SEND_SIGNAL(shaken, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, chaplain)
	TEST_ASSERT_NULL(shaken.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Вбитого можно растолкать.")
	var/datum/status_effect/heretic_hammer_nailed/dying = dead.has_status_effect(/datum/status_effect/heretic_hammer_nailed)
	var/obj/effect/heretic_hammer_nail_crack/crack = dying.crack
	dead.death()
	TEST_ASSERT(QDELETED(dying) && QDELETED(crack), "Смерть снимает вбивку вместе с проломом.")
	TEST_ASSERT_EQUAL(length(hammer_k.nailed), 1, "Путь держит только оставшегося вбитого.")
	hammer_k.on_body_lose(user)
	TEST_ASSERT_NULL(left.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Смена тела отпускает вбитых.")

/// Таран рвёт хватку, сносит окно, валит первого врага и выдёргивает вбитого; даром раз в 40 секунд, затем за Накал.
/datum/unit_test/heretic_hammer_ram/Run()
	hammer_test_indoors()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/spell/hammer_ram))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	user.forceMove(heretic_lead_test_spot(0, 2))
	TEST_ASSERT(findtext(hammer_k.ram_block_reason(user, heretic_lead_test_spot(4, 2)), "Молотом"), "Без Молота в руке Тарана нет.")
	hammer_test_hammer(user, FALSE)
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, heretic_lead_test_spot(1, 2))
	var/mob/living/carbon/human/enemy = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/mob/living/carbon/human/grabber = heretic_lead_test_crew(heretic_lead_test_spot(0, 1))
	grabber.start_pulling(user)
	TEST_ASSERT_EQUAL(user.pulledby, grabber, "Еретика держат.")
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(4, 2)), "Таран: [hammer_k.hammer_failure]")
	TEST_ASSERT_NULL(grabber.pulling, "Таран рвёт хватку.")
	TEST_ASSERT(QDELETED(window), "Таран сносит окно.")
	TEST_ASSERT(enemy.IsKnockdown(), "Таран валит первого врага.")
	TEST_ASSERT(get_dist(user, heretic_lead_test_spot(0, 2)) >= 2, "Таран несёт вперёд.")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START, "Первый Таран даром.")
	TEST_ASSERT(!findtext(hammer_k.combat_resource_state(), "даром"), "Панель ресурса знает, что дармовой Таран потрачен.")
	hammer_k.combat_resource = HERETIC_HAMMER_RAM_COST - 1
	TEST_ASSERT(!hammer_k.ram(user, heretic_lead_test_spot(0, 2)), "Без Накала и дармового заряда Таран не идёт.")
	TEST_ASSERT(findtext(hammer_k.hammer_failure, "Накала"), "Отказ называет цену: [hammer_k.hammer_failure]")
	user.forceMove(heretic_lead_test_spot(0, 4))
	var/mob/living/carbon/human/pinned = hammer_test_pinned(hammer_k, heretic_lead_test_spot(2, 4))
	hammer_k.combat_resource = HERETIC_HAMMER_RAM_COST
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(4, 4)), "Таран за Накал: [hammer_k.hammer_failure]")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Таран стоит [HERETIC_HAMMER_RAM_COST] Накала.")
	TEST_ASSERT_NULL(pinned.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Таран выдёргивает вбитого.")

/// Таран бьёт шлюз: незапертый распахивает, запертый только ранит; обычную стену проламывает.
/datum/unit_test/heretic_hammer_ram_doors/Run()
	hammer_test_indoors()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/spell/hammer_ram))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	user.forceMove(heretic_lead_test_spot(0, 2))
	hammer_test_hammer(user, FALSE)
	var/obj/machinery/door/airlock/bolted = allocate(/obj/machinery/door/airlock, heretic_lead_test_spot(1, 2))
	bolted.locked = TRUE
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(4, 2)), "Таран в шлюз: [hammer_k.hammer_failure]")
	TEST_ASSERT(bolted.obj_integrity < bolted.max_integrity, "Таран ранит шлюз.")
	TEST_ASSERT(bolted.density, "Запертый шлюз Таран не открывает.")
	TEST_ASSERT_EQUAL(get_turf(user), heretic_lead_test_spot(0, 2), "О запертый шлюз Таран останавливается.")
	user.forceMove(heretic_lead_test_spot(0, 3))
	var/obj/machinery/door/airlock/plain = allocate(/obj/machinery/door/airlock, heretic_lead_test_spot(1, 3))
	COOLDOWN_RESET(hammer_k, free_ram)
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(4, 3)), "Таран в незапертый шлюз: [hammer_k.hammer_failure]")
	TEST_ASSERT(wait_for_var(plain, NAMEOF(plain, density), FALSE, 3 SECONDS), "Незапертый шлюз Таран распахивает.")
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(3, 4), /turf/closed/wall)
	user.forceMove(heretic_lead_test_spot(2, 4))
	COOLDOWN_RESET(hammer_k, free_ram)
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(5, 4)), "Таран в стену: [hammer_k.hammer_failure]")
	TEST_ASSERT(!iswallturf(heretic_lead_test_spot(3, 4)), "Таран проламывает обычную стену.")
	var/obj/machinery/door/poddoor/blast = allocate(/obj/machinery/door/poddoor, heretic_lead_test_spot(1, 0))
	user.forceMove(heretic_lead_test_spot(0, 0))
	COOLDOWN_RESET(hammer_k, free_ram)
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(4, 0)), "Таран в бронестворку: [hammer_k.hammer_failure]")
	var/obj/machinery/door/firedoor/closed/sealed = allocate(/obj/machinery/door/firedoor/closed, heretic_lead_test_spot(1, 1))
	sealed.welded = TRUE
	user.forceMove(heretic_lead_test_spot(0, 1))
	COOLDOWN_RESET(hammer_k, free_ram)
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(4, 1)), "Таран в заваренную пожарную дверь: [hammer_k.hammer_failure]")
	sleep(2 SECONDS)
	TEST_ASSERT(blast.density, "Бронестворку Таран только бьёт, но не открывает.")
	TEST_ASSERT(sealed.density, "Заваренную пожарную дверь Таран не открывает.")
	var/obj/machinery/door/firedoor/closed/unsealed = allocate(/obj/machinery/door/firedoor/closed, heretic_lead_test_spot(1, -1))
	user.forceMove(heretic_lead_test_spot(0, -1))
	COOLDOWN_RESET(hammer_k, free_ram)
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(4, -1)), "Таран в пожарную дверь: [hammer_k.hammer_failure]")
	TEST_ASSERT(wait_for_var(unsealed, NAMEOF(unsealed, density), FALSE, 3 SECONDS), "Незаваренную пожарную дверь Таран распахивает.")
	var/obj/machinery/door/window/own_windoor = allocate(/obj/machinery/door/window, heretic_lead_test_spot(0, 5))
	own_windoor.setDir(EAST)
	user.forceMove(heretic_lead_test_spot(0, 5))
	COOLDOWN_RESET(hammer_k, free_ram)
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(4, 5)), "Таран в винтдор на своей клетке: [hammer_k.hammer_failure]")
	TEST_ASSERT(own_windoor.obj_integrity < own_windoor.max_integrity, "Таран бьёт винтдор на своей клетке.")
	TEST_ASSERT(wait_for_var(own_windoor, NAMEOF(own_windoor, density), FALSE, 3 SECONDS), "Винтдор на своей клетке Таран распахивает.")
	var/obj/machinery/door/window/far_windoor = allocate(/obj/machinery/door/window, heretic_lead_test_spot(3, 5))
	far_windoor.setDir(EAST)
	user.forceMove(heretic_lead_test_spot(2, 5))
	COOLDOWN_RESET(hammer_k, free_ram)
	TEST_ASSERT(hammer_k.ram(user, heretic_lead_test_spot(5, 5)), "Таран к винтдору на дальнем краю клетки: [hammer_k.hammer_failure]")
	TEST_ASSERT_EQUAL(get_turf(user), heretic_lead_test_spot(3, 5), "Винтдор на дальнем краю клетки не держит вход в неё.")
	TEST_ASSERT(far_windoor.obj_integrity < far_windoor.max_integrity, "Войдя в клетку, Таран бьёт винтдор на её дальнем краю.")

/// Сотрясение бьёт и валит соседей, дальних изматывает; Наковальня с неба бьёт по клетке и встаёт разбиваемой преградой; Раскол бежит трещиной и валит стоящих на линии.
/datum/unit_test/heretic_hammer_spells/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/spell/hammer_quake, /datum/eldritch_knowledge/spell/hammer_anvil, /datum/eldritch_knowledge/spell/hammer_fissure))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	user.forceMove(heretic_lead_test_spot(2, 2))
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	hammer_k.combat_resource = HERETIC_HAMMER_QUAKE_COST
	TEST_ASSERT(!hammer_k.quake(user), "Сотрясение - только Молотом в двух руках.")
	hammer.attack_self(user)
	var/mob/living/carbon/human/near = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/mob/living/carbon/human/far = heretic_lead_test_crew(heretic_lead_test_spot(2, 5))
	TEST_ASSERT(hammer_k.quake(user), "Сотрясение начинается.")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Сотрясение стоит [HERETIC_HAMMER_QUAKE_COST] Накала.")
	TEST_ASSERT(!near.IsKnockdown(), "Удар в пол - после замаха.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(near, TYPE_PROC_REF(/mob/living, IsKnockdown)), 2 SECONDS, "Сотрясение"), "Сотрясение валит соседа.")
	TEST_ASSERT(near.getBruteLoss() >= HERETIC_HAMMER_QUAKE_NEAR_DAMAGE, "Сосед получает урон.")
	TEST_ASSERT(far.getStaminaLoss() >= HERETIC_HAMMER_QUAKE_STAMINA, "Дальнего Сотрясение изматывает.")
	TEST_ASSERT_NOTNULL(far.has_status_effect(/datum/status_effect/heretic_hammer_dazed), "Дальний оглушён и замедлен.")
	TEST_ASSERT(!far.IsKnockdown(), "Дальнего Сотрясение не валит.")
	var/mob/living/carbon/human/struck = heretic_lead_test_crew(heretic_lead_test_spot(1, 3))
	hammer_k.combat_resource = HERETIC_HAMMER_ANVIL_COST - 1
	TEST_ASSERT(!hammer_k.drop_anvil(user, struck), "Без Накала наковальни нет.")
	TEST_ASSERT(findtext(hammer_k.hammer_failure, "Накала"), "Отказ называет цену: [hammer_k.hammer_failure]")
	hammer_k.combat_resource = HERETIC_HAMMER_ANVIL_COST
	TEST_ASSERT(hammer_k.drop_anvil(user, struck), "Наковальня с неба: [hammer_k.hammer_failure]")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_hammer/anvil_shadow) in get_turf(struck), "Тень наковальни видна заранее.")
	TEST_ASSERT(!struck.IsKnockdown(), "Наковальня падает не сразу.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(struck, TYPE_PROC_REF(/mob/living, IsKnockdown)), 3 SECONDS, "Наковальня"), "Наковальня валит цель.")
	TEST_ASSERT(struck.getBruteLoss() >= HERETIC_HAMMER_ANVIL_DAMAGE, "Наковальня бьёт по голове.")
	var/obj/structure/heretic_hammer_anvil/anvil = locate() in get_turf(struck)
	TEST_ASSERT(anvil?.density, "Наковальня встаёт преградой.")
	hammer_k.combat_resource = HERETIC_HAMMER_ANVIL_COST
	TEST_ASSERT(!hammer_k.drop_anvil(user, struck), "На наковальню вторая не падает.")
	TEST_ASSERT(findtext(hammer_k.hammer_failure, "уже стоит"), "Отказ называет причину: [hammer_k.hammer_failure]")
	anvil.take_damage(HERETIC_HAMMER_ANVIL_INTEGRITY * 2, BRUTE, MELEE, FALSE)
	TEST_ASSERT(QDELETED(anvil), "Наковальню можно разбить.")
	user.forceMove(heretic_lead_test_spot(0, 0))
	var/turf/open/floor/plated = heretic_lead_test_spot(1, 0)
	plated.baseturfs = /turf/open/floor/plating
	var/mob/living/carbon/human/lined = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	hammer_k.combat_resource = HERETIC_HAMMER_FISSURE_COST
	TEST_ASSERT(hammer_k.fissure(user, heretic_lead_test_spot(4, 0)), "Раскол: [hammer_k.hammer_failure]")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Раскол стоит [HERETIC_HAMMER_FISSURE_COST] Накала.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(lined, TYPE_PROC_REF(/mob/living, IsKnockdown)), 2 SECONDS, "Раскол"), "Раскол валит стоящего на линии.")
	TEST_ASSERT(lined.getBruteLoss() >= HERETIC_HAMMER_FISSURE_DAMAGE, "Раскол ранит стоящего на линии.")
	TEST_ASSERT(isplatingturf(heretic_lead_test_spot(1, 0)), "Плитка по линии ломается до обшивки.")
	var/turf/open/floor/over_space = heretic_lead_test_spot(2, 0)
	TEST_ASSERT(isfloorturf(over_space) && !isplatingturf(over_space) && over_space.broken, "Плитка без обшивки под ней трескается на месте, дыры нет.")
	TEST_ASSERT(!isplatingturf(heretic_lead_test_spot(1, 1)), "Пол рядом с линией цел.")

/// Трещина Раскола бежит от еретика: дальняя клетка раскрывается и валит позже ближней.
/datum/unit_test/heretic_hammer_fissure_runs/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/spell/hammer_fissure))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	user.forceMove(heretic_lead_test_spot(0, 0))
	hammer_test_hammer(user)
	var/mob/living/carbon/human/near = heretic_lead_test_crew(heretic_lead_test_spot(1, 0))
	var/mob/living/carbon/human/far = heretic_lead_test_crew(heretic_lead_test_spot(4, 0))
	TEST_ASSERT(hammer_k.fissure_strike(WEAKREF(user), EAST), "Раскол бьёт: [hammer_k.strike_break_reason(user)]")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_hammer/fissure) in heretic_lead_test_spot(1, 0), "Первая клетка раскрывается в миг удара.")
	TEST_ASSERT(near.IsKnockdown(), "Стоящий у ног падает сразу.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_hammer/fissure) in heretic_lead_test_spot(4, 0), "Четвёртая клетка ещё цела: трещина до неё не добежала.")
	TEST_ASSERT(!far.IsKnockdown() && !far.getBruteLoss(), "Дальнего трещина ещё не достала.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(far, TYPE_PROC_REF(/mob/living, IsKnockdown)), 2 SECONDS, "Раскол добегает"), "Трещина добегает до дальнего и валит его.")
	TEST_ASSERT(far.getBruteLoss() >= HERETIC_HAMMER_FISSURE_DAMAGE, "Дальний ранен, когда трещина до него дошла.")

/// Великий Молот лежит в руках по рисунку своего файла и в одной, и в двух руках.
/datum/unit_test/heretic_hammer_great_inhand/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/melee/sickly_blade/hammer/great = hammer_test_hammer(user, FALSE, /obj/item/melee/sickly_blade/hammer/great)
	hammer_test_inhand(great, "hammer_great")
	great.attack_self(user)
	TEST_ASSERT(ISWIELDED(great), "Великий Молот берут в две руки.")
	TEST_ASSERT_EQUAL(great.icon_state, "hammer_great", "На иконке Великий Молот один и тот же.")
	hammer_test_inhand(great, "hammer_great_wielded")
	great.attack_self(user)
	hammer_test_inhand(great, "hammer_great")

/// Несокрушимый держится, пока Молот в двух руках: толчок не валит, Молот не выбить, выносливость тратится меньше; Ярость кузни режет долгое падение до секунды и даёт Накал.
/datum/unit_test/heretic_hammer_unbroken/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/hammer_unbroken))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/datum/eldritch_knowledge/hammer_unbroken/unbroken = heretic.get_knowledge(/datum/eldritch_knowledge/hammer_unbroken)
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED), "Одной рукой Несокрушимый не держится.")
	hammer.attack_self(user)
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED), "С Молотом в двух руках толчок не валит.")
	TEST_ASSERT(HAS_TRAIT(hammer, TRAIT_NODROP), "Молот в двух руках не выбить.")
	TEST_ASSERT_EQUAL(user.physiology.heretic_stamina_mod, 1 - HERETIC_HAMMER_STAMINA_CUT / 100, "Урон выносливости слабее на [HERETIC_HAMMER_STAMINA_CUT]%.")
	user.Knockdown(5 SECONDS)
	TEST_ASSERT(user.AmountKnockdown() <= HERETIC_HAMMER_RAGE_LIMIT, "Ярость кузни сокращает падение до секунды: [user.AmountKnockdown()].")
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, HERETIC_HAMMER_START + HERETIC_HAMMER_RAGE_HEAT, "Ярость даёт Накал.")
	user.SetKnockdown(0)
	user.Knockdown(5 SECONDS)
	TEST_ASSERT(user.AmountKnockdown() > HERETIC_HAMMER_RAGE_LIMIT, "Ярость приходит не чаще раза в [unbroken.rage_cooldown() / (1 SECONDS)] секунд.")
	user.SetKnockdown(0)
	unbroken.passive_level = length(unbroken.passive_values)
	TEST_ASSERT_EQUAL(unbroken.rage_cooldown(), unbroken.passive_values[length(unbroken.passive_values)], "Ступени улучшения ускоряют Ярость.")
	hammer.attack_self(user)
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED) && !HAS_TRAIT(hammer, TRAIT_NODROP), "Отпустив Молот, Несокрушимого лишаются.")
	TEST_ASSERT_EQUAL(user.physiology.heretic_stamina_mod, 1, "Выносливость снова тратится как обычно.")

/// Клеймо кузни: Молот в «Помощи» выбивает его в стене, прохожий экипаж засчитывает отдел один раз, держится шесть клейм, нулевой жезл, сварка и снос стены стирают их.
/datum/unit_test/heretic_hammer_brand/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	user.forceMove(heretic_lead_test_spot(5, 2))
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	var/turf/closed/wall/wall = heretic_lead_test_spot(6, 2)
	heretic_test_area(wall, /area/cargo/storage)
	user.a_intent = INTENT_HELP
	hammer.melee_attack_chain(user, wall)
	var/obj/effect/heretic_hammer_brand/brand = locate() in wall
	TEST_ASSERT_NOTNULL(brand, "Молот в «Помощи» выбивает клеймо в стене.")
	TEST_ASSERT(iswallturf(wall), "Клеймо не ломает стену.")
	TEST_ASSERT(!hammer_k.brand(user, wall), "В одну стену второе клеймо не ложится.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Само клеймо дело не продвигает.")
	user.forceMove(heretic_lead_test_spot(4, 2))
	TEST_ASSERT(COOLDOWN_FINISHED(brand, hum_sound) && COOLDOWN_FINISHED(brand, owner_notice), "Своего еретика клеймо не слышит.")
	user.forceMove(heretic_lead_test_spot(5, 2))
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	crew.forceMove(heretic_lead_test_spot(4, 2))
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Тело без игрока отдел не засчитывает.")
	crew.forceMove(heretic_lead_test_spot(3, 2))
	crew.ckey = "hammerbrandtest"
	crew.forceMove(heretic_lead_test_spot(4, 2))
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Тело с ckey, но без клиента отдел не засчитывает.")
	crew.forceMove(heretic_lead_test_spot(3, 2))
	crew.key = null
	crew.mock_client = new /datum/client_interface
	crew.Unconscious(10 SECONDS)
	TEST_ASSERT_EQUAL(crew.stat, UNCONSCIOUS, "Цель без сознания.")
	crew.forceMove(heretic_lead_test_spot(4, 2))
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Тело без сознания отдел не засчитывает.")
	crew.SetUnconscious(0)
	crew.forceMove(heretic_lead_test_spot(3, 2))
	crew.handcuffed = new /obj/item/restraints/handcuffs(crew)
	crew.update_handcuffed()
	crew.forceMove(heretic_lead_test_spot(4, 2))
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Связанного клеймо не засчитывает: он не идёт сам.")
	QDEL_NULL(crew.handcuffed)
	crew.update_handcuffed()
	crew.forceMove(heretic_lead_test_spot(3, 2))
	TEST_ASSERT_EQUAL(crew.stat, CONSCIOUS, "Цель пришла в себя.")
	crew.forceMove(heretic_lead_test_spot(4, 2))
	crew.mock_client = null
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Член экипажа у клейма продвигает дело.")
	TEST_ASSERT("[/area/cargo/storage]" in heretic.deed.counted_keys, "Засчитан отдел клейма.")
	crew.forceMove(heretic_lead_test_spot(4, 3))
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Отдел засчитывается один раз.")
	for(var/dy in list(-1, 0, 1, 3, 4, 5))
		TEST_ASSERT(hammer_k.brand(user, heretic_lead_test_spot(6, dy)), "Клеймо в стене [dy] выбито.")
	TEST_ASSERT_EQUAL(length(hammer_k.brands), HERETIC_HAMMER_BRAND_LIMIT, "Держится не больше [HERETIC_HAMMER_BRAND_LIMIT] клейм.")
	TEST_ASSERT(QDELETED(brand), "Новое клеймо вытесняет старейшее.")
	var/obj/effect/heretic_hammer_brand/holy = hammer_k.brands[1]
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	holy.attackby(rod, crew)
	TEST_ASSERT(QDELETED(holy), "Нулевой жезл стирает клеймо.")
	TEST_ASSERT_EQUAL(length(hammer_k.brands), HERETIC_HAMMER_BRAND_LIMIT - 1, "Стёртое клеймо уходит из счёта.")
	var/obj/effect/heretic_hammer_brand/walled = hammer_k.brands[1]
	var/turf/closed/wall/host = walled.loc
	host.dismantle_wall()
	TEST_ASSERT(QDELETED(walled), "Снесённая стена уносит клеймо.")
	var/obj/effect/heretic_hammer_brand/welded = hammer_k.brands[1]
	var/obj/item/weldingtool/torch = allocate(/obj/item/weldingtool)
	crew.dropItemToGround(rod)
	crew.put_in_hands(torch)
	torch.switched_on(crew)
	welded.attackby(torch, crew)
	TEST_ASSERT(wait_for_qdeleted(welded, HERETIC_HAMMER_BRAND_WELD_TIME + 2 SECONDS), "Сварка заваривает клеймо.")
	var/list/obj/effect/heretic_hammer_brand/left = hammer_k.brands.Copy()
	qdel(heretic)
	for(var/obj/effect/heretic_hammer_brand/stale as anything in left)
		TEST_ASSERT(QDELETED(stale), "Снятие роли стирает клейма.")

/// Еретик Молота после вознесения на полигоне.
/datum/unit_test/proc/hammer_test_ascended()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	for(var/dx in -1 to 5)
		for(var/dy in -1 to 5)
			heretic_test_area(heretic_lead_test_spot(dx, dy), /area/antag_training)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/hammer_final)
	var/datum/eldritch_knowledge/final_eldritch/hammer_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/hammer_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.simulated = TRUE
	finale.on_body_gain(user)
	return list("heretic" = heretic, "user" = user, "hammer" = hammer_test_knowledge(heretic), "finale" = finale)

/// Последний удар перековывает Молот в Великий и роняет Раскалённые наковальни: горячую не разбить и касание обжигает, струи или ведро воды остужают, остывшую разбивают; пока стоит хоть одна, вознёсшийся лечится, последняя разбитая гасит силу.
/datum/unit_test/heretic_hammer_ascension/Run()
	var/list/fixture = hammer_test_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_hammer/hammer_k = fixture["hammer"]
	var/datum/eldritch_knowledge/final_eldritch/hammer_final/finale = fixture["finale"]
	TEST_ASSERT(hammer_k.ascension_active, "Вознесение включает силу Молота.")
	var/obj/item/melee/sickly_blade/hammer/plain = hammer_test_hammer(user, FALSE)
	var/obj/item/melee/sickly_blade/hammer/great/great = finale.forge_great(user)
	allocated += great
	TEST_ASSERT(QDELETED(plain), "Обычный Молот перековывается.")
	TEST_ASSERT(great?.great && (great in user.held_items), "Великий Молот остаётся в руке.")
	TEST_ASSERT(finale.raise_anvils(user), "Вознесение роняет наковальни.")
	TEST_ASSERT_EQUAL(length(finale.hot_anvils), HERETIC_HAMMER_HOT_ANVILS, "Падают [HERETIC_HAMMER_HOT_ANVILS] наковальни.")
	TEST_ASSERT(!finale.raise_anvils(user), "Наковальни падают один раз.")
	for(var/obj/structure/heretic_hammer_hot_anvil/each as anything in finale.hot_anvils)
		TEST_ASSERT(each.hot && each.density, "Наковальня раскалена и загораживает клетку.")
		TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_hammer/great_shockwave) in each.loc, "Наковальня падает с ударной волной.")
		TEST_ASSERT(get_dist(each, user) > 1, "Наковальня не падает вплотную к вознёсшемуся.")
	TEST_ASSERT(hammer_k.anvils_hot, "Путь знает, что наковальни стоят.")
	TEST_ASSERT_NOTNULL(user.alerts[HERETIC_HAMMER_ANVIL_ALERT], "Вознёсшийся видит значок наковален.")
	TEST_ASSERT(finale.toll_timer, "Набат взведён.")
	finale.toll()
	TEST_ASSERT(finale.toll_timer, "Набат бьёт снова через [HERETIC_HAMMER_TOLL_PERIOD / (1 SECONDS)] секунд.")
	var/obj/structure/heretic_hammer_hot_anvil/first = finale.hot_anvils[1]
	first.take_damage(HERETIC_HAMMER_HOT_ANVIL_INTEGRITY * 2, BRUTE, MELEE, FALSE)
	TEST_ASSERT(!QDELETED(first) && first.obj_integrity == first.max_integrity, "Горячую наковальню не разбить.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(0, 0))
	first.attack_hand(crew)
	TEST_ASSERT(crew.getFireLoss() >= HERETIC_HAMMER_HOT_ANVIL_BURN, "Касание горячей наковальни обжигает.")
	TEST_ASSERT(findtext(jointext(first.examine(crew), " "), "струй"), "Осмотр называет, сколько струй осталось.")
	var/full_light = first.light_power
	hammer_test_douse(first, 5)
	hammer_test_douse(first, 5)
	TEST_ASSERT(first.hot && first.douses == 1, "Брызги одной струи считаются за одну.")
	TEST_ASSERT_EQUAL(round(first.light_power / full_light, 0.01), round((HERETIC_HAMMER_HOT_ANVIL_DOUSES - 1) / HERETIC_HAMMER_HOT_ANVIL_DOUSES, 0.01), "С каждой струёй наковальня светит тусклее.")
	first.ex_act(EXPLODE_DEVASTATE)
	TEST_ASSERT(!QDELETED(first) && first.douses == 2, "Взрыв горячую наковальню не разбивает, а сбивает жар, как одна струя.")
	for(var/index in first.douses + 1 to HERETIC_HAMMER_HOT_ANVIL_DOUSES)
		COOLDOWN_RESET(first, douse_gap)
		hammer_test_douse(first, 5)
	TEST_ASSERT(!first.hot && first.icon_state == "hot_anvil_quenched", "[HERETIC_HAMMER_HOT_ANVIL_DOUSES] струи остужают наковальню.")
	TEST_ASSERT(first.name == "cooled anvil" && !findtext(first.desc, "раскалённая"), "У остывшей наковальни своё имя и описание.")
	TEST_ASSERT_EQUAL(finale.standing_anvils(), HERETIC_HAMMER_HOT_ANVILS, "Остывшая наковальня ещё стоит.")
	first.take_damage(HERETIC_HAMMER_HOT_ANVIL_INTEGRITY * 2, BRUTE, MELEE, FALSE)
	TEST_ASSERT(QDELETED(first), "Остывшую наковальню разбивают.")
	TEST_ASSERT_EQUAL(finale.standing_anvils(), HERETIC_HAMMER_HOT_ANVILS - 1, "Разбитая наковальня уходит из счёта.")
	var/obj/structure/heretic_hammer_hot_anvil/second = finale.hot_anvils[1]
	hammer_test_douse(second, HERETIC_HAMMER_HOT_ANVIL_BUCKET)
	TEST_ASSERT(!second.hot, "Ведро воды остужает наковальню разом.")
	great.attack_self(user)
	TEST_ASSERT(ISWIELDED(great), "Великий Молот берут в две руки.")
	user.adjustBruteLoss(20)
	var/brute = user.getBruteLoss()
	finale.on_life(user)
	TEST_ASSERT_EQUAL(round(brute - user.getBruteLoss(), 0.01), round(HERETIC_HAMMER_HOT_ANVIL_HEAL * SSprocessing.wait / (1 SECONDS), 0.01), "Пока стоит наковальня, вознёсшийся с Молотом в двух руках лечит [HERETIC_HAMMER_HOT_ANVIL_HEAL] ушиб в секунду.")
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/mob/living/carbon/human/neighbour = heretic_lead_test_crew(heretic_lead_test_spot(2, 3))
	hammer_test_hit(user, great, target)
	TEST_ASSERT(neighbour.getBruteLoss() >= HERETIC_HAMMER_SHOCKWAVE_DAMAGE, "Великий Молот бьёт и соседей цели.")
	var/mob/living/carbon/human/gunner = heretic_lead_test_crew(heretic_lead_test_spot(0, 2))
	user.adjustBruteLoss(-user.getBruteLoss())
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/bullet, 20)
	var/braced_wound = user.getBruteLoss()
	user.adjustBruteLoss(-braced_wound)
	great.attack_self(user)
	heretic_lead_test_shot(gunner, user, /obj/item/projectile/bullet, 20)
	TEST_ASSERT(braced_wound > 0 && braced_wound < user.getBruteLoss(), "Великий Молот в двух руках ослабляет пули: [braced_wound] против [user.getBruteLoss()].")
	second.take_damage(HERETIC_HAMMER_HOT_ANVIL_INTEGRITY * 2, BRUTE, MELEE, FALSE)
	var/obj/structure/heretic_hammer_hot_anvil/last = finale.hot_anvils[1]
	hammer_test_douse(last, HERETIC_HAMMER_HOT_ANVIL_BUCKET)
	last.take_damage(HERETIC_HAMMER_HOT_ANVIL_INTEGRITY * 2, BRUTE, MELEE, FALSE)
	TEST_ASSERT(finale.anvils_spent, "Последняя разбитая наковальня кончает их силу.")
	TEST_ASSERT(!hammer_k.anvils_hot, "Путь знает, что наковален нет.")
	TEST_ASSERT_NULL(user.alerts[HERETIC_HAMMER_ANVIL_ALERT], "Значок наковален гаснет.")
	TEST_ASSERT_NULL(finale.toll_timer, "Набат стихает.")
	great.attack_self(user)
	brute = user.getBruteLoss()
	finale.on_life(user)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), brute, "Без наковален вознёсшийся не лечится.")

/// Смерть вознёсшегося остужает наковальни, снятие роли убирает их.
/datum/unit_test/heretic_hammer_ascension_lifecycle/Run()
	var/list/fixture = hammer_test_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/final_eldritch/hammer_final/finale = fixture["finale"]
	if(!user.back)
		user.equip_to_slot_if_possible(allocate(/obj/item/storage/backpack), ITEM_SLOT_BACK, disable_warning = TRUE)
	var/obj/item/bag = user.back
	var/obj/item/melee/sickly_blade/hammer/packed = allocate(/obj/item/melee/sickly_blade/hammer)
	TEST_ASSERT(bag && SEND_SIGNAL(bag, COMSIG_TRY_STORAGE_INSERT, packed, user, TRUE, TRUE), "Молот убран в рюкзак.")
	var/obj/item/melee/sickly_blade/hammer/great/forged = finale.forge_great(user)
	allocated += forged
	TEST_ASSERT(QDELETED(packed) && forged?.loc == bag, "Молот из рюкзака перековывается и остаётся в рюкзаке: [forged?.loc].")
	TEST_ASSERT(finale.raise_anvils(user), "Наковальни падают.")
	var/list/obj/structure/heretic_hammer_hot_anvil/anvils = finale.hot_anvils.Copy()
	hammer_test_douse(anvils[1], HERETIC_HAMMER_HOT_ANVIL_BUCKET)
	finale.on_death(user)
	TEST_ASSERT(finale.anvils_spent && !finale.standing_anvils(), "Со смертью вознёсшегося наковальни остывают.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(heretic_lead_test_spot(0, 0))
	for(var/obj/structure/heretic_hammer_hot_anvil/anvil as anything in anvils)
		TEST_ASSERT(!anvil.hot, "Остывшую наковальню можно разбить.")
		TEST_ASSERT(findtext(jointext(anvil.examine(crew), " "), "погасла"), "Осмотр говорит, что кузня за наковальней погасла.")
		TEST_ASSERT(LAZYLEN(anvil.active_timers), "Мёртвая кузня рассыплется сама.")
	var/obj/structure/heretic_hammer_hot_anvil/crumbling = anvils[1]
	crumbling.crumble()
	TEST_ASSERT(QDELETED(crumbling), "Остывшая наковальня мёртвой кузни рассыпается.")
	TEST_ASSERT_EQUAL(length(finale.hot_anvils), length(anvils) - 1, "Рассыпавшаяся уходит из счёта.")
	qdel(heretic)
	for(var/obj/structure/heretic_hammer_hot_anvil/anvil as anything in anvils)
		TEST_ASSERT(QDELETED(anvil), "Снятие роли убирает наковальни.")

/// Урок Молота проходит восемь шагов настоящими действиями: две руки, Накал, Сокрушающий удар, вбивка, лом техника, Таран, вода и клеймо.
/datum/unit_test/heretic_hammer_lesson/Run()
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_HAMMER, /datum/eldritch_knowledge/base_hammer)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = heretic.get_knowledge(/datum/eldritch_knowledge/base_hammer)
	user.forceMove(heretic_lead_test_spot(3, 2))
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/datum/heretic_path_lesson/hammer/lesson = new(null, hammer_k, user, target)
	allocated += lesson
	TEST_ASSERT(heretic.get_knowledge(/datum/eldritch_knowledge/spell/hammer_ram) && heretic.get_knowledge(/datum/eldritch_knowledge/hammer_nail), "Урок открывает Таран и Вбить в пол.")
	var/obj/item/melee/sickly_blade/hammer/hammer = locate() in user.held_items
	TEST_ASSERT_NOTNULL(hammer, "Урок даёт Молот в руку.")
	hammer.attack_self(user)
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Две руки открывают Накал.")
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(lesson.stage, 3, "Удар в двух руках открывает Сокрушающий удар.")
	TEST_ASSERT(hammer_k.swing(user), "Замах урока: [hammer_k.swing_block_reason(user)]")
	var/datum/status_effect/heretic_hammer_swing/swing = user.has_status_effect(/datum/status_effect/heretic_hammer_swing)
	TEST_ASSERT(wait_for_var(swing, NAMEOF(swing, ready), TRUE, HERETIC_HAMMER_SWING_WINDUP + 2 SECONDS), "Замах урока готов.")
	hammer_test_hit(user, hammer, target)
	TEST_ASSERT_EQUAL(lesson.stage, 4, "Сокрушающий удар открывает вбивку.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_hammer_test_landed), target), 3 SECONDS, "мишень лежит"), "Мишень лежит после Сокрушающего удара.")
	target.SetKnockdown(0)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(target, TYPE_PROC_REF(/mob/living, IsKnockdown)), 3 SECONDS, "мишень снова лежит"), "Пока вбивка не засчитана, мишень не встаёт.")
	hammer_test_hit(user, hammer, target, INTENT_GRAB)
	TEST_ASSERT_EQUAL(lesson.stage, 5, "Вбивка открывает лом техника.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_stage_past), lesson, 5), HERETIC_HAMMER_NAIL_PRY_TIME + 5 SECONDS, "лом техника"), "Учебный техник выдёргивает мишень ломом.")
	TEST_ASSERT_NULL(target.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Мишень больше не вбита.")
	TEST_ASSERT(hammer_k.ram(user, target), "Таран урока: [hammer_k.hammer_failure]")
	TEST_ASSERT_EQUAL(lesson.stage, 7, "Таран открывает воду.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_test_stage_past), lesson, 7), 5 SECONDS, "вода техника"), "Учебный техник окатывает ученика водой.")
	TEST_ASSERT(hammer_k.brand(user, heretic_lead_test_spot(6, 2)), "Клеймо урока выбито.")
	TEST_ASSERT(lesson.finished(), "Урок пройден.")
	TEST_ASSERT_EQUAL(length(lesson.steps()), 8, "В уроке восемь шагов.")
	qdel(lesson)
	TEST_ASSERT(QDELETED(hammer), "Реквизит урока убирается вместе с ним.")

/// Предметы и постройки Молота создаются и удаляются чисто; без хозяина клеймо и раскалённая наковальня не появляются.
/datum/unit_test/heretic_hammer_atoms/Run()
	var/turf/spot = heretic_lead_test_spot(2, 2)
	for(var/atom_type in list(/obj/effect/heretic_hammer_nail_crack, /obj/structure/heretic_hammer_anvil, /obj/item/melee/sickly_blade/hammer, /obj/item/melee/sickly_blade/hammer/great))
		var/atom/movable/thing = new atom_type(spot)
		TEST_ASSERT(!QDELETED(thing), "[atom_type] создаётся.")
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[atom_type] удаляется.")
	var/obj/structure/heretic_hammer_hot_anvil/orphan = new(spot)
	TEST_ASSERT(QDELETED(orphan), "Раскалённая наковальня без вознесения не появляется.")
	var/obj/effect/heretic_hammer_brand/stray = new(heretic_lead_test_spot(6, 2))
	TEST_ASSERT(QDELETED(stray), "Клеймо без Молота не держится.")

/// Числа в кодексе Молота совпадают с дефайнами механик.
/datum/unit_test/heretic_hammer_texts/Run()
	var/list/expected = list(
		/datum/eldritch_knowledge/base_hammer = list("[HERETIC_HAMMER_WIELDED_FORCE] урона", "на [HERETIC_HAMMER_FORCE] без отброса", "+[HERETIC_HAMMER_CRUSH_DAMAGE] урона", "на [HERETIC_HAMMER_CRUSH_THROW] клетки", "до [HERETIC_HAMMER_BRAND_LIMIT]", "на [HERETIC_HAMMER_STANCE_CUT]% слабее", "на [HERETIC_HAMMER_STANCE_STUN_CUT]% короче", "лечит на [HERETIC_HAMMER_FORGE_HEAL]", "запас [HERETIC_HAMMER_START] из [HERETIC_HAMMER_CAPACITY]", "каждые [HERETIC_HAMMER_COOL_TIME / (1 SECONDS)] секунд", "до [HERETIC_HAMMER_ASCENDED_CAPACITY] и не стынет"),
		/datum/eldritch_knowledge/spell/hammer_ram = list("на [HERETIC_HAMMER_RAM_RANGE] клеток", "[HERETIC_HAMMER_RAM_COST] Накала", "раз в [HERETIC_HAMMER_RAM_FREE_COOLDOWN / (1 SECONDS)] секунд"),
		/datum/eldritch_knowledge/hammer_nail = list("[HERETIC_HAMMER_NAIL_COST] Накала", "на [HERETIC_HAMMER_NAIL_TIME / (1 SECONDS)] секунд", "за [HERETIC_HAMMER_NAIL_PRY_TIME / (1 SECONDS)] секунды"),
		/datum/eldritch_knowledge/hammer_grasp = list("на [HERETIC_HAMMER_GRASP_THROW] клетки", "за [HERETIC_HAMMER_CATCH_TIME / (1 SECONDS)] секунды", "[HERETIC_HAMMER_GRASP_HEAT] Накала"),
		/datum/eldritch_knowledge/hammer_mark = list("[HERETIC_HAMMER_SHATTER_TIME / (1 SECONDS)] секунд", "на [HERETIC_HAMMER_SHATTER_ARMOR] хуже"),
		/datum/eldritch_knowledge/hammer_unbroken = list("на [HERETIC_HAMMER_STAMINA_CUT]%", "дают [HERETIC_HAMMER_RAGE_HEAT] Накала", "не на [HERETIC_HAMMER_STANCE_STUN_CUT]%, а на [HERETIC_HAMMER_UNBROKEN_STUN_CUT]%"),
		/datum/eldritch_knowledge/spell/hammer_fissure = list("За [HERETIC_HAMMER_FISSURE_COST] Накала", "на [HERETIC_HAMMER_FISSURE_LENGTH] клеток", "[HERETIC_HAMMER_FISSURE_DAMAGE] урона", "[HERETIC_HAMMER_FISSURE_COOLDOWN / (1 SECONDS)] секунд"),
		/datum/eldritch_knowledge/final_eldritch/hammer_final = list("[HERETIC_HAMMER_HOT_ANVILS] Раскалённые наковальни", "раз в [HERETIC_HAMMER_TOLL_PERIOD / (1 SECONDS)] секунд", "на [HERETIC_HAMMER_GREAT_PROJECTILE_CUT]% слабее", "[HERETIC_HAMMER_HOT_ANVIL_INTEGRITY] прочности", "соседей цели на [HERETIC_HAMMER_SHOCKWAVE_DAMAGE]"),
	)
	for(var/knowledge_type in expected)
		var/datum/eldritch_knowledge/knowledge = new knowledge_type
		var/text = "[knowledge.summary] [jointext(knowledge.details || list(), " ")] [jointext(knowledge.resource_rules || list(), " ")]"
		for(var/fragment in expected[knowledge_type])
			TEST_ASSERT(findtext(text, fragment), "[knowledge_type]: в кодексе есть «[fragment]».")
		qdel(knowledge)
	var/obj/effect/proc_holder/spell/self/heretic_hammer/swing/swing = /obj/effect/proc_holder/spell/self/heretic_hammer/swing
	TEST_ASSERT(findtext(initial(swing.desc), "Затем [HERETIC_HAMMER_SWING_WINDOW / (1 SECONDS)] секунды"), "Описание Замаха называет окно удара.")
	var/atom/movable/screen/alert/heretic_hammer_anvils/alert = /atom/movable/screen/alert/heretic_hammer_anvils
	TEST_ASSERT(findtext(initial(alert.desc), "раз в [HERETIC_HAMMER_TOLL_PERIOD / (1 SECONDS)] секунд"), "Значок наковален называет период Набата.")

/// Удар, Сокрушение и одна стена ровно.
/proc/heretic_hammer_test_slam_once(brute)
	return abs(brute - (HERETIC_HAMMER_WIELDED_FORCE + HERETIC_HAMMER_CRUSH_DAMAGE + HERETIC_HAMMER_SLAM_DAMAGE)) < 0.01

/// Цель для точного счёта урона. В резерве тестов невесомость, без гравитации брошенный дрейфует и после броска; перелом от тупого удара заставляет харкать кровью (+3 ушиба), а без голода рвоты нет.
/datum/unit_test/proc/hammer_test_exact_crew(turf/spot)
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(spot)
	ADD_TRAIT(crew, TRAIT_NOHUNGER, "heretic_hammer_test")
	crew.AddElement(/datum/element/forced_gravity, STANDARD_GRAVITY)
	return crew

/proc/heretic_hammer_test_thrown(atom/movable/thing)
	return !thing.throwing

/// Таран не берёт укреплённую стену, стену и окно, за которыми космос, неразрушимое окно и корпус шаттла; упёршись сразу, ничего не тратит.
/datum/unit_test/heretic_hammer_ram_limits/Run()
	hammer_test_indoors()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/spell/hammer_ram))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	hammer_test_hammer(user, FALSE)
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(0, 0), /turf/closed/wall/r_wall)
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(0, 1), /turf/closed/wall)
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(1, 1), /turf/open/space)
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(1, 2), /turf/open/space)
	var/obj/structure/window/fulltile/outer = allocate(/obj/structure/window/fulltile, heretic_lead_test_spot(0, 2))
	var/obj/structure/window/fulltile/sealed = allocate(/obj/structure/window/fulltile, heretic_lead_test_spot(0, 3))
	sealed.resistance_flags |= INDESTRUCTIBLE
	var/obj/structure/window/shuttle/hull = allocate(/obj/structure/window/shuttle, heretic_lead_test_spot(0, 4))
	for(var/dy in 0 to 4)
		user.forceMove(heretic_lead_test_spot(-1, dy))
		TEST_ASSERT(!hammer_k.ram(user, heretic_lead_test_spot(4, dy)), "Таран в ряду [dy] упирается.")
		TEST_ASSERT(findtext(hammer_k.hammer_failure, "Путь закрыт"), "Отказ Тарана называет причину: [hammer_k.hammer_failure]")
		TEST_ASSERT_EQUAL(get_turf(user), heretic_lead_test_spot(-1, dy), "Упёршийся Таран оставляет на месте.")
	TEST_ASSERT(COOLDOWN_FINISHED(hammer_k, free_ram) && hammer_k.combat_resource == HERETIC_HAMMER_START, "Упёршийся сразу Таран не тратит ни дарового рывка, ни Накала.")
	TEST_ASSERT(istype(heretic_lead_test_spot(0, 0), /turf/closed/wall/r_wall) && iswallturf(heretic_lead_test_spot(0, 1)), "Укреплённая стена и стена у космоса целы.")
	TEST_ASSERT(!QDELETED(outer) && !QDELETED(sealed) && !QDELETED(hull), "Окно у космоса, неразрушимое окно и окно шаттла целы.")

/// Приёмы кнопками, как у игрока: Раскол и Таран по клику не по оси идут по оси, Раскол не ломает голодек, Сотрясение и брызги Наковальни не проходят сквозь стены, сорванный удар называет причину.
/datum/unit_test/heretic_hammer_spell_clicks/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/spell/hammer_ram, /datum/eldritch_knowledge/spell/hammer_quake, /datum/eldritch_knowledge/spell/hammer_anvil, /datum/eldritch_knowledge/spell/hammer_fissure))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/datum/eldritch_knowledge/spell/fissure_k = heretic.get_knowledge(/datum/eldritch_knowledge/spell/hammer_fissure)
	var/datum/eldritch_knowledge/spell/ram_k = heretic.get_knowledge(/datum/eldritch_knowledge/spell/hammer_ram)
	var/datum/eldritch_knowledge/spell/quake_k = heretic.get_knowledge(/datum/eldritch_knowledge/spell/hammer_quake)
	var/datum/eldritch_knowledge/spell/anvil_k = heretic.get_knowledge(/datum/eldritch_knowledge/spell/hammer_anvil)
	user.forceMove(heretic_lead_test_spot(0, 0))
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user)
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(1, 0), /turf/open/floor/holofloor)
	var/turf/open/floor/holo = heretic_lead_test_spot(1, 0)
	holo.baseturfs = /turf/open/floor/plating
	var/mob/living/carbon/human/lined = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	hammer_k.combat_resource = HERETIC_HAMMER_FISSURE_COST
	sand_click(user, fissure_k.granted_spell, heretic_lead_test_spot(4, 1))
	TEST_ASSERT_EQUAL(hammer_k.combat_resource, 0, "Раскол по кнопке: [fissure_k.granted_spell.heretic_failure_reason]")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(lined, TYPE_PROC_REF(/mob/living, IsKnockdown)), 2 SECONDS, "Раскол по оси"), "Клик чуть выше оси - трещина всё равно бежит по оси.")
	TEST_ASSERT(istype(heretic_lead_test_spot(1, 0), /turf/open/floor/holofloor), "Раскол не ломает пол голодека.")
	var/turf/ram_start = heretic_lead_test_spot(0, 2)
	user.forceMove(ram_start)
	sand_click(user, ram_k.granted_spell, heretic_lead_test_spot(4, 3))
	TEST_ASSERT(user.y == ram_start.y && user.x > ram_start.x, "Таран по клику не по оси идёт по оси: [user.x - run_loc_floor_bottom_left.x],[user.y - run_loc_floor_bottom_left.y].")
	user.forceMove(heretic_lead_test_spot(2, 2))
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(3, 2), /turf/closed/wall)
	var/mob/living/carbon/human/behind = heretic_lead_test_crew(heretic_lead_test_spot(4, 2))
	var/mob/living/carbon/human/open = heretic_lead_test_crew(heretic_lead_test_spot(2, 4))
	hammer_k.combat_resource = HERETIC_HAMMER_QUAKE_COST
	var/obj/effect/proc_holder/spell/quake_spell = quake_k.granted_spell
	TEST_ASSERT(quake_spell.cast_check(FALSE, user), "Сотрясение по кнопке: [quake_spell.heretic_failure_reason]")
	quake_spell.choose_targets(user)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(open, TYPE_PROC_REF(/mob/living, has_status_effect), /datum/status_effect/heretic_hammer_dazed), 2 SECONDS, "Сотрясение"), "Сотрясение бьёт открытого.")
	TEST_ASSERT(!behind.has_status_effect(/datum/status_effect/heretic_hammer_dazed) && !behind.getStaminaLoss(), "Сотрясение не бьёт сквозь стену.")
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(5, 4), /turf/closed/wall)
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(4, 5), /turf/closed/wall)
	var/mob/living/carbon/human/struck = heretic_lead_test_crew(heretic_lead_test_spot(4, 4))
	var/mob/living/carbon/human/pinched = heretic_lead_test_crew(heretic_lead_test_spot(5, 5))
	var/mob/living/carbon/human/splashed = heretic_lead_test_crew(heretic_lead_test_spot(4, 3))
	hammer_k.combat_resource = HERETIC_HAMMER_ANVIL_COST
	sand_click(user, anvil_k.granted_spell, heretic_lead_test_spot(4, 4))
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(struck, TYPE_PROC_REF(/mob/living, IsKnockdown)), 3 SECONDS, "Наковальня по кнопке"), "Наковальня по кнопке падает на клетку.")
	TEST_ASSERT(!pinched.getStaminaLoss(), "Брызги наковальни не проходят между двумя стенами.")
	TEST_ASSERT(splashed.getStaminaLoss() >= HERETIC_HAMMER_ANVIL_SPLASH_STAMINA, "Брызги наковальни бьют соседа на открытой клетке.")
	TEST_ASSERT(ISWIELDED(hammer), "Молот в двух руках.")
	user.Paralyze(2 SECONDS)
	TEST_ASSERT(findtext(hammer_k.strike_break_reason(user), "оглушили"), "Сорванный удар называет оглушение: [hammer_k.strike_break_reason(user)]")
	user.SetParalyzed(0)
	user.dropItemToGround(hammer, force = TRUE)
	TEST_ASSERT(findtext(hammer_k.strike_break_reason(user), "двух руках"), "Без Молота в руках срыв называет Молот: [hammer_k.strike_break_reason(user)]")

/// Сокрушающий удар и вбивка по цели охоты засчитывают приём пути в дело.
/datum/unit_test/heretic_hammer_combat_deed/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/hammer_nail))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user)
	var/mob/living/carbon/human/crushed = heretic_lead_test_crew(heretic_lead_test_spot(2, 2), "Assistant")
	heretic.set_hunt_target(crushed.mind)
	TEST_ASSERT(hammer_k.swing(user), "Замах: [hammer_k.swing_block_reason(user)]")
	var/datum/status_effect/heretic_hammer_swing/swing = user.has_status_effect(/datum/status_effect/heretic_hammer_swing)
	TEST_ASSERT(wait_for_var(swing, NAMEOF(swing, ready), TRUE, HERETIC_HAMMER_SWING_WINDUP + 2 SECONDS), "Замах готов.")
	hammer_test_hit(user, hammer, crushed)
	TEST_ASSERT("hunt:[REF(crushed.mind)]" in heretic.deed.counted_keys, "Сокрушающий удар по цели охоты засчитан в дело.")
	heretic.deed.combat_tiers.Cut()
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	var/mob/living/carbon/human/nailed = heretic_lead_test_crew(heretic_lead_test_spot(2, 3), "Assistant")
	heretic.set_hunt_target(nailed.mind)
	nailed.Knockdown(HERETIC_HAMMER_NAIL_TIME)
	hammer_k.combat_resource = HERETIC_HAMMER_NAIL_COST
	hammer_test_hit(user, hammer, nailed, INTENT_GRAB)
	TEST_ASSERT_NOTNULL(nailed.has_status_effect(/datum/status_effect/heretic_hammer_nailed), "Цель охоты вбита в пол.")
	TEST_ASSERT("hunt:[REF(nailed.mind)]" in heretic.deed.counted_keys, "Вбивка цели охоты засчитана в дело.")

/datum/unit_test/heretic_hammer_unbroken_tackle
	var/tackle_roll

/datum/unit_test/heretic_hammer_unbroken_tackle/proc/hammer_test_note_roll(datum/source, roll)
	SIGNAL_HANDLER
	tackle_roll = roll

/// Несокрушимый на деле: настоящий подкат не валит, а паралич роняет Молот из любой руки.
/datum/unit_test/heretic_hammer_unbroken_tackle/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/hammer_unbroken))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user)
	TEST_ASSERT(hammer_k.braced, "Молот в двух руках держит Несокрушимого.")
	// Бросок 3-4 и 5+ кладут цель через KnockToFloor(), мимо сигналов оглушения.
	for(var/max_roll in list(4, INFINITY))
		user.forceMove(heretic_lead_test_spot(1, 2))
		user.adjustStaminaLoss(-user.getStaminaLoss())
		var/mob/living/carbon/human/sacker = heretic_lead_test_crew(heretic_lead_test_spot(-1, 2))
		var/datum/component/tackler/tackler = sacker.AddComponent(/datum/component/tackler, 0, 1 SECONDS, 4, 1, 20)
		tackler.max_roll = max_roll
		RegisterSignal(sacker, COMSIG_CARBON_TACKLED, PROC_REF(hammer_test_note_roll))
		tackle_roll = null
		sacker.tackling = TRUE
		sacker.throw_at(user, 4, 1, sacker, FALSE)
		TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_hammer_test_thrown), sacker), 3 SECONDS, "подкат"), "Подкат долетает.")
		TEST_ASSERT(max_roll == INFINITY ? tackle_roll >= 5 : tackle_roll == max_roll, "Бросок подката [tackle_roll], нужен [max_roll == INFINITY ? "5+" : max_roll].")
		TEST_ASSERT(!user.IsKnockdown() && !user.IsParalyzed(), "Подкат с броском [tackle_roll] не валит еретика с Молотом в двух руках.")
		TEST_ASSERT(!user.resting && CHECK_MOBILITY(user, MOBILITY_STAND), "После подката с броском [tackle_roll] еретик стоит на ногах.")
		qdel(sacker)
	for(var/left_hand in list(TRUE, FALSE))
		user.SetParalyzed(0)
		user.SetKnockdown(0)
		if(user.is_holding(hammer))
			user.dropItemToGround(hammer, force = TRUE)
		if(left_hand)
			user.put_in_l_hand(hammer)
		else
			user.put_in_r_hand(hammer)
		if(user.get_active_held_item() != hammer)
			user.swap_hand(user.get_held_index_of_item(hammer))
		hammer.attack_self(user)
		TEST_ASSERT(ISWIELDED(hammer) && hammer_k.braced, "Молот снова в двух руках.")
		COOLDOWN_START(hammer_k, rage, 1 MINUTES)
		user.Paralyze(3 SECONDS)
		TEST_ASSERT(!user.is_holding(hammer), "Парализованный роняет Молот из [left_hand ? "левой" : "правой"] руки.")
	user.SetParalyzed(0)

/// Трещину Звона даёт Молот того, кто бьёт, а не того, кто ставил метку; метка без трещин видна бледной трещиной.
/datum/unit_test/heretic_hammer_mark_striker/Run()
	var/datum/antagonist/heretic/marker = hammer_test_heretic()
	var/datum/antagonist/heretic/smith = hammer_test_heretic()
	var/mob/living/carbon/human/smith_body = smith.owner.current
	smith_body.forceMove(heretic_lead_test_spot(1, 3))
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(smith_body)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 3))
	var/datum/status_effect/eldritch/hammer/mark = target.apply_status_effect(/datum/status_effect/eldritch/hammer, hammer_test_knowledge(marker))
	TEST_ASSERT_NOTNULL(mark, "Звон наковальни повешен.")
	var/list/drawn = list()
	mark.update_owner_underlay(target, drawn)
	TEST_ASSERT(length(drawn) == 1 && mark.marked_underlay.alpha == HERETIC_HAMMER_MARK_FAINT_ALPHA, "Метка без трещин видна бледной трещиной.")
	hammer_test_hit(smith_body, hammer, target)
	TEST_ASSERT_EQUAL(mark.cracks, 1, "Трещину даёт Молот бьющего еретика.")

/// Одна струя огнетушителя - одно остывание, хотя частицы бьют в наковальню дольше секунды.
/datum/unit_test/heretic_hammer_anvil_extinguisher/Run()
	var/list/fixture = hammer_test_ascended()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/hammer_final/finale = fixture["finale"]
	TEST_ASSERT(finale.raise_anvils(user), "Наковальни падают.")
	var/obj/structure/heretic_hammer_hot_anvil/anvil = finale.hot_anvils[1]
	hammer_test_douse(anvil, 1)
	sleep(1.2 SECONDS)
	hammer_test_douse(anvil, 1)
	TEST_ASSERT_EQUAL(anvil.douses, 1, "Брызги одной струи за 1,2 секунды - одно остывание.")
	anvil = finale.hot_anvils[2]
	var/turf/side
	for(var/direction in GLOB.cardinals)
		var/turf/open/candidate = get_step(anvil, direction)
		if(istype(candidate) && !candidate.is_blocked_turf(exclude_mobs = FALSE))
			side = candidate
			break
	TEST_ASSERT_NOTNULL(side, "Рядом с наковальней есть место.")
	var/mob/living/carbon/human/crew = heretic_lead_test_crew(side)
	var/obj/item/extinguisher/extinguisher = allocate(/obj/item/extinguisher, side)
	crew.put_in_hands(extinguisher)
	extinguisher.safety = FALSE
	extinguisher.precision = TRUE
	extinguisher.last_use = -100
	extinguisher.afterattack(anvil, crew, TRUE)
	sleep(2 SECONDS)
	TEST_ASSERT_EQUAL(anvil.douses, 1, "Одна струя огнетушителя засчитана один раз.")

/// Наковальня вознесения не встаёт вплотную к выбранной клетке, в проход шириной в клетку и у двери.
/datum/unit_test/heretic_hammer_anvil_spots/Run()
	var/list/fixture = hammer_test_ascended()
	var/datum/eldritch_knowledge/final_eldritch/hammer_final/finale = fixture["finale"]
	var/turf/middle = heretic_lead_test_spot(2, 2)
	TEST_ASSERT(finale.anvil_spot_valid(middle, TRUE, list()), "Посреди зала наковальне место есть.")
	TEST_ASSERT(!finale.anvil_spot_valid(middle, TRUE, list(heretic_lead_test_spot(3, 3))), "Вплотную к выбранной клетке вторая не встаёт.")
	TEST_ASSERT(finale.anvil_spot_valid(middle, TRUE, list(heretic_lead_test_spot(4, 2))), "Через клетку от выбранной - можно.")
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(1, 4), /turf/closed/wall)
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(3, 4), /turf/closed/wall)
	TEST_ASSERT(!finale.anvil_spot_valid(heretic_lead_test_spot(2, 4), TRUE, list()), "В проход шириной в клетку наковальня не встаёт.")
	allocate(/obj/machinery/door/firedoor, heretic_lead_test_spot(0, 1))
	TEST_ASSERT(!finale.anvil_spot_valid(heretic_lead_test_spot(1, 1), TRUE, list()), "У двери наковальня не встаёт.")

/// Обряд Последнего удара на станции: Великий Молот остаётся в руке, Раскалённые наковальни падают в общие отсеки и не вплотную друг к другу.
/datum/unit_test/heretic_hammer_ascension_ritual/Run()
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.ascension_notice_sent = TRUE
	heretic.simulated = TRUE
	heretic.total_sacrifices = HERETIC_ASCENSION_SACRIFICES
	hammer_test_hammer(user, FALSE)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/hammer_final)
	var/datum/eldritch_knowledge/final_eldritch/hammer_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/hammer_final)
	finale.ritual_time = 0
	for(var/body_index in 1 to HERETIC_ASCENSION_BODIES)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, get_turf(user))
		body.last_mind = allocate_mind()
		body.stat = DEAD
	TEST_ASSERT(rune.do_ritual(user, finale), "Обряд Последнего удара завершается вознесением.")
	var/obj/item/melee/sickly_blade/hammer/held = locate() in user.held_items
	TEST_ASSERT(held?.great, "Обряд перековывает Молот в руке в Великий.")
	TEST_ASSERT(finale.anvils_raised && length(finale.hot_anvils), "Обряд роняет Раскалённые наковальни.")
	var/list/turf/placed = list()
	for(var/obj/structure/heretic_hammer_hot_anvil/anvil as anything in finale.hot_anvils)
		TEST_ASSERT(is_station_level(anvil.z) && heretic_station_public_area(get_area(anvil)), "Наковальня падает в общий отсек станции: [AREACOORD(anvil)].")
		for(var/turf/other as anything in placed)
			TEST_ASSERT(get_dist(other, anvil) > 1, "Наковальни не падают вплотную друг к другу.")
		placed += get_turf(anvil)
	heretic_release_sky(finale)

/// Вбивка, кончившаяся сама, засчитывает шаг лома, и урок не застревает.
/datum/unit_test/heretic_hammer_lesson_pry_end/Run()
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_HAMMER, /datum/eldritch_knowledge/base_hammer)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = heretic.get_knowledge(/datum/eldritch_knowledge/base_hammer)
	user.forceMove(heretic_lead_test_spot(3, 2))
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/datum/heretic_path_lesson/hammer/lesson = new(null, hammer_k, user, target)
	allocated += lesson
	target.Knockdown(HERETIC_HAMMER_NAIL_TIME)
	var/datum/status_effect/heretic_hammer_nailed/nail = target.apply_status_effect(/datum/status_effect/heretic_hammer_nailed, hammer_k)
	TEST_ASSERT_NOTNULL(nail, "Мишень вбита.")
	lesson.set_stage(5)
	qdel(nail)
	TEST_ASSERT_EQUAL(lesson.stage, 6, "Вбивка, кончившаяся сама, засчитывает шаг лома.")

/// Удар о преграду даёт ровно HERETIC_HAMMER_SLAM_DAMAGE: лёгкому движок не даёт ничего, и Молот добирает своё; окно бьёт так же, как стена.
/datum/unit_test/heretic_hammer_slam_exact/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/hammer_grasp))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	user.forceMove(heretic_lead_test_spot(3, 3))
	var/obj/item/melee/sickly_blade/hammer/hammer = hammer_test_hammer(user, FALSE)
	var/mob/living/carbon/human/grasped = hammer_test_exact_crew(heretic_lead_test_spot(4, 3))
	grasped.mob_weight = MOB_WEIGHT_LIGHT
	user.a_intent = INTENT_HARM
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(grasped, user, TRUE)
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_hammer_test_thrown), grasped), 3 SECONDS, "отброс Хваткой"), "Хватка кузни отбрасывает.")
	TEST_ASSERT_EQUAL(get_turf(grasped), heretic_lead_test_spot(5, 3), "Отброшенный Хваткой упирается в стену.")
	TEST_ASSERT_EQUAL(grasped.getBruteLoss(), 10 + HERETIC_HAMMER_SLAM_DAMAGE, "Лёгкий, отброшенный Хваткой в стену: 10 самой Хватки Мансуса и ровно [HERETIC_HAMMER_SLAM_DAMAGE] о стену.")
	user.remove_status_effect(/datum/status_effect/heretic_hammer_catch)
	hammer.attack_self(user)
	allocate(/obj/structure/window/fulltile, heretic_lead_test_spot(5, 1))
	var/mob/living/carbon/human/light = hammer_test_exact_crew(heretic_lead_test_spot(4, 2))
	light.mob_weight = MOB_WEIGHT_LIGHT
	var/mob/living/carbon/human/glassed = hammer_test_exact_crew(heretic_lead_test_spot(4, 1))
	var/list/cases = list("лёгкий о стену" = light, "о окно" = glassed)
	for(var/label in cases)
		var/mob/living/carbon/human/target = cases[label]
		user.forceMove(get_step(target, WEST))
		TEST_ASSERT(hammer_k.swing(user), "Замах: [hammer_k.swing_block_reason(user)]")
		var/datum/status_effect/heretic_hammer_swing/swing = user.has_status_effect(/datum/status_effect/heretic_hammer_swing)
		TEST_ASSERT(wait_for_var(swing, NAMEOF(swing, ready), TRUE, HERETIC_HAMMER_SWING_WINDUP + 2 SECONDS), "Замах готов.")
		hammer_test_hit(user, hammer, target)
		TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_hammer_test_landed), target), 3 SECONDS, "удар [label]"), "Сокрушённый ([label]) падает.")
		TEST_ASSERT(heretic_hammer_test_slam_once(target.getBruteLoss()), "Сокрушающий удар, [label]: удар, +[HERETIC_HAMMER_CRUSH_DAMAGE] и ровно [HERETIC_HAMMER_SLAM_DAMAGE] о преграду: [target.getBruteLoss()].")
	TEST_ASSERT_EQUAL(get_turf(glassed), heretic_lead_test_spot(4, 1), "Окно останавливает сокрушённого.")

/// Волна Сотрясения докатывается до клеток радиуса со своей задержкой и не проходит сквозь шлюз; разбитая наковальня рассыпается обломками.
/datum/unit_test/heretic_hammer_quake_ripple_anvil_break/Run()
	for(var/distance in 1 to HERETIC_HAMMER_QUAKE_RANGE)
		TEST_ASSERT(icon_exists(HERETIC_HAMMER_FX_ICON, "quake_ripple_[distance]"), "Есть волна для клетки на расстоянии [distance].")
	var/turf/center = heretic_lead_test_spot(2, 2)
	allocate(/obj/machinery/door/airlock, heretic_lead_test_spot(3, 2))
	allocate(/obj/effect/temp_visual/heretic_hammer/quake_ring, center)
	var/list/ripple_states = list()
	for(var/obj/effect/temp_visual/heretic_hammer/quake_ripple/ripple in range(HERETIC_HAMMER_QUAKE_RANGE, center))
		ripple_states["[ripple.x - center.x],[ripple.y - center.y]"] = ripple.icon_state
		qdel(ripple)
	TEST_ASSERT_NULL(ripple_states["0,0"], "Под самим еретиком волны нет, там кольцо удара.")
	TEST_ASSERT_EQUAL(ripple_states["0,1"], "quake_ripple_1", "Соседняя клетка - первая волна.")
	TEST_ASSERT_EQUAL(ripple_states["2,2"], "quake_ripple_2", "Клетка через одну - вторая волна, позже первой.")
	TEST_ASSERT_NULL(ripple_states["2,0"], "Волна не проходит сквозь закрытый шлюз.")
	var/turf/anvil_spot = heretic_lead_test_spot(0, 0)
	var/obj/structure/heretic_hammer_anvil/anvil = allocate(/obj/structure/heretic_hammer_anvil, anvil_spot)
	anvil.deconstruct(FALSE)
	TEST_ASSERT(QDELETED(anvil), "Наковальня рассыпается.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_hammer/anvil_break) in anvil_spot, "Наковальня раскалывается на куски, а не просто пропадает.")

/// Сотрясение держат стены, закрытые двери, окна и фальшстены, краевые - своей стороной; решётка, открытая дверь и боковой винтдор пропускают.
/datum/unit_test/heretic_hammer_wave_blockers/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic(list(/datum/eldritch_knowledge/spell/hammer_quake))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_hammer/hammer_k = hammer_test_knowledge(heretic)
	user.forceMove(heretic_lead_test_spot(2, 2))
	hammer_test_hammer(user)
	var/list/blockers = list(
		allocate(/obj/machinery/door/airlock, heretic_lead_test_spot(3, 2)),
		allocate(/obj/structure/window/fulltile, heretic_lead_test_spot(1, 2)),
		allocate(/obj/structure/falsewall, heretic_lead_test_spot(2, 4)),
	)
	var/obj/machinery/door/window/facing = allocate(/obj/machinery/door/window, heretic_lead_test_spot(2, 1))
	facing.setDir(NORTH)
	blockers += facing
	var/list/victims = list(
		"за шлюзом" = heretic_lead_test_crew(heretic_lead_test_spot(4, 2)),
		"за окном" = heretic_lead_test_crew(heretic_lead_test_spot(0, 2)),
		"за фальшстеной" = heretic_lead_test_crew(heretic_lead_test_spot(2, 5)),
		"за винтдором лицом к удару" = heretic_lead_test_crew(heretic_lead_test_spot(2, 0)),
	)
	var/mob/living/carbon/human/open = heretic_lead_test_crew(heretic_lead_test_spot(1, 3))
	hammer_k.combat_resource = HERETIC_HAMMER_QUAKE_COST
	TEST_ASSERT(hammer_k.quake(user), "Сотрясение начинается.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(open, TYPE_PROC_REF(/mob/living, IsKnockdown)), 2 SECONDS, "Сотрясение"), "Сотрясение бьёт соседа по открытой диагонали.")
	for(var/label in victims)
		var/mob/living/carbon/human/victim = victims[label]
		TEST_ASSERT(!victim.getStaminaLoss() && !victim.has_status_effect(/datum/status_effect/heretic_hammer_dazed), "Сотрясение не бьёт [label].")
	QDEL_LIST(blockers)
	var/obj/machinery/door/airlock/opened = allocate(/obj/machinery/door/airlock, heretic_lead_test_spot(3, 2))
	INVOKE_ASYNC(opened, TYPE_PROC_REF(/obj/machinery/door, open), 2)
	TEST_ASSERT(wait_for_var(opened, NAMEOF(opened, density), FALSE, 3 SECONDS), "Шлюз открыт.")
	allocate(/obj/structure/grille, heretic_lead_test_spot(1, 2))
	var/obj/machinery/door/window/side = allocate(/obj/machinery/door/window, heretic_lead_test_spot(2, 3))
	side.setDir(EAST)
	var/obj/machinery/door/window/own = allocate(/obj/machinery/door/window, heretic_lead_test_spot(2, 2))
	own.setDir(SOUTH)
	hammer_k.combat_resource = HERETIC_HAMMER_QUAKE_COST
	TEST_ASSERT(hammer_k.quake(user), "Второе Сотрясение начинается.")
	var/mob/living/carbon/human/door_side = victims["за шлюзом"]
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(door_side, TYPE_PROC_REF(/mob/living, has_status_effect), /datum/status_effect/heretic_hammer_dazed), 2 SECONDS, "второе Сотрясение"), "Открытый шлюз волну не держит.")
	var/mob/living/carbon/human/grille_side = victims["за окном"]
	TEST_ASSERT(grille_side.has_status_effect(/datum/status_effect/heretic_hammer_dazed), "Решётка волну не держит.")
	var/mob/living/carbon/human/side_victim = victims["за фальшстеной"]
	TEST_ASSERT(side_victim.has_status_effect(/datum/status_effect/heretic_hammer_dazed), "Винтдор боком к удару волну не держит.")
	var/mob/living/carbon/human/own_side = victims["за винтдором лицом к удару"]
	TEST_ASSERT(!own_side.has_status_effect(/datum/status_effect/heretic_hammer_dazed), "Закрытый винтдор на своей клетке держит волну своей стороной.")

/// Ударная волна Великого Молота не бьёт соседей цели за стеной и за закрытым винтдором, открытого соседа бьёт.
/datum/unit_test/heretic_hammer_shockwave_blockers/Run()
	var/datum/antagonist/heretic/heretic = hammer_test_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/melee/sickly_blade/hammer/great = hammer_test_hammer(user, TRUE, /obj/item/melee/sickly_blade/hammer/great)
	TEST_ASSERT(great.great && ISWIELDED(great), "Великий Молот в двух руках.")
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(3, 2), /turf/closed/wall)
	allocate(/datum/heretic_hammer_test_turf, heretic_lead_test_spot(2, 1), /turf/closed/wall)
	var/obj/machinery/door/window/edge = allocate(/obj/machinery/door/window, heretic_lead_test_spot(2, 2))
	edge.setDir(NORTH)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 2))
	var/mob/living/carbon/human/open = heretic_lead_test_crew(heretic_lead_test_spot(1, 3))
	var/mob/living/carbon/human/behind_door = heretic_lead_test_crew(heretic_lead_test_spot(2, 3))
	var/mob/living/carbon/human/behind_walls = heretic_lead_test_crew(heretic_lead_test_spot(3, 1))
	hammer_test_hit(user, great, target)
	TEST_ASSERT_EQUAL(get_turf(target), heretic_lead_test_spot(2, 2), "Стена не даёт отбросить цель.")
	TEST_ASSERT(open.getBruteLoss() >= HERETIC_HAMMER_SHOCKWAVE_DAMAGE, "Ударная волна бьёт открытого соседа.")
	TEST_ASSERT(!behind_door.getBruteLoss(), "Ударная волна не проходит сквозь закрытый винтдор.")
	TEST_ASSERT(!behind_walls.getBruteLoss(), "Ударная волна не проходит между двумя стенами.")
