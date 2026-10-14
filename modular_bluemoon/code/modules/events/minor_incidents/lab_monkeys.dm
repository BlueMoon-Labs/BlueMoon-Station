#define LAB_MONKEY_COUNT 3
#define LAB_MONKEY_REWARD 300
/// Личная благодарность тому, кто принёс или привёл обезьяну домой.
#define LAB_MONKEY_BRINGER_REWARD 50
#define LAB_MONKEY_HOLD_TIME (30 SECONDS)
#define LAB_MONKEY_SPAWN_MIN_DIST 6
#define LAB_MONKEY_SPAWN_MAX_DIST 24
#define LAB_MONKEY_DURATION (15 MINUTES)
/// Раннер событий шагает раз в две секунды.
#define LAB_MONKEY_EVENT_STEP (2 SECONDS)
/// Сколько после того, как обезьяну отпустили, принёсший ещё считается принёсшим.
#define LAB_MONKEY_HANDLER_GRACE (1 MINUTES)
#define LAB_MONKEY_SEEK_RANGE 5
#define LAB_MONKEY_FLEE_RANGE 2
#define LAB_MONKEY_MOVE_DELAY 4
#define LAB_MONKEY_MISCHIEF_COOLDOWN (1 MINUTES)
#define LAB_MONKEY_DIVE_TIME (2 SECONDS)
#define LAB_MONKEY_THIEF "thief"
#define LAB_MONKEY_DIVER "diver"
#define LAB_MONKEY_SKITTISH "skittish"

/datum/round_event_control/lab_monkeys
	name = "Escaped Lab Monkeys"
	typepath = /datum/round_event/lab_monkeys
	weight = 15
	max_occurrences = 1
	earliest_start = 15 MINUTES
	min_players = 10
	severity = DIRECTOR_SEVERITY_MINOR
	category = EVENT_CATEGORY_SPAWNERS
	family = "lab_monkeys"
	var/list/home_area_types = list(/area/medical/genetics)
	var/list/fallback_area_types = list(/area/science/lab, /area/science/research, /area/science/misc_lab, /area/science/explab)
	var/list/excluded_area_types = list(/area/science/research/abandoned)

/datum/round_event_control/lab_monkeys/New()
	. = ..()
	description = "Из генетики (без неё - из научного отдела) сбегают [LAB_MONKEY_COUNT] лабораторные обезьяны с бирками и характером: одна тащит ID-карты, другая лезет в мусоропроводы, третья пуглива и идёт только на банан. Кто принёс обезьяну домой, получает [LAB_MONKEY_BRINGER_REWARD] кредитов; если за [LAB_MONKEY_DURATION / (1 MINUTES)] минут все вернутся живыми и [LAB_MONKEY_HOLD_TIME / (1 SECONDS)] секунд пробудут дома, отдел лаборатории получит [LAB_MONKEY_REWARD] кредитов."

/// Отсек, откуда сбежали обезьяны: генетика, а без неё научный отдел; сам тип из списка раньше подотсеков.
/datum/round_event_control/lab_monkeys/proc/find_home()
	for(var/list/area_types in list(home_area_types, fallback_area_types))
		var/area/subtype_home
		for(var/area/location as anything in minor_crew_station_areas(area_types, excluded_area_types))
			if(!length(minor_crew_area_floors(location, first_only = TRUE)))
				continue
			if(location.type in area_types)
				return location
			if(!subtype_home)
				subtype_home = location
		if(subtype_home)
			return subtype_home
	return null

/// Тип из списка, под который попал отсек: обезьяна засчитывается в любом его подотсеке.
/datum/round_event_control/lab_monkeys/proc/home_type_of(area/home)
	for(var/area_type in home_area_types + fallback_area_types)
		if(istype(home, area_type))
			return area_type
	return home.type

