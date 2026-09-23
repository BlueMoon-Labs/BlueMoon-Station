#define HERETIC_VOID_WINTER_HEALING 1

/datum/eldritch_knowledge/base_void
	name = "Мерцание зимы"
	desc = "Открывает Путь Пустоты: собирайте осколки зимы, замедляйте врагов магией и выбирайте дистанцию боя. Скованность держится 4 секунды после последнего воздействия; способности и поля обновляют её, не складывая силу замедления. Нож на руне при температуре не выше 0 °C или внутри вашего Зимнего предела превращается в клинок Пустоты. Зимний предел создаёт область холода и молчания."
	ritual_hint = "Подойдут кухонные и боевые ножи, тесаки и заточки. Воздух на клетке руны должен быть не теплее 0 °C. Вместо охлаждения комнаты можно накрыть руну своим Зимним пределом: поле должно сохраняться до конца обряда."
	gain_text = "В тишине между ударами сердца я услышал снег."
	required_atoms = list(/obj/item/kitchen/knife)
	result_atoms = list(/obj/item/melee/sickly_blade/void)
	cost = 0
	route = PATH_VOID

/datum/eldritch_knowledge/base_void/recipe_snowflake_check(list/atoms, loc, list/selected_atoms, mob/living/user)
	var/turf/open/floor/floor = get_turf(loc)
	if(!istype(floor))
		return FALSE
	if(floor.GetTemperature() <= T0C)
		return TRUE
	var/obj/effect/heretic_combat_zone/void/winter = combat_zone
	return user?.mind && istype(winter) && !QDELETED(winter) && winter.master_mind?.resolve() == user.mind && (floor in winter.field_turfs)

/datum/eldritch_knowledge/void_grasp
	name = "Хватка Пустоты"
	desc = "Хватка замедляет врага на 4 секунды независимо от температуры тела, ненадолго лишает голоса и охлаждает. Повторная хватка обновляет время замедления. Улучшенная хватка дополнительно обжигает уже скованного Пустотой врага: 5 ожогов на втором уровне и 10 на третьем."
	gain_text = "Я протянул руку и на мгновение услышал чужую тишину."
	cost = 1
	route = PATH_VOID

/datum/eldritch_knowledge/void_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!iscarbon(target) || !heretic_can_affect(user, target))
		return FALSE
	var/mob/living/carbon/victim = target
	if(victim.has_status_effect(/datum/status_effect/heretic_void_chill) && passive_level > 1)
		victim.adjustFireLoss((passive_level - 1) * 5)
	victim.adjust_bodytemperature(-passive_values[passive_level])
	victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
	victim.silent = max(victim.silent, 3)
	return TRUE

/datum/eldritch_knowledge/cold_snap
	name = "Путь Аристократа"
	desc = "Вы перестаёте дышать и получаете защиту от низких температур. Вакуум всё ещё опасен из-за недостатка давления. На полу с воздухом не теплее 0 °C, внутри своего Зимнего предела или поля фонаря тишины вы восстанавливаете по 1 ушибу и 1 ожогу в секунду."
	gain_text = "Аристократ стоял среди снега, не оставляя в воздухе ни облачка пара."
	cost = 1
	route = PATH_VOID

/datum/eldritch_knowledge/cold_snap/on_body_gain(mob/living/user)
	if(!user)
		return
	ADD_TRAIT(user, TRAIT_RESISTCOLD, REF(src))
	ADD_TRAIT(user, TRAIT_NOBREATH, REF(src))

/datum/eldritch_knowledge/cold_snap/on_body_lose(mob/living/user)
	if(!user)
		return
	REMOVE_TRAIT(user, TRAIT_RESISTCOLD, REF(src))
	REMOVE_TRAIT(user, TRAIT_NOBREATH, REF(src))

/datum/eldritch_knowledge/cold_snap/on_life(mob/user)
	if(!isliving(user) || user.stat == DEAD || !in_winter(user))
		return
	heretic_heal_damage(user, HERETIC_VOID_WINTER_HEALING, HERETIC_VOID_WINTER_HEALING)

/datum/eldritch_knowledge/cold_snap/proc/in_winter(mob/living/user)
	var/turf/open/floor/floor = get_turf(user)
	if(!istype(floor))
		return FALSE
	if(floor.GetTemperature() <= T0C)
		return TRUE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_void/path = heretic?.get_knowledge(/datum/eldritch_knowledge/base_void)
	if(!path)
		return FALSE
	for(var/obj/effect/heretic_combat_zone/void/winter in list(path.combat_zone, path.relic_zone))
		if(!QDELETED(winter) && (floor in winter.field_turfs))
			return TRUE
	return FALSE

