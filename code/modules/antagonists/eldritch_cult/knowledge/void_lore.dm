/datum/eldritch_knowledge/base_void
	name = "Мерцание зимы"
	desc = "Открывает Путь Пустоты: собирайте осколки зимы, оставляйте холодные зоны и выбирайте дистанцию боя. Кухонный нож на руне при температуре не выше 0 °C или внутри вашего Зимнего предела превращается в клинок Пустоты. Зимний предел создаёт область холода и молчания."
	ritual_hint = "Воздух на клетке руны должен быть не теплее 0 °C. Вместо охлаждения комнаты можно накрыть руну своим Зимним пределом: поле должно сохраняться до конца обряда."
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
	desc = "Хватка ненадолго лишает врага голоса и снижает температуру его тела. Подготовьте Зимний предел, чтобы удержать противника в холоде."
	gain_text = "Я протянул руку и на мгновение услышал чужую тишину."
	cost = 1
	route = PATH_VOID

/datum/eldritch_knowledge/void_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!iscarbon(target) || !heretic_can_affect(user, target))
		return FALSE
	var/mob/living/carbon/victim = target
	victim.adjust_bodytemperature(-passive_values[passive_level])
	victim.silent = max(victim.silent, 3)
	return TRUE

/datum/eldritch_knowledge/cold_snap
	name = "Путь Аристократа"
	desc = "Вы перестаёте дышать и получаете защиту от низких температур. Вакуум всё ещё опасен из-за недостатка давления."
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

/datum/eldritch_knowledge/void_cloak
	name = "Плащ пустоты"
	desc = "Соедините осколок стекла, верхнюю одежду и простыню, чтобы создать плащ Пустоты. Поднятый капюшон скрывает плащ и содержимое его карманов."
	gain_text = "Сова хранит то, что существует только в чужой памяти."
	cost = 1
	result_atoms = list(/obj/item/clothing/suit/hooded/cultrobes/void)
	required_atoms = list(/obj/item/shard, /obj/item/clothing/suit, /obj/item/bedsheet)

/datum/eldritch_knowledge/void_mark
	name = "Метка Пустоты"
	desc = "Хватка накладывает Метку Пустоты. Удар клинком Пустоты активирует её: охлаждает врага, лишает его голоса на несколько секунд и даёт осколок зимы."
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
	desc = "Телепортируйтесь на открытую клетку в пределах 3–7 клеток; враги рядом с выходом и входом получают по 20 ушибов. Соедините шахтёрский фонарь, осколок стекла и лист бумаги, чтобы создать фонарь тишины. За осколок зимы он несёт вокруг вас поле холода и тишины, пока вы держите его в руке."
	required_atoms = list(/obj/item/flashlight/lantern, /obj/item/shard, /obj/item/paper)
	result_atoms = list(/obj/item/heretic_relic/hush_lantern)
	gain_text = "Аристократ сделал шаг и оставил за собой пустое место."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/void_blink
	route = PATH_VOID

/datum/eldritch_knowledge/rune_carver
	name = "Нож резьбы"
	desc = "Соедините кухонный нож, осколок стекла и лист бумаги, чтобы создать резной нож. Им можно вырезать до трёх ловушек на полу."
	gain_text = "Каждый надрез напоминает реальности о её границах."
	cost = 1
	required_atoms = list(/obj/item/kitchen/knife, /obj/item/shard, /obj/item/paper)
	result_atoms = list(/obj/item/melee/rune_knife)

/datum/eldritch_knowledge/crucible
	name = "Разинутый тигель"
	desc = "Соедините бак с водой и стол, чтобы создать разинутый тигель. Он перерабатывает предметы в зелья запретной алхимии."
	gain_text = "Отверженный император не ответил, но его голод остался со мной."
	cost = 1
	required_atoms = list(/obj/structure/reagent_dispensers/watertank, /obj/structure/table)
	result_atoms = list(/obj/structure/eldritch_crucible)

/datum/eldritch_knowledge/void_blade_upgrade
	name = "Ищущий клинок"
	desc = "Щёлкните клинком Пустоты по отмеченному врагу в поле зрения на расстоянии до 5 клеток, чтобы переместиться рядом с ним и ударить. Способность восстанавливается 8 секунд и требует свободной клетки возле цели."
	gain_text = "Метки в снегу связывают места, которые никогда не были рядом."
	cost = 2
	route = PATH_VOID
	COOLDOWN_DECLARE(blink_cooldown)