/// Коридоры и техтоннели неподалёку от лаборатории, но не у самой двери.
/datum/round_event_control/lab_monkeys/proc/get_spawn_turfs(area/home, first_only = FALSE)
	var/list/result = list()
	var/list/home_floors = minor_crew_area_floors(home, first_only = TRUE)
	if(!length(home_floors))
		return result
	var/turf/origin = home_floors[1]
	for(var/turf/open/floor/floor in RANGE_TURFS(LAB_MONKEY_SPAWN_MAX_DIST, origin))
		if(get_dist(floor, origin) < LAB_MONKEY_SPAWN_MIN_DIST)
			continue
		var/area/location = get_area(floor)
		if(!istype(location, /area/hallway) && !istype(location, /area/maintenance))
			continue
		if(!minor_crew_valid_floor(floor))
			continue
		result += floor
		if(first_only)
			return result
	return result

/datum/round_event_control/lab_monkeys/director_preflight()
	var/area/home = find_home()
	var/ready = !!(home && length(get_spawn_turfs(home, first_only = TRUE)))
	director_preflight_detail = ready ? "Обезьяны сбегут из отсека [home.name]." : "Нет генетики или научного отдела с коридором рядом."
	director_preflight_failure = ready ? null : director_preflight_detail
	return ready

/datum/round_event/lab_monkeys
	announce_when = 1
	end_when = LAB_MONKEY_DURATION / LAB_MONKEY_EVENT_STEP
	fakeable = FALSE
	var/home_type
	var/home_name
	var/department_account
	var/department_name
	var/list/monkeys = list()
	/// Weakref обезьяны -> world.time, с которого она непрерывно сидит дома.
	var/list/home_since = list()
	/// Weakref обезьяны -> weakref того, кто занёс её домой.
	var/list/bringers = list()
	var/list/secured = list()
	var/resolved = FALSE

/datum/round_event/lab_monkeys/start()
	var/datum/round_event_control/lab_monkeys/escape = control
	var/area/home = escape?.find_home()
	var/list/spots = home ? escape.get_spawn_turfs(home) : null
	if(!length(spots))
		var/reason = home ? "рядом с отсеком [home.name] нет коридора или техтоннеля" : "на станции нет генетики или научного отдела"
		log_game("DIRECTOR: [control?.name] не запущено: [reason].")
		message_admins("[control?.name] не запущено: [reason].")
		return
	release_monkeys(home, spots, escape.home_type_of(home))

/datum/round_event/lab_monkeys/proc/release_monkeys(area/home, list/spots, matched_type)
	var/static/list/temperaments = list(LAB_MONKEY_THIEF, LAB_MONKEY_DIVER, LAB_MONKEY_SKITTISH)
	home_type = matched_type || home.type
	home_name = home.name
	department_account = ispath(home_type, /area/medical) ? ACCOUNT_MED : ACCOUNT_SCI
	department_name = department_account == ACCOUNT_MED ? "медицинский отдел" : "научный отдел"
	spots = spots.Copy()
	for(var/specimen in 1 to LAB_MONKEY_COUNT)
		var/turf/spot = length(spots) > 1 ? pick_n_take(spots) : spots[1]
		var/mob/living/carbon/monkey/monkey = new(spot)
		monkey.AddComponent(/datum/component/lab_monkey_tag, specimen, home_name, temperaments[(specimen - 1) % length(temperaments) + 1])
		monkeys += WEAKREF(monkey)
	log_game("DIRECTOR: [control?.name], из отсека [home_name] сбежало обезьян: [length(monkeys)].")

/datum/round_event/lab_monkeys/announce(fake)
	if(!length(monkeys))
		return
	priority_announce("Из отсека [home_name] сбежали [LAB_MONKEY_COUNT] подопытные обезьяны с бирками на ошейниках. LM-1 срывает с людей ID-карты, LM-2 лезет в мусоропроводы, LM-3 пуглива и убегает от людей, но идёт к тому, у кого в руках банан. Верните их живыми в [home_name] и продержите там [LAB_MONKEY_HOLD_TIME / (1 SECONDS)] секунд. Кто принёс или привёл обезьяну, получает [LAB_MONKEY_BRINGER_REWARD] кредитов; если все трое будут дома в течение [LAB_MONKEY_DURATION / (1 MINUTES)] минут, [department_name] получит [LAB_MONKEY_REWARD] кредитов.", "Отдел учёта лабораторных животных NanoTrasen")

