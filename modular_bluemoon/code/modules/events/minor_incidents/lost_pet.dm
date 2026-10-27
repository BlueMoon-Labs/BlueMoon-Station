#define LOST_PET_REWARD 150
#define LOST_PET_MIN_DISTANCE 30
#define LOST_PET_FLYERS 4
#define LOST_PET_DURATION (30 MINUTES)
/// Раннер событий шагает раз в две секунды.
#define LOST_PET_EVENT_STEP (2 SECONDS)
/// Сколько после того, как питомца отпустили, приведший ещё считается приведшим.
#define LOST_PET_HANDLER_GRACE (1 MINUTES)
#define LOST_PET_BRINGER_RANGE 7
#define LOST_PET_PHOTO_SCALE 0.3
/// Датчик ошейника отмечается в общем канале раз в столько минут.
#define LOST_PET_PING_MIN (3 MINUTES)
#define LOST_PET_PING_MAX (5 MINUTES)
/// Сколько питомец ходит за тем, кто его погладил или угостил.
#define LOST_PET_FOLLOW_TIME (60 SECONDS)
#define LOST_PET_FOLLOW_STEP_DELAY 3

/datum/round_event_control/lost_pet
	name = "Lost Pet"
	typepath = /datum/round_event/lost_pet
	weight = 15
	max_occurrences = 1
	earliest_start = 15 MINUTES
	min_players = 8
	severity = DIRECTOR_SEVERITY_MINOR
	category = EVENT_CATEGORY_FRIENDLY
	family = "lost_pet"
	/// Тип отсека, должность главы и отдел; первое совпадение по типу отсека.
	var/static/list/departments = list(
		list(/area/command/heads_quarters/hop, "Head of Personnel", "отдел кадров"),
		list(/area/command/heads_quarters/cmo, "Chief Medical Officer", "медицинский отдел"),
		list(/area/command/heads_quarters/ce, "Chief Engineer", "инженерный отдел"),
		list(/area/command/heads_quarters/rd, "Research Director", "научный отдел"),
		list(/area/command/heads_quarters/hos, "Head of Security", "служба безопасности"),
		list(/area/command/heads_quarters/captain, "Captain", "командование"),
		list(/area/command, "Captain", "командование"),
		list(/area/medical, "Chief Medical Officer", "медицинский отдел"),
		list(/area/engineering, "Chief Engineer", "инженерный отдел"),
		list(/area/science, "Research Director", "научный отдел"),
		list(/area/security, "Head of Security", "служба безопасности"),
		list(/area/cargo, "Quartermaster", "отдел снабжения"),
		list(/area/service, "Head of Personnel", "сервисный отдел"),
	)
	/// Именные питомцы станции, точные типы: донатные питомцы из маяков сюда не попадают.
	var/static/list/station_pet_types = list(
		/mob/living/simple_animal/pet/dog/corgi/Ian,
		/mob/living/simple_animal/pet/dog/corgi/Lisa,
		/mob/living/simple_animal/pet/cat/Runtime,
		/mob/living/simple_animal/pet/cat/Proc,
		/mob/living/simple_animal/pet/fox/Renault,
		/mob/living/simple_animal/parrot/Polly,
		/mob/living/simple_animal/opossum/poppy,
		/mob/living/simple_animal/sloth/paperwork,
		/mob/living/simple_animal/sloth/citrus,
	)
	var/list/hideout_area_types = list(/area/maintenance)
	/// Куда может «прописаться» потерявшийся щенок или котёнок, если своих питомцев нет.
	var/list/stray_home_types = list(/area/command/heads_quarters/hop, /area/command/heads_quarters/cmo, /area/command/heads_quarters/ce, /area/command/heads_quarters/rd, /area/service/bar, /area/medical/medbay/lobby)

/datum/round_event_control/lost_pet/New()
	. = ..()
	description = "Станционный питомец (Ian, Runtime, Polly, Renault и др.) теряется в техтоннелях, в коридорах появляются листовки. Датчик ошейника раз в [LOST_PET_PING_MIN / (1 MINUTES)]-[LOST_PET_PING_MAX / (1 MINUTES)] минут сообщает отсек по общему каналу, погладивший или угостивший питомца [LOST_PET_FOLLOW_TIME / (1 SECONDS)] секунд ведёт его за собой. Приведший его живым домой получает [LOST_PET_REWARD] кредитов, глава отдела - хорошее настроение. Без питомцев на станции теряется щенок или котёнок с ошейником отдела."

