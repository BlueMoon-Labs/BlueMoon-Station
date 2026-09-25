#define HERETIC_VOID_WINTER_HEALING 1

/datum/eldritch_knowledge/base_void
	name = "Мерцание зимы"
	summary = "Холод копит осколки зимы, а Зимний предел за осколок сковывает и глушит врагов на поле 5×5."
	details = list(
		"На полу с воздухом холоднее 0 °C осколок приходит раз в 20 секунд; открытый космос не годится.",
		"В тепле осколки копятся только до 2, второй - через 30 секунд после первого.",
		"Готовую цель в своём зимнем поле сердце уводит в изнанку за 1 секунду; вставшая или ушедшая из поля цель срывает увод.",
		"Зимний предел за 1 осколок: одно поле 5×5 на 15 секунд замедляет, охлаждает и глушит врагов.",
		"Скованность спадает через 4 секунды после последнего воздействия; воздух поле не охлаждает.",
		"Хватка по работающему светильнику гасит его, новый отдел идёт в дело пути.",
		"Нож на руне в холоде до 0 °C или в своём Зимнем пределе даёт клинок Пустоты.",
	)
	role = HERETIC_ROLE_CRAFT
	ritual_hints = list(
		"Подойдут кухонные и боевые ножи, тесаки и заточки.",
		"Воздух на клетке руны должен быть не теплее 0 °C.",
		"Вместо охлаждения комнаты накройте руну своим Зимним пределом до конца обряда.",
	)
	resource_rules = list(
		"Запас до 4 осколков.",
		"Пол с воздухом холоднее 0 °C даёт осколок раз в 20 секунд; открытый космос не подходит.",
		"В тепле копится до 2 осколков, второй - через 30 секунд после первого.",
		"Взрыв Метки Пустоты клинком даёт осколок.",
		"Зимний предел и фонарь тишины тратят по 1 осколку.",
	)
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
	summary = "Хватка сковывает врага на 4 секунды, ненадолго глушит голос и охлаждает."
	details = list(
		"Замедление не зависит от температуры тела, повторная хватка обновляет срок.",
		"Охлаждение по уровням улучшения: 30 / 40 / 50 градусов.",
		"На 2 и 3 уровне хватка по уже скованной цели жжёт на 5 и 10.",
		"Защита от магии срывает эффект.",
	)
	role = HERETIC_ROLE_GRASP
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
	summary = "Вы не дышите и не мёрзнете, а в холоде и своих полях лечитесь каждую секунду."
	details = list(
		"Дышать не нужно, холод не вредит; вакуум опасен из-за давления.",
		"На полу с воздухом до 0 °C, в Зимнем пределе или поле фонаря - 1 ушиб и 1 ожог в секунду.",
		"В тепле вне своих полей лечения нет.",
	)
	role = HERETIC_ROLE_PASSIVE
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
	summary = "Осколок стекла, верхняя одежда и простыня дают плащ Пустоты, скрытый под капюшоном."
	details = list(
		"Плащ держит 30% ударов, пуль, лазеров и энергии.",
		"Поднятый капюшон прячет от осмотра плащ и содержимое его карманов.",
		"Капюшон поднимают только еретик и его слуги.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Сова хранит то, что существует только в чужой памяти."
	cost = 1
	result_atoms = list(/obj/item/clothing/suit/hooded/cultrobes/void)
	required_atoms = list(/obj/item/shard, /obj/item/clothing/suit, /obj/item/bedsheet)

/datum/eldritch_knowledge/void_mark
	name = "Метка Пустоты"
	summary = "Хватка ставит метку на 15 секунд, удар клинком Пустоты её взрывает."
	details = list(
		"Взрыв: 15 холодовых ожогов, замедление на 4 секунды, охлаждение и молчание.",
		"Взрыв даёт осколок зимы.",
		"Замедление от хватки и метки обновляется, но не складывается.",
		"Метка гаснет через 15 секунд, если её не взорвать.",
	)
	role = HERETIC_ROLE_MARK
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
	summary = "Прыжок на 3-7 клеток бьёт врагов у входа и выхода; фонарь, стекло и бумага дают фонарь тишины."
	details = list(
		"Укажите видимую свободную клетку в 3-7 клетках: вы переноситесь туда.",
		"Враги в клетке от точек входа и выхода получают 20 ушибов и замедление на 4 секунды.",
		"Зоны без телепортации держат вас. Перезарядка 30 секунд.",
		"Шахтёрский фонарь, осколок стекла и лист бумаги на руне дают фонарь тишины.",
		"Фонарь в руке за 1 осколок 15 секунд несёт вокруг вас поле 3×3: замедление, холод, молчание.",
		"Поле гаснет, если выпустить фонарь; между включениями 25 секунд.",
		"Сдвиг работает в чужой хватке; до вознесения - не под оглушением и не в стамкрите.",
	)
	role = HERETIC_ROLE_ESCAPE
	required_atoms = list(/obj/item/flashlight/lantern, /obj/item/shard, /obj/item/paper)
	result_atoms = list(/obj/item/heretic_relic/hush_lantern)
	gain_text = "Аристократ сделал шаг и оставил за собой пустое место."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/void_blink
	route = PATH_VOID

/datum/eldritch_knowledge/rune_carver
	name = "Нож резьбы"
	summary = "Нож, осколок стекла и бумага дают резной нож: до 3 рун-ловушек на полу."
	details = list(
		"Предупреждающая руна почти невидима и сообщает, кто и где на неё наступил.",
		"Хватающая руна ранит ноги, валит на 5 секунд и выбивает вещи из рук.",
		"Руна безумия даёт слабость, головокружение, дрожь, слепоту, спутанность и немоту.",
		"Уничтожение ножа стирает его руны.",
	)
	role = HERETIC_ROLE_RELIC
	gain_text = "Каждый надрез напоминает реальности о её границах."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/shard, /obj/item/paper)
	result_atoms = list(/obj/item/melee/rune_knife)