/datum/eldritch_knowledge/void_blade_upgrade/on_ranged_attack_eldritch_blade(atom/target, mob/user, click_parameters)
	if(!isliving(user) || !COOLDOWN_FINISHED(src, blink_cooldown) || !heretic_can_affect(user, target, chargecost = 0))
		return
	var/mob/living/victim = target
	var/mob/living/living_user = user
	if(user.z != victim.z || get_dist(user, victim) > 5 || !(victim in view(5, user)) || !victim.has_status_effect(/datum/status_effect/eldritch/void))
		return
	if(!CHECK_MOBILITY(living_user, MOBILITY_USE) || living_user.incapacitated())
		return
	var/obj/item/melee/sickly_blade/void/blade = user.get_active_held_item()
	if(!istype(blade))
		return
	var/turf/destination
	for(var/direction in GLOB.cardinals)
		var/turf/candidate = get_step(victim, direction)
		if(isopenturf(candidate) && !is_blocked_turf(candidate, TRUE))
			destination = candidate
			break
	if(!destination || !do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC))
		return
	COOLDOWN_START(src, blink_cooldown, 8 SECONDS)
	blade.melee_attack_chain(user, victim, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)

/datum/eldritch_knowledge/spell/voidpull
	name = "Притяжение пустоты"
	desc = "Притягивает видимых врагов с расстояния до 3 клеток. Ближайшие получают 20 ушибов и короткое оглушение. Препятствия останавливают притяжение."
	gain_text = "Аристократ пригласил меня ближе. Отказаться я уже не мог."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/targeted/void_pull
	route = PATH_VOID

/datum/eldritch_knowledge/spell/boogiewoogie
	name = "Аплодисменты пустоты"
	desc = "Поменяйтесь местами с живым существом на открытом полу в поле зрения. Защита от магии останавливает подмену."
	gain_text = "Мы с Аристократом поменялись местами, и никто этого не заметил."
	cost = 2
	spell_to_add = /obj/effect/proc_holder/spell/pointed/boogie_woogie
	route = PATH_VOID

/datum/eldritch_knowledge/spell/domain_expansion
	name = "Бесконечная пустота"
	desc = "После трёх секунд сосредоточения создайте домен 7×7 на 20 секунд. Враги в нём замедляются и получают метки Пустоты. Выход из домена сразу снимает замедление."
	gain_text = "Мне больше не нужен снег, чтобы слышать шаги гостя."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	spell_to_add = /obj/effect/proc_holder/spell/aoe_turf/domain_expansion
	route = PATH_VOID

/datum/eldritch_knowledge/final_eldritch/void_final
	name = "Вальс конца времён"
	desc = "После трёх подношений принесите три мёртвых тела на руну. Начало обряда раскроет его место всей станции и даст экипажу 30 секунд, чтобы помешать. Вознесение окружает вас зимней бурей и даёт защиту от среды. Последний такт оттесняет видимых врагов на две клетки, охлаждает и отмечает их, оставляя зимний круг радиусом три клетки на 12 секунд. Ближайшие враги теряют тепло; голос подавляют только активные зимние поля."
	gain_text = "Аристократ подал мне руку. Этот танец переживёт станцию."
	cost = 3
	sacs_needed = HERETIC_ASCENSION_SACRIFICES
	required_atoms = list(/mob/living/carbon/human, /mob/living/carbon/human, /mob/living/carbon/human)
	route = PATH_VOID
	parallax_scene = ANTAG_SCENE_HERETIC_VOID
	ascension_traits = list(TRAIT_NOBREATH, TRAIT_RESISTCOLD, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE)
	ascension_spells = list(/obj/effect/proc_holder/spell/self/heretic_last_waltz)
	var/datum/looping_sound/void_loop/sound_loop
	var/datum/weather/void_storm/heretic/storm

/datum/eldritch_knowledge/final_eldritch/void_final/on_finished_recipe(mob/living/user, list/atoms, loc)
	if(!..())
		return FALSE
	on_body_gain(user)
	user.client?.give_award(/datum/award/achievement/misc/void_ascension, user)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/void_final/on_body_gain(mob/living/user)
	. = ..()
	if(finished && !sound_loop && user.stat != DEAD)
		sound_loop = new(user, TRUE, TRUE)

/datum/eldritch_knowledge/final_eldritch/void_final/on_body_lose(mob/living/user)
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
	for(var/mob/living/carbon/victim in view(5, user))
		if(!heretic_can_affect(user, victim, chargecost = 0))
			continue
		victim.adjust_bodytemperature(-15)
	var/turf/open/floor/floor = get_turf(user)
	if(!istype(floor))
		return
	floor.TakeTemperature(-15)
	var/area/user_area = get_area(user)
	if(!sound_loop)
		sound_loop = new(user, TRUE, TRUE)
	if(storm && !(floor.z in storm.impacted_z_levels))
		stop_storm()
	if(!storm)
		storm = new(list(floor.z), user_area)
		storm.telegraph()
	else if(storm.followed_area != user_area)
		storm.move_to_area(user_area)

/datum/weather/void_storm/heretic
	var/area/followed_area

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
