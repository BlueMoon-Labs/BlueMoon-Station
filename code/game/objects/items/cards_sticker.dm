#define DATA_ICON "icon"
#define DATA_ICON_STATE "icon_state"
#define DATA_S_ASSIGNMENT "special_assignment"

/obj/item/card_sticker
	name = "Card sticker"
	desc = "Расширение, устанавливаемое поверх стандартной ID-карты. \
	Перехватывает и подменяет отображаемые данные: визуальный стиль карты, цветовую схему и название должности.\n\
	Не влияет на реальные уровни доступа и системы аутентификации, изменяя исключительно представление информации для интерфейсов и внешнего осмотра."
	icon = 'icons/obj/card.dmi'
	icon_state = "occult_id"
	w_class = WEIGHT_CLASS_TINY
	var/const/wrap_delay = 1.3 SECONDS // time to wrap sticker on card
	var/special_assignment = "syndicate" // id card HUD icon
	var/prefix = "Test" // prefix for card assigment
	var/auto_equip = FALSE // for loadout
	var/permit = null // only for auto_equip
	var/permit_only_extended = FALSE
	// Список слов, при наличиии которых в профессии, префикс отображен не будет
	// Проверка на сам префикс будет, даже если список пустой, что бы избежать «Syndicate Syndicate Admiral»
	var/list/prefix_not_allowed_with = list()
	// list of changed vars on ID card
	var/list/previous_icon_data = list(
		DATA_ICON = "",
		DATA_ICON_STATE = "",
		DATA_S_ASSIGNMENT = "",
	)

/obj/item/card_sticker/examine(mob/user)
	. = ..()
	. += span_notice("Расширение, устанавливаемое поверх стандартной ID-карты. \
	Перехватывает и подменяет отображаемые данные: визуальный стиль карты, цветовую схему и название должности.\n\
	Не влияет на реальные уровни доступа и системы аутентификации, изменяя исключительно представление информации для интерфейсов и внешнего осмотра.")

// При выдаче через лодаут карта помещается в рюкзак и применяется на основную карту
/obj/item/card_sticker/on_enter_storage(datum/component/storage/concrete/S)

	if(auto_equip)
		auto_equip = FALSE
		var/mob/living/carbon/human/my_owner = null

		// Проверяем инветарь и сумку куклы
		var/atom/movable/cur = loc
		for(var/i = 1, i <= 2, i++)
			if(!cur)
				break

			if(ishuman(cur))
				my_owner = cur
				break

			// дальше поднимаемся только если следующий loc тоже movable
			if(!istype(cur.loc, /atom/movable))
				break

			cur = cur.loc

		if(my_owner)
			var/obj/item/card/id/id_card = my_owner.get_item_by_slot(ITEM_SLOT_ID)
			if(id_card)
				// Активируем наклейку
				if(wrap(id_card, my_owner, silent = TRUE, force = TRUE))
					// Обновляем ПДА
					var/obj/item/pda/PDA = locate(/obj/item/pda) in my_owner.contents
					if(istype(PDA))
						PDA.ownjob = id_card.get_assignment_name()
						PDA.update_label()

			if(permit && (!permit_only_extended || GLOB.master_mode == ROUNDTYPE_EXTENDED))
				var/obj/item/clothing/accessory/permit/special/prmt = new permit(my_owner)
				//Привязываем пермит
				prmt.bind_to_user(my_owner, TRUE)

				var/obj/item/clothing/under/U = my_owner.get_item_by_slot(ITEM_SLOT_ICLOTHING)
				// Крепим к одежде, если не удалось, помещаем в сумку
				if(!(istype(U) && U.attach_accessory(prmt, my_owner, FALSE)))
					my_owner.equip_in_one_of_slots(prmt, list("backpack" = ITEM_SLOT_BACKPACK), critical = TRUE)

	return ..()

/obj/item/card_sticker/proc/wrap(obj/item/card/id/card, mob/user, silent = FALSE, force = FALSE)
	. = FALSE
	if(card.sticker || (user && INTERACTING_WITH(user, card)))
		return
	if(!silent)
		balloon_alert(user, "Присоединяю...")
	if(!force && !do_after(user, wrap_delay, card))
		return

	if(!forceMove(card))
		return
	card.sticker = src

	for(var/var_name in previous_icon_data)
		previous_icon_data[var_name] = card.vars[var_name]

	//if(special_assignment)
		//card.special_assignment = special_assignment
	card.icon = icon
	card.icon_state = icon_state

	card.update_label()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.sec_hud_set_ID()

	return TRUE

