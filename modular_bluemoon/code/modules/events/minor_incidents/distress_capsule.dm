#define DISTRESS_CAPSULE_MIN_DIST 2
#define DISTRESS_CAPSULE_MAX_DIST 4
#define DISTRESS_CAPSULE_GPS_TAG "Сигнал бедствия"
#define DISTRESS_CAPSULE_WAIT (10 MINUTES)
/// Гости узнают о капсуле сразу, экипаж - позже: роль успевают занять до прихода спасателей.
#define DISTRESS_CAPSULE_HEADSTART_SECONDS 40
#define DISTRESS_CAPSULE_BEEP_INTERVAL (5 SECONDS)
#define DISTRESS_CAPSULE_BEACON_LIFETIME (20 MINUTES)
#define DISTRESS_CAPSULE_BEEP_VOLUME 20
#define DISTRESS_CAPSULE_PRY_TIME (6 SECONDS)
#define DISTRESS_CAPSULE_FORCE_TIME (12 SECONDS)
#define DISTRESS_CAPSULE_CUT_TIME (8 SECONDS)
#define DISTRESS_CAPSULE_STUCK_COOLDOWN (5 SECONDS)
#define DISTRESS_CAPSULE_SCRAP 5
#define DISTRESS_SURVIVOR_BRUTE 40
#define DISTRESS_SURVIVOR_OXY 25
#define DISTRESS_RESCUE_HEALTH 80
#define DISTRESS_RESCUE_REWARD 300
#define DISTRESS_RECORDER_COOLDOWN (3 SECONDS)

/datum/round_event_control/minor_outside/distress_capsule
	name = "Distress Capsule"
	typepath = /datum/round_event/minor_outside/distress_capsule
	category = EVENT_CATEGORY_SPAWNERS
	min_players = 10
	family = "distress_capsule"
	announcement_title = "Служба поиска и спасения NanoTrasen"

/datum/round_event_control/minor_outside/distress_capsule/New()
	description = "У корпуса станции дрейфует спасательная капсула с сигналом бедствия. Гости узнают о ней за [DISTRESS_CAPSULE_HEADSTART_SECONDS] секунд до экипажа и могут сыграть раненого пилота; если роль никто не займёт, в капсуле останутся аварийный набор и бортовой самописец. Когда пилот выходит из медбея здоровым (не меньше [DISTRESS_RESCUE_HEALTH]% здоровья), медбей получает [DISTRESS_RESCUE_REWARD] кредитов."
	announcement_text = "Принят автоматический сигнал бедствия гражданской спасательной капсулы: она дрейфует у внешней обшивки станции, координаты есть в GPS под меткой «[DISTRESS_CAPSULE_GPS_TAG]». По телеметрии люк заклинило, вскрыть его можно ломом. Парамедикам и сотрудникам с допуском к EVA - проверить капсулу; спасённого пилота направьте в медбей, а не в бухгалтерию. Когда пилот выйдет из медбея здоровым, служба поиска и спасения переведёт в бюджет медбея [DISTRESS_RESCUE_REWARD] кредитов."
	return ..()

/datum/round_event_control/minor_outside/distress_capsule/find_site(first_only = FALSE)
	return outside_find_hull_space(DISTRESS_CAPSULE_MIN_DIST, DISTRESS_CAPSULE_MAX_DIST, first_only)

/datum/round_event/minor_outside/distress_capsule
	announce_when = DISTRESS_CAPSULE_HEADSTART_SECONDS EVENT_SECONDS

/datum/round_event/minor_outside/distress_capsule/spawn_at(turf/site)
	var/obj/structure/distress_capsule/capsule = new(site)
	if(capsule.spawner)
		notify_ghosts("У обшивки станции дрейфует спасательная капсула. Можно сыграть раненого пилота гражданского челнока: экипаж узнает о капсуле через [DISTRESS_CAPSULE_HEADSTART_SECONDS] секунд.", source = capsule.spawner, action = NOTIFY_ATTACK, header = "Distress Capsule")
	return capsule

/datum/round_event/minor_outside/distress_capsule/describe_site(turf/site)
	var/area/nearest = outside_nearest_station_area(site, DISTRESS_CAPSULE_MAX_DIST + 1)
	return nearest ? "Ближайший отсек: [nearest.name]." : null

