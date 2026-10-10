/obj/item/storage/belt/grenade/fire_grenade
	name = "firetrooper belt"
	desc = "A belt for holding lots of incendiary grenades."
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE

/obj/item/storage/belt/grenade/fire_grenade/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 15
	STR.display_numerical_stacking = TRUE
	STR.max_combined_w_class = 60
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.can_hold = typecacheof(list(
		/obj/item/grenade,
		/obj/item/screwdriver,
		/obj/item/lighter,
		/obj/item/multitool,
		/obj/item/reagent_containers/food/drinks/bottle/molotov,
		/obj/item/grenade/plastic/c4,
		))

/obj/item/storage/belt/grenade/fire_grenade/PopulateContents()
	new /obj/item/grenade/flashbang(src)
	new /obj/item/grenade/flashbang(src)
	new /obj/item/grenade/chem_grenade/incendiary(src)
	new /obj/item/grenade/chem_grenade/incendiary(src)
	new /obj/item/grenade/chem_grenade/incendiary(src)

/obj/item/storage/belt/buscadero
	name = "buscadero"
	desc = "A buscadero for holding ammunition."
	icon = 'modular_bluemoon/icons/obj/clothing/belts.dmi'
	icon_state = "buscadero"
	item_state = "utility"
	lefthand_file = 'icons/mob/inhands/equipment/belt_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/belt_righthand.dmi'

/obj/item/storage/belt/buscadero/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 36
	STR.max_combined_w_class = 36
	STR.display_numerical_stacking = TRUE
	STR.can_hold = typecacheof(list(
		/obj/item/ammo_casing/g45l
		))

/obj/item/storage/belt/buscadero/attackby(obj/item/A, mob/user, params)
	// 1. Проверяем, что по поясу кликнули именно коробкой патронов .45
	if(istype(A, /obj/item/ammo_box/g45l))
		var/obj/item/ammo_box/g45l/box = A
		
		// Проверяем, есть ли вообще патроны внутри коробки
		if(!box.stored_ammo || !box.stored_ammo.len)
			to_chat(user, "<span class='warning'>[box.name] пуста!</span>")
			return TRUE

		// Получаем компонент хранилища пояса
		var/datum/component/storage/STR = GetComponent(/datum/component/storage)
		if(!STR)
			return ..()

		// РУЧНОЙ ПОДСЧЕТ: Считаем, сколько патронов УЖЕ лежит в поясе прямо сейчас
		var/current_bullet_count = 0
		for(var/obj/item/ammo_casing/B in src.contents)
			current_bullet_count++

		// Если в поясе уже есть 36 или больше патронов — сразу выходим
		if(current_bullet_count >= 36)
			to_chat(user, "<span class='warning'>[src.name] уже заполнен до предела (36/36 патронов), больше не влезает!</span>")
			return TRUE

		var/transferred_count = 0

		// 2. Цикл переноса: перебираем патроны в коробке с конца списка
		for(var/i = box.stored_ammo.len; i > 0; i--)
			// Проверяем жесткий лимит в 36 штук прямо во время засыпания очередного патрона
			if(current_bullet_count >= 36)
				break

			var/obj/item/ammo_casing/bullet = box.stored_ammo[i]
			if(!bullet)
				continue

			// Просим компонент принять патрон
			if(STR.handle_item_insertion(bullet, TRUE, user))
				// Если пояс успешно принял патрон, удаляем его из списка коробки
				box.stored_ammo -= bullet
				transferred_count++
				current_bullet_count++ // Увеличиваем счетчик патронов в поясе
			else
				break

		// 3. Выводим итоги
		if(transferred_count > 0)
			playsound(src.loc, 'sound/weapons/bulletinsert.ogg', 50, TRUE)
			to_chat(user, "<span class='notice'>Вы быстро высыпали [transferred_count] патрон\\ов из [box.name] прямо в [src.name] ([current_bullet_count]/36).</span>")
			
			box.update_icon()
			src.update_icon()
		else
			to_chat(user, "<span class='warning'>[src.name] полон, патроны не влезают!</span>")
		
		return TRUE 

	return ..()

/obj/item/storage/belt/cowboy_holster
	name = "Cowboy holster"
	desc = "A holster to carry a speedloaders and revolvers	. WARNING: Badasses only."
	icon = 'modular_bluemoon/icons/obj/clothing/belts.dmi'
	icon_state = "cowboy"
	item_state = "utility"
	lefthand_file = 'icons/mob/inhands/equipment/belt_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/belt_righthand.dmi'

obj/item/storage/belt/cowboy_holster/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 6
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.can_hold = typecacheof(list(
		/obj/item/gun/ballistic/revolver,
		/obj/item/ammo_box
		))