/datum/round_event_control/lost_pet/proc/department_for(area/location)
	for(var/list/entry as anything in departments)
		if(istype(location, entry[1]))
			return entry
	return null

/datum/round_event_control/lost_pet/proc/valid_home(area/location)
	if(!location || istype(location, /area/maintenance) || istype(location, /area/hallway) || istype(location, /area/space))
		return FALSE
	return length(minor_crew_area_floors(location, first_only = TRUE)) > 0

/// Питомцем управляет игрок: событие его не теряет и не уводит лаской или угощением.
/proc/lost_pet_player_controlled(mob/living/animal)
	return animal.key || animal.client || animal.mind

/// Именной питомец станции из списка, живой и без игрока.
/datum/round_event_control/lost_pet/proc/is_station_pet(mob/living/simple_animal/animal)
	if(QDELETED(animal) || animal.stat == DEAD || lost_pet_player_controlled(animal))
		return FALSE
	return animal.type in station_pet_types

/// Станционный питомец свободен и сидит в отсеке своего отдела.
/datum/round_event_control/lost_pet/proc/is_candidate(mob/living/simple_animal/animal)
	if(!is_station_pet(animal))
		return FALSE
	if(!isturf(animal.loc) || !is_station_level(animal.z) || animal.buckled || animal.pulledby)
		return FALSE
	var/area/home = get_area(animal)
	return valid_home(home) && department_for(home)

/datum/round_event_control/lost_pet/proc/pick_pet(first_only = FALSE)
	var/list/candidates = list()
	for(var/mob/living/simple_animal/animal in GLOB.mob_living_list)
		if(!is_candidate(animal))
			continue
		candidates += animal
		if(first_only)
			break
	return length(candidates) ? pick(candidates) : null

/datum/round_event_control/lost_pet/proc/pick_stray_home()
	var/list/homes = list()
	for(var/area/location as anything in minor_crew_station_areas(stray_home_types))
		if(valid_home(location))
			homes += location
	return length(homes) ? pick(homes) : null

/// Укромные закутки техтоннелей подальше от дома, без утилизации, солнечных панелей и шлюзов наружу; на другой палубе - любые.
/datum/round_event_control/lost_pet/proc/get_hideouts(turf/home_turf, first_only = FALSE)
	var/list/result = list()
	for(var/area/location as anything in minor_crew_station_areas(hideout_area_types))
		for(var/turf/open/floor/floor in location)
			if(home_turf && floor.z == home_turf.z && get_dist(floor, home_turf) < LOST_PET_MIN_DISTANCE)
				continue
			if(!is_maintenance_hideout(floor))
				continue
			result += floor
			if(first_only)
				return result
		CHECK_TICK
	return result

/datum/round_event_control/lost_pet/proc/get_flyer_spots()
	var/list/spots = list()
	for(var/area/location as anything in shuffle(minor_crew_station_areas(list(/area/hallway))))
		var/list/floors = minor_crew_area_floors(location, require_air = FALSE)
		if(!length(floors))
			continue
		spots += pick(floors)
		if(length(spots) >= LOST_PET_FLYERS)
			break
	return spots

/datum/round_event_control/lost_pet/director_preflight()
	var/area/home
	var/mob/living/simple_animal/pet = pick_pet(first_only = TRUE)
	home = pet ? get_area(pet) : pick_stray_home()
	var/ready = FALSE
	if(home)
		var/list/home_floors = minor_crew_area_floors(home, first_only = TRUE)
		ready = length(home_floors) && length(get_hideouts(home_floors[1], first_only = TRUE))
	director_preflight_detail = ready ? "Питомец: [pet ? pet.name : "щенок или котёнок"], дом - [home.name]." : "Нет питомца, дома или техтоннелей, где он мог бы потеряться."
	director_preflight_failure = ready ? null : director_preflight_detail
	return !!ready