/datum/round_event/lab_monkeys/tick()
	check_monkeys()
	stir_monkeys()

/datum/round_event/lab_monkeys/proc/check_monkeys()
	if(resolved || !length(monkeys))
		return
	for(var/datum/weakref/monkey_ref as anything in monkeys)
		if(monkey_ref in secured)
			continue
		var/mob/living/carbon/monkey/monkey = monkey_ref.resolve()
		if(QDELETED(monkey) || monkey.stat == DEAD)
			fail(monkeys.Find(monkey_ref))
			return
		var/datum/component/lab_monkey_tag/tag = monkey.GetComponent(/datum/component/lab_monkey_tag)
		tag?.note_handler(minor_crew_carrier(monkey))
		if(!istype(get_area(monkey), home_type))
			home_since -= monkey_ref
			bringers -= monkey_ref
			continue
		if(isnull(home_since[monkey_ref]))
			home_since[monkey_ref] = world.time
			var/mob/living/carbon/human/bringer = tag?.recent_handler()
			if(bringer)
				bringers[monkey_ref] = WEAKREF(bringer)
			continue
		if(world.time - home_since[monkey_ref] >= LAB_MONKEY_HOLD_TIME)
			secure(monkey, monkey_ref)
	if(length(secured) >= length(monkeys))
		reward()

/// Сбежавшие обезьяны вне дома проказничают по своему характеру.
/datum/round_event/lab_monkeys/proc/stir_monkeys()
	if(resolved)
		return
	for(var/datum/weakref/monkey_ref as anything in monkeys)
		if((monkey_ref in secured) || !isnull(home_since[monkey_ref]))
			continue
		var/mob/living/carbon/monkey/monkey = monkey_ref.resolve()
		var/datum/component/lab_monkey_tag/tag = monkey?.GetComponent(/datum/component/lab_monkey_tag)
		tag?.act_out()

/datum/round_event/lab_monkeys/proc/secure(mob/living/carbon/monkey/monkey, datum/weakref/monkey_ref)
	secured += monkey_ref
	home_since -= monkey_ref
	var/specimen = monkeys.Find(monkey_ref)
	playsound(monkey, 'sound/machines/ping.ogg', 30, TRUE, SILENCED_SOUND_EXTRARANGE)
	monkey.visible_message(span_notice("Бирка на ошейнике [monkey] коротко пищит: образец на месте ([length(secured)] из [length(monkeys)])."))
	if(locate(/obj/item) in monkey.held_items)
		monkey.visible_message(span_notice("[monkey] бросает на пол всё, что утащила."))
		monkey.drop_all_held_items()
	var/datum/weakref/bringer_ref = bringers[monkey_ref]
	bringers -= monkey_ref
	var/mob/living/carbon/human/bringer = bringer_ref?.resolve()
	var/paid = FALSE
	if(bringer && bringer.stat != DEAD)
		paid = minor_crew_pay_person(bringer, LAB_MONKEY_BRINGER_REWARD, "возврат лабораторного образца LM-[specimen]")
		to_chat(bringer, span_notice("Образец LM-[specimen] на месте. [paid ? "Отдел учёта перевёл вам [LAB_MONKEY_BRINGER_REWARD] кредитов." : "Благодарность перевести некуда: при вас нет ID-карты со счётом."]"))
	log_game("DIRECTOR: [control?.name], образец LM-[specimen] дома[bringer ? ", принёс [key_name(bringer)][paid ? ", выдано [LAB_MONKEY_BRINGER_REWARD] кр." : ", счёта нет"]" : ""].")

