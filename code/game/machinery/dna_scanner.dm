/obj/machinery/dna_scannernew
	name = "\improper DNA scanner"
	desc = "Эта машина сканирует цепочки ДНК."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "scanner"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 50
	active_power_usage = 300
	occupant_typecache = list(/mob/living, /obj/item/bodypart/head, /obj/item/organ/brain)
	circuit = /obj/item/circuitboard/machine/clonescanner
	var/locked = FALSE
	var/damage_coeff
	var/scan_level
	var/precision_coeff
	var/message_cooldown
	var/breakout_time = 1200
	var/obj/machinery/computer/scan_consolenew/linked_console = null

/obj/machinery/dna_scannernew/RefreshParts()
	scan_level = 0
	damage_coeff = 0
	precision_coeff = 0
	for(var/obj/item/stock_parts/scanning_module/P in component_parts)
		scan_level += P.rating
	for(var/obj/item/stock_parts/matter_bin/M in component_parts)
		precision_coeff = M.rating
	for(var/obj/item/stock_parts/micro_laser/P in component_parts)
		damage_coeff = P.rating

/obj/machinery/dna_scannernew/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Статус-дисплей сообщает: \n\
		- Точность импульса увеличена в <b>[precision_coeff**2]</b> раз(а). \n\
		- Объём облучения уменьшен в <b>[damage_coeff**2]</b> раз(а).")
		if(scan_level >= 3)
			. += span_notice("- Сканер улучшен и поддерживает автообработку.")

/obj/machinery/dna_scannernew/update_icon_state()
	//no power or maintenance
	if(machine_stat & (NOPOWER|BROKEN))
		icon_state = initial(icon_state)+ (state_open ? "_open" : "") + "_unpowered"
		return

	if((machine_stat & MAINT) || panel_open)
		icon_state = initial(icon_state)+ (state_open ? "_open" : "") + "_maintenance"
		return

	//running and someone in there
	if(occupant)
		icon_state = initial(icon_state)+ "_occupied"
		return

	//running
	icon_state = initial(icon_state)+ (state_open ? "_open" : "")

/obj/machinery/dna_scannernew/proc/toggle_open(mob/user)
	if(panel_open)
		to_chat(user, "<span class='notice'>Для начала закройте панель техобслуживания.</span>")
		return

	if(state_open)
		close_machine()
		return

	else if(locked)
		to_chat(user, "<span class='notice'>Болты опущены, держа створки запертыми.</span>")
		return

	open_machine()

/obj/machinery/dna_scannernew/container_resist(mob/living/user)
	if(!locked)
		open_machine()
		return
	user.visible_message("<span class='notice'>Вы видите как [user] пинает створки [src]!</span>", \
		"<span class='notice'>Вы прислонились к стенке [src] и начали выдавливать дверь наружу... (это займёт примерно [DisplayTimeText(breakout_time)].)</span>", \
		"<span class='hear'>Вы слышите металлический лязг от [src].</span>")
	if(INTERACTING_WITH(user, src))
		to_chat(user, span_warning("Вы уже взаимодействуете с [src]!"))
		return
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || state_open || !locked)
			return
		locked = FALSE
		user.visible_message("<span class='warning'>[user] успешно выбирается из [src]!</span>", \
			"<span class='notice'>Вы успешно выбрались из [src]!</span>")
		open_machine()

/obj/machinery/dna_scannernew/proc/locate_computer(type_)
	for(var/direction in GLOB.cardinals)
		var/C = locate(type_, get_step(src, direction))
		if(C)
			return C
	return null

/obj/machinery/dna_scannernew/close_machine(mob/living/carbon/user)
	if(!state_open)
		return FALSE

	..(user)

// search for ghosts, if the corpse is empty and the scanner is connected to a cloner
	var/mob/living/mob_occupant = get_mob_or_brainmob(occupant)
	if(istype(mob_occupant))
		if(locate_computer(/obj/machinery/computer/cloning))
			if(!mob_occupant.suiciding && !(HAS_TRAIT(mob_occupant, TRAIT_NOCLONE)) && !mob_occupant.hellbound)
				mob_occupant.notify_ghost_cloning("Ваш труп поместили в сканер клонирования. Вернитесь в тело, если хотите быть клонированными!", source = src)

	// DNA manipulators cannot operate on severed heads or brains
	if(iscarbon(occupant))
		if(linked_console)
			linked_console.on_scanner_close()

	return TRUE

/obj/machinery/dna_scannernew/open_machine()
	if(state_open)
		return FALSE

	..()

	if(linked_console)
		linked_console.on_scanner_open()

	return TRUE

/obj/machinery/dna_scannernew/relaymove(mob/user as mob)
	if(user.stat || locked)
		if(message_cooldown <= world.time)
			message_cooldown = world.time + 50
			to_chat(user, "<span class='warning'>Створки [src] не поддаются!</span>")
		return
	open_machine()

/obj/machinery/dna_scannernew/attackby(obj/item/I, mob/user, params)

	if(!occupant && default_deconstruction_screwdriver(user, icon_state, icon_state, I))//sent icon_state is irrelevant...
		update_icon()//..since we're updating the icon here, since the scanner can be unpowered when opened/closed
		return

	if(default_pry_open(I))
		return

	if(default_deconstruction_crowbar(I))
		return

	return ..()

/obj/machinery/dna_scannernew/interact(mob/user)
	toggle_open(user)

/obj/machinery/dna_scannernew/MouseDrop_T(mob/target, mob/user)
	var/mob/living/L = user
	if(user.stat || (isliving(user) && (!(L.mobility_flags & MOBILITY_STAND) || !(L.mobility_flags & MOBILITY_UI))) || !Adjacent(user) || !user.Adjacent(target) || !iscarbon(target) || !user.IsAdvancedToolUser())
		return
	close_machine(target)


//Just for transferring between genetics machines.
/obj/item/disk/data
	name = "DNA data disk"
	desc = "Дискета для хранения генетической информации, работы любого генетика."
	icon_state = "datadisk0" //Gosh I hope syndies don't mistake them for the nuke disk.
	var/list/genetic_makeup_buffer = list()
	var/list/fields = list()
	var/list/mutations = list()
	var/max_mutations = 6
	var/read_only = FALSE //Well,it's still a floppy disk

/obj/item/disk/data/Initialize(mapload)
	. = ..()
	icon_state = "datadisk[rand(0,6)]"
	add_overlay("datadisk_gene")

/obj/item/disk/data/attack_self(mob/user)
	read_only = !read_only
	to_chat(user, "<span class='notice'Вы перевели ползунок защиты данных в положение [read_only ? "защищено" : "незащищено"].</span>")

/obj/item/disk/data/examine(mob/user)
	. = ..()
	. += "Ползунок защиты данных в положении [read_only ? "защищено" : "незащищено"]."
