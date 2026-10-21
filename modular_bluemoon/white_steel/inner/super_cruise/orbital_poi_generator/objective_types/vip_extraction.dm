/datum/orbital_objective/vip_recovery
	name = "VIP эвакуация"
	var/generated = FALSE
	var/mob/mob_to_recover
	//Relatively easy mission.
	min_payout = 65 * CARGO_CRATE_VALUE
	max_payout = 125 * CARGO_CRATE_VALUE
	var/vip_timeout = 0
	var/vip_timer_id

/datum/orbital_objective/vip_recovery/get_text()
	return "Кто-то, представляющий особый интерес, находится по адресу [station_name]. Мы требуем его немедленно спасти. \
		Мы предполагаем, что эта VIP-персона всё ещё жива. Также, возможно вам понадобится помощь местного отряда службы безопасности, так как \
		вероятно вы встретите неприятеля. Доставьте этого человека на транспортный фёрри у дока «port bay 2»: как только он окажется \
		на борту, фёрри сам отправится на Центральное Командование и задание будет выполнено."

/datum/orbital_objective/vip_recovery/get_target()
	return mob_to_recover


/datum/orbital_objective/vip_recovery/on_assign(obj/machinery/computer/objective/objective_computer)
	. = ..()
	var/obj/docking_port/mobile/ferry = SSshuttle.getShuttle("ferry")
	if(ferry && ferry.mode == SHUTTLE_IDLE && ferry.getDockedId() != "ferry_home")
		SSshuttle.moveShuttle("ferry", "ferry_home", 1)

/datum/orbital_objective/vip_recovery/Destroy()
	if(vip_timer_id)
		deltimer(vip_timer_id)
		vip_timer_id = null
	if(!QDELETED(mob_to_recover))
		var/target_name = mob_to_recover.real_name
		if(istext(target_name))
			LAZYREMOVE(GLOB.mob_spawners[target_name], mob_to_recover)
			if(!LAZYLEN(GLOB.mob_spawners[target_name]))
				GLOB.mob_spawners -= target_name
	mob_to_recover = null
	return ..()


/datum/orbital_objective/vip_recovery/check_failed()
	if(generated)
		if(QDELETED(mob_to_recover))
			return TRUE
		if(mob_to_recover in SSzclear.nullspaced_mobs)
			return TRUE
		send_ferry_if_loaded()
		if(is_centcom_level(mob_to_recover.z) && mob_to_recover.stat == CONSCIOUS)
			finish_vip_recovery()
	return FALSE

/datum/orbital_objective/vip_recovery/proc/vip_expired()
	if(completed)
		return
	if(QDELETED(src))
		return
	if(generated && !QDELETED(mob_to_recover) && is_centcom_level(mob_to_recover.z) && mob_to_recover.stat == CONSCIOUS)
		return
	if(generated && !QDELETED(mob_to_recover))
		var/mob/living/vip = mob_to_recover
		to_chat(vip, span_userdanger("Время вышло. Вас больше не будут эвакуировать."))
		if(vip.client)
			vip.ghostize()
		qdel(vip)
		mob_to_recover = null
	remove_objective()

/datum/orbital_objective/vip_recovery/proc/finish_vip_recovery()
	if(vip_timer_id)
		deltimer(vip_timer_id)
		vip_timer_id = null
	var/mob/living/vip = mob_to_recover
	if(!QDELETED(vip) && isliving(vip))
		award_vip_metadollars(vip)
		complete_vip_mind_objective(vip)
		despawn_vip(vip)
	complete_objective()


/datum/orbital_objective/vip_recovery/proc/despawn_vip(mob/living/vip)
	if(vip.client)
		vip.ghostize()
	qdel(vip)

/datum/orbital_objective/vip_recovery/proc/award_vip_metadollars(mob/living/vip)
	var/client/C = vip.client
	var/vip_ckey = C?.ckey || vip.ckey
	if(!vip_ckey)
		return
	if(C?.prefs)
		SSmetadollars.add_amount(C, 1, "ruin_vip")
	else
		SSmetadollars.metadollar_adjust(1, vip_ckey, null)
	to_chat(vip, span_purple("Вы добрались до Центрального Командования. Награда: 1 метадоллар."))

/datum/orbital_objective/vip_recovery/proc/complete_vip_mind_objective(mob/living/vip)
	if(!vip.mind)
		return
	var/datum/antagonist/vip_recovery/antag = vip.mind.has_antag_datum(/datum/antagonist/vip_recovery)
	if(!antag)
		return
	for(var/datum/objective/vip_return/return_objective in antag.objectives)
		return_objective.completed = TRUE

//WHITE-STEEL PORT: если VIP на борту фёрри, запускаем фёрри на ЦК-док ferry_away.
/datum/orbital_objective/vip_recovery/proc/send_ferry_if_loaded()
	var/obj/docking_port/mobile/ferry = SSshuttle.getShuttle("ferry")
	if(!ferry || ferry.mode != SHUTTLE_IDLE)
		return
	if(ferry.getDockedId() == "ferry_away")
		return
	if(!ferry.is_in_shuttle_bounds(mob_to_recover))
		return
	SSshuttle.moveShuttle("ferry", "ferry_away", 1)