/datum/round_event/lab_monkeys/proc/reward()
	resolved = TRUE
	var/paid = minor_crew_pay_department(department_account, LAB_MONKEY_REWARD, "ЦК: возврат лабораторных образцов")
	priority_announce("Все [LAB_MONKEY_COUNT] образца вернулись в [home_name] живыми. [paid ? "[capitalize(department_name)] получает [LAB_MONKEY_REWARD] кредитов" : "Премию начислить некуда, но спасибо"]; следующий журнал вольера просим заполнять до побега, а не после.", "Отдел учёта лабораторных животных NanoTrasen")
	log_game("DIRECTOR: [control?.name], все обезьяны возвращены в [home_name][paid ? ", отделу выдано [LAB_MONKEY_REWARD] кр." : ", бюджета отдела нет."]")
	kill()

/datum/round_event/lab_monkeys/proc/fail(specimen)
	resolved = TRUE
	minor_announce("Образец LM-[specimen] погиб или пропал. Домой вернулось [length(secured)] из [length(monkeys)], премии отделу не будет.", "Отдел учёта лабораторных животных NanoTrasen")
	log_game("DIRECTOR: [control?.name], образец LM-[specimen] погиб или пропал, возвращено [length(secured)] из [length(monkeys)], награды не будет.")
	kill()

/datum/round_event/lab_monkeys/end()
	if(resolved || !length(monkeys))
		return
	resolved = TRUE
	minor_announce("Срок поиска истёк: в [home_name] вернулось [length(secured)] из [length(monkeys)] образцов, премии отделу не будет. Оставшиеся обезьяны остаются на станции.", "Отдел учёта лабораторных животных NanoTrasen")
	log_game("DIRECTOR: [control?.name], время вышло, возвращено [length(secured)] из [length(monkeys)], награды не будет.")

/// Пластиковая бирка лабораторной обезьяны: номер, характер и кто её последним нёс.
/datum/component/lab_monkey_tag
	var/specimen
	var/home_name
	var/temperament
	var/mutable_appearance/tag_overlay
	var/datum/weakref/last_handler
	var/last_handled_at = 0
	/// Человек, к чьей карте обезьяна уже тянется: срывает её на следующем шаге, если он не отошёл.
	var/datum/weakref/snatch_victim
	var/dive_timer
	COOLDOWN_DECLARE(mischief_cooldown)

/datum/component/lab_monkey_tag/Initialize(specimen, home_name, temperament)
	if(!ismonkey(parent))
		return COMPONENT_INCOMPATIBLE
	src.specimen = specimen
	src.home_name = home_name
	src.temperament = temperament
	tag_overlay = mutable_appearance('modular_bluemoon/icons/obj/minor_incidents/lab_monkeys.dmi', "lab_tag", -NECK_LAYER)

/datum/component/lab_monkey_tag/Destroy()
	deltimer(dive_timer)
	return ..()

/datum/component/lab_monkey_tag/RegisterWithParent()
	var/atom/monkey = parent
	monkey.add_overlay(tag_overlay)
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/lab_monkey_tag/UnregisterFromParent()
	var/atom/monkey = parent
	monkey.cut_overlay(tag_overlay)
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)

/datum/component/lab_monkey_tag/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("На шее пластиковый ошейник с биркой: «Образец LM-[specimen]. [home_name]. [temperament_note()] Нашедшему - вернуть в лабораторию».")

/datum/component/lab_monkey_tag/proc/temperament_note()
	switch(temperament)
		if(LAB_MONKEY_THIEF)
			return "Тащит ID-карты, держать подальше от персонала."
		if(LAB_MONKEY_DIVER)
			return "Лезет в мусоропроводы."
		if(LAB_MONKEY_SKITTISH)
			return "Пуглива, подходит только к тому, у кого банан."
	return ""

/datum/component/lab_monkey_tag/proc/note_handler(mob/living/carbon/human/handler)
	if(!handler)
		return
	last_handler = WEAKREF(handler)
	last_handled_at = world.time

/datum/component/lab_monkey_tag/proc/recent_handler()
	var/mob/living/carbon/human/handler = last_handler?.resolve()
	if(!handler || handler.stat == DEAD || world.time - last_handled_at > LAB_MONKEY_HANDLER_GRACE)
		return null
	return handler