/datum/round_event/lost_pet
	announce_when = 1
	end_when = LOST_PET_DURATION / LOST_PET_EVENT_STEP
	fakeable = FALSE
	var/datum/weakref/pet_ref
	var/pet_name
	var/home_type
	var/home_name
	var/head_title
	var/datum/weakref/last_handler
	var/last_handled_at = 0
	var/next_ping = 0
	var/resolved = FALSE
	var/static/list/stray_names = list("Biscuit", "Pickle", "Button", "Noodle", "Waffles", "Pixel", "Muffin", "Socks")

/datum/round_event/lost_pet/start()
	var/datum/round_event_control/lost_pet/search = control
	if(!istype(search))
		return
	var/mob/living/simple_animal/pet = search.pick_pet()
	var/area/home = pet ? get_area(pet) : search.pick_stray_home()
	var/list/home_floors = home ? minor_crew_area_floors(home, first_only = TRUE) : null
	var/list/hideouts = length(home_floors) ? search.get_hideouts(pet ? get_turf(pet) : home_floors[1]) : null
	if(!length(hideouts))
		var/reason = !home ? "нет ни станционного питомца, ни отсека для щенка" : (!length(home_floors) ? "в отсеке [home.name] нет свободного пола" : "нет укромных техтоннелей подальше от отсека [home.name]")
		log_game("DIRECTOR: [control.name] не запущено: [reason].")
		message_admins("[control.name] не запущено: [reason].")
		return
	var/turf/hideout = pick(hideouts)
	var/list/department_entry = search.department_for(home)
	if(!pet)
		pet = make_stray(hideout, home, department_entry)
	lose_pet(pet, home, hideout, department_entry)
	for(var/turf/spot as anything in search.get_flyer_spots())
		var/obj/item/paper/lost_pet_flyer/flyer = new(spot)
		flyer.describe(pet, home_name, LOST_PET_REWARD)

/datum/round_event/lost_pet/proc/make_stray(turf/hideout, area/home, list/department_entry)
	var/stray_type = pick(/mob/living/simple_animal/pet/dog/corgi/puppy, /mob/living/simple_animal/pet/cat/kitten)
	var/mob/living/simple_animal/pet/stray = new stray_type(hideout)
	var/stray_name = pick(stray_names)
	stray.fully_replace_character_name(null, "\proper [stray_name]")
	var/obj/item/clothing/neck/petcollar/lost_pet/collar = new(stray)
	collar.mark_owner(department_entry ? department_entry[3] : home.name, home.name, stray_name)
	stray.pcollar = collar
	stray.regenerate_icons()
	return stray

/datum/round_event/lost_pet/proc/lose_pet(mob/living/simple_animal/pet, area/home, turf/hideout, list/department_entry)
	pet_ref = WEAKREF(pet)
	pet_name = pet.name
	home_type = home.type
	home_name = home.name
	if(department_entry)
		head_title = department_entry[2]
		if(ispath(department_entry[1], /area/command/heads_quarters))
			home_type = department_entry[1]
	pet.stop_pulling()
	pet.forceMove(hideout)
	if(istype(pet, /mob/living/simple_animal/parrot))
		var/mob/living/simple_animal/parrot/parrot = pet
		parrot.parrot_perch = null
	next_ping = world.time + rand(LOST_PET_PING_MIN, LOST_PET_PING_MAX)
	RegisterSignal(pet, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_petted))
	RegisterSignal(pet, COMSIG_PARENT_ATTACKBY, PROC_REF(on_treated))
	log_game("DIRECTOR: [control?.name], [pet_name] потерялся: дом [home_name], сейчас в [get_area_name(hideout, TRUE)].")

/datum/round_event/lost_pet/announce(fake)
	if(!pet_ref)
		return
	var/mob/living/pet = pet_ref.resolve()
	var/returned = pet ? "верну[pet.ru_sya()]" : "вернулся"
	priority_announce("[pet_name] не [returned] в [home_name]: датчик ошейника отметился в техтоннелях и раз в [LOST_PET_PING_MIN / (1 MINUTES)]-[LOST_PET_PING_MAX / (1 MINUTES)] минут сообщает отсек по общему каналу. Погладьте или угостите питомца, и [LOST_PET_FOLLOW_TIME / (1 SECONDS)] секунд он будет ходить за вами. Приведите его домой живым - нашедшему положено [LOST_PET_REWARD] кредитов. Приметы и фотография - на листовках в коридорах.", "Служба учёта станционной фауны NanoTrasen")

