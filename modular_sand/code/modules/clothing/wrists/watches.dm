/obj/item/clothing/wrists/clockwork_watch
	name = "Часы в стиле Стимпанк"
	desc = "Стильные часы в стиле Стимпанк, сделанные из тысяч крошечных зубчатых колес."
	gender = MALE
	icon_state = "clockwork_slab"
	item_state = "clockwork_slab"
	//body_parts_covered = HAND_LEFT | ARM_LEFT //BLUEMOON COMMENTED
	attack_verb = list("показывает время")

/obj/item/clothing/wrists/clockwork_watch/red
	name = "Красные Стильные Часы"
	desc = "Особо красивые часы красного цвета. Сидят довольно удобно!"
	gender = MALE
	icon_state = "redwork_slab"
	item_state = "redwork_slab"
	//body_parts_covered = HAND_LEFT | ARM_LEFT //BLUEMOON COMMENTED
	attack_verb = list("показывает время")

/obj/item/clothing/wrists/clockwork_watch/examine(mob/user)
	. = ..()
	. += "<span class='info'>Station Time: [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"

/obj/item/clothing/wrists/clockwork_watch/attack(mob/target, mob/user)
	. = ..()
	to_chat(target, "<span class='info'>Station Time: [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]")