/datum/component/lab_monkey_tag/proc/act_out()
	var/mob/living/carbon/monkey/monkey = parent
	if(monkey.stat != CONSCIOUS || monkey.restrained() || monkey.pulledby || monkey.buckled || !isturf(monkey.loc))
		snatch_victim = null
		return FALSE
	switch(temperament)
		if(LAB_MONKEY_THIEF)
			return steal_id(monkey)
		if(LAB_MONKEY_DIVER)
			return dive(monkey)
		if(LAB_MONKEY_SKITTISH)
			return shy_away(monkey)
	return FALSE

/// Люди в сознании, которых обезьяна видит: кандидаты из грида, ближние первыми.
/datum/component/lab_monkey_tag/proc/people_in_sight(mob/living/carbon/monkey/monkey)
	var/list/people = list()
	for(var/mob/living/carbon/human/person in SSspatial_grid.orthogonal_range_search(monkey, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, LAB_MONKEY_SEEK_RANGE))
		if(person.stat != CONSCIOUS || !isturf(person.loc) || get_dist(monkey, person) > LAB_MONKEY_SEEK_RANGE || !can_see(monkey, person, LAB_MONKEY_SEEK_RANGE))
			continue
		people[person] = get_dist(monkey, person)
	return sortTim(people, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)

/datum/component/lab_monkey_tag/proc/nearest_bin(mob/living/carbon/monkey/monkey)
	var/obj/machinery/disposal/bin/nearest
	for(var/turf/spot as anything in RANGE_TURFS(LAB_MONKEY_SEEK_RANGE, monkey))
		var/obj/machinery/disposal/bin/bin = locate() in spot
		if(!bin || (nearest && get_dist(monkey, bin) >= get_dist(monkey, nearest)) || !can_see(monkey, bin, LAB_MONKEY_SEEK_RANGE))
			continue
		nearest = bin
	return nearest

/datum/component/lab_monkey_tag/proc/snatchable_id(mob/living/carbon/human/person)
	var/obj/item/worn = person.wear_id
	return worn?.GetID() && !HAS_TRAIT(worn, TRAIT_NODROP)

/// Тянется к ID-карте ближайшего человека и срывает её шагом позже, если тот не отошёл.
/datum/component/lab_monkey_tag/proc/steal_id(mob/living/carbon/monkey/monkey)
	if(!COOLDOWN_FINISHED(src, mischief_cooldown))
		return FALSE
	var/mob/living/carbon/human/victim = snatch_victim?.resolve()
	snatch_victim = null
	if(victim && victim.stat == CONSCIOUS && monkey.Adjacent(victim) && snatchable_id(victim))
		var/obj/item/loot = victim.wear_id
		if(!victim.temporarilyRemoveItemFromInventory(loot))
			return FALSE
		COOLDOWN_START(src, mischief_cooldown, LAB_MONKEY_MISCHIEF_COOLDOWN)
		monkey.drop_all_held_items()
		if(!monkey.put_in_hands(loot))
			loot.forceMove(monkey.drop_location())
		playsound(monkey, 'sound/weapons/thudswoosh.ogg', 40, TRUE, SILENCED_SOUND_EXTRARANGE)
		victim.visible_message(span_warning("[monkey] срывает [loot] с [victim] и отскакивает!"), span_userdanger("[monkey] срывает с вас [loot]!"))
		log_game("DIRECTOR: Escaped Lab Monkeys, образец LM-[specimen] утащил [loot] у [key_name(victim)].")
		return TRUE
	for(var/mob/living/carbon/human/person as anything in people_in_sight(monkey))
		if(!snatchable_id(person))
			continue
		if(monkey.Adjacent(person))
			snatch_victim = WEAKREF(person)
			person.visible_message(span_warning("[monkey] тянется к ID-карте [person]!"), span_userdanger("[monkey] тянется к вашей ID-карте!"))
		else
			SSmove_manager.move_to(monkey, person, 1, LAB_MONKEY_MOVE_DELAY, LAB_MONKEY_EVENT_STEP)
		return TRUE
	return FALSE

