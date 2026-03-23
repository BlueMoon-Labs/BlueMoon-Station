/datum/uplink_item/role_restricted/pie_book
	name = "Book: Summon Pie"
	desc = "Книга, дающая читателю способность призывать пирог. Отлично сочетается с дурацкими шутками над окружающими."
	item = /obj/item/book/granter/spell/summon_pie
	cost = 1 // возможность засрать ими бар и ывзвать у СБ проблемы с закидывающими их ассистентами
	restricted_roles = list("Clown", "Mime")
