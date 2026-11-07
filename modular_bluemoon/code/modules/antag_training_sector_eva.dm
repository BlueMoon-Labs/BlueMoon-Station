/area/antag_training/sector/eva
	name = "Training EVA"
	has_gravity = FALSE

/datum/antag_training_sector/eva
	id = "eva"
	name = "Космос и EVA"
	desc = "Поле обломков шаттла «Кассиопея» в открытом космосе без гравитации: джетпаки, магнитные ботинки, скафандры, шлюз и форпост сборщиков на астероиде."
	map_path = "_maps/templates/antag_training/eva.dmm"
	area_type = /area/antag_training/sector/eva
	origin_x = 61
	origin_y = 36
	spawn_offset = list(2, 7)
	target_offset = list(33, 32)

/obj/structure/closet/antag_training_eva
	name = "EVA locker"
	desc = "Шкаф с комплектом для выхода в открытый космос: скафандр со шлемом, кислородный джетпак и магнитные ботинки."
	icon_state = "emergency"
	anchored = TRUE

/obj/structure/closet/antag_training_eva/PopulateContents()
	new /obj/item/clothing/suit/space/eva(src)
	new /obj/item/clothing/head/helmet/space/eva(src)
	new /obj/item/tank/jetpack/oxygen(src)
	new /obj/item/clothing/shoes/magboots(src)

/obj/item/paper/antag_training_eva
	name = "EVA checklist"
	default_raw_text = "<b>Выход в открытый космос</b><br><br>\
		1. Наденьте скафандр, шлем и магнитные ботинки, джетпак - на спину.<br>\
		2. Откройте подачу воздуха из джетпака: шлем скафандра держит её без маски.<br>\
		3. Двери шлюза связаны: открытие одной закрывает другую.<br><br>\
		<b>В невесомости</b><br>\
		- Без опоры не сдвинуться: держитесь за стены, решётки, камни и крупные предметы рядом.<br>\
		- Оттолкнувшись, вы летите по инерции, пока рядом не окажется опора.<br>\
		- Брошенный предмет или струя огнетушителя толкает вас в обратную сторону.<br>\
		- Включённые магнитные ботинки держат на полу и обшивке, но замедляют шаг.<br>\
		- Джетпак включается кнопкой действия, стабилизатор гасит дрейф. Газ джетпака тратится и на полёт, и на дыхание."

/obj/item/paper/antag_training_eva/salvage_log
	name = "salvage log"
	default_raw_text = "<b>Журнал бригады сборщиков</b><br><br>\
		Шаттл «Кассиопея» разорвало на три части: рубка, пассажирский отсек и корма с двигателями. Воздуха в обломках нет.<br><br>\
		- Титан и листы обшивки снимаем с кормы, приборы и платы - из рубки.<br>\
		- В невесомости опора - стены обломков, балки и решётки: отталкивайтесь от них.<br>\
		- По полю обломков ходить только с напарником и с запасом газа на обратный путь.<br>\
		- Добычу складывать в ящики у форпоста, руду - в рудный ящик на площадке шлюза."
