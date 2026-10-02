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
	// Проверяем, что по поясу кликнули именно коробкой патронов .45
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

		var/transferred_count = 0

		// Цикл переноса перебираем патроны в коробке с конца списка
		for(var/i = box.stored_ammo.len; i > 0; i--)
			var/obj/item/ammo_casing/bullet = box.stored_ammo[i]
			if(!bullet)
				continue

			// Встроенный метод компонента хранилища Splurt.
			// Сам проверит лимит в 36 патронов и тип /obj/item/ammo_casing/g45l.
			if(STR.handle_item_insertion(bullet, TRUE, user))
				// Если пояс успешно принял патрон, удаляем его из списка коробки
				box.stored_ammo -= bullet
				transferred_count++
			else
				// Если handle_item_insertion вернул FALSE, значит пояс полностью забит (достиг 36 штук)
				break

		// Выводим итоги
		if(transferred_count > 0)
			// Воспроизводим фирменный звук засыпания патронов
			playsound(src.loc, 'sound/weapons/bulletinsert.ogg', 50, TRUE)
			to_chat(user, "<span class='notice'>Вы быстро высыпали [transferred_count] патрон\\ов из [box.name] прямо в [src.name].</span>")
			
			// Обновляем спрайты коробки и пояса
			box.update_icon()
			src.update_icon()
		else
			to_chat(user, "<span class='warning'>[src.name] уже заполнен до предела, патроны не влезают!</span>")
		
		return TRUE // Блокируем дефолтный attackby

	// Если кликнули чем-то другим — пусть работает стандартная логика
	return ..()
