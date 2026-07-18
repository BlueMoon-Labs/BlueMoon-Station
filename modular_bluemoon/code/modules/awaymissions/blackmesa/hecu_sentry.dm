/obj/item/hecusentry
	name = "HECU Sentry Gun (Folded)"
	desc = "A compact, folded HECU sentry gun. Use a wrench to deploy it."
	icon = 'modular_bluemoon/icons/obj/urbanism/hecusentry.dmi'
	icon_state = "sentry_notd"
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/hecusentry/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WRENCH)
		user.visible_message("<span class='notice'>[user] begins deploying the [src]...</span>", "<span class='notice'>You begin deploying the [src]...</span>")
		if(I.use_tool(src, user, 30, volume=50))
			var/obj/machinery/porta_turret/hecu/T = new(get_turf(user))
			T.update_icon()
			user.visible_message("<span class='notice'>[user] deploys the [src].</span>", "<span class='notice'>You deploy the [src].</span>")
			qdel(src)
		return
	..()

/obj/machinery/porta_turret/hecu
	name = "HECU Sentry Gun"
	desc = "An automated sentry gun used by the HECU. It has a high fire rate and low damage."
	icon = 'modular_bluemoon/icons/obj/urbanism/hecusentry.dmi'
	icon_state = "sentry_on"
	base_icon_state = "sentry"
	faction = list(FACTION_HECU)
	installation = null
	lethal_projectile = /obj/item/projectile/bullet/c10mm/hecu
	lethal_projectile_sound = 'modular_bluemoon/sound/weapons/mesa/mp5.ogg'
	shot_delay = 3
	scan_range = 7
	max_integrity = 200
	anchored = TRUE
	always_up = TRUE
	has_cover = FALSE
	on = TRUE
	turret_flags = TURRET_FLAG_SHOOT_ALL | TURRET_FLAG_SHOOT_ANOMALOUS
	mode = TURRET_LETHAL
	speed_process = TRUE

/obj/machinery/porta_turret/hecu/check_should_process()
	if (datum_flags & DF_ISPROCESSING)
		if (!on || !anchored || (machine_stat & BROKEN) || !powered())
			STOP_PROCESSING(SSfastprocess, src)
	else
		if (on && anchored && !(machine_stat & BROKEN) && powered())
			START_PROCESSING(SSfastprocess, src)

/obj/machinery/porta_turret/hecu/setup()
	return

/obj/machinery/porta_turret/hecu/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(beep)), 10)

/obj/machinery/porta_turret/hecu/proc/beep()
	if(on && !(machine_stat & (BROKEN | NOPOWER)))
		playsound(src, 'modular_bluemoon/sound/weapons/mesa/turretping.ogg', 70, FALSE)
	addtimer(CALLBACK(src, PROC_REF(beep)), 10)

/obj/machinery/porta_turret/hecu/assess_perp(mob/living/carbon/human/perp)
	if(in_faction(perp))
		return FALSE
	return 10

/obj/machinery/porta_turret/hecu/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WRENCH)
		if(machine_stat & BROKEN)
			to_chat(user, "<span class='warning'>The [src] is too damaged to be folded!</span>")
			return
		user.visible_message("<span class='notice'>[user] begins folding the [src]...</span>", "<span class='notice'>You begin folding the [src]...</span>")
		if(I.use_tool(src, user, 30, volume=50))
			user.visible_message("<span class='notice'>[user] folds the [src].</span>", "<span class='notice'>You fold the [src].</span>")
			new /obj/item/hecusentry(get_turf(src))
			qdel(src)
		return
	return ..()

/obj/machinery/porta_turret/hecu/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "sentry_broken"
		return
	if(on && !(machine_stat & NOPOWER))
		icon_state = "sentry_on"
	else
		icon_state = "sentry_off"

/obj/item/projectile/bullet/c10mm/hecu
	name = "small caliber bullet"
	damage = 10

/obj/item/hecusentry_remote
	name = "HECU Sentry Remote"
	desc = "A remote control for HECU sentry guns. Use on a sentry to link it."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-syndie"
	var/list/obj/machinery/porta_turret/hecu/linked_sentries = list()

/obj/item/hecusentry_remote/attack_self(mob/user)
	if(!linked_sentries.len)
		to_chat(user, "<span class='warning'>No sentries linked!</span>")
		return

	var/any_on = FALSE
	var/i = 1
	while(i <= linked_sentries.len)
		var/obj/machinery/porta_turret/hecu/T = linked_sentries[i]
		if(QDELETED(T))
			linked_sentries.Cut(i, i+1)
			continue
		if(T.on)
			any_on = TRUE
		i++

	if(!linked_sentries.len)
		to_chat(user, "<span class='warning'>All linked sentries were destroyed!</span>")
		return

	var/target_state = !any_on

	for(var/obj/machinery/porta_turret/hecu/T in linked_sentries)
		T.setState(target_state, TURRET_LETHAL, FALSE)

	to_chat(user, "<span class='notice'>You [target_state ? "activate" : "deactivate"] [linked_sentries.len] linked sentries.</span>")
	playsound(user, 'sound/machines/click.ogg', 50, TRUE)

/obj/item/hecusentry_remote/afterattack(atom/target, mob/user, proximity_flag)
	if(istype(target, /obj/machinery/porta_turret/hecu))
		var/obj/machinery/porta_turret/hecu/T = target
		if(T in linked_sentries)
			linked_sentries -= T
			to_chat(user, "<span class='notice'>Sentry unlinked.</span>")
		else
			linked_sentries += T
			to_chat(user, "<span class='notice'>Sentry linked.</span>")
		return
	..()
