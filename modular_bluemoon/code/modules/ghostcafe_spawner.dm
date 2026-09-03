// Ghost Cafe Human Spawner

/obj/item/ghostcafe_spawner
	name = "Ghost Cafe Spawner"
	desc = "Палка для спавна кукл для битья в ГК. При клике на турф предлагается выбор лоадаута. Спавнит только одного человека за раз."
	icon = 'icons/obj/guns/magic.dmi'
	icon_state = "nothingwand"
	item_state = "wand"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL

	var/cooldown = 10 SECONDS
	var/next_spawn_time = 0
	var/mob/living/carbon/human/current_spawned = null

	var/list/available_outfits = list(
		"Чёрная Меза: Учёный" = /datum/outfit/science_team_ghostcafe,
		"Чёрная Меза: Охранник" = /datum/outfit/security_guard_ghostcafe,
		"Ядерный Оперативник" = /datum/outfit/syndicate/training,
		"Ядерный Оперативник: Полный набор" = /datum/outfit/syndicate/full/training,
		"Ядерный Оперативник: Лидер" = /datum/outfit/syndicate/leader/training,
		"Ядерный Оперативник: Lone" = /datum/outfit/syndicate/lone/training,
		"ERT: Командир" = /datum/outfit/ert/commander/training,
		"ERT: офицер" = /datum/outfit/ert/security/training,
		"Комбатант" = /datum/outfit/inteq_agent/training,
	)

/obj/item/ghostcafe_spawner/afterattack(atom/target, mob/user, proximity)
	var/area/current_area = get_area(user)
	if(!istype(current_area, /area/centcom/holding/shootingrange))
		to_chat(user, span_warning("Этот предмет можно использовать только в тире!"))
		return

	if(!isturf(target))
		return

	var/area/target_area = get_area(target)
	if(!istype(target_area, /area/centcom/holding/shootingrange))
		to_chat(user, span_warning("Спавн возможен только в пределах тира!"))
		return

	if(world.time < next_spawn_time)
		var/time_left = (next_spawn_time - world.time) / 10
		to_chat(user, span_warning("Подождите ещё [time_left] секунд перед следующим спавном!"))
		return

	var/choice = tgui_input_list(user, "Выберите лоадаут для спавна", "Ghost Cafe Spawner", available_outfits)
	if(!choice)
		return

	var/datum/outfit/selected_outfit = available_outfits[choice]
	var/datum/outfit/outfit_instance = new selected_outfit

	if(current_spawned && !QDELETED(current_spawned))
		current_spawned.dust()
		current_spawned = null

	var/mob/living/carbon/human/H = new /mob/living/carbon/human(target)
	H.set_species(/datum/species/human) // Жёстко задаём человека

	H.equipOutfit(outfit_instance)

	// Remove any radios or PDAs
	for(var/obj/item/radio/R in H.get_all_slots())
		qdel(R)
	for(var/obj/item/modular_computer/pda/P in H.get_all_slots())
		qdel(P)

	// Replace ID cards with useless ones
	for(var/obj/item/card/id/ID in H.get_all_slots())
		if(istype(ID, /obj/item/card/id/syndicate))
			qdel(ID)
			H.equip_to_slot_or_del(new /obj/item/card/id/no_banking, ITEM_SLOT_ID)
		else if(istype(ID, /obj/item/card/id/away))
			qdel(ID)
			H.equip_to_slot_or_del(new /obj/item/card/id/no_banking, ITEM_SLOT_ID)

	protect_clothing(H)

	current_spawned = H
	next_spawn_time = world.time + cooldown

	to_chat(user, span_notice("Заспавнен человек с лоадаутом: [outfit_instance.name]"))
	playsound(src, 'sound/magic/staff_change.ogg', 50, TRUE)

	qdel(outfit_instance)

/obj/item/ghostcafe_spawner/proc/protect_clothing(mob/living/carbon/human/H)
	// Protect all items from being dropped
	for(var/slot in H.get_all_slots())
		if(istype(slot, /obj/item))
			var/obj/item/I = slot
			I.item_flags |= ABSTRACT
			I.resistance_flags |= INDESTRUCTIBLE
			if(istype(I, /obj/item/clothing))
				var/obj/item/clothing/C = I
				C.flags_inv |= HIDEJUMPSUIT

	// Protect backpack from being opened
	var/obj/item/storage/backpack/B = H.back
	if(B)
		B.item_flags |= ABSTRACT

	H.flags_1 |= PREVENT_CONTENTS_EXPLOSION_1

// Лоадауты

