GLOBAL_LIST_EMPTY(monkey_recyclers)

/obj/machinery/monkey_recycler
	name = "monkey recycler"
	desc = "Машина для переработки мёртвых мартышек в кубы." // except it literally never does
	icon = 'icons/obj/machines/kitchen.dmi'
	icon_state = "grinder"
	layer = BELOW_OBJ_LAYER
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 5
	active_power_usage = 50
	circuit = /obj/item/circuitboard/machine/monkey_recycler
	var/stored_matter = 0
	var/cube_production = 0.2
	var/list/connected = list()			//Keeps track of connected xenobio consoles, for deletion in /Destroy()

/obj/machinery/monkey_recycler/Initialize(mapload)
	. = ..()
	if (mapload)
		GLOB.monkey_recyclers += src
	add_overlay("grinder_monkey")
	locate_camera_console()

/obj/machinery/monkey_recycler/Destroy()
	GLOB.monkey_recyclers -= src
	for(var/thing in connected)
		var/obj/machinery/computer/camera_advanced/xenobio/console = thing
		console.connected_recycler = null
	connected.Cut()
	return ..()

/obj/machinery/monkey_recycler/update_overlays()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || panel_open)
		return

	if(stored_matter >= 1)
		. += "grinder_active"
		. += emissive_appearance(icon, "grinder_active", src, alpha = src.alpha)
	else if(cube_production >= 6)
		. += "grinder_loaded"
		. += emissive_appearance(icon, "grinder_loaded", src, alpha = src.alpha)
	else
		. += "grinder_empty"
		. += emissive_appearance(icon, "grinder_empty", src, alpha = src.alpha)

/obj/machinery/monkey_recycler/proc/locate_camera_console()
	if(length(connected))
		return // we're already connected!
	for(var/obj/machinery/computer/camera_advanced/xenobio/xeno_camera in GLOB.machines)
		if(get_area(xeno_camera) == get_area(loc))
			xeno_camera.connected_recycler = src
			connected |= xeno_camera
			break

/obj/machinery/monkey_recycler/RefreshParts()	//Ranges from 1 to 5 per monkey recycled
	cube_production = 0
	for(var/obj/item/stock_parts/manipulator/B in component_parts)
		cube_production += B.rating * 0.5
	for(var/obj/item/stock_parts/matter_bin/M in component_parts)
		cube_production += M.rating * 0.5

/obj/machinery/monkey_recycler/examine_display_content(mob/user)
	. += "– Производится <b>[cube_production]</b> ед. кубов за мартышку."
	if(cube_production >= 6)
		. += "\n– Этот переработчик способен создавать обезьяньи кубики своими силами."

/obj/machinery/monkey_recycler/attackby(obj/item/O, mob/user, params)
	if(default_deconstruction_screwdriver(user, "grinder_open", "grinder", O))
		return

	if(default_pry_open(O))
		return

	if(default_unfasten_wrench(user, O))
		power_change()
		return

	if(default_deconstruction_crowbar(O))
		return

	if(machine_stat) //NOPOWER etc
		return
	else
		return ..()

/obj/machinery/monkey_recycler/MouseDrop_T(mob/living/target, mob/living/user)
	if(!istype(target))
		return
	if(ismonkey(target))
		stuff_monkey_in(target, user)

/obj/machinery/monkey_recycler/proc/stuff_monkey_in(mob/living/carbon/monkey/target, mob/living/user)
	if(!istype(target))
		return
	if(target.stat == CONSCIOUS)
		to_chat(user, span_warning("Мартышка слишком сильно борется за жизнь при попытке переработать её!"))
		return
	if(target.buckled || target.has_buckled_mobs())
		to_chat(user, span_warning("Мартышка прикреплена к чему-то."))
		return
	qdel(target)
	target = null //we sleep in this proc, clear reference NOW
	to_chat(user, span_notice("Вы засовываете мартышку в машину."))
	playsound(src.loc, 'sound/machines/juicer.ogg', 50, 1)
	Shake(2, 2, 4 SECONDS)
	use_power(500)
	stored_matter += cube_production
	update_icon()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), user, span_notice("В машине теперь хранится [stored_matter] эквивалента обезьяньего биоматериала .")))

/obj/machinery/monkey_recycler/interact(mob/user)
	if(cube_production >= 6 && stored_matter < 1) //Tier 6
		stored_matter++
	if(stored_matter >= 1)
		to_chat(user, span_notice("Машина громко шипит и конденсирует кусок обезьянины. Через момент он превращается в кубик."))
		playsound(src.loc, 'sound/machines/hiss.ogg', 50, 1)
		for(var/i in 1 to FLOOR(stored_matter, 1))
			new /obj/item/reagent_containers/food/snacks/cube/monkey(src.loc)
			stored_matter--
		to_chat(user, span_notice("Машина показывает на дисплее, что в ней осталось [stored_matter] эквивалента обезьяньего биоматериала."))
	else
		to_chat(user, span_danger("Машине требуется как минимум 1 мартышка биоэквивалентом, для производства кубика. Сейчас эквивалента материала: [stored_matter]."))
	update_icon()

/obj/machinery/monkey_recycler/multitool_act(mob/living/user, obj/item/multitool/I)
	if(istype(I))
		to_chat(user, span_notice("Вы загрузили данные [src] в буфер мультитула."))
		I.buffer = src
		return TRUE
