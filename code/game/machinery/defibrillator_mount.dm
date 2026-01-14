//Holds defibs and recharges them from the powernet
//You can activate the mount with an empty hand to grab the paddles
//Not being adjacent will cause the paddles to snap back
/obj/machinery/defibrillator_mount
	name = "defibrillator mount"
	desc = "Стойка с креплениями. На неё можно повесить дефибриллятор для зарядки его внутренней батареи и удобного доступа к его электродам."
	icon = 'icons/obj/machines/defib_mount.dmi'
	icon_state = "defibrillator_mount"
	density = FALSE
	use_power = IDLE_POWER_USE
	idle_power_usage = 1
	power_channel = EQUIP
	req_one_access = list(ACCESS_MEDICAL, ACCESS_HEADS, ACCESS_SECURITY) //used to control clamps
	var/obj/item/defibrillator/defib //this mount's defibrillator
	var/clamps_locked = FALSE //if true, and a defib is loaded, it can't be removed without unlocking the clamps

/obj/machinery/defibrillator_mount/Initialize(mapload, ndir)
	. = ..()
	if(ndir)
		setDir(ndir)

/obj/machinery/defibrillator_mount/loaded/Initialize(mapload, ndir) //loaded subtype for mapping use
	. = ..()
	defib = new/obj/item/defibrillator/loaded(src)

/obj/machinery/defibrillator_mount/Destroy()
	if(defib)
		defib.forceMove(drop_location())
		defib = null
	. = ..()

/obj/machinery/defibrillator_mount/examine(mob/user)
	. = ..()
	if(defib)
		. += "<span class='notice'>Дефибриллятор закреплён. Alt-click, чтобы снять его.<span>"
		if(GLOB.security_level >= SEC_LEVEL_RED)
			. += "<span class='notice'>Из-за кода тревоги, фиксирующие зажимы могут быть переключены ID-картой.</span>"
		else
			. += "<span class='notice'>Фиксирующие зажимы могут быть [clamps_locked ? "раз" : "за"]блокированы ID-картой с доступами.</span>"
	. += span_notice("Держится на нескольких <b>болтах</b>.")

/obj/machinery/defibrillator_mount/process()
	if(defib && defib.cell && defib.cell.charge < defib.cell.maxcharge && is_operational())
		use_power(200)
		defib.cell.give(180) //90% efficiency, slightly better than the cell charger's 87.5%
		update_icon()
	var/turf/T = get_turf(src)
	var/turf/parentwall = get_step(T, REVERSE_DIR(src.dir))
	if(!istype(parentwall, /turf/closed))
		fall_down()

/obj/machinery/defibrillator_mount/proc/fall_down()
	if(defib)
		defib.forceMove(drop_location())
		defib = null
	visible_message(span_warning("Дефибрилляторная стойка упала без стабильной опоры!"))
	new /obj/item/wallframe/defib_mount(drop_location())
	qdel(src)
	return

/obj/machinery/defibrillator_mount/update_overlays()
	. = ..()
	if(!defib)
		return

	. += "defib"

	if(defib.powered)
		. += (defib.safety ? "online" : "emagged")
		var/ratio = defib.cell.charge / defib.cell.maxcharge
		ratio = CEILING(ratio * 4, 1) * 25
		. += "charge[ratio]"

	if(clamps_locked)
		. += "clamps"

/obj/machinery/defibrillator_mount/get_cell()
	if(defib)
		return defib.get_cell()

//defib interaction
/obj/machinery/defibrillator_mount/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!defib)
		to_chat(user, "<span class='warning'>Отсутствует дефибриллятор!</span>")
		return
	if(defib.paddles.loc != defib)
		to_chat(user, "<span class='warning'>[defib.paddles.loc == user ? "Вы уже держите" : "Кто-то уже держит"] электроды [defib]!</span>")
		return
	user.put_in_hands(defib.paddles)

