/obj/machinery/nanite_chamber
	name = "nanite chamber"
	desc = "Устройство сканирования, репрограммирования и инъекции нанитов."
	circuit = /obj/item/circuitboard/machine/nanite_chamber
	icon = 'icons/obj/machines/nanite_chamber.dmi'
	icon_state = "nanite_chamber"
	layer = ABOVE_WINDOW_LAYER
	use_power = IDLE_POWER_USE
	anchored = TRUE
	density = TRUE
	idle_power_usage = 50
	active_power_usage = 300

	var/obj/machinery/computer/nanite_chamber_control/console
	var/locked = FALSE
	var/breakout_time = 1200
	var/scan_level
	var/busy = FALSE
	var/busy_icon_state
	var/busy_message
	var/message_cooldown = 0

/obj/machinery/nanite_chamber/Initialize(mapload)
	. = ..()
	occupant_typecache = GLOB.typecache_living

/obj/machinery/nanite_chamber/RefreshParts()
	scan_level = 0
	for(var/obj/item/stock_parts/scanning_module/P in component_parts)
		scan_level += P.rating

/obj/machinery/nanite_chamber/examine_display_content(mob/user)
	. += "– Сканирующий модуль был улучшен до уровня <b>[scan_level]</b>."

/obj/machinery/nanite_chamber/proc/set_busy(status, message, working_icon)
	busy = status
	busy_message = message
	busy_icon_state = working_icon
	update_icon()

/obj/machinery/nanite_chamber/proc/set_safety(threshold)
	if(!occupant || SEND_SIGNAL(occupant, COMSIG_NANITE_CHECK_CONSOLE_LOCK))
		return
	SEND_SIGNAL(occupant, COMSIG_NANITE_SET_SAFETY, threshold)

/obj/machinery/nanite_chamber/proc/set_cloud(cloud_id)
	if(!occupant || SEND_SIGNAL(occupant, COMSIG_NANITE_CHECK_CONSOLE_LOCK))
		return
	SEND_SIGNAL(occupant, COMSIG_NANITE_SET_CLOUD, cloud_id)

/obj/machinery/nanite_chamber/proc/inject_nanites()
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if((machine_stat & MAINT) || panel_open)
		return
	if(!occupant || busy)
		return

	var/locked_state = locked
	locked = TRUE

	//TODO OMINOUS MACHINE SOUNDS
	set_busy(TRUE, "Инициализация протокола инъекции...", "[initial(icon_state)]_raising")
	addtimer(CALLBACK(src, PROC_REF(set_busy), TRUE, "Анализ биоструктуры носителя...", "[initial(icon_state)]_active"),20)
	addtimer(CALLBACK(src, PROC_REF(set_busy), TRUE, "Взвод нанитов...", "[initial(icon_state)]_active"),40)
	addtimer(CALLBACK(src, PROC_REF(set_busy), TRUE, "Инъекция...", "[initial(icon_state)]_active"),70)
	addtimer(CALLBACK(src, PROC_REF(set_busy), TRUE, "Активация нанитов...", "[initial(icon_state)]_falling"),110)
	addtimer(CALLBACK(src, PROC_REF(complete_injection), locked_state),130)

/obj/machinery/nanite_chamber/proc/complete_injection(locked_state)
	//TODO MACHINE DING
	locked = locked_state
	set_busy(FALSE)
	if(!occupant)
		return
	occupant.AddComponent(/datum/component/nanites, 100)

/obj/machinery/nanite_chamber/proc/remove_nanites(datum/nanite_program/NP)
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if((machine_stat & MAINT) || panel_open)
		return
	if(!occupant || busy || SEND_SIGNAL(occupant, COMSIG_NANITE_CHECK_CONSOLE_LOCK))
		return

	var/locked_state = locked
	locked = TRUE

	//TODO OMINOUS MACHINE SOUNDS
	set_busy(TRUE, "Инициализация протокола очистки...", "[initial(icon_state)]_raising")
	addtimer(CALLBACK(src, PROC_REF(set_busy), TRUE, "Анализ биоструктуры носителя...", "[initial(icon_state)]_active"),20)
	addtimer(CALLBACK(src, PROC_REF(set_busy), TRUE, "Уведомление нанитов...", "[initial(icon_state)]_active"),40)
	addtimer(CALLBACK(src, PROC_REF(set_busy), TRUE, "Иниациация глубокого алгоритма самоуничтожения...", "[initial(icon_state)]_active"),70)
	addtimer(CALLBACK(src, PROC_REF(set_busy), TRUE, "Зачистка остатков нанитов...", "[initial(icon_state)]_falling"),110)
	addtimer(CALLBACK(src, PROC_REF(complete_removal), locked_state),130)