/datum/eldritch_knowledge/void_cloak
	name = "Плащ пустоты"
	desc = "Соедините осколок стекла, верхнюю одежду и простыню, чтобы создать плащ Пустоты. Поднятый капюшон скрывает плащ и содержимое его карманов."
	gain_text = "Сова хранит то, что существует только в чужой памяти."
	cost = 1
	result_atoms = list(/obj/item/clothing/suit/hooded/cultrobes/void)
	required_atoms = list(/obj/item/shard, /obj/item/clothing/suit, /obj/item/bedsheet)

/datum/eldritch_knowledge/void_mark
	name = "Метка Пустоты"
	desc = "Хватка накладывает Метку Пустоты. Удар клинком Пустоты активирует её: наносит 15 холодовых ожогов, замедляет врага на 4 секунды независимо от температуры, охлаждает, ненадолго лишает голоса и даёт осколок зимы. Замедление от хватки и метки обновляется, не складываясь."
	gain_text = "Я научился отмечать людей, которым суждено услышать снег."
	cost = 2
	route = PATH_VOID

/datum/eldritch_knowledge/void_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!heretic_can_affect(user, target))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/void)
	return TRUE

/datum/eldritch_knowledge/spell/void_phase
	name = "Пустотный сдвиг"
	desc = "Телепортируйтесь на открытую клетку в пределах 3–7 клеток; враги рядом с выходом и входом получают по 20 ушибов и замедляются на 4 секунды. Соедините шахтёрский фонарь, осколок стекла и лист бумаги, чтобы создать фонарь тишины. За осколок зимы он несёт вокруг вас поле замедления, холода и тишины, пока вы держите его в руке."
	required_atoms = list(/obj/item/flashlight/lantern, /obj/item/shard, /obj/item/paper)
	result_atoms = list(/obj/item/heretic_relic/hush_lantern)
	gain_text = "Аристократ сделал шаг и оставил за собой пустое место."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/void_blink
	route = PATH_VOID

/datum/eldritch_knowledge/rune_carver
	name = "Нож резьбы"
	desc = "Соедините нож, осколок стекла и лист бумаги, чтобы создать резной нож. Им можно вырезать до трёх ловушек на полу."
	gain_text = "Каждый надрез напоминает реальности о её границах."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/shard, /obj/item/paper)
	result_atoms = list(/obj/item/melee/rune_knife)

/datum/eldritch_knowledge/crucible
	name = "Разинутый тигель"
	desc = "Соедините бак с водой и стол, чтобы создать разинутый тигель. Он сам набирает долю вязкой жидкости каждые 30 секунд, органы и части тел добавляют долю сразу; полный тигель из трёх долей варит одно зелье. Тигель у вас один: повторный обряд переносит его на новое место вместе с содержимым."
	gain_text = "Отверженный император не ответил, но его голод остался со мной."
	cost = 1
	required_atoms = list(/obj/structure/reagent_dispensers/watertank, /obj/structure/table)
	result_atoms = list(/obj/structure/eldritch_crucible)
	var/datum/weakref/crucible_ref

/datum/eldritch_knowledge/crucible/on_finished_recipe(mob/living/user, list/atoms, loc)
	var/obj/structure/eldritch_crucible/crucible = new(loc)
	var/obj/structure/eldritch_crucible/previous = crucible_ref?.resolve()
	if(previous)
		crucible.set_mass(previous.current_mass)
		previous.visible_message(span_warning("[previous] проваливается сам в себя и исчезает."))
		qdel(previous)
	crucible_ref = WEAKREF(crucible)
	return TRUE

/datum/eldritch_knowledge/void_blade_upgrade
	name = "Ищущий клинок"
	desc = "Каждое ранение вашим клинком Пустоты дополнительно наносит 8 холодовых ожогов и замедляет на 4 секунды. Держите клинок в активной руке и нажмите ЛКМ по отмеченному врагу вне досягаемости удара, в поле зрения и не дальше 5 клеток: вы переместитесь рядом и ударите. Shift не требуется. Сдвиг восстанавливается 8 секунд, а к цели внутри вашего домена Бесконечной пустоты — 2 секунды; осмотрите клинок, чтобы узнать готовность. Возле цели нужна клетка без препятствий. Антимагия защищает от дополнительных эффектов и сдвига."
	gain_text = "Метки в снегу связывают места, которые никогда не были рядом."
	cost = 2
	route = PATH_VOID
	COOLDOWN_DECLARE(blink_cooldown)
	COOLDOWN_DECLARE(blink_feedback)
	COOLDOWN_DECLARE(blink_failure_log)
	var/blink_failure_reason
	var/blade_damage = 8

/datum/eldritch_knowledge/void_blade_upgrade/on_eldritch_blade(atom/target, mob/user, proximity_flag, click_parameters)
	if(!isliving(target))
		return
	var/mob/living/victim = target
	victim.adjustFireLoss(blade_damage)
	victim.apply_status_effect(/datum/status_effect/heretic_void_chill)

