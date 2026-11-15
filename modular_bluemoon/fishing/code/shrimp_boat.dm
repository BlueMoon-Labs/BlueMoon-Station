// Секретное креветочное судно.
/area/fishboat
	name = "Wellcheers Shrimp Boat"
	icon_state = "away"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	sound_environment = SOUND_ENVIRONMENT_CITY
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED

/turf/open/water/fishboat
	name = "deep saltwater"
	desc = "Холодная чёрная вода. Где-то в глубине что-то большое шевелится."
	icon_state = "riverwater_motion"
	color = "#17435c"
	slowdown = 2
	baseturfs = /turf/open/water/fishboat
	blocks_air = TRUE

/turf/open/water/fishboat/Initialize(mapload)
	. = ..()
	var/datum/component/fishing_spot/spot = GetComponent(/datum/component/fishing_spot)
	if(spot)
		spot.fish_source = GLOB.preset_fish_sources[/datum/fish_source/shrimp_boat]

/turf/open/water/fishboat/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(!isliving(arrived))
		return
	var/mob/living/swimmer = arrived
	if((swimmer.movement_type & FLYING) || swimmer.incorporeal_move)
		return
	swimmer.visible_message(
		span_userdanger("[swimmer] уходит под воду!"),
		span_userdanger("Ледяная вода смыкается над головой. Что-то тянет вас обратно на палубу!"),
	)
	INVOKE_ASYNC(src, PROC_REF(pull_back), swimmer)

/turf/open/water/fishboat/proc/pull_back(mob/living/swimmer)
	if(QDELETED(swimmer) || !istype(get_turf(swimmer), /turf/open/water/fishboat))
		return
	var/turf/target = get_shrimp_boat_spawn()
	if(!target)
		swimmer.adjustBruteLoss(30)
		return
	swimmer.forceMove(target)
	swimmer.Stun(3 SECONDS)
	swimmer.Knockdown(3 SECONDS)
	swimmer.adjustBruteLoss(5)
	to_chat(swimmer, span_warning("Вас вышвыривает обратно на палубу."))

/// Рыбалка у борта. Возврат домой выпадает редко.
/datum/fish_source/shrimp_boat
	catalog_description = "Тёмная вода у борта «Wellcheers»"
	fishing_difficulty = FISHING_EASY_DIFFICULTY
	background = "background_dank"
	duds = list("пусто", "только тина", "крючок зацепился за борт")
	fish_table = list(
		FISHING_DUD = 25,
		/obj/item/fish/ratfish = 2,
		/obj/item/fish/sludgefish = 1,
		/obj/item/fish/goldfish = 1,
		/obj/item/trash/plate = 1,
		/obj/item/soap = 1,
		/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers = 2,
		/obj/item/fish/lcm/bass = 1,
		/obj/item/fish/lcm/trout = 1,
		/obj/item/fish/lcm/eel = 1,
		/obj/item/fish/lcm/northernpike = 1,
		/obj/item/fish/lcm/salmon = 1,
		/obj/item/fish/lcm/yang = 1,
		/obj/item/fish/lcm/yin = 1,
		/obj/item/fish/lcm/mosb = 1,
		/obj/item/fish/lcm/ufo = 1,
		/obj/item/fish/lcm/unidentified_fish_object = 1,
		/obj/item/fish/lcm/waterflea = 1,
		/obj/item/fish/lcm/sheephead = 1,
		/obj/item/fish/lcm/bluefintuna = 1,
		/obj/item/fish/lcm/smolshark = 1,
		/obj/item/fish/lcm/marine_shrimp = 1,
		/obj/item/fish/lcm/lobster = 1,
		/obj/item/fish/lcm/blue_tang = 1,
		/obj/item/fish/lcm/deep_fry = 1,
		/obj/item/fish/lcm/pigfish = 1,
		/obj/item/fish/lcm/piscine_mermaid = 1,
		/obj/item/fish/lcm/tuna_pallid = 1,
		/obj/item/fish/lcm/fishmael = 1,
		/obj/item/fish/lcm/seabunny = 1,
		/obj/item/fish/lcm/searabbit = 1,
		/obj/item/fish/lcm/siltcurrent = 1,
		/obj/item/fish/lcm/weever_blue_album = 1,
		/obj/item/fish/lcm/walkin_man = 1,
		/obj/item/fish/lcm/boxin_man = 1,
		/obj/item/shrimp_boat_return = 5,
	)

/// Билет
/obj/item/shrimp_boat_ticket
	name = "soggy Wellcheers can"
	desc = "Помятая банка «Wellcheers», пахнущая солью и креветками. Если открыть её в руке, можно оказаться очень далеко."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "cola"
	w_class = WEIGHT_CLASS_TINY

/obj/item/shrimp_boat_ticket/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return
	if(send_to_shrimp_boat(user))
		qdel(src)
	else
		to_chat(user, span_warning("Банка пуста. Похоже, этот сон уже не вернуть."))

/// Редкий улов у борта шхуны. Возвращает туда, откуда игрок попал на корабль.
/obj/item/shrimp_boat_return
	name = "salted note"
	desc = "Записка, запечённая в треснувшую бутылку. Почерк указывает обратный путь. Активируйте в руке, чтобы вернуться."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paper"
	w_class = WEIGHT_CLASS_TINY

/obj/item/shrimp_boat_return/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return
	if(return_from_shrimp_boat(user))
		qdel(src)
	else
		to_chat(user, span_warning("Записка рассыпается в руках, но путь домой так и не находится."))

/obj/effect/landmark/shrimp_boat_spawn
	name = "shrimp boat spawn"