/obj/machinery/nanite_chamber/proc/complete_removal(locked_state)
	//TODO MACHINE DING
	locked = locked_state
	set_busy(FALSE)
	if(!occupant)
		return
	if(isliving(occupant))
		var/mob/living/L = occupant
		var/obj/item/implant/nanite_pump/pump = locate() in L.implants
		if(pump)
			qdel(pump)

	SEND_SIGNAL(occupant, COMSIG_NANITE_DELETE)

/obj/machinery/nanite_chamber/update_icon_state()
	//running and someone in there
	if(occupant)
		if(busy)
			icon_state = busy_icon_state
		else
			icon_state = initial(icon_state) + "_occupied"
	else
		//running
		icon_state = initial(icon_state) + (state_open ? "_open" : "")

/obj/machinery/nanite_chamber/update_overlays()
	. = ..()

	if((machine_stat & MAINT) || panel_open)
		. += "maint"

	else if(!(machine_stat & (NOPOWER|BROKEN)))
		if(busy || locked)
			. += "red"
			if(locked)
				. += "bolted"
		else
			. += "green"

/obj/machinery/nanite_chamber/proc/toggle_open(mob/user)
	if(panel_open)
		to_chat(user, span_notice("Для начала закройте люк техобслуживания."))
		return

	if(state_open)
		close_machine()
		return

	else if(locked)
		to_chat(user, span_notice("Болты опускаются, надёжно закрывая створки."))
		return

	open_machine()

/obj/machinery/nanite_chamber/container_resist(mob/living/user)
	if(!locked)
		open_machine()
		return
	if(busy)
		return
	user.visible_message(span_notice("Вы видите как [user] пинает створки внутри [src]!"), \
		span_notice("Вы отклонились к задней стенке [src] и начинаете продавливать себе путь наружу... (это займёт примерно [DisplayTimeText(breakout_time)].)"), \
		span_hear("Вы слышите металлический лязг, исходящий от [src]."))
	if(INTERACTING_WITH(user, src))
		to_chat(user, span_warning("Вы уже взаимодействуете с [src]!"))
		return
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || state_open || !locked || busy)
			return
		locked = FALSE
		user.visible_message(span_warning("[user] успешно выбирается из [src]!"), \
			span_notice("Вы успешно выбираетесь из [src]!</span>"))
		open_machine()

/obj/machinery/nanite_chamber/close_machine(mob/living/carbon/user)
	if(!state_open)
		return FALSE

	..(user)
	return TRUE

/obj/machinery/nanite_chamber/open_machine()
	if(state_open)
		return FALSE

	..()
	return TRUE

/obj/machinery/nanite_chamber/relaymove(mob/user as mob)
	if(user.stat || locked)
		if(message_cooldown <= world.time)
			message_cooldown = world.time + 50
			to_chat(user, span_warning("Створки [src] не поддаются!"))
		return
	open_machine()

/obj/machinery/nanite_chamber/attackby(obj/item/I, mob/user, params)
	if(!occupant && default_deconstruction_screwdriver(user, icon_state, icon_state, I))//sent icon_state is irrelevant...
		update_icon()//..since we're updating the icon here, since the scanner can be unpowered when opened/closed
		return

	if(default_pry_open(I))
		return

	if(default_deconstruction_crowbar(I))
		return

	return ..()

/obj/machinery/nanite_chamber/interact(mob/user)
	toggle_open(user)

/obj/machinery/nanite_chamber/MouseDrop_T(mob/target, mob/user)
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK) || !Adjacent(target) || !user.Adjacent(target) || !iscarbon(target))
		return
	if(close_machine(target))
		log_combat(user, target, "inserted", null, "into [src].")
	add_fingerprint(user)