/datum/eldritch_knowledge/void_blade_upgrade/on_ranged_attack_eldritch_blade(atom/target, mob/user, click_parameters)
	blink_failure_reason = null
	if(!isliving(user) || !isliving(target))
		return FALSE
	var/mob/living/victim = target
	var/mob/living/living_user = user
	if(!CHECK_MOBILITY(living_user, MOBILITY_USE) || living_user.incapacitated())
		return reject_blink(user, "Вы не можете действовать: дождитесь окончания оглушения или освободитесь.")
	var/obj/item/melee/sickly_blade/void/blade = user.get_active_held_item()
	if(!istype(blade))
		return reject_blink(user, "Возьмите клинок Пустоты в активную руку.")
	if(!COOLDOWN_FINISHED(src, blink_cooldown))
		return reject_blink(user, "Сдвиг восстановится через [DisplayTimeText(COOLDOWN_TIMELEFT(src, blink_cooldown))].")
	if(!isturf(user.loc) || !isturf(victim.loc))
		return reject_blink(user, "Вы и цель должны находиться вне контейнеров и укрытий.")
	if(user.z != victim.z || get_dist(user, victim) > 5)
		return reject_blink(user, "Цель должна быть на вашем уровне, не дальше 5 клеток.")
	if(!(victim in view(5, user)))
		return reject_blink(user, "Цель должна быть в поле зрения.")
	if(victim.stat == DEAD || victim == user || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		return reject_blink(user, "Выберите живого противника.")
	if(!victim.has_status_effect(/datum/status_effect/eldritch/void))
		return reject_blink(user, "На цели нет Метки Пустоты. Наложите её хваткой или доменом.")
	if(!heretic_can_affect(user, victim, chargecost = 0))
		return reject_blink(user, "Защита цели от магии блокирует сдвиг.")
	var/turf/destination
	for(var/direction in GLOB.cardinals)
		var/turf/candidate = get_step(victim, direction)
		if(isopenturf(candidate) && !is_blocked_turf(candidate, TRUE))
			destination = candidate
			break
	if(!destination)
		return reject_blink(user, "Возле цели нет клетки без препятствий.")
	if(!do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC))
		return reject_blink(user, "Перемещение заблокировано: покиньте зону запрета телепортации или снимите удерживающий эффект.")
	COOLDOWN_START(src, blink_cooldown, in_own_domain(user, victim) ? HERETIC_VOID_DOMAIN_BLINK_COOLDOWN : HERETIC_VOID_BLINK_COOLDOWN)
	blade.melee_attack_chain(user, victim, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)
	return TRUE

/datum/eldritch_knowledge/void_blade_upgrade/proc/in_own_domain(mob/living/user, mob/living/victim)
	var/datum/status_effect/heretic_domain/presence = victim.has_status_effect(/datum/status_effect/heretic_domain)
	for(var/obj/effect/domain_expansion/domain as anything in presence?.domains)
		if(user in domain.immune)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/void_blade_upgrade/proc/reject_blink(mob/user, reason)
	blink_failure_reason = reason
	if(COOLDOWN_FINISHED(src, blink_feedback))
		COOLDOWN_START(src, blink_feedback, 1 SECONDS)
		to_chat(user, span_warning("[name]: [reason]"))
	if(COOLDOWN_FINISHED(src, blink_failure_log))
		COOLDOWN_START(src, blink_failure_log, 5 SECONDS)
		log_game("[key_name(user)] не применяет [name] ([type]): [reason] в [AREACOORD(user)].")
	return FALSE

/datum/eldritch_knowledge/spell/voidpull
	name = "Притяжение пустоты"
	desc = "Притягивает видимых врагов с расстояния до 3 клеток на два шага к вам и замедляет их на 4 секунды. Те, кто уже стоял вплотную к вам в момент применения, получают 20 ушибов и падают на 2 секунды. Препятствия останавливают притяжение."
	gain_text = "Аристократ пригласил меня ближе. Отказаться я уже не мог."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/void_pull
	route = PATH_VOID

/datum/eldritch_knowledge/spell/boogiewoogie
	name = "Аплодисменты пустоты"
	desc = "Поменяйтесь местами с живым существом на открытом полу в поле зрения. Успешный обмен замедляет враждебную цель на 4 секунды. Защита от магии останавливает подмену."
	gain_text = "Мы с Аристократом поменялись местами, и никто этого не заметил."
	cost = 2
	spell_to_add = /obj/effect/proc_holder/spell/pointed/boogie_woogie
	route = PATH_VOID