/datum/round_event/lost_pet/tick()
	check_return()

/datum/round_event/lost_pet/proc/check_return()
	if(resolved || !pet_ref)
		return
	var/mob/living/simple_animal/pet = pet_ref.resolve()
	if(QDELETED(pet) || pet.stat == DEAD)
		resolved = TRUE
		log_game("DIRECTOR: [control?.name], [pet_name] погиб или пропал, награды не будет.")
		kill()
		return
	note_handler(pet)
	if(istype(get_area(pet), home_type))
		return_home(pet)
		return
	if(world.time >= next_ping)
		ping_collar(pet)

/// Датчик ошейника сообщает в общий канал, в каком отсеке питомец.
/datum/round_event/lost_pet/proc/ping_collar(mob/living/simple_animal/pet)
	next_ping = world.time + rand(LOST_PET_PING_MIN, LOST_PET_PING_MAX)
	var/area/location = get_area(pet)
	if(!location)
		return FALSE
	return paperwork_radio("Датчик ошейника: [pet_name] сейчас в отсеке [location.name].", RADIO_CHANNEL_COMMON)

/datum/round_event/lost_pet/proc/on_petted(mob/living/simple_animal/pet, mob/living/user)
	SIGNAL_HANDLER
	if(resolved || !ishuman(user) || user.a_intent != INTENT_HELP || pet.stat != CONSCIOUS || lost_pet_player_controlled(pet))
		return
	lure(pet, user)

/datum/round_event/lost_pet/proc/on_treated(mob/living/simple_animal/pet, obj/item/treat, mob/living/user, params)
	SIGNAL_HANDLER
	if(resolved || !ishuman(user) || user.a_intent == INTENT_HARM || pet.stat != CONSCIOUS || lost_pet_player_controlled(pet))
		return
	if(!istype(treat, /obj/item/reagent_containers/food/snacks))
		return
	user.visible_message(span_notice("[user] угощает [pet] - [treat] исчезает в два счёта."), span_notice("Вы угощаете [pet], и [treat] исчезает в два счёта."))
	qdel(treat)
	lure(pet, user)
	return COMPONENT_NO_AFTERATTACK

/datum/round_event/lost_pet/proc/lure(mob/living/simple_animal/pet, mob/living/carbon/human/user)
	if(!pet.GetComponent(/datum/component/lost_pet_follow))
		pet.visible_message(span_notice((istype(pet, /mob/living/simple_animal/parrot) ? "[pet] перелетает на плечо [user]." : "[pet] доверчиво тянется к [user] и идёт следом.")))
	pet.AddComponent(/datum/component/lost_pet_follow, user, LOST_PET_FOLLOW_TIME)
	note_handler(pet)

/// Кто ведёт питомца: тащит, держит на руках или за кем он идёт.
/datum/round_event/lost_pet/proc/note_handler(mob/living/simple_animal/pet)
	var/mob/living/handler = minor_crew_carrier(pet)
	if(!handler)
		var/datum/component/lost_pet_follow/follow = pet.GetComponent(/datum/component/lost_pet_follow)
		handler = follow?.leader_ref?.resolve()
	if(!ishuman(handler))
		return null
	last_handler = WEAKREF(handler)
	last_handled_at = world.time
	return handler

/// Ведущий питомца, а без него тот, кто вёл его последним и ещё рядом.
/datum/round_event/lost_pet/proc/find_bringer(mob/living/simple_animal/pet)
	var/mob/living/carbon/human/bringer = note_handler(pet)
	if(bringer)
		return bringer
	bringer = last_handler?.resolve()
	if(bringer && bringer.stat != DEAD && world.time - last_handled_at <= LOST_PET_HANDLER_GRACE && get_dist(bringer, pet) <= LOST_PET_BRINGER_RANGE)
		return bringer
	return null

/datum/round_event/lost_pet/proc/release_pet(mob/living/simple_animal/pet)
	if(!pet)
		return
	UnregisterSignal(pet, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_PARENT_ATTACKBY))
	qdel(pet.GetComponent(/datum/component/lost_pet_follow))

