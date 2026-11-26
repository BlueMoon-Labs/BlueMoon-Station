/datum/gear/unlockable
	category = LOADOUT_CATEGORY_UNLOCKABLE
	slot = ITEM_SLOT_NECK

	var/progress_required //what does our progress need to be to unlock it
	var/progress_key //what is the key used to retrieve existing progress for this unlockable

/datum/gear/unlockable/janitor
	name = "Janitor Bedsheet"
	description = "Убери 100 беспорядков шваброй, чтобы разблокировать. На нём есть предупреждающий знак!"
	path = /obj/item/bedsheet/unlockable/janitor

	progress_required = 100
	progress_key = "janitor"

/datum/gear/unlockable/cook
	name = "Cook Bedsheet"
	description = "Приготовь 250 блюд в микроволновке, чтобы разблокировать. На нём нарисована микроволновка!"
	path = /obj/item/bedsheet/unlockable/cook

	progress_required = 250
	progress_key = "cook"

/datum/gear/unlockable/miner
	name = "Miner Bedsheet"
	description = "Накопи 100 000 очков шахтёра, чтобы разблокировать. Сделано из шкуры голиафа!"
	path = /obj/item/bedsheet/unlockable/miner

	progress_required = 100000
	progress_key = "miner"

/datum/gear/unlockable/pawlicker_medal
	name = "Paw Medal"
	description = "Разблокируется за достижение pawlicker. Не задавай лишних вопросов."
	path = /obj/item/clothing/accessory/medal/pawlicker

	slot = ITEM_SLOT_ACCESSORY
	progress_required = 1
	progress_key = "achievement_pawlicker"