/obj/item/card_sticker/proc/unwrap(obj/item/card/id/card, mob/user, silent = FALSE, force = FALSE)
	. = FALSE
	if(card.sticker != src || (user && INTERACTING_WITH(user, card)))
		return
	if(!silent)
		balloon_alert(user, "Снимаю...")
	if(!force && !do_after(user, wrap_delay, card))
		return

	if(user && !user.put_in_hands(src))
		return
	else if(!user)
		moveToNullspace()

	card.sticker = null

	for(var/var_name in previous_icon_data)
		card.vars[var_name] = previous_icon_data[var_name]
		previous_icon_data[var_name] = ""

	card.update_label()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.sec_hud_set_ID()

	return TRUE

/obj/item/card_sticker/heresy
	name = "Occult sticker"
	desc = "Sticker for research related to occult activities whose nature of phenomena is poorly supported by scientific evidence."
	icon_state = "occult_id"
	prefix = "Heretic"
	special_assignment = "heresy"
	permit = /obj/item/clothing/accessory/permit/special/deviant/heresey

/obj/item/card_sticker/heresy/loadout
	auto_equip = TRUE

/obj/item/card_sticker/lust
	name = "Sex Worker sticker"
	desc = "Sticker for employee of Silver Love Co."
	icon_state = "lust_id"
	prefix = "Sex Worker"
	special_assignment = "lust"
	prefix_not_allowed_with = list("Sex")
	permit = /obj/item/clothing/accessory/permit/special/deviant/lust

/obj/item/card_sticker/lust/loadout
	auto_equip = TRUE

/obj/item/card_sticker/agony
	name = "Ravenheart Resident sticker"
	desc = "Sticker for research related to extreme activities whose nature of agony is strictly prohibited by scientific evidence."
	icon_state = "agony_id"
	prefix = "Ravenheart"
	special_assignment = "agony"
	permit = /obj/item/clothing/accessory/permit/special/deviant/agony
	permit_only_extended = TRUE

/obj/item/card_sticker/agony/loadout
	auto_equip = TRUE

/obj/item/card_sticker/muck
	name = "Muck sticker"
	desc = "Sticker for employees with dirty thoughts and such more..."
	icon_state = "muck_id"
	prefix = "Mucker"
	special_assignment = "muck"
	permit = /obj/item/clothing/accessory/permit/special/deviant/muck

/obj/item/card_sticker/muck/loadout
	auto_equip = TRUE

/obj/item/card_sticker/vampire
	name = "Bloodfledge sticker"
	desc = "An sticker made to easily recognize bloodsucker fledglings without requiring medical scans."
	icon_state = "vampire2"
	prefix = "Bloodsucker"
	special_assignment = "bloodsuckerfledgling"

/obj/item/card_sticker/vampire/loadout
	auto_equip = TRUE

/obj/item/card_sticker/blumenland
	name = "Blumenland Citizen sticker"
	desc = "An sticker made to recognize Blumenland Confederation habbitants and tourists."
	icon_state = "blumland"
	prefix = "Blumenland"
	special_assignment = "bmland"

/obj/item/card_sticker/blumenland/loadout
	auto_equip = TRUE

/obj/item/card_sticker/syndicate
	name = "Syndicate Employee sticker"
	desc = "An sticker made to recognize Triglav Syndicate agents and supportives."
	icon_state = "card_black"
	prefix = "Syndicate"
	special_assignment = "syndicate"
	prefix_not_allowed_with = list("Syndi", "NT", "Nanotrasen")

/obj/item/card_sticker/syndicate/loadout
	auto_equip = TRUE

/obj/item/card_sticker/sol
	name = "SolFed Citizen sticker"
	desc = "An sticker made to recognize Solar Federation habbitants and tourists."
	icon_state = "sol"
	prefix = "SolFed"
	special_assignment = "sol"
	prefix_not_allowed_with = list("Sol", "Solar Federation")

/obj/item/card_sticker/sol/loadout
	auto_equip = TRUE

/obj/item/card_sticker/nri
	name = "NRI Citizen sticker"
	desc = "An sticker made to recognize Novaya Rossiyskya Imperia habbitants and tourists."
	icon_state = "nri"
	prefix = "NRI"
	special_assignment = "nri"
	prefix_not_allowed_with = list("New Russian Empire")

/obj/item/card_sticker/nri/loadout
	auto_equip = TRUE

#undef DATA_ICON
#undef DATA_ICON_STATE
#undef DATA_S_ASSIGNMENT