/obj/machinery/defibrillator_mount/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/defibrillator))
		if(defib)
			to_chat(user, "<span class='warning'>В [src] уже есть дефибриллятор!</span>")
			return
		if(HAS_TRAIT(I, TRAIT_NODROP) || !user.transferItemToLoc(I, src))
			to_chat(user, "<span class='warning'>[I] прилип к вашей руке!</span>")
			return
		user.visible_message("<span class='notice'>[user] вставляет [I] в слот [src]!</span>", \
		"<span class='notice'>Вы вжимаете [I] внутрь стойки и оно входит с характерным кликом.</span>")
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		defib = I
		update_icon()
		return
	else if(I == defib.paddles)
		defib.paddles.snap_back()
		return
	var/obj/item/card/id = I.GetID()
	if(id)
		if(check_access(id) || GLOB.security_level >= SEC_LEVEL_RED) //anyone can toggle the clamps in red alert!
			if(!defib)
				to_chat(user, "<span class='warning'>Вы не можете закрепить зажимы на отсутствующем дефибрилляторе.</span>")
				return
			clamps_locked = !clamps_locked
			to_chat(user, "<span class='notice'>Зажимы [clamps_locked ? "за" : "от"]креплены.</span>")
			update_icon()
		else
			to_chat(user, "<span class='warning'>В доступе отказано.</span>")
		return
	..()

/obj/machinery/defibrillator_mount/multitool_act(mob/living/user, obj/item/W)
	if(!W.tool_behaviour == TOOL_MULTITOOL)
		return
	if(!defib)
		to_chat(user, "<span class='warning'>Отсутствует дефибриллятор!</span>")
		return TRUE
	if(!clamps_locked)
		to_chat(user, "<span class='warning'>Зажимы [src] откреплены!</span>")
		return TRUE
	user.visible_message("<span class='notice'>[user] прижимает [W] внутрь ID-слота [src]...</span>", \
	"<span class='notice'>You begin overriding the clamps on [src]...</span>")
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)
	if(!do_after(user, 100, target = src) || !clamps_locked)
		return
	user.visible_message("<span class='notice'>[user] даёт пульс пр помощи [W] и зажимы [src] открепляются.</span>", \
	"<span class='notice'>You override the locking clamps on [src]!</span>")
	playsound(src, 'sound/machines/locktoggle.ogg', 50, TRUE)
	clamps_locked = FALSE
	update_icon()
	return TRUE

/obj/machinery/defibrillator_mount/wrench_act(mob/living/user, obj/item/I)
	if(defib)
		balloon_alert("Нужно вынуть дефибриллятор!")
	else if(I.use_tool(src, user, 1.5 SECONDS))
		new /obj/item/wallframe/defib_mount(drop_location())
		qdel(src)
	return TRUE

/obj/machinery/defibrillator_mount/AltClick(mob/living/carbon/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	. = TRUE
	if(!defib)
		to_chat(user, "<span class='warning'>Сложно будет достать дефибриллятор из стойки, которая его не имеет.</span>")
		return
	if(clamps_locked)
		to_chat(user, "<span class='warning'>Вы пытаетесь вытащить [defib], но зажимы стойки туго затянуты!</span>")
		return
	if(!user.get_empty_held_indexes())
		to_chat(user, "<span class='warning'>Вам нужна свободная рука!</span>")
		return
	user.put_in_hands(defib)
	user.visible_message("<span class='notice'>[user] вынимает [defib] из [src].</span>", \
	"<span class='notice'>Вы сняли [defib] с [src] и отсоединили зарядные кабели.</span>")
	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	defib = null
	update_icon()

//wallframe, for attaching the mounts easily
/obj/item/wallframe/defib_mount
	name = "unhooked defibrillator mount"
	desc = "Рамка дефибрилляторной стойки. Может быть снята гаечным ключом после размещения."
	icon = 'icons/obj/machines/defib_mount.dmi'
	icon_state = "defibrillator_mount_item"
	custom_materials = list(/datum/material/iron = 300, /datum/material/glass = 100)
	w_class = WEIGHT_CLASS_BULKY
	result_path = /obj/machinery/defibrillator_mount
	pixel_shift = -28
