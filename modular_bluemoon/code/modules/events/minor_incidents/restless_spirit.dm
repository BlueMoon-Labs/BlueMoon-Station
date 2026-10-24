#define SPIRIT_DURATION (15 MINUTES)
#define SPIRIT_SPOOK_MIN (40 SECONDS)
#define SPIRIT_SPOOK_MAX (80 SECONDS)
#define SPIRIT_WANDER_TIME (7 MINUTES)
#define SPIRIT_RANGE 5
#define SPIRIT_CALM_TIME_HOLY (5 SECONDS)
#define SPIRIT_CALM_TIME_LAY (12 SECONDS)
#define SPIRIT_HOLY_CHANCE 70
#define SPIRIT_LAY_CHANCE 40
#define SPIRIT_RITUAL_CANDLES 2
#define SPIRIT_RITUAL_RANGE 2
#define SPIRIT_HOLY_WATER_DOSE 5
#define SPIRIT_ANTIQUE_PRICE 250
#define SPIRIT_SNUFF_CHANCE 60
#define SPIRIT_CANDLE_SHIVER_TIME (1.5 SECONDS)
#define SPIRIT_LAMPS_PER_SPOOK 2
#define SPIRIT_FLICKER_MIN 3
#define SPIRIT_FLICKER_MAX 6
#define SPIRIT_SHADE_RISE 24

/datum/round_event_control/station_incident/service/restless_spirit
	name = "Restless Spirit"
	typepath = /datum/round_event/station_incident/service/restless_spirit
	category = EVENT_CATEGORY_ENTITIES
	family = "restless_spirit"
	min_players = 5
	area_groups = list(list(/area/service/chapel), list(/area/medical/morgue))
	announcement_title = "Отдел паранормального страхования NanoTrasen"

/datum/round_event_control/station_incident/service/restless_spirit/New()
	. = ..()
	incident_message = "Зарегистрирована паранормальная активность низкого класса: гаснут свечи, а в описи появился реликварий, которого там не было. Страховка такие случаи не покрывает. Священнику поручено успокоить источник Библией, нулевым жезлом или святой водой. Наверняка это получается обрядом: реликварий на алтаре или столе часовни и не меньше [SPIRIT_RITUAL_CANDLES] горящих свечей рядом. Неуспокоенный дух каждые [DisplayTimeText(SPIRIT_WANDER_TIME)] перебирается в соседний отсек; вредит он только репутации."
	description = "В часовне (без неё - в морге) появляется старый реликварий с неспокойным духом: до [DisplayTimeText(SPIRIT_DURATION)] гаснут свечи, мигает свет, сдвигаются мелочи и слышен шёпот, а каждые [DisplayTimeText(SPIRIT_WANDER_TIME)] проявления перебираются в соседний отсек. Дух успокаивают Библией, нулевым жезлом или святой водой: без обряда у священника выходит в [SPIRIT_HOLY_CHANCE]% случаев, у остальных - в [SPIRIT_LAY_CHANCE]%; на алтаре с [SPIRIT_RITUAL_CANDLES] горящими свечами рядом - наверняка. Успокоенный реликварий продаётся через карго за [SPIRIT_ANTIQUE_PRICE] кредитов."

/datum/round_event/station_incident/service/restless_spirit

/datum/round_event/station_incident/service/restless_spirit/apply_effect(turf/target)
	var/obj/item/minor_reliquary/reliquary = new(target)
	reliquary.alpha = 0
	animate(reliquary, alpha = 255, time = 2 SECONDS)
	reliquary.start_haunting(SPIRIT_DURATION)
	return TRUE

/datum/mood_event/minor_spirit_calmed
	description = "<span class='nicegreen'>Я помог неспокойной душе обрести покой.</span>\n"
	mood_change = 2
	timeout = 10 MINUTES

