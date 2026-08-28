// Редкий предмет технического лута и добротное самодельное оружие.

/obj/item/lead_pipe
	name = "Lead Pipe"
	desc = "Увесистая свинцовая труба.\nСвинец - редкий гость в этом секторе после того, как его вывели из оборота из-за заботы о здоровье сотрудников. \
	\nЦиники, впрочем, поговаривают, что запрет НТ на свинец - не более чем схема, дабы пресечь поставки на заводы боеприпасов Синдиката."
	icon = 'icons/obj/maintenance_loot.dmi'
	icon_state = "lead_pipe"
	item_state = "lead_pipe"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	resistance_flags = FIRE_PROOF | ACID_PROOF
	force = 15
	throwforce = 12
	throw_range = 4
	w_class = WEIGHT_CLASS_BULKY
	attack_verb_continuous = list("бьёт", "лупит", "впечатывает")
	attack_verb_simple = list("бьёшь", "лупишь", "впечатываешь")
	pickup_sound = 'sound/items/handling/lead_pipe/lead_pipe_pickup.ogg'
	drop_sound = 'modular_bluemoon/krashly/sound/items/metal_drop.ogg'
	throw_drop_sound = 'sound/items/handling/lead_pipe/lead_pipe_drop.ogg'
	hitsound = 'sound/items/handling/lead_pipe/lead_pipe_hit.ogg'

/datum/crafting_recipe/lead_pipe // BLUEMOON ADD - крафт из подручных материалов
	name = "Свинцовая труба"
	result = /obj/item/lead_pipe
	reqs = list(/obj/item/stack/sheet/metal = 3,
				/obj/item/stack/rods = 2)
	tools = list(TOOL_WELDER)
	time = 60
	category = CAT_WEAPONRY
	subcategory = CAT_MELEE