/obj/structure/distress_capsule
	name = "escape capsule"
	desc = "Одноместная спасательная капсула гражданского челнока. Обшивка обожжена при отстреле, на крыше мигает маяк бедствия."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/distress_capsule.dmi'
	icon_state = "capsule"
	density = TRUE
	anchored = TRUE
	max_integrity = 300
	var/hatch_open = FALSE
	var/obj/effect/mob_spawn/human/distress_survivor/spawner
	var/beacon_timer
	var/beacon_until = 0
	var/wait_timer
	COOLDOWN_DECLARE(stuck_message_cooldown)

/obj/structure/distress_capsule/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/gps, DISTRESS_CAPSULE_GPS_TAG)
	spawner = new(src)
	spawner.capsule = src
	wait_timer = addtimer(CALLBACK(src, PROC_REF(stop_waiting)), DISTRESS_CAPSULE_WAIT, TIMER_STOPPABLE)
	beacon_until = world.time + DISTRESS_CAPSULE_BEACON_LIFETIME
	beacon_timer = addtimer(CALLBACK(src, PROC_REF(beacon_beep)), DISTRESS_CAPSULE_BEEP_INTERVAL, TIMER_STOPPABLE)

/obj/structure/distress_capsule/Destroy()
	silence_beacon()
	deltimer(wait_timer)
	wait_timer = null
	QDEL_NULL(spawner)
	var/turf/drop = drop_location()
	for(var/atom/movable/thing as anything in contents)
		if(drop)
			thing.forceMove(drop)
		else
			qdel(thing)
	return ..()

/obj/structure/distress_capsule/update_icon_state()
	icon_state = hatch_open ? "capsule_open" : "capsule"
	return ..()

/obj/structure/distress_capsule/examine(mob/user)
	. = ..()
	if(hatch_open)
		. += span_notice("Люк сорван. Пустой корпус можно разрезать сваркой на металл.")
		return
	. += span_notice("Люк заклинило. Снаружи его можно вскрыть ломом, изнутри - выбить.")
	if(!beacon_timer)
		. += span_notice("Звуковой маяк молчит, но сигнал в GPS ещё идёт.")

/// Маяк пищит, пока капсулу не вскрыли, роль ещё ждёт пилота или пилот внутри, но не дольше срока батареи.
/obj/structure/distress_capsule/proc/beacon_beep()
	beacon_timer = null
	if(hatch_open)
		return
	playsound(src, pick('modular_bluemoon/sound/minor_incidents/distress_capsule_beacon_1.ogg', 'modular_bluemoon/sound/minor_incidents/distress_capsule_beacon_2.ogg', 'modular_bluemoon/sound/minor_incidents/distress_capsule_beacon_3.ogg'), DISTRESS_CAPSULE_BEEP_VOLUME, FALSE, SILENCED_SOUND_EXTRARANGE, pressure_affected = FALSE)
	if(world.time + DISTRESS_CAPSULE_BEEP_INTERVAL <= beacon_until)
		beacon_timer = addtimer(CALLBACK(src, PROC_REF(beacon_beep)), DISTRESS_CAPSULE_BEEP_INTERVAL, TIMER_STOPPABLE)

/obj/structure/distress_capsule/proc/silence_beacon()
	deltimer(beacon_timer)
	beacon_timer = null

/obj/structure/distress_capsule/proc/receive_survivor(mob/living/survivor)
	deltimer(wait_timer)
	wait_timer = null
	if(!hatch_open)
		survivor.forceMove(src)
	if(ishuman(survivor))
		survivor.AddComponent(/datum/component/distress_rescue)
	log_game("DIRECTOR: Distress Capsule, [key_name(survivor)] занимает роль пилота капсулы в [AREACOORD(src)].")