/obj/item/minor_reliquary
	name = "old reliquary"
	desc = "Потемневший серебряный реликварий с мутным стеклом в стенке. Описи к нему нет, бирки тоже."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/restless_spirit.dmi'
	icon_state = "reliquary"
	item_state = "paintcan"
	w_class = WEIGHT_CLASS_NORMAL
	light_color = "#a9dcff"
	var/haunted = FALSE
	var/calmed = FALSE
	var/calming = FALSE
	var/spook_timer
	var/fade_timer
	var/wander_timer
	/// Клетка в соседнем отсеке, куда перебрались проявления; null - дух у реликвария.
	var/turf/haunt_turf
	var/static/list/whispers = list(
		'modular_bluemoon/sound/minor_incidents/restless_spirit_whisper_1.ogg',
		'modular_bluemoon/sound/minor_incidents/restless_spirit_whisper_2.ogg',
		'modular_bluemoon/sound/minor_incidents/restless_spirit_whisper_3.ogg',
	)
	var/static/list/chills = list(
		"Кто-то шепчет у самого уха, но рядом никого нет.",
		"По спине пробегает холодок, будто где-то открыли шлюз.",
		"Воздух на миг становится ледяным, дыхание вырывается паром.",
		"Краем глаза вы замечаете бледное движение у стены.",
	)

/obj/item/minor_reliquary/Destroy()
	stop_timers()
	haunt_turf = null
	return ..()

/obj/item/minor_reliquary/examine(mob/user)
	. = ..()
	if(calmed)
		. += span_notice("Антиквар возьмёт такую вещь: её можно продать через карго.")
		return
	if(!haunted)
		return
	. += span_warning("Под стеклом дрожит холодное сияние.")
	var/area/haunt_area = get_area(haunt_center())
	if(haunt_turf && haunt_area != get_area(src))
		. += span_warning("Дух бродит по отсеку [haunt_area.name]: шёпот и холод теперь там. Успокаивать его всё равно нужно у реликвария.")
	. += span_notice("Дух успокаивают Библией, нулевым жезлом или святой водой (от [SPIRIT_HOLY_WATER_DOSE] ед.). Без обряда у священника это выходит в [SPIRIT_HOLY_CHANCE]% случаев, у остальных - в [SPIRIT_LAY_CHANCE]% и дольше.")
	. += span_notice("Обряд: поставьте реликварий на алтарь или стол в часовне и зажгите рядом не меньше [SPIRIT_RITUAL_CANDLES] свечей - тогда дух уйдёт наверняка. Неуспокоенный дух каждые [DisplayTimeText(SPIRIT_WANDER_TIME)] перебирается в соседний отсек.")
	if(on_altar())
		. += span_notice("Реликварий стоит на алтаре. Горящих свечей рядом: [min(lit_candles_near(), SPIRIT_RITUAL_CANDLES)] из [SPIRIT_RITUAL_CANDLES].")

/obj/item/minor_reliquary/update_overlays()
	. = ..()
	if(haunted)
		. += mutable_appearance('modular_bluemoon/icons/effects/minor_incidents/restless_spirit.dmi', "wisp")

/obj/item/minor_reliquary/proc/start_haunting(duration)
	if(haunted || calmed)
		return FALSE
	haunted = TRUE
	fade_timer = addtimer(CALLBACK(src, PROC_REF(fade_out)), duration, TIMER_STOPPABLE)
	set_light(2, 0.6)
	update_appearance()
	schedule_spook()
	schedule_wander()
	return TRUE

/obj/item/minor_reliquary/proc/schedule_spook()
	deltimer(spook_timer)
	spook_timer = addtimer(CALLBACK(src, PROC_REF(spook)), rand(SPIRIT_SPOOK_MIN, SPIRIT_SPOOK_MAX), TIMER_STOPPABLE)

/obj/item/minor_reliquary/proc/schedule_wander()
	deltimer(wander_timer)
	wander_timer = addtimer(CALLBACK(src, PROC_REF(wander)), SPIRIT_WANDER_TIME, TIMER_STOPPABLE)

/obj/item/minor_reliquary/proc/stop_timers()
	deltimer(spook_timer)
	deltimer(fade_timer)
	deltimer(wander_timer)
	spook_timer = null
	fade_timer = null
	wander_timer = null

/obj/item/minor_reliquary/proc/haunt_center()
	return haunt_turf || get_turf(src)

/obj/item/minor_reliquary/proc/spook()
	spook_timer = null
	if(!haunted)
		return FALSE
	if(!call(src, pick(PROC_REF(spook_candles), PROC_REF(spook_lights), PROC_REF(spook_nudge), PROC_REF(spook_whisper)))())
		spook_whisper()
	schedule_spook()
	return TRUE