/proc/get_shrimp_boat_spawn()
	var/obj/effect/landmark/shrimp_boat_spawn/landmark = locate(/obj/effect/landmark/shrimp_boat_spawn) in world
	return landmark ? get_turf(landmark) : null

/datum/component/shrimp_boat_abductee
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/turf/origin

/datum/component/shrimp_boat_abductee/Initialize(turf/origin_turf)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	origin = origin_turf
	START_PROCESSING(SSprocessing, src)

/datum/component/shrimp_boat_abductee/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	origin = null
	return ..()

/datum/component/shrimp_boat_abductee/process(seconds_per_tick)
	var/mob/living/captive = parent
	if(QDELETED(captive) || captive.stat == DEAD)
		return
	if(istype(get_area(captive), /area/fishboat))
		return
	var/turf/target = get_shrimp_boat_spawn()
	if(!target || QDELETED(captive))
		return
	captive.forceMove(target)
	to_chat(captive, span_warning("Шхуна не отпускает. Море возвращает вас на палубу."))

/proc/send_to_shrimp_boat(mob/living/user)
	if(!isliving(user) || QDELETED(user))
		return FALSE
	var/turf/target = get_shrimp_boat_spawn()
	if(!target)
		return FALSE
	var/turf/origin = get_turf(user)
	var/datum/component/shrimp_boat_abductee/abductee = user.AddComponent(/datum/component/shrimp_boat_abductee, origin)
	if(abductee)
		abductee.origin = origin
	user.visible_message(
		span_warning("[user] покачивается и засыпает..."),
		span_userdanger("Вас неудержимо клонит в сон... слышно, как кричат чайки."),
	)
	user.Sleeping(3 SECONDS)
	user.forceMove(target)
	to_chat(user, span_warning("Вы просыпаетесь на палубе шхуны «Wellcheers». Вокруг только море."))
	for(var/mob/living/carbon/human/species/shrimp/shrimp in view(7, target))
		shrimp.say("Добро пожаловать на борт «Wellcheers», свежий улов!")
	return TRUE

/proc/return_from_shrimp_boat(mob/living/user)
	if(!isliving(user) || QDELETED(user))
		return FALSE
	var/datum/component/shrimp_boat_abductee/abductee = user.GetComponent(/datum/component/shrimp_boat_abductee)
	var/turf/destination = abductee?.origin
	if(abductee)
		STOP_PROCESSING(SSprocessing, abductee)
		qdel(abductee)
	if(!destination || QDELETED(destination) || !isturf(destination))
		var/obj/effect/landmark/start_landmark = length(GLOB.start_landmarks_list) ? pick(GLOB.start_landmarks_list) : null
		destination = start_landmark ? get_turf(start_landmark) : null
	if(!destination)
		return FALSE
	user.forceMove(destination)
	user.visible_message(
		span_notice("[user] исчезает в облаке солёных брызг."),
		span_notice("Записка рассыпается в руках, и вы снова оказываетесь дома."),
	)
	return TRUE

// Пассажиры-креветки
/datum/species/shrimp
	name = "Shrimp"
	id = "shrimp"
	limbs_id = "shrimp"
	override_bp_icon = 'modular_bluemoon/fishing/icons/mob/shrimp_parts.dmi'
	say_mod = "burbles"
	sexes = 0
	nojumpsuit = TRUE
	species_traits = list(NO_UNDERWEAR)
	inherent_traits = list(TRAIT_ADVANCEDTOOLUSER, TRAIT_GENELESS)
	use_skintones = FALSE
	var/list/special_names = list("Cajun", "Leech", "Krill", "Prawn", "Oyster", "Gill", "Shrimp", "Shrimple", "Old Bay", "Lobster", "Crabby", "Finn", "Craw", "Crawdad", "Chowder", "Crusty", "Krillin", "Barney", "Saeu", "Mantis", "Pistol", "Carieda", "Crangon", "Pop", "Shelldon", "Shelly", "Krabs", "Jumbo", "Caspian", "Little Buoy", "Brook", "River", "Bubbles")
	var/human_name_chance = 5

/datum/species/shrimp/random_name(gender, unique, lastname)
	if(prob(human_name_chance) && length(GLOB.last_names))
		return pick(GLOB.last_names)
	return pick(special_names)

/mob/living/carbon/human/species/shrimp
	race = /datum/species/shrimp

/mob/living/carbon/human/species/shrimp/Initialize(mapload)
	. = ..()
	if(dna?.species)
		var/shrimp_name = dna.species.random_name()
		name = shrimp_name
		real_name = shrimp_name
		dna.real_name = shrimp_name

/mob/living/carbon/human/species/shrimp/examine(mob/user)
	. = ..()
	. += span_notice("Креветка-боцман шхуны. Следит за порядком на палубе и явно знает, где здесь клюёт.")

/mob/living/carbon/human/species/shrimp/update_overlays()
	. = ..()
	if(!istype(dna?.species, /datum/species/shrimp))
		return
	for(var/leg_state in list("shrimp_l_leg", "shrimp_r_leg"))
		var/mutable_appearance/leg = mutable_appearance('modular_bluemoon/fishing/icons/mob/shrimp_parts.dmi', leg_state, ABOVE_MOB_LAYER)
		leg.dir = dir
		. += leg

/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers
	name = "can of 'Wellcheers' soda"
	desc = "Банка газировки «Wellcheers». Пахнет морем и креветками."
	icon_state = "monkey_energy"
	list_reagents = list(/datum/reagent/consumable/space_cola = 10)

/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers/red
	name = "can of cherry 'Wellcheers' soda"
	icon_state = "cola"

/obj/item/reagent_containers/food/drinks/soda_cans/wellcheers/purple
	name = "can of grape 'Wellcheers' soda"
	icon_state = "purple_can"