/datum/eldritch_knowledge/crucible
	name = "Разинутый тигель"
	summary = "Бак с водой и стол дают тигель, который варит зелья еретика."
	details = list(
		"Тигель набирает долю раз в 30 секунд, органы и части тел добавляют долю сразу.",
		"Полный тигель из 3 долей варит одно зелье на выбор.",
		"Зелья: 15 секунд сквозь стены, 60 секунд зрения сквозь стены или 60 секунд лечения ран.",
		"Тигель один: повторный обряд переносит его вместе с содержимым.",
	)
	role = HERETIC_ROLE_RELIC
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
	summary = "Клинок Пустоты жжёт холодом на 8 и переносит вас к отмеченному врагу в 5 клетках."
	details = list(
		"Каждый удар: 8 холодовых ожогов и замедление на 4 секунды.",
		"ЛКМ клинком по отмеченному врагу в поле зрения до 5 клеток: вы встаёте рядом и бьёте.",
		"Сдвиг восстанавливается 8 секунд, к цели в своей Бесконечной пустоте - 2 секунды.",
		"Готовность видна при осмотре клинка; рядом с целью нужна свободная клетка.",
		"Защита от магии спасает от холода и сдвига.",
	)
	role = HERETIC_ROLE_ATTACK
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
	summary = "Тянет видимых врагов в 3 клетках на 2 шага к вам, а стоящих вплотную валит на 2 секунды."
	details = list(
		"Враги в 3 клетках сдвигаются к вам на 2 шага и замедляются на 4 секунды.",
		"Кто уже стоял вплотную, получает 20 ушибов и падает на 2 секунды.",
		"Препятствия останавливают притяжение; пристёгнутых и закреплённых не тянет.",
		"Защита от магии спасает. Перезарядка 40 секунд.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Аристократ пригласил меня ближе. Отказаться я уже не мог."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/void_pull
	route = PATH_VOID

/datum/eldritch_knowledge/spell/boogiewoogie
	name = "Аплодисменты пустоты"
	summary = "Меняет вас местами с живым существом на открытом полу в поле зрения."
	details = list(
		"Укажите живое существо в 15 клетках: вы меняетесь местами.",
		"Враждебная цель после обмена замедляется на 4 секунды.",
		"Пристёгнутые, закреплённые и защищённые от магии не меняются; зоны без телепортации держат.",
		"Перезарядка 10 секунд.",
	)
	role = HERETIC_ROLE_SUPPORT
	gain_text = "Мы с Аристократом поменялись местами, и никто этого не заметил."
	cost = 2
	spell_to_add = /obj/effect/proc_holder/spell/pointed/boogie_woogie
	route = PATH_VOID

/datum/eldritch_knowledge/spell/domain_expansion
	name = "Бесконечная пустота"
	summary = "За 3 секунды разворачивает домен 7×7 на 20 секунд: враги в нём скованы и помечены."
	details = list(
		"3 секунды стойте на месте, затем вокруг вас встаёт домен 7×7 на 20 секунд.",
		"Враги внутри замедлены и получают Метку Пустоты; союзники проходят свободно.",
		"С Ищущим клинком сдвиг к врагу в домене восстанавливается 2 секунды вместо 8.",
		"Скованность спадает через 4 секунды после выхода. Перезарядка 60 секунд.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Мне больше не нужен снег, чтобы слышать шаги гостя."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/aoe_turf/domain_expansion
	route = PATH_VOID

/datum/eldritch_knowledge/final_eldritch/void_final
	name = "Вальс конца времён"
	summary = "Вокруг вас зимняя буря, часть пуль летит обратно, открывается Последний такт."
	details = list(
		"Нужны 3 назначенные души и 3 человеческих трупа на руне; станция узнаёт место и 30 секунд может помешать.",
		"Общая стойкость вознесения; аура в 5 клетках охлаждает и сковывает врагов.",
		"Буря разворачивает назад веером 30% снарядов, они могут попасть в кого угодно, даже в стрелка.",
		"Последний такт: 30 холодовых ожогов врагам в 5 клетках, замедление, отброс на 2 клетки и метка.",
		"После такта зимний круг радиусом 3 клетки держит скованность 12 секунд; перезарядка 40 секунд.",
		"Голос глушат только зимние поля, а в тепле буря совсем не трогает экипаж.",
		"Слабость - тепло: горящий или разогретый на 20 градусов выше нормы не отклоняет пули и не сковывает.",
	)
	role = HERETIC_ROLE_ASCENSION
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