/datum/orbital_objective/vip_recovery/generate_objective_stuff(turf/chosen_turf)
	var/mob/living/carbon/human/created_human = new(chosen_turf)
	//Maybe polling ghosts would be better than the shintience code
	LAZYADD(GLOB.mob_spawners[created_human.real_name], created_human)
	notify_ghosts("VIP-персона может быть занята.", source = created_human, action = NOTIFY_ORBIT, flashwindow = FALSE, ignore_key = POLL_IGNORE_SPLITPERSONALITY, ignore_dnr_observers = FALSE)
	created_human.AddElement(/datum/element/point_of_interest)
	created_human.mind_initialize()
	//Remove nearby dangers
	for(var/mob/living/simple_animal/hostile/SA in range(10, created_human))
		qdel(SA)
	//Give them a space worthy suit
	var/turf/open/T = locate() in shuffle(view(1, created_human))
	if(T)
		new /obj/item/clothing/suit/space/hardsuit/ancient(T)
		new /obj/item/tank/internals/oxygen(T)
		new /obj/item/clothing/mask/gas(T)
		new /obj/item/storage/belt/utility/full(T)
	//WHITE-STEEL PORT: VIP экипируется одним из боевых лодаутов — 4 ERT-MOPP или 3 HSC (урезанные VIP-копии).
	var/static/list/vip_outfits = list(
		/datum/outfit/ert/commander/mopp,
		/datum/outfit/ert/security/mopp,
		/datum/outfit/ert/medic/mopp,
		/datum/outfit/ert/engineer/mopp,
		/datum/outfit/hsc/vip,
		/datum/outfit/hsc/vip/medic,
		/datum/outfit/hsc/vip/assistant,
	)
	created_human.equipOutfit(pick(vip_outfits))
	strip_vip_weapons(created_human)
	grant_vip_space_adaptation(created_human)
	lock_vip_equipment(created_human)
	created_human.mind.add_antag_datum(/datum/antagonist/vip_recovery)
	mob_to_recover = created_human
	generated = TRUE
	vip_timeout = world.time + 15 MINUTES
	if(vip_timer_id)
		deltimer(vip_timer_id)
	vip_timer_id = addtimer(CALLBACK(src, PROC_REF(vip_expired)), 15 MINUTES, TIMER_STOPPABLE)
	start_ghost_role_poll(created_human, "VIP эвакуация: занять роль VIP-персоны?", POLL_IGNORE_SPLITPERSONALITY, "VIP-персоны", "Вы — VIP-персона! Задача: выжить на руине и вернуться на ЦК живым. У вас есть 15 минут на эвакуацию! За успешную миссию вам выплатят 1 метадоллар!")

/datum/orbital_objective/vip_recovery/proc/lock_vip_equipment(mob/living/carbon/human/H)
	if(!ishuman(H))
		return
	var/obj/item/worn_mask = H.get_item_by_slot(ITEM_SLOT_MASK)
	var/obj/item/worn_belt = H.get_item_by_slot(ITEM_SLOT_BELT)
	for(var/obj/item/equipped as anything in H.get_equipped_items())
		if(!istype(equipped) || equipped == worn_mask || equipped == worn_belt)
			continue
		ADD_TRAIT(equipped, TRAIT_NODROP, "vip_equipment_lock")

/datum/orbital_objective/vip_recovery/proc/strip_vip_weapons(mob/living/carbon/human/H)
	if(!ishuman(H))
		return
	for(var/obj/item/I in H.GetAllContents())
		if(istype(I, /obj/item/gun) || istype(I, /obj/item/ammo_box) || istype(I, /obj/item/ammo_casing) || istype(I, /obj/item/storage/box/ammo))
			qdel(I)

/datum/orbital_objective/vip_recovery/proc/grant_vip_space_adaptation(mob/living/carbon/human/H)
	if(!ishuman(H))
		return
	ADD_TRAIT(H, TRAIT_RESISTCOLD, "vip_space_adaptation")
	ADD_TRAIT(H, TRAIT_RESISTLOWPRESSURE, "vip_space_adaptation")
	ADD_TRAIT(H, TRAIT_LOWPRESSURECOOLING, "vip_space_adaptation")

//=====================
// Centcom Official
//=====================

/datum/outfit/centcom_official_vip
	name = "VIP Centcom"

	uniform = /obj/item/clothing/under/rank/centcom/officer
	shoes = /obj/item/clothing/shoes/sneakers/black
	gloves = /obj/item/clothing/gloves/color/black
	ears = /obj/item/radio/headset/headset_cent/empty
	glasses = /obj/item/clothing/glasses/sunglasses
	belt = /obj/item/gun/energy/e_gun
	l_pocket = /obj/item/pen
	back = /obj/item/storage/backpack/satchel
	r_pocket = /obj/item/modular_computer/pda/heads
	l_hand = /obj/item/clipboard
	r_hand = /obj/item/gps
	id = /obj/item/card/id/away/old