/datum/round_event/lost_pet/proc/return_home(mob/living/simple_animal/pet)
	if(resolved)
		return FALSE
	resolved = TRUE
	var/mob/living/carbon/human/bringer = find_bringer(pet)
	release_pet(pet)
	var/paid = FALSE
	var/bringer_name
	if(bringer)
		bringer_name = minor_crew_public_name(bringer)
		paid = minor_crew_pay_person(bringer, LOST_PET_REWARD, "вознаграждение за питомца [pet_name]")
		to_chat(bringer, span_notice("[pet_name] снова дома. [paid ? "Вознаграждение - [LOST_PET_REWARD] кредитов - переведено на счёт вашей ID-карты." : "Вознаграждение перевести некуда: при вас нет ID-карты со счётом."]"))
	var/cheered = cheer_heads()
	minor_announce("[pet_name] снова в [home_name]. [bringer_name ? "Вознаграждение получает [bringer_name]." : "Дорогу домой питомец нашёл сам."] Спасибо за бдительность.", "Служба учёта станционной фауны NanoTrasen")
	log_game("DIRECTOR: [control?.name], [pet_name] вернулся в [home_name][bringer ? ", привёл [key_name(bringer)] (объявлен как [bringer_name])[paid ? ", выдано [LOST_PET_REWARD] кр." : ", счёта нет"]" : ", сам"]; глав обрадовано: [cheered].")
	kill()
	return TRUE

/datum/round_event/lost_pet/proc/cheer_heads()
	if(!head_title)
		return 0
	var/cheered = 0
	for(var/mob/living/carbon/human/head as anything in GLOB.human_list)
		if(head.stat == DEAD || head.mind?.assigned_role != head_title)
			continue
		SEND_SIGNAL(head, COMSIG_ADD_MOOD_EVENT, "lost_pet_returned", /datum/mood_event/lost_pet_returned, pet_name)
		cheered++
	return cheered

/datum/round_event/lost_pet/end()
	if(resolved || !pet_ref)
		return
	resolved = TRUE
	release_pet(pet_ref?.resolve())
	log_game("DIRECTOR: [control?.name], время вышло, [pet_name] домой не вернулся.")

/// Питомец идёт за тем, кто его погладил или угостил; попугай садится ему на плечо.
/datum/component/lost_pet_follow
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS
	var/datum/weakref/leader_ref
	var/old_wander
	var/end_timer

/datum/component/lost_pet_follow/Initialize(mob/living/leader, duration)
	if(!isanimal(parent) || !istype(leader))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/simple_animal/pet = parent
	old_wander = pet.wander
	RegisterSignal(pet, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_player_control))
	follow(leader, duration)

/datum/component/lost_pet_follow/InheritComponent(datum/component/new_comp, i_am_original, mob/living/leader, duration)
	if(istype(leader))
		follow(leader, duration)

/datum/component/lost_pet_follow/Destroy()
	deltimer(end_timer)
	var/mob/living/leader = leader_ref?.resolve()
	if(leader)
		UnregisterSignal(leader, COMSIG_PARENT_QDELETING)
	var/mob/living/simple_animal/pet = parent
	if(pet)
		UnregisterSignal(pet, COMSIG_MOB_CLIENT_LOGIN)
	if(istype(pet, /mob/living/simple_animal/parrot))
		unperch(pet)
	else if(pet)
		SSmove_manager.stop_looping(pet)
		pet.wander = old_wander
	return ..()

/datum/component/lost_pet_follow/proc/follow(mob/living/leader, duration)
	var/mob/living/simple_animal/pet = parent
	var/mob/living/previous = leader_ref?.resolve()
	if(previous && previous != leader)
		UnregisterSignal(previous, COMSIG_PARENT_QDELETING)
		if(istype(pet, /mob/living/simple_animal/parrot))
			unperch(pet)
	leader_ref = WEAKREF(leader)
	RegisterSignal(leader, COMSIG_PARENT_QDELETING, PROC_REF(on_leader_deleted), override = TRUE)
	deltimer(end_timer)
	end_timer = addtimer(CALLBACK(src, PROC_REF(stop_following)), duration, TIMER_STOPPABLE)
	if(istype(pet, /mob/living/simple_animal/parrot))
		var/mob/living/simple_animal/parrot/parrot = pet
		if(ishuman(leader) && parrot.buckled != leader)
			parrot.perch_on_human(leader)
		return
	pet.wander = FALSE
	SSmove_manager.move_to(pet, leader, 1, LOST_PET_FOLLOW_STEP_DELAY, duration)

