/obj/item/lighter/donator/bm/militaryzippo
	name = "military zippo"
	desc = "Army styled zippo with graved \"Dmitry Strelnikov\" on backside. Has a much hotter flame than normal."
	icon = 'modular_bluemoon/fluffs/icons/obj/items.dmi'
	icon_state = "mzippo"
	heat = 2000
	light_color = LIGHT_COLOR_FIRE
	overlay_state = "mzippo"
	grind_results = list(/datum/reagent/iron = 1, /datum/reagent/fuel = 5, /datum/reagent/oil = 5)

/obj/item/reagent_containers/glass/beaker/elf_bottle
	name = "potion bottle"
	desc = "Фиолетовая бутылка, что выглядет очень старой. \
		Она выглядет так буд-то её используют для хранения зелий.  \
		На этикетке написано 'Зелье снятия одежды'."
	icon = 'modular_bluemoon/fluffs/icons/obj/items.dmi'
	icon_state = "elf_bottle"
	volume = 150
	possible_transfer_amounts = list(1,2,3,5,10,25,50,100,150)
	container_flags = APTFT_ALTCLICK|APTFT_VERB
	list_reagents = list(/datum/reagent/consumable/ethanol/panty_dropper = 50)
	container_HP = 10

////////////////////////

/obj/item/modkit/hahun_jukebox
	name = "Irrelian Jukebox"
	desc = "A modkit for making a jukebox into an acradorian version."
	product = /obj/item/jukebox/hahun
	fromitem = list(/obj/item/jukebox)

/obj/item/jukebox/hahun
	name = "Irellian music player"
	desc = "An Irellian musical player, resembles a phone with acratorian design, have two little antennas and a port for headphones"
	icon = 'modular_bluemoon/fluffs/icons/obj/items.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/items_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/items_right.dmi'
	icon_state = "hahun_jukebox"
	item_state = "hahun_jukebox"

////////////////////////

/obj/item/modkit/invis_belt
	name = "\improper Invisible Belt Kit"
	desc = "Экспериментальный комплект полихромных нанитов, предназначенных для временной модификации внешних свойств одежды. \
	После активации наниты закрепляются в структуре ткани, выстраивая адаптивную решётку, изменяющую показатели светопропускания и преломления. \n\
	В активном режиме одежда становится визуально прозрачной для наблюдателя, при этом сохраняя физическую целостность, теплоизоляцию и защитные свойства. \
	Эффект не постоянный, наниты со временем деактивируются и разрушаются."
	icon_state = "blueshield_helmet_kit"
	product = null
	fromitem = list(/obj/item/storage/belt)

/obj/item/modkit/invis_belt/afterattack(obj/item/O, mob/user)
	if(!istype(O))
		return
	for(var/path in fromitem)
		if(istype(O, path))
			O.item_state = null
			O.update_slot_icon()
			user.visible_message(span_warning("[user] modifies [O]!"),span_warning("You modify the [O]!"))
			qdel(src)
			return

////////////////////////

/obj/item/sign/flag/imperium
	name = "flag of Imperium"
	desc = "Флаг далекой, колоссальной, жестокой и забюрократизированной империи."
	icon = 'modular_bluemoon/fluffs/icons/obj/flags.dmi'
	icon_state = "folded_imperium_red"
	can_lock_coffin = TRUE
	sign_path = /obj/structure/sign/flag/imperium

/obj/structure/sign/flag/imperium
	name = "flag of Imperium"
	desc = "Флаг далекой, колоссальной, жестокой и забюрократизированной империи."
	icon = 'modular_bluemoon/fluffs/icons/obj/flags.dmi'
	icon_state = "flag_imperium_red"
	item_flag = /obj/item/sign/flag/imperium

/obj/item/sign/flag/imperium/gray
	icon_state = "folded_imperium_gray"
	sign_path = /obj/structure/sign/flag/imperium/gray

/obj/structure/sign/flag/imperium/gray
	icon_state = "flag_imperium_gray"
	item_flag = /obj/item/sign/flag/imperium/gray


/obj/item/storage/box/imperium_flags
	name = "Imperium flag kit"
	desc = "Коробка с набором флагов одной далекой империи."
	icon_state = "secbox_xl"

/obj/item/storage/box/imperium_flags/PopulateContents()
	// По 2x3 флага в коробке
	for(var/path in list(/obj/item/sign/flag/imperium, /obj/item/sign/flag/imperium/gray))
		for(var/i = 1 to 3)
			new path(src)