/obj/item/minor_reliquary/proc/spook_candles(snuff = prob(SPIRIT_SNUFF_CHANCE))
	var/turf/center = haunt_center()
	var/area/haunt_area = get_area(center)
	for(var/obj/item/candle/candle in range(SPIRIT_RANGE, center))
		if(!candle.lit || get_area(candle) != haunt_area)
			continue
		if(snuff)
			candle.put_out_candle()
			candle.visible_message(span_warning("Пламя [candle] вздрагивает и гаснет, хотя сквозняка нет."))
			return TRUE
		var/old_range = candle.light_range
		candle.set_light(1)
		addtimer(CALLBACK(src, PROC_REF(restore_candle), WEAKREF(candle), old_range), SPIRIT_CANDLE_SHIVER_TIME)
		candle.visible_message(span_warning("Пламя [candle] съёживается и на миг синеет."))
		return TRUE
	return FALSE

/obj/item/minor_reliquary/proc/restore_candle(datum/weakref/candle_ref, old_range)
	var/obj/item/candle/candle = candle_ref.resolve()
	if(candle?.lit)
		candle.set_light(old_range)

/obj/item/minor_reliquary/proc/spook_lights()
	var/turf/center = haunt_center()
	var/area/haunt_area = get_area(center)
	var/list/lamps = list()
	for(var/obj/machinery/light/lamp in range(SPIRIT_RANGE, center))
		if(lamp.on && lamp.status == LIGHT_OK && get_area(lamp) == haunt_area)
			lamps += lamp
	if(!length(lamps))
		return FALSE
	for(var/i in 1 to min(SPIRIT_LAMPS_PER_SPOOK, length(lamps)))
		var/obj/machinery/light/lamp = pick_n_take(lamps)
		lamp.flicker(rand(SPIRIT_FLICKER_MIN, SPIRIT_FLICKER_MAX))
	return TRUE

/obj/item/minor_reliquary/proc/spook_nudge()
	var/turf/center = haunt_center()
	var/area/haunt_area = get_area(center)
	var/list/loose = list()
	for(var/obj/item/thing in range(SPIRIT_RANGE, center))
		if(thing == src || thing.anchored || thing.w_class > WEIGHT_CLASS_SMALL || !isturf(thing.loc) || get_area(thing) != haunt_area)
			continue
		loose += thing
	while(length(loose))
		var/obj/item/thing = pick_n_take(loose)
		for(var/direction in shuffle(GLOB.cardinals))
			var/turf/next = get_step(thing, direction)
			if(!next || get_area(next) != haunt_area)
				continue
			if(thing.Move(next, direction))
				thing.visible_message(span_warning("[thing] сам собой сдвигается по полу."))
				return TRUE
	return FALSE

/obj/item/minor_reliquary/proc/spook_whisper()
	var/turf/center = haunt_center()
	if(!center)
		return FALSE
	playsound(center, pick(whispers), 30, TRUE, SILENCED_SOUND_EXTRARANGE)
	var/area/haunt_area = get_area(center)
	for(var/mob/living/witness in SSspatial_grid.orthogonal_range_search(center, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, SPIRIT_RANGE))
		if(get_area(witness) == haunt_area)
			to_chat(witness, span_warning(pick(chills)))
	return TRUE

/// Неуспокоенный дух перебирается в соседний отсек: проявления идут уже там.
/obj/item/minor_reliquary/proc/wander()
	wander_timer = null
	if(!haunted)
		return FALSE
	schedule_wander()
	var/turf/origin = haunt_center()
	var/turf/destination = find_neighbour_turf()
	if(!origin || !destination)
		return FALSE
	haunt_turf = destination
	var/area/new_area = get_area(destination)
	new /obj/effect/temp_visual/minor_spirit_shade(origin, get_dir(origin, destination))
	new /obj/effect/temp_visual/minor_spirit_shade(destination)
	origin.visible_message(span_warning("Бледная тень соскальзывает сквозь стену, и шёпот уходит в сторону отсека [new_area.name]."))
	spook_whisper()
	log_game("DIRECTOR: Restless Spirit, дух перебрался в [AREACOORD(destination)].")
	return TRUE

/// Пол соседнего отсека: через проход или через одну стену от места проявлений.
/obj/item/minor_reliquary/proc/find_neighbour_turf()
	var/area/current = get_area(haunt_center())
	if(!current)
		return null
	var/list/candidates = list()
	for(var/turf/open/floor/floor in current)
		for(var/direction in GLOB.cardinals)
			var/turf/next = get_step(floor, direction)
			if(isclosedturf(next))
				next = get_step(next, direction)
			if(is_wander_target(next, current))
				candidates += next
	return length(candidates) ? pick(candidates) : null