/// Пилота никто не сыграл: капсула оказывается пустой, внутри остаются аварийный набор и самописец.
/obj/structure/distress_capsule/proc/stop_waiting()
	wait_timer = null
	if(!spawner)
		return FALSE
	QDEL_NULL(spawner)
	silence_beacon()
	var/atom/holder = hatch_open ? drop_location() : src
	new /obj/item/storage/firstaid/regular(holder)
	new /obj/item/storage/toolbox/emergency(holder)
	new /obj/item/distress_flight_recorder(holder)
	log_game("DIRECTOR: Distress Capsule, роль пилота не занята; в капсуле остались аварийный набор и самописец ([AREACOORD(src)]).")
	return TRUE

/obj/structure/distress_capsule/proc/open_hatch(mob/living/user)
	if(hatch_open)
		return FALSE
	hatch_open = TRUE
	silence_beacon()
	stop_waiting()
	qdel(GetComponent(/datum/component/gps))
	var/turf/drop = drop_location()
	for(var/atom/movable/thing as anything in contents)
		thing.forceMove(drop)
	playsound(src, 'sound/machines/airlockforced.ogg', 50, TRUE)
	visible_message(span_notice("Люк [src] со скрежетом отходит в сторону."))
	update_appearance()
	log_game("DIRECTOR: Distress Capsule, люк вскрыт ([user ? key_name(user) : "без участия игрока"]) в [AREACOORD(src)].")
	return TRUE

/obj/structure/distress_capsule/crowbar_act(mob/living/user, obj/item/tool)
	if(hatch_open)
		to_chat(user, span_notice("Люк [src] уже открыт."))
		return TRUE
	user.visible_message(span_notice("[user] поддевает люк [src] ломом."), span_notice("Вы поддеваете заклинивший люк [src] ломом..."))
	if(tool.use_tool(src, user, DISTRESS_CAPSULE_PRY_TIME, volume = 50) && !QDELETED(src))
		open_hatch(user)
	return TRUE

/obj/structure/distress_capsule/welder_act(mob/living/user, obj/item/tool)
	if(!hatch_open)
		to_chat(user, span_warning("Сначала нужно вскрыть люк: внутри может быть человек."))
		return TRUE
	if(!tool.tool_start_check(user, amount = 1))
		return TRUE
	to_chat(user, span_notice("Вы начинаете разрезать корпус [src]..."))
	if(tool.use_tool(src, user, DISTRESS_CAPSULE_CUT_TIME, amount = 1, volume = 50) && !QDELETED(src))
		deconstruct(TRUE)
	return TRUE

/obj/structure/distress_capsule/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1) && drop_location())
		new /obj/item/stack/sheet/metal(drop_location(), DISTRESS_CAPSULE_SCRAP)
	qdel(src)

/obj/structure/distress_capsule/container_resist(mob/living/user)
	if(hatch_open)
		user.forceMove(drop_location())
		return
	to_chat(user, span_notice("Вы упираетесь в заклинивший люк и начинаете выбивать его изнутри..."))
	if(do_after(user, DISTRESS_CAPSULE_FORCE_TIME, src) && user.loc == src)
		open_hatch(user)

/obj/structure/distress_capsule/relaymove(mob/living/user, direction)
	if(hatch_open || user.stat || !COOLDOWN_FINISHED(src, stuck_message_cooldown))
		return
	COOLDOWN_START(src, stuck_message_cooldown, DISTRESS_CAPSULE_STUCK_COOLDOWN)
	to_chat(user, span_warning("Люк заклинило. Выбить его изнутри можно сопротивлением (Resist)."))

/obj/effect/mob_spawn/human/distress_survivor
	name = "Capsule Survivor"
	short_desc = "Вы - пилот гражданского челнока, разбившегося на подлёте к станции NanoTrasen."
	flavour_text = "Двигатель отказал у самой станции, и вы успели уйти в спасательную капсулу. Она дрейфует у обшивки, маяк подаёт сигнал бедствия. Вы ранены и надышались дымом, но аварийный скафандр цел и баллон подключён, а в ухе гарнитура. Люк заклинило: дождитесь спасателей или выбейте его изнутри (Resist) - снаружи открытый космос."
	important_info = "Вы не антагонист. На станции вы гость и подчиняетесь её законам. Дойдите до медбея: если вы выйдете оттуда здоровым, служба поиска и спасения заплатит медикам. Чтобы остаться на борту и работать, обратитесь к главе персонала (HoP): он может оформить вас в экипаж."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/distress_capsule.dmi'
	icon_state = "capsule"
	mob_name = "capsule survivor"
	roundstart = FALSE
	death = FALSE
	random = TRUE
	can_load_appearance = TRUE
	make_bank_account = TRUE
	brute_damage = DISTRESS_SURVIVOR_BRUTE
	oxy_damage = DISTRESS_SURVIVOR_OXY
	outfit = /datum/outfit/distress_survivor
	id_job = "Civilian Pilot"
	banType = ROLE_GHOSTROLE
	category = "midround"
	var/obj/structure/distress_capsule/capsule

