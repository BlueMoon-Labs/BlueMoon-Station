// Интеграция ROMEROL outbreak / ящика с патогеном (WhiteMoon-Station zombie_event.dm, адаптация под BlueMoon)

/datum/round_event_control/zombie_infestation
	name = "ROMEROL Pathogen Outbreak"
	typepath = /datum/round_event/zombie_infestation
	weight = 1
	earliest_start = 60 MINUTES
	max_occurrences = 1
	min_players = 50
	category = EVENT_CATEGORY_HEALTH
	description = "Случайные члены экипажа на станции получают скрытую ромерол-инфекцию."

/datum/round_event/zombie_infestation
	announce_when = 120
	announce_chance = 100
	fakeable = TRUE
	var/infected = 1

/datum/round_event/zombie_infestation/setup()
	. = ..()
	infected = rand(3, 6)

/datum/round_event/zombie_infestation/start()
	. = ..()
	var/infectees = 0
	for(var/mob/living/carbon/human/iterating_human in shuffle(GLOB.player_list))
		if(!iterating_human.client)
			continue
		if(!is_station_level(iterating_human.z))
			continue
		if(HAS_TRAIT(iterating_human, TRAIT_EXEMPT_HEALTH_EVENTS))
			continue
		if(infectees >= infected)
			break
		if(try_to_zombie_infect_event(iterating_human))
			infectees++
			notify_ghosts("[iterating_human] has been infected by the ROMEROL pathogen!", source = iterating_human)

/datum/round_event/zombie_infestation/announce(fake)
	priority_announce("Автоматизированные системы фильтрации воздуха выявили грибковый патоген 'РОМЕРОЛ' в вентиляционных системах станции, введён карантин.", "ВНИМАНИЕ: БИОЛОГИЧЕСКАЯ ОПАСНОСТЬ", 'sound/announcer/medibot/hazdet.ogg', has_important_message = TRUE)

/proc/try_to_zombie_infect_event(mob/living/carbon/human/target)
	CHECK_DNA_AND_SPECIES(target)

	if(!target.get_bodypart(BODY_ZONE_HEAD))
		return FALSE

	if(NOZOMBIE in target.dna.species.species_traits)
		return FALSE

	if(HAS_TRAIT(target, TRAIT_ROBOTIC_ORGANISM))
		return FALSE

	if(HAS_TRAIT(target, TRAIT_VIRUSIMMUNE))
		return FALSE

	if(target.reagents.has_reagent(/datum/reagent/medicine/spaceacillin) && prob(75))
		return FALSE

	var/obj/item/organ/zombie_infection/infection = target.getorganslot(ORGAN_SLOT_ZOMBIE)
	if(infection)
		return FALSE
	infection = new()
	infection.Insert(target)
	return TRUE

/datum/supply_pack/misc/zombie
	name = "NT-CZV-1 Vials"
	desc = "Contains NT-CZV vials. Highly classified."
	special = TRUE
	contains = list()
	crate_type = /obj/structure/closet/crate/zombie

/datum/round_event_control/stray_cargo/zombie
	name = "Stray Zombie Cargo Pod"
	typepath = /datum/round_event/stray_cargo/zombie
	weight = 1
	max_occurrences = 1
	earliest_start = 60 MINUTES
	min_players = 50
	category = EVENT_CATEGORY_BUREAUCRATIC
	description = "На станцию падает капсула с ящиком биологической опасности (ромерол)."

/datum/round_event/stray_cargo/zombie
	possible_pack_types = list(/datum/supply_pack/misc/zombie)

/datum/round_event/stray_cargo/zombie/make_pod()
	var/area/pod_storage_area = locate(/area/centcom/supplypod/podStorage) in GLOB.sortedAreas
	var/obj/structure/closet/supplypod/S = new(pick(get_area_turfs(pod_storage_area))) //Lets not runtime
	S.setStyle(STYLE_SYNDICATE)
	return S

/obj/structure/closet/crate/zombie
	name = "biohazard crate"
	desc = "Пломбированный контейнер высокой биологической опасности. На боку - предупреждающий знак и штрихкод PACT-BT-7."
	icon_state = "chemcrate"
	var/virus_released = FALSE

/obj/structure/closet/crate/zombie/after_open(mob/living/user, force)
	. = ..()
	if(virus_released)
		return
	virus_released = TRUE
	playsound(src, 'sound/effects/smoke.ogg', 50, TRUE, -3)
	var/datum/reagents/zombie_holder = new/datum/reagents(100)
	zombie_holder.my_atom = src
	zombie_holder.add_reagent(/datum/reagent/romerol/lethal, 30)
	var/datum/effect_system/smoke_spread/chem/smoke = new()
	smoke.set_up(zombie_holder, 6, get_turf(src), silent = TRUE)
	smoke.attach(src)
	smoke.start()
	qdel(zombie_holder)

/obj/structure/closet/crate/zombie/PopulateContents()
	new /obj/item/reagent_containers/glass/bottle/romerol_interdyne(src)
	new /obj/item/reagent_containers/glass/bottle/romerol_interdyne/empty(src)

/obj/item/reagent_containers/glass/bottle/romerol_interdyne
	name = "INT-RMRL Vial"
	desc = "Небольшая ампула патогена INT-RMRL. Производство Interdyne."
	list_reagents = list(/datum/reagent/romerol = 30)

/obj/item/reagent_containers/glass/bottle/romerol_interdyne/empty
	name = "INT-RMRL Vial"
	desc = "Пустая ампула INT-RMRL. На этикетке предупреждение о хрупкости, явно не попытка пиара."
	list_reagents = list()