/datum/eldritch_knowledge/spell/domain_expansion
	name = "Бесконечная пустота"
	desc = "После трёх секунд сосредоточения создайте домен 7×7 на 20 секунд. Враги в нём замедляются и получают метки Пустоты. С «Ищущим клинком» сдвиг к врагу внутри домена восстанавливается 2 секунды вместо 8. Скованность проходит через 4 секунды после выхода. Перезарядка 60 секунд."
	gain_text = "Мне больше не нужен снег, чтобы слышать шаги гостя."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/aoe_turf/domain_expansion
	route = PATH_VOID

/datum/eldritch_knowledge/final_eldritch/void_final
	name = "Вальс конца времён"
	desc = "После трёх подношений принесите три мёртвых тела на руну. Начало обряда раскроет его место всей станции и даст экипажу 30 секунд, чтобы помешать. После вознесения вы получаете общую стойкость вознесения. Вас окружает зимняя буря. Последний такт наносит видимым врагам в пределах 5 клеток 30 холодовых ожогов, замедляет на 4 секунды, оттесняет на две клетки, охлаждает и отмечает их, оставляя зимний круг радиусом три клетки на 12 секунд. Аура в пределах 5 клеток поддерживает охлаждение и скованность; голос подавляют только активные зимние поля. Безвоздушная буря разворачивает назад веером 30% снарядов, летящих в вас, и они могут попасть в кого-то другого, даже в стрелка. Слабость - тепло: пока вы горите или разогреты больше чем на 20 градусов выше нормы, буря не отклоняет снаряды, аура не охлаждает и не сковывает, а непогода не трогает экипаж."
	gain_text = "Аристократ подал мне руку. Этот танец переживёт станцию. Пули вязнут в безвоздушной буре вокруг нас, и лишь жар может сбить нас с такта."
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	route = PATH_VOID
	parallax_scene = ANTAG_SCENE_HERETIC_VOID
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_last_waltz)
	var/datum/looping_sound/void_loop/sound_loop
	var/datum/weather/void_storm/heretic/storm

/datum/eldritch_knowledge/final_eldritch/void_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	if(!simulated)
		user.client?.give_award(/datum/award/achievement/misc/void_ascension, user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/void_final/on_body_gain(mob/living/user)
	. = ..()
	if(finished && !sound_loop && user.stat != DEAD)
		sound_loop = new(user, TRUE, TRUE)
	if(finished && applied_body == user)
		user.AddComponent(/datum/component/heretic_void_storm)

/datum/eldritch_knowledge/final_eldritch/void_final/on_body_lose(mob/living/user)
	var/mob/living/body = applied_body || user
	qdel(body?.GetComponent(/datum/component/heretic_void_storm))
	stop_storm()
	return ..()

/datum/eldritch_knowledge/final_eldritch/void_final/on_death(mob/user)
	stop_storm()
	return ..()

/datum/eldritch_knowledge/final_eldritch/void_final/proc/stop_storm()
	QDEL_NULL(sound_loop)
	if(storm)
		storm.end()
		QDEL_NULL(storm)

/datum/eldritch_knowledge/final_eldritch/void_final/on_life(mob/user)
	. = ..()
	if(!finished || !isliving(user) || user.stat == DEAD)
		return
	var/overheated = heretic_void_overheated(user)
	if(storm)
		storm.suppressed = overheated
	if(!overheated)
		for(var/mob/living/carbon/victim in heretic_field_view(5, user))
			if(!heretic_can_affect(user, victim, chargecost = 0))
				continue
			victim.adjust_bodytemperature(-15)
			victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
	var/turf/open/floor/floor = get_turf(user)
	if(!istype(floor))
		return
	if(!overheated)
		floor.TakeTemperature(-15)
	var/area/user_area = get_area(user)
	if(!sound_loop)
		sound_loop = new(user, TRUE, TRUE)
	if(storm && !(floor.z in storm.impacted_z_levels))
		stop_storm()
	if(!storm)
		storm = new(list(floor.z), user_area)
		storm.suppressed = overheated
		storm.telegraph()
	else if(storm.followed_area != user_area)
		storm.move_to_area(user_area)

/datum/weather/void_storm/heretic
	var/area/followed_area
	var/suppressed = FALSE

/datum/weather/void_storm/heretic/can_weather_act(mob/living/mob_to_check)
	if(suppressed)
		return FALSE
	return ..()

/datum/weather/void_storm/heretic/New(list/z_levels, area/initial_area)
	followed_area = initial_area
	if(initial_area)
		area_type = initial_area.type
	return ..(z_levels)

/datum/weather/void_storm/heretic/update_areas()
	if(followed_area)
		impacted_areas = list(followed_area)
	return ..()

/datum/weather/void_storm/heretic/proc/move_to_area(area/new_area)
	if(!new_area || followed_area == new_area)
		return
	var/previous_stage = stage
	stage = END_STAGE
	update_areas()
	stage = previous_stage
	followed_area = new_area
	area_type = new_area.type
	update_areas()

#undef HERETIC_VOID_WINTER_HEALING