//=====================
// Matryr Dictator
//=====================

/datum/antagonist/vip_dictator
	name = "Insane VIP"
	show_in_antagpanel = TRUE
	roundend_category = "Ruin VIPs"
	antagpanel_category = "Other"
	greentext_reward = 25

/datum/outfit/vip_dictator
	name = "VIP Dictator"

	uniform = /obj/item/clothing/under/rank/security/head_of_security
	suit = /obj/item/clothing/suit/armor/hos
	suit_store = /obj/item/gun/ballistic/automatic/pistol/m1911
	shoes = /obj/item/clothing/shoes/jackboots
	gloves = /obj/item/clothing/gloves/combat
	ears = /obj/item/radio/headset
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	belt = /obj/item/storage/belt/sabre
	l_pocket = /obj/item/ammo_box/magazine/m45
	r_pocket = /obj/item/grenade/smokebomb
	id = /obj/item/card/id/away/old
	neck = /obj/item/clothing/neck/necklace/dope
	head = /obj/item/clothing/head/HoS/beret/syndicate
	r_hand = /obj/item/gps

//=====================
// Greytide
//=====================

/datum/outfit/greytide
	name = "VIP Greytide"

	uniform = /obj/item/clothing/under/color/grey
	suit = /obj/item/clothing/suit/armor/vest
	shoes = /obj/item/clothing/shoes/laceup
	ears = /obj/item/radio/headset
	glasses = /obj/item/clothing/glasses/sunglasses
	belt = /obj/item/storage/belt/bandolier/greytide
	l_pocket = /obj/item/clothing/gloves/color/yellow
	r_pocket = /obj/item/gps
	id = /obj/item/card/id
	head = /obj/item/clothing/head/helmet
	mask = /obj/item/clothing/mask/gas/german
	l_hand = /obj/item/gun/ballistic/shotgun/doublebarrel
	r_hand = /obj/item/storage/toolbox/mechanical/old


/obj/item/storage/belt/bandolier/greytide/PopulateContents()
	var/static/items_inside = list(
		/obj/item/ammo_casing/shotgun/improvised = 12)
	generate_items_inside(items_inside,src)

//=====================
// VIP: цель и роль
//=====================
/datum/objective/vip_return
	name = "Возвращение на ЦК"
	explanation_text = "Выжить и вернуться на Центральное Командование."
	completable = TRUE

/datum/objective/vip_return/check_completion()
	if(completed)
		return TRUE
	var/mob/living/L = owner?.current
	if(!L || L.stat == DEAD)
		return FALSE
	return is_centcom_level(L.z)

/datum/antagonist/vip_recovery
	name = "Very Important Person"
	show_in_antagpanel = FALSE
	antagpanel_category = "Other"
	roundend_category = "Ruin VIPs"
	greentext_reward = 25
	antag_memory = "Вы — VIP-персона с объекта. Держитесь живыми: авангард должен доставить вас на \
		транспортный фёрри у дока «port bay 2», после чего он сам стартует на Центральное Командование."

/datum/antagonist/vip_recovery/on_gain()
	var/datum/objective/vip_return/return_objective = new
	return_objective.owner = owner
	objectives += return_objective
	. = ..()

/datum/antagonist/vip_recovery/greet()
	to_chat(owner, span_boldnotice("[antag_memory]"))
	owner.announce_objectives()

//=====================
// VIP: урезанные копии HSC-лодаутов
//=====================
/datum/outfit/hsc/vip
	name = "VIP HSC Security"
	belt = /obj/item/gun/ballistic/automatic/pistol/suppressed
	l_pocket = null
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom = 1,
		/obj/item/storage/box/handcuffs = 1,
		/obj/item/storage/firstaid/regular = 1,
		/obj/item/gun/energy/modular_laser_rifle/carbine = 1,
		/obj/item/storage/box/ammo/m10mm = 1,
	)

/datum/outfit/hsc/vip/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	return

/datum/outfit/hsc/vip/medic
	name = "VIP HSC Medic"
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/hsc/medical
	id = /obj/item/card/id/ert/hsc/medic
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom = 1,
		/obj/item/storage/firstaid/tactical/ert_first = 1,
		/obj/item/storage/firstaid/tactical/ert_second = 1,
		/obj/item/reagent_containers/hypospray/combat = 1,
		/obj/item/roller = 1,
		/obj/item/gun/energy/modular_laser_rifle/carbine = 1,
		/obj/item/storage/box/ammo/m10mm = 1,
	)

/datum/outfit/hsc/vip/assistant
	name = "VIP HSC Assistant"
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	suit = /obj/item/clothing/suit/space/hardsuit/ert/alert/hsc/assistant
	id = /obj/item/card/id/ert/hsc/assistant
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom = 1,
		/obj/item/storage/firstaid/tactical/ert_first = 1,
		/obj/item/storage/firstaid/tactical/ert_second = 1,
		/obj/item/roller = 1,
		/obj/item/bodybag/bluespace = 1,
		/obj/item/gun/energy/modular_laser_rifle/carbine = 1,
		/obj/item/storage/box/ammo/m10mm = 1,
	)