/obj/item/minor_reliquary/proc/is_wander_target(turf/candidate, area/current)
	if(!istype(candidate, /turf/open/floor) || !is_station_level(candidate.z))
		return FALSE
	var/area/candidate_area = get_area(candidate)
	return candidate_area != current && !istype(candidate_area, /area/space) && !istype(candidate_area, /area/shuttle)

/obj/item/minor_reliquary/proc/on_altar()
	if(!isturf(loc))
		return FALSE
	var/in_chapel = istype(get_area(src), /area/service/chapel)
	for(var/obj/structure/stand in loc)
		if(istype(stand, /obj/structure/sacrificealtar) || istype(stand, /obj/structure/fluff/divine))
			return TRUE
		if(in_chapel && istype(stand, /obj/structure/table))
			return TRUE
	return FALSE

/obj/item/minor_reliquary/proc/lit_candles_near()
	. = 0
	var/turf/center = get_turf(src)
	if(!center)
		return
	for(var/obj/item/candle/candle in range(SPIRIT_RITUAL_RANGE, center))
		if(candle.lit)
			.++

/obj/item/minor_reliquary/proc/ritual_ready()
	return on_altar() && lit_candles_near() >= SPIRIT_RITUAL_CANDLES

/obj/item/minor_reliquary/attackby(obj/item/tool, mob/living/user, params)
	if(is_calming_tool(tool))
		attempt_calm(user, tool)
		return TRUE
	return ..()

/obj/item/minor_reliquary/proc/is_calming_tool(obj/item/tool)
	if(istype(tool, /obj/item/storage/book/bible) || istype(tool, /obj/item/nullrod))
		return TRUE
	return haunted && tool.reagents?.has_reagent(/datum/reagent/water/holywater, SPIRIT_HOLY_WATER_DOSE)

/obj/item/minor_reliquary/proc/is_holy(mob/living/user)
	return user?.mind?.isholy

/obj/item/minor_reliquary/proc/calm_time(mob/living/user)
	return is_holy(user) ? SPIRIT_CALM_TIME_HOLY : SPIRIT_CALM_TIME_LAY

/obj/item/minor_reliquary/proc/calm_chance(mob/living/user)
	if(ritual_ready())
		return 100
	return is_holy(user) ? SPIRIT_HOLY_CHANCE : SPIRIT_LAY_CHANCE

/obj/item/minor_reliquary/proc/attempt_calm(mob/living/user, obj/item/tool)
	if(!haunted)
		to_chat(user, span_notice("Реликварий молчит: успокаивать уже некого."))
		return FALSE
	if(calming)
		return FALSE
	var/with_water = !istype(tool, /obj/item/storage/book/bible) && !istype(tool, /obj/item/nullrod)
	calming = TRUE
	if(istype(tool, /obj/item/storage/book/bible))
		user.visible_message(span_notice("[user] читает молитву над [src]."), span_notice("Вы читаете молитву над реликварием..."))
	else if(istype(tool, /obj/item/nullrod))
		user.visible_message(span_notice("[user] медленно проводит [tool.name] над [src]."), span_notice("Вы медленно проводите [tool.name] над реликварием..."))
	else
		user.visible_message(span_notice("[user] окропляет [src] святой водой."), span_notice("Вы окропляете реликварий святой водой..."))
	if(ritual_ready())
		to_chat(user, span_notice("Реликварий на алтаре, свечи рядом горят: обряд готов, дух уйдёт наверняка, если пламя не погаснет."))
	var/finished = do_after(user, calm_time(user), target = src)
	calming = FALSE
	if(!finished || !haunted)
		return FALSE
	if(with_water)
		if(!tool.reagents?.has_reagent(/datum/reagent/water/holywater, SPIRIT_HOLY_WATER_DOSE))
			to_chat(user, span_warning("Святой воды не хватило."))
			return FALSE
		tool.reagents.remove_reagent(/datum/reagent/water/holywater, SPIRIT_HOLY_WATER_DOSE)
	if(!prob(calm_chance(user)))
		to_chat(user, span_warning("Сияние под стеклом вздрагивает, но не гаснет. Дух вас не слушает. Обряд на алтаре со свечами сработал бы наверняка."))
		spook_whisper()
		return FALSE
	return calm(user)