/datum/outfit/syndicate/blackmesa
	name = "Syndicate Operator - Ghost Cafe"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/space/syndicate
	head = /obj/item/clothing/head/helmet/space/syndicate
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	mask = /obj/item/clothing/mask/gas/syndicate
	back = /obj/item/storage/backpack
	belt = /obj/item/storage/belt/military
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol,
		/obj/item/ammo_box/magazine/m10mm,
		/obj/item/kitchen/knife/combat,
		/obj/item/grenade/smokebomb,
	)
	id = /obj/item/card/id/syndicate
	ears = null

/datum/outfit/inteq_agent
	name = "Inteq Agent - Ghost Cafe"
	uniform = /obj/item/clothing/under/rank/security/officer
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/helmet/sec
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	mask = /obj/item/clothing/mask/gas
	back = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/military
	backpack_contents = list(
		/obj/item/gun/ballistic/automatic/pistol,
		/obj/item/ammo_box/magazine/m10mm,
		/obj/item/kitchen/knife/combat,
		/obj/item/grenade/flashbang,
	)
	id = /obj/item/card/id/syndicate
	ears = null

// Training outfit variants - no post_equip antagonist logic

/datum/outfit/syndicate/training
	name = "Syndicate Operative - Training"
	ears = null
	post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
		return // Skip antagonist post_equip

/datum/outfit/syndicate/full/training
	name = "Syndicate Operative - Full Kit Training"
	ears = null
	r_hand = null // Remove bulldog for training
	post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
		return // Skip antagonist post_equip

/datum/outfit/syndicate/leader/training
	name = "Syndicate Leader - Training"
	ears = null
	post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
		return // Skip antagonist post_equip

/datum/outfit/syndicate/lone/training
	name = "Syndicate Lone - Training"
	ears = null
	post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
		return // Skip antagonist post_equip

/datum/outfit/ert/commander/training
	name = "ERT Commander - Training"
	ears = null
	post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
		return // Skip antagonist post_equip

/datum/outfit/ert/security/training
	name = "ERT Security - Training"
	ears = null
	post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
		return // Skip antagonist post_equip

/datum/outfit/inteq_agent/training
	name = "Inteq Agent - Training"
	ears = null
	post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
		return // Skip antagonist post_equip

// Ghost Cafe specific outfits (based on Black Mesa but without radios)

/datum/outfit/science_team_ghostcafe
	name = "Black Mesa Scientist - Ghost Cafe"
	uniform = /obj/item/clothing/under/rank/rnd/scientist/halflife
	suit = /obj/item/clothing/suit/toggle/labcoat
	shoes = /obj/item/clothing/shoes/laceup
	back = /obj/item/storage/backpack/satchel/leather
	backpack_contents = list(/obj/item/reagent_containers/glass/beaker, /obj/item/storage/wallet)
	ears = null
	id = /obj/item/card/id/no_banking

/datum/outfit/security_guard_ghostcafe
	name = "Black Mesa Guard - Ghost Cafe"
	uniform = /obj/item/clothing/under/rank/security/officer/blueshirt
	head = /obj/item/clothing/head/helmet/blueshirt
	gloves = /obj/item/clothing/gloves/color/black
	suit = /obj/item/clothing/suit/armor/vest/blueshirt
	shoes = /obj/item/clothing/shoes/jackboots
	back = /obj/item/storage/backpack/satchel/blueshield/mesasec
	belt = /obj/item/storage/belt/security/blackmesa
	backpack_contents = list(/obj/item/gun/ballistic/automatic/pistol/hl9mm, /obj/item/ammo_box/magazine/pistolm9mm, /obj/item/reagent_containers/food/snacks/donut/apple,)
	ears = null
	id = /obj/item/card/id/no_banking

// Ghost Cafe specific items

/obj/item/gun/magic/wand/resurrection/debug/ghostcafe
	name = "Ghost Cafe Resurrection Wand"
	desc = "Магическая палочка для воскрешения мёртвых в тире. Работает только в тире с кулдауном 10 секунд."
	max_charges = 50
	var/cooldown_time = 10 SECONDS
	var/next_use_time = 0

/obj/item/gun/magic/wand/resurrection/debug/ghostcafe/afterattack(atom/target, mob/user, proximity)
	if(!proximity)
		return

	var/area/current_area = get_area(user)
	if(!istype(current_area, /area/centcom/holding/shootingrange))
		to_chat(user, span_warning("Эта палочка работает только в тире!"))
		return

	if(world.time < next_use_time)
		var/time_left = (next_use_time - world.time) / 10
		to_chat(user, span_warning("Кулдаун! Осталось [round(time_left)] секунд."))
		return

	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.stat == DEAD)
			..()
			next_use_time = world.time + cooldown_time
			to_chat(user, span_notice("Вы воскресили [H.name]!"))
		else
			to_chat(user, span_warning("[H.name] ещё жив!"))
	else
		to_chat(user, span_warning("Можно воскрешать только людей!"))
