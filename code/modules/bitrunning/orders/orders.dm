/datum/orderable_item
	var/name
	var/category_index
	var/cost_per_order = 0
	var/purchase_path
	var/desc

/proc/get_orderable_items(category)
	var/static/list/catalog_by_category
	if(isnull(catalog_by_category))
		catalog_by_category = list()
		for(var/datum/orderable_item/item as anything in subtypesof(/datum/orderable_item))
			if(initial(item.cost_per_order) <= 0 || isnull(initial(item.purchase_path)))
				continue
			var/item_category = initial(item.category_index)
			var/list/bucket = catalog_by_category[item_category]
			if(isnull(bucket))
				bucket = list()
				catalog_by_category[item_category] = bucket
			bucket += item

	return catalog_by_category[category] || list()

/datum/orderable_item/bepis
	category_index = CATEGORY_BEPIS

/datum/orderable_item/bepis/circuit_stack
	purchase_path = /obj/item/stack/circuit_stack/full
	cost_per_order = 150

/datum/orderable_item/bepis/survival_pen
	purchase_path = /obj/item/pen/survival
	cost_per_order = 150

/datum/orderable_item/bepis/party_sleeper
	purchase_path = /obj/item/circuitboard/machine/sleeper/party
	cost_per_order = 750
	desc = "Списанная плата криокапсулы, переоборудованная для развлечений."

/datum/orderable_item/bepis/sprayoncan
	purchase_path = /obj/item/toy/sprayoncan
	cost_per_order = 750

/datum/orderable_item/bitrunning_flair
	category_index = CATEGORY_BITRUNNING_FLAIR

/datum/orderable_item/bitrunning_flair/cornchips
	purchase_path = /obj/item/reagent_containers/food/snacks/cornchips
	cost_per_order = 100

/datum/orderable_item/bitrunning_flair/mountain_wind
	purchase_path = /obj/item/reagent_containers/food/drinks/soda_cans/space_mountain_wind
	cost_per_order = 100

/datum/orderable_item/bitrunning_flair/pwr_game
	purchase_path = /obj/item/reagent_containers/food/drinks/soda_cans/pwr_game
	cost_per_order = 200

/datum/orderable_item/bitrunning_flair/grey_bull
	purchase_path = /obj/item/reagent_containers/food/drinks/soda_cans/grey_bull
	cost_per_order = 200

/datum/orderable_item/bitrunning_flair/medkit
	purchase_path = /obj/item/storage/firstaid/brute
	desc = "Не корите себя, это всего лишь игра!"
	cost_per_order = 500

/datum/orderable_item/bitrunning_flair/medkit_fire
	purchase_path = /obj/item/storage/firstaid/fire
	desc = "Отлично подходит после жарких игровых сессий."
	cost_per_order = 500

/datum/orderable_item/bitrunning_flair/oval_sunglasses
	purchase_path = /obj/item/clothing/glasses/sunglasses/oval
	cost_per_order = 1000

/datum/orderable_item/bitrunning_flair/trenchcoat
	purchase_path = /obj/item/clothing/suit/jacket/leather_trenchcoat
	cost_per_order = 1000

/datum/orderable_item/bitrunning_flair/jackboots
	purchase_path = /obj/item/clothing/shoes/jackboots
	cost_per_order = 1000

/datum/orderable_item/bitrunning_tech
	category_index = CATEGORY_BITRUNNING_TECH

/datum/orderable_item/bitrunning_tech/item_tier1
	cost_per_order = 750
	purchase_path = /obj/item/disk/bitrunning/item/tier1
	desc = "Этот диск содержит программу, позволяющую экипировать медицинский лучевой пистолет, взрывчатку C4 или коробку бесконечной пиццы."

/datum/orderable_item/bitrunning_tech/item_tier2
	cost_per_order = 1250
	purchase_path = /obj/item/disk/bitrunning/item/tier2
	desc = "Этот диск содержит программу, позволяющую экипировать люксовый медипен, пистолет или бронежилет."

/datum/orderable_item/bitrunning_tech/item_tier3
	cost_per_order = 2000
	purchase_path = /obj/item/disk/bitrunning/item/tier3
	desc = "Этот диск содержит программу, позволяющую экипировать продвинутый энергетический пистолет, двуклинковый энергомеч или минибомбу."

/datum/orderable_item/bitrunning_tech/ability_tier1
	cost_per_order = 750
	purchase_path = /obj/item/disk/bitrunning/ability/tier1
	desc = "Этот диск содержит программу, позволяющую призывать Сыр или Малое исцеление."

/datum/orderable_item/bitrunning_tech/ability_tier2
	cost_per_order = 1500
	purchase_path = /obj/item/disk/bitrunning/ability/tier2
	desc = "Этот диск содержит программу, позволяющую применять Огненный шар, Молнию или Силовой барьер."

/datum/orderable_item/bitrunning_tech/ability_tier3
	cost_per_order = 2500
	purchase_path = /obj/item/disk/bitrunning/ability/tier3
	desc = "Этот диск содержит программу, позволяющую превращаться в малого пепельного дрейка или полярного медведя."

/datum/orderable_item/bitrunning_tech/gimmick_sports
	cost_per_order = 750
	purchase_path = /obj/item/disk/bitrunning/gimmick/sports
	desc = "Этот диск содержит программу, позволяющую экипировать спортивный гиммик-набор снаряжения."

/datum/orderable_item/bitrunning_tech/gimmick_dungeon_crawling
	cost_per_order = 1250
	purchase_path = /obj/item/disk/bitrunning/gimmick/dungeon
	desc = "Этот диск содержит программу, позволяющую экипировать гиммик-набор для подземелий."

/datum/orderable_item/bitrunning_tech/pref_item
	cost_per_order = 500
	purchase_path = /obj/item/disk/bitrunning/prefs
	desc = "Этот диск содержит программу, позволяющую загружать собственных персонажей."

/datum/orderable_item/bitrunning_tech/pka_mod
	purchase_path = /obj/item/disk/bitrunning/item/pka_mods
	cost_per_order = 750
	desc = "Этот диск содержит программу, позволяющую устанавливать модкиты на протокинетический ускоритель. Протокинетический ускоритель не входит в комплект."

/datum/orderable_item/bitrunning_tech/pka_mod/premium
	purchase_path = /obj/item/disk/bitrunning/item/pka_mods/premium
	cost_per_order = 1600
	desc = "Этот диск содержит программу, позволяющую устанавливать улучшенные модкиты на протокинетический ускоритель. Протокинетический ускоритель не входит в комплект."

/datum/orderable_item/bitrunning_tech/pkc_mod
	purchase_path = /obj/item/disk/bitrunning/item/pkc_mods
	cost_per_order = 750
	desc = "Этот диск содержит программу, позволяющую устанавливать трофеи для протокинетического дробителя. Протокинетический дробитель не входит в комплект."

/datum/orderable_item/bitrunning_tech/pkc_mod/premium
	purchase_path = /obj/item/disk/bitrunning/item/pkc_mods/premium
	cost_per_order = 1600
	desc = "Этот диск содержит программу, позволяющую устанавливать усиленные трофеи для протокинетического дробителя. Протокинетический дробитель не входит в комплект."
