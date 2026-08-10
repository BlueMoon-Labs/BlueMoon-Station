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
		"Чёрная Меза: Учёный" = /datum/outfit/science_team,
		"Чёрная Меза: Охранник" = /datum/outfit/security_guard,
		"Ядерный Оперативник" = /datum/outfit/syndicate,
		"Ядерный Оперативник: Полный набор" = /datum/outfit/syndicate/full,
		"Ядерный Оперативник: Лидер" = /datum/outfit/syndicate/leader,
		"Ядерный Оперативник: Lone" = /datum/outfit/syndicate/lone,
		"ERT: Командир" = /datum/outfit/ert/commander,
		"ERT: офицер" = /datum/outfit/ert/security,
		"Комбатант" = /datum/outfit/inteq_agent,
	)

/obj/item/ghostcafe_spawner/afterattack(atom/target, mob/user, proximity)
	var/area/current_area = get_area(user)
	if(!istype(current_area, /area/centcom/holding/shootingrange))
		to_chat(user, span_warning("Этот предмет можно использовать только в тире!"))
		return

	if(!isturf(target))
		return

	if(world.time < next_spawn_time)
		var/time_left = (next_spawn_time - world.time) / 10
		to_chat(user, span_warning("Подождите ещё [time_left] секунд перед следующим спавном!"))
		return

	var/choice = tgui_input_list(user, "Выберите лоадаут для спавна", "Ghost Cafe Spawner", available_outfits)
	if(!choice)
		return

	var/datum/outfit/selected_outfit = available_outfits[choice]

	if(current_spawned && !QDELETED(current_spawned))
		current_spawned.dust()
		current_spawned = null

	var/mob/living/carbon/human/H = new /mob/living/carbon/human(target)
	H.set_species(/datum/species/human) // Жёстко задаём человека

	H.equipOutfit(selected_outfit)

	protect_clothing(H)

	current_spawned = H
	next_spawn_time = world.time + cooldown

	to_chat(user, span_notice("Заспавнен человек с лоадаутом: [selected_outfit.name]"))
	playsound(src, 'sound/magic/staff_change.ogg', 50, TRUE)

/obj/item/ghostcafe_spawner/proc/protect_clothing(mob/living/carbon/human/H)
	// Защищаем все слоты от снятия
	for(var/slot in H.get_all_slots())
		if(istype(slot, /obj/item/clothing))
			var/obj/item/clothing/C = slot
			C.flags_inv |= HIDEJUMPSUIT  // Используем существующий флаг вместо CANTSTRIP
			C.item_flags |= ABSTRACT  // Защита от дропа

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