/// Дух успокоен: тень уходит из реликвария, эффекты прекращаются, реликварий становится антиквариатом.
/obj/item/minor_reliquary/proc/calm(mob/living/user)
	if(!haunted)
		return FALSE
	var/turf/spot = get_turf(src)
	end_haunting()
	calmed = TRUE
	name = "antique reliquary"
	desc = "Старинный серебряный реликварий тонкой работы. Стекло в стенке прояснилось, внутри пусто и тихо."
	if(spot)
		new /obj/effect/temp_visual/minor_spirit_shade(spot)
	visible_message(span_notice("Из [src] поднимается бледная тень и тает в воздухе. Холодное сияние под стеклом гаснет, вокруг становится теплее."))
	playsound(src, 'sound/effects/pray_chaplain.ogg', 50, TRUE)
	if(user)
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "minor_spirit_calmed", /datum/mood_event/minor_spirit_calmed)
	log_game("DIRECTOR: Restless Spirit, дух успокоил [key_name(user)] в [get_area_name(src, TRUE)].")
	return TRUE

/obj/item/minor_reliquary/proc/fade_out()
	fade_timer = null
	if(!haunted)
		return FALSE
	end_haunting()
	desc = "Потемневший реликварий с мутным стеклом. Что бы в нём ни было, оно ушло само и прихватило с собой всю ценность."
	visible_message(span_notice("Шёпот у [src] стихает сам собой. Реликварий тускнеет."))
	log_game("DIRECTOR: Restless Spirit, дух затих сам в [get_area_name(src, TRUE)].")
	return TRUE

/obj/item/minor_reliquary/proc/end_haunting()
	haunted = FALSE
	haunt_turf = null
	stop_timers()
	set_light(0)
	update_appearance()

/// Бледная тень духа: без направления поднимается и тает, с направлением уходит в ту сторону.
/obj/effect/temp_visual/minor_spirit_shade
	name = "pale shade"
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	color = "#a9dcff"
	alpha = 0
	randomdir = FALSE
	duration = 2 SECONDS

/obj/effect/temp_visual/minor_spirit_shade/Initialize(mapload, drift_dir)
	. = ..()
	var/drift_x = 0
	var/drift_y = SPIRIT_SHADE_RISE
	if(drift_dir)
		setDir(drift_dir)
		drift_x = (drift_dir & EAST) ? world.icon_size : ((drift_dir & WEST) ? -world.icon_size : 0)
		drift_y = (drift_dir & NORTH) ? world.icon_size : ((drift_dir & SOUTH) ? -world.icon_size : 0)
	animate(src, alpha = 170, time = 0.4 SECONDS)
	animate(pixel_x = drift_x, pixel_y = drift_y, alpha = 0, time = duration - 0.4 SECONDS, easing = SINE_EASING)

/datum/export/minor_reliquary
	cost = SPIRIT_ANTIQUE_PRICE
	k_elasticity = 0
	unit_name = "antique reliquary"
	export_types = list(/obj/item/minor_reliquary)

/datum/export/minor_reliquary/get_cost(obj/item/minor_reliquary/reliquary, allowed_categories, apply_elastic)
	if(!istype(reliquary) || !reliquary.calmed)
		return 0
	return ..()

#undef SPIRIT_DURATION
#undef SPIRIT_SPOOK_MIN
#undef SPIRIT_SPOOK_MAX
#undef SPIRIT_WANDER_TIME
#undef SPIRIT_RANGE
#undef SPIRIT_CALM_TIME_HOLY
#undef SPIRIT_CALM_TIME_LAY
#undef SPIRIT_HOLY_CHANCE
#undef SPIRIT_LAY_CHANCE
#undef SPIRIT_RITUAL_CANDLES
#undef SPIRIT_RITUAL_RANGE
#undef SPIRIT_HOLY_WATER_DOSE
#undef SPIRIT_ANTIQUE_PRICE
#undef SPIRIT_SNUFF_CHANCE
#undef SPIRIT_CANDLE_SHIVER_TIME
#undef SPIRIT_LAMPS_PER_SPOOK
#undef SPIRIT_FLICKER_MIN
#undef SPIRIT_FLICKER_MAX
#undef SPIRIT_SHADE_RISE
