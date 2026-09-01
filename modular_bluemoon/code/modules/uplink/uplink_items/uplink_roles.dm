/datum/uplink_item/role_restricted/pie_book
	name = "Book: Summon Pie"
	desc = "Книга, дающая читателю способность призывать пирог. Отлично сочетается с дурацкими шутками над окружающими."
	item = /obj/item/book/granter/spell/summon_pie
	cost = 1 // возможность засрать ими бар и ывзвать у СБ проблемы с закидывающими их ассистентами
	restricted_roles = list("Clown", "Mime")

/datum/uplink_item/role_restricted/rebarxbowsyndie
	name = "Syndicate Rebar Crossbow"
	desc = "Более профессиональная версия самодельного арбалета инженера. Магазин на 6 выстрелов, быстрая перезарядка, \
		улучшенный прицел и более смертоносные болты. В комплекте колчан и инструкция по изготовлению боеприпасов."
	item = /obj/item/storage/box/syndie_kit/rebarxbowsyndie
	cost = 12
	restricted_roles = list("Station Engineer", "Chief Engineer", "Atmospheric Technician")