/// Бежит к ближайшему мусоропроводу и протискивается внутрь.
/datum/component/lab_monkey_tag/proc/dive(mob/living/carbon/monkey/monkey)
	if(dive_timer || !COOLDOWN_FINISHED(src, mischief_cooldown))
		return FALSE
	var/obj/machinery/disposal/bin/bin = nearest_bin(monkey)
	if(!bin)
		return FALSE
	if(!monkey.Adjacent(bin))
		SSmove_manager.move_to(monkey, bin, 1, LAB_MONKEY_MOVE_DELAY, LAB_MONKEY_EVENT_STEP)
		return TRUE
	COOLDOWN_START(src, mischief_cooldown, LAB_MONKEY_MISCHIEF_COOLDOWN)
	monkey.visible_message(span_warning("[monkey] с визгом запрыгивает на край [bin] и лезет внутрь!"))
	dive_timer = addtimer(CALLBACK(src, PROC_REF(finish_dive), bin), LAB_MONKEY_DIVE_TIME, TIMER_STOPPABLE)
	return TRUE

/datum/component/lab_monkey_tag/proc/finish_dive(obj/machinery/disposal/bin/bin)
	dive_timer = null
	var/mob/living/carbon/monkey/monkey = parent
	if(QDELETED(bin) || monkey.stat != CONSCIOUS || monkey.pulledby || !monkey.Adjacent(bin) || !bin.can_stuff_mob_in(monkey, monkey, TRUE))
		return FALSE
	monkey.forceMove(bin)
	bin.update_appearance()
	bin.visible_message(span_warning("[monkey] скрывается в [bin]."))
	return TRUE

/// Убегает от людей рядом, но сама идёт к тому, у кого в руках банан; с бананом в лапах успокаивается.
/datum/component/lab_monkey_tag/proc/shy_away(mob/living/carbon/monkey/monkey)
	if(locate(/obj/item/reagent_containers/food/snacks/grown/banana) in monkey.held_items)
		return FALSE
	var/mob/living/carbon/human/threat
	for(var/mob/living/carbon/human/person as anything in people_in_sight(monkey))
		if(locate(/obj/item/reagent_containers/food/snacks/grown/banana) in person.held_items)
			note_handler(person)
			if(!monkey.Adjacent(person))
				SSmove_manager.move_to(monkey, person, 1, LAB_MONKEY_MOVE_DELAY, LAB_MONKEY_EVENT_STEP)
			return TRUE
		if(!threat && get_dist(monkey, person) <= LAB_MONKEY_FLEE_RANGE)
			threat = person
	if(!threat)
		return FALSE
	SSmove_manager.move_away(monkey, threat, LAB_MONKEY_SEEK_RANGE, LAB_MONKEY_MOVE_DELAY, LAB_MONKEY_EVENT_STEP)
	return TRUE

#undef LAB_MONKEY_COUNT
#undef LAB_MONKEY_REWARD
#undef LAB_MONKEY_BRINGER_REWARD
#undef LAB_MONKEY_HOLD_TIME
#undef LAB_MONKEY_SPAWN_MIN_DIST
#undef LAB_MONKEY_SPAWN_MAX_DIST
#undef LAB_MONKEY_DURATION
#undef LAB_MONKEY_EVENT_STEP
#undef LAB_MONKEY_HANDLER_GRACE
#undef LAB_MONKEY_SEEK_RANGE
#undef LAB_MONKEY_FLEE_RANGE
#undef LAB_MONKEY_MOVE_DELAY
#undef LAB_MONKEY_MISCHIEF_COOLDOWN
#undef LAB_MONKEY_DIVE_TIME
#undef LAB_MONKEY_THIEF
#undef LAB_MONKEY_DIVER
#undef LAB_MONKEY_SKITTISH