/datum/component/lost_pet_follow/proc/unperch(mob/living/simple_animal/parrot/parrot)
	if(!parrot.buckled)
		return
	parrot.buckled.unbuckle_mob(parrot, TRUE)
	parrot.parrot_state = PARROT_WANDER
	parrot.icon_state = parrot.icon_living
	parrot.pixel_x = parrot.base_pixel_x
	parrot.pixel_y = parrot.base_pixel_y

/datum/component/lost_pet_follow/proc/on_leader_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/lost_pet_follow/proc/on_player_control(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/component/lost_pet_follow/proc/stop_following()
	end_timer = null
	qdel(src)

/datum/mood_event/lost_pet_returned
	description = "<span class='nicegreen'>Питомец отдела снова дома.</span>\n"
	mood_change = 4
	timeout = 10 MINUTES

/datum/mood_event/lost_pet_returned/add_effects(pet_name)
	description = "<span class='nicegreen'>[pet_name] снова дома. Экипаж молодец.</span>\n"

/obj/item/clothing/neck/petcollar/lost_pet
	name = "department pet collar"
	desc = "Ошейник с жетоном отдела."
	treat_path = null

/obj/item/clothing/neck/petcollar/lost_pet/proc/mark_owner(department, home_name, pet_name)
	tagname = pet_name
	desc = "Ошейник с жетоном и датчиком: «[pet_name]. Собственность: [department]. Нашедшего просят вернуть в [home_name]»."

/obj/item/paper/lost_pet_flyer
	name = "lost pet flyer"
	desc = "Листовка «Пропал питомец» с фотографией питомца и отрывными полосками с номером внизу."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/lost_pet.dmi'
	icon_state = "flyer"
	color = null
	show_written_words = FALSE
	var/mutable_appearance/pet_photo

/obj/item/paper/lost_pet_flyer/proc/describe(mob/living/simple_animal/pet, home_name, reward)
	var/photo_state = pet.icon_living || pet.icon_state
	if(istype(pet, /mob/living/simple_animal/parrot))
		var/mob/living/simple_animal/parrot/parrot = pet
		photo_state = parrot.icon_sit
	pet_photo = mutable_appearance(icon(pet.icon, photo_state, EAST, 1))
	pet_photo.transform = matrix(LOST_PET_PHOTO_SCALE, 0, 0, 0, LOST_PET_PHOTO_SCALE, 0)
	pet_photo.pixel_y = 3
	pet_photo.appearance_flags |= PIXEL_SCALE
	add_raw_text("<center><font size=5><b>ПРОПАЛ ПИТОМЕЦ</b></font></center><hr>\
		<b>Кличка:</b> [pet.name]<br><b>Дом:</b> [home_name]<br>\
		<b>Приметы:</b> на фотографии<br>\
		Где видели последний раз: техтоннели. Датчик ошейника раз в [LOST_PET_PING_MIN / (1 MINUTES)]-[LOST_PET_PING_MAX / (1 MINUTES)] минут сообщает по общему каналу, в каком отсеке питомец.<br>\
		Отзывается на ласку и еду: если погладить или угостить, [LOST_PET_FOLLOW_TIME / (1 SECONDS)] секунд ходит следом.<hr>\
		Нашедшего просят привести питомца домой живым. <b>Вознаграждение - [reward] кредитов.</b><br>\
		<i>Отрывные полоски с номером уже кто-то оторвал.</i>")
	update_appearance()

/obj/item/paper/lost_pet_flyer/update_overlays()
	. = ..()
	if(pet_photo)
		. += pet_photo

#undef LOST_PET_REWARD
#undef LOST_PET_MIN_DISTANCE
#undef LOST_PET_FLYERS
#undef LOST_PET_DURATION
#undef LOST_PET_EVENT_STEP
#undef LOST_PET_HANDLER_GRACE
#undef LOST_PET_BRINGER_RANGE
#undef LOST_PET_PHOTO_SCALE
#undef LOST_PET_PING_MIN
#undef LOST_PET_PING_MAX
#undef LOST_PET_FOLLOW_TIME
#undef LOST_PET_FOLLOW_STEP_DELAY