/obj/effect/mob_spawn/human/distress_survivor/Destroy()
	if(capsule?.spawner == src)
		capsule.spawner = null
	capsule = null
	return ..()

/obj/effect/mob_spawn/human/distress_survivor/create(ckey, name, load_character, spawn_type)
	var/obj/structure/distress_capsule/home = capsule
	. = ..()
	var/mob/living/survivor = .
	if(istype(survivor) && !QDELETED(home))
		home.receive_survivor(survivor)

/obj/effect/mob_spawn/human/distress_survivor/special_post_appearance(mob/living/carbon/human/survivor)
	. = ..()
	if(ishuman(survivor))
		distress_survivor_species_gear(survivor)

/// Загруженный персонаж может дышать не кислородом: баллон и одежда под его вид.
/proc/distress_survivor_species_gear(mob/living/carbon/human/survivor)
	var/tank_type
	switch(survivor.dna?.species?.breathid)
		if("tox")
			tank_type = /obj/item/tank/internals/plasmaman/full
		if("n2")
			tank_type = /obj/item/tank/internals/emergency_nitrogen/double
	if(tank_type)
		var/obj/item/old_tank = survivor.s_store
		survivor.internal = null
		qdel(old_tank)
		var/obj/item/tank/new_tank = new tank_type(survivor)
		if(!survivor.equip_to_slot_if_possible(new_tank, ITEM_SLOT_SUITSTORE, disable_warning = TRUE) && !survivor.put_in_hands(new_tank))
			new_tank.forceMove(survivor.drop_location())
		if(new_tank.loc == survivor)
			survivor.internal = new_tank
		survivor.update_action_buttons_icon()
	if(!isplasmaman(survivor))
		return
	var/obj/item/old_uniform = survivor.w_uniform
	if(old_uniform && survivor.temporarilyRemoveItemFromInventory(old_uniform, TRUE, FALSE))
		qdel(old_uniform)
	survivor.equip_to_slot_or_del(new /obj/item/clothing/under/plasmaman(survivor), ITEM_SLOT_ICLOTHING)
	var/obj/item/clothing/head/helmet/space/plasmaman/envirohelm = new(survivor)
	if(!survivor.put_in_hands(envirohelm))
		envirohelm.forceMove(survivor.drop_location())

/datum/outfit/distress_survivor
	name = "Distress Capsule Survivor"
	uniform = /obj/item/clothing/under/misc/overalls
	suit = /obj/item/clothing/suit/space/fragile
	head = /obj/item/clothing/head/helmet/space/fragile
	mask = /obj/item/clothing/mask/breath
	ears = /obj/item/radio/headset
	suit_store = /obj/item/tank/internals/emergency_oxygen/double
	internals_slot = ITEM_SLOT_SUITSTORE
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_pocket = /obj/item/flashlight
	id = /obj/item/card/id

/// Пилот, вышедший из медбея здоровым, приносит медбею премию службы спасения.
/datum/component/distress_rescue
	var/in_medbay = FALSE
	var/rescued = FALSE

/datum/component/distress_rescue/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/distress_rescue/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ENTER_AREA, PROC_REF(on_enter_area))

/datum/component/distress_rescue/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ENTER_AREA)

/datum/component/distress_rescue/proc/on_enter_area(datum/source, area/new_area)
	SIGNAL_HANDLER
	if(rescued)
		return
	if(istype(new_area, /area/medical))
		in_medbay = TRUE
		return
	if(!in_medbay)
		return
	in_medbay = FALSE
	var/mob/living/survivor = parent
	if(survivor.stat != CONSCIOUS || survivor.health < DISTRESS_RESCUE_HEALTH)
		return
	rescued = TRUE
	INVOKE_ASYNC(src, PROC_REF(discharge))

/datum/component/distress_rescue/proc/discharge()
	var/mob/living/survivor = parent
	var/paid = minor_crew_pay_department(ACCOUNT_MED, DISTRESS_RESCUE_REWARD, "Служба поиска и спасения: пилот спасательной капсулы выписан")
	paperwork_radio("Спасённый пилот спасательной капсулы [survivor.real_name] выписан из медбея.[paid ? " Служба поиска и спасения переводит в бюджет медбея [DISTRESS_RESCUE_REWARD] кредитов." : ""]", RADIO_CHANNEL_MEDICAL)
	to_chat(survivor, span_nicegreen("Вы выходите из медбея на своих ногах. Служба поиска и спасения благодарит медиков станции."))
	log_game("DIRECTOR: Distress Capsule, [key_name(survivor)] выписан из медбея здоровым[paid ? ", медбею переведено [DISTRESS_RESCUE_REWARD] кр." : ", бюджета медбея нет"].")
	qdel(src)

/obj/item/distress_flight_recorder
	name = "flight recorder"
	desc = "Оранжевый бортовой самописец спасательной капсулы. Корпус ударопрочный, кнопка воспроизведения сбоку: используйте его в руке, чтобы прослушать последнюю запись."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/distress_capsule.dmi'
	icon_state = "flight_recorder"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	item_state = "analyzer"
	w_class = WEIGHT_CLASS_SMALL
	drop_sound = 'sound/items/handling/taperecorder_drop.ogg'
	pickup_sound = 'sound/items/handling/taperecorder_pickup.ogg'
	var/static/list/transcript = list(
		"Бортовой самописец. Челнок «Пеликан-7», рейс Тау Кита - станция NanoTrasen.",
		"\[-04:12\] Пилот: Диспетчер, «Пеликан-7». Давление в топливной магистрали падает, иду к станции по аварийному коридору.",
		"\[-02:31\] Борт: Утечка топлива. Тяга сорок процентов.",
		"\[-01:06\] Пилот: Не дотяну. Капсулу отстреливаю на автомате, сам к шлюзу, там скафандр.",
		"\[-00:09\] Борт: Капсула отделена. Кресло пилота не занято.",
		"\[+00:47\] Буксир «Мирный-2»: Пилота подобрали, живой и злой. Капсулу ловить не будем, маяк оставляем станции. Конец связи.",
	)
	COOLDOWN_DECLARE(playback_cooldown)

/obj/item/distress_flight_recorder/attack_self(mob/user)
	. = ..()
	if(!COOLDOWN_FINISHED(src, playback_cooldown))
		return
	COOLDOWN_START(src, playback_cooldown, DISTRESS_RECORDER_COOLDOWN)
	playsound(src, 'sound/items/taperecorder/taperecorder_play.ogg', 30, TRUE, SILENCED_SOUND_EXTRARANGE)
	to_chat(user, examine_block(jointext(transcript, "<br>")))

#undef DISTRESS_CAPSULE_MIN_DIST
#undef DISTRESS_CAPSULE_MAX_DIST
#undef DISTRESS_CAPSULE_GPS_TAG
#undef DISTRESS_CAPSULE_WAIT
#undef DISTRESS_CAPSULE_HEADSTART_SECONDS
#undef DISTRESS_CAPSULE_BEEP_INTERVAL
#undef DISTRESS_CAPSULE_BEACON_LIFETIME
#undef DISTRESS_CAPSULE_BEEP_VOLUME
#undef DISTRESS_CAPSULE_PRY_TIME
#undef DISTRESS_CAPSULE_FORCE_TIME
#undef DISTRESS_CAPSULE_CUT_TIME
#undef DISTRESS_CAPSULE_STUCK_COOLDOWN
#undef DISTRESS_CAPSULE_SCRAP
#undef DISTRESS_SURVIVOR_BRUTE
#undef DISTRESS_SURVIVOR_OXY
#undef DISTRESS_RESCUE_HEALTH
#undef DISTRESS_RESCUE_REWARD
#undef DISTRESS_RECORDER_COOLDOWN
