/obj/item/borg_chameleon
	name = "cyborg chameleon projector"
	icon = 'icons/obj/device.dmi'
	icon_state = "shield0"
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	var/friendlyName
	var/savedName
	/// Шасси борга до маскировки: deactivate() возвращал его в дефолтный robots.dmi,
	/// и Meka/догборг навсегда терял и спрайт, и позы отдыха (в robots.dmi их нет).
	var/saved_base_icon
	var/saved_icon_override
	var/saved_pixel_offset
	var/saved_bubble_icon
	var/obj/item/robot_module/saved_module
	var/list/startup_filters = list()
	var/mob/living/silicon/robot/startup_user
	var/active = FALSE
	var/activationCost = 300
	var/activationUpkeep = 50
	var/disguise = null
	var/disguise_icon_override = null
	var/disguise_pixel_offset = null
	var/mob/listeningTo
	var/static/list/signalCache = list( // list here all signals that should break the camouflage
			COMSIG_PARENT_ATTACKBY,
			COMSIG_ATOM_ATTACK_HAND,
			COMSIG_MOVABLE_IMPACT_ZONE,
			COMSIG_ATOM_BULLET_ACT,
			COMSIG_ATOM_EX_ACT,
			COMSIG_ATOM_FIRE_ACT,
			COMSIG_ATOM_EMP_ACT,
			)
	var/mob/living/silicon/robot/user // needed for process()
	var/animation_playing = FALSE

	var/list/engymodels = list("Default", "Default - Treads", "Heavy", "Sleek", "Marina", "Can", "Spider", "Loader","Handy", "Pup Dozer", "Vale")


/obj/item/borg_chameleon/Initialize(mapload)
	. = ..()
	friendlyName = pick(GLOB.ai_names)

/obj/item/borg_chameleon/Destroy()
	clear_startup_filters()
	deactivate(user, TRUE)
	return ..()

/obj/item/borg_chameleon/proc/clear_startup_filters()
	if(!QDELETED(startup_user))
		for(var/own_filter in startup_filters)
			animate(own_filter)
			startup_user.filters -= own_filter
	startup_filters.Cut()
	startup_user = null

/obj/item/borg_chameleon/dropped(mob/user)
	. = ..()
	disrupt(user)

/obj/item/borg_chameleon/equipped(mob/user)
	. = ..()
	disrupt(user)

/obj/item/borg_chameleon/attack_self(mob/living/silicon/robot/user)
	if(active && user == src.user)
		toggle(user)
		return
	if (user && user.cell && user.cell.charge > activationCost)
		if (isturf(user.loc))
			toggle(user)
		else
			to_chat(user, "<span class='warning'>You can't use [src] while inside something!</span>")
	else
		to_chat(user, "<span class='warning'>You need at least [activationCost] charge in your cell to use [src]!</span>")

/obj/item/borg_chameleon/proc/toggle(mob/living/silicon/robot/user)
	if(QDELETED(user) || loc != user || !user.module)
		return
	if(active)
		playsound(src, 'sound/effects/pop.ogg', 100, TRUE, -6)
		to_chat(user, "<span class='notice'>You deactivate \the [src].</span>")
		deactivate(user)
	else
		if(animation_playing)
			to_chat(user, "<span class='notice'>\the [src] is recharging.</span>")
			return
		var/borg_icon = input(user, "Select an icon!", "Robot Icon", null) as null|anything in engymodels
		if(!borg_icon || QDELETED(src) || QDELETED(user) || loc != user || !user.module)
			return FALSE
		// Previous wide disguises must not leak their offset into regular models.
		disguise_pixel_offset = 0
		switch(borg_icon)
			if("Default")
				disguise = "engineer"
				disguise_icon_override = 'icons/mob/robots.dmi'
			if("Default - Treads")
				disguise = "engi-tread"
				disguise_icon_override = 'modular_citadel/icons/mob/robots.dmi'
			if("Loader")
				disguise = "loaderborg"
				disguise_icon_override = 'modular_citadel/icons/mob/robots.dmi'
			if("Handy")
				disguise = "handyeng"
				disguise_icon_override = 'modular_citadel/icons/mob/robots.dmi'
			if("Sleek")
				disguise = "sleekeng"
				disguise_icon_override = 'modular_citadel/icons/mob/robots.dmi'
			if("Can")
				disguise = "caneng"
				disguise_icon_override = 'modular_citadel/icons/mob/robots.dmi'
			if("Marina")
				disguise = "marinaeng"
				disguise_icon_override = 'modular_citadel/icons/mob/robots.dmi'
			if("Spider")
				disguise = "spidereng"
				disguise_icon_override = 'modular_citadel/icons/mob/robots.dmi'
			if("Heavy")
				disguise = "heavyeng"
				disguise_icon_override = 'modular_citadel/icons/mob/robots.dmi'
			if("Pup Dozer")
				disguise = "pupdozer"
				disguise_icon_override = 'modular_citadel/icons/mob/widerobot.dmi'
				disguise_pixel_offset = -16
			if("Vale")
				disguise = "valeeng"
				disguise_icon_override = 'modular_citadel/icons/mob/widerobot.dmi'
				disguise_pixel_offset = -16
		animation_playing = TRUE
		to_chat(user, "<span class='notice'>You activate \the [src].</span>")
		playsound(src, 'sound/effects/seedling_chargeup.ogg', 100, TRUE, -6)
		startup_user = user
		var/X,Y,rsq,i
		for(i=1, i<=7, ++i)
			do
				X = 60*rand() - 30
				Y = 60*rand() - 30
				rsq = X*X + Y*Y
			while(rsq<100 || rsq>900)
			var/own_filter = filter(type="wave", x=X, y=Y, size=rand()*2.5+0.5, offset=rand())
			startup_filters += own_filter
			user.filters += own_filter
			animate(own_filter, offset=own_filter:offset, time=0, loop=3, flags=ANIMATION_PARALLEL)
			animate(offset=own_filter:offset-1, time=rand()*20+10)
		var/completed = do_after(user, 50, target=user)
		if(QDELETED(src))
			return
		if(completed && !QDELETED(user) && loc == user && user.module && user.cell?.use(activationCost))
			playsound(src, 'sound/effects/bamf.ogg', 100, TRUE, -6)
			to_chat(user, "<span class='notice'>You are now disguised as the Nanotrasen engineering borg \"[friendlyName]\".</span>")
			activate(user)
		else if(!QDELETED(user))
			to_chat(user, "<span class='warning'>The chameleon field fizzles.</span>")
			do_sparks(3, FALSE, user)
		clear_startup_filters()
		animation_playing = FALSE

/obj/item/borg_chameleon/process()
	if(!active)
		return PROCESS_KILL
	if(QDELETED(user) || !user.module || user.module != saved_module)
		deactivate(user, TRUE)
		return PROCESS_KILL
	if(!user.cell || !user.cell.use(activationUpkeep))
		disrupt(user)
		return PROCESS_KILL

/obj/item/borg_chameleon/proc/activate(mob/living/silicon/robot/user)
	START_PROCESSING(SSobj, src)
	src.user = user
	savedName = user.name
	saved_base_icon = user.module.cyborg_base_icon
	saved_icon_override = user.module.cyborg_icon_override
	saved_pixel_offset = user.module.cyborg_pixel_offset
	saved_bubble_icon = user.bubble_icon
	saved_module = user.module
	user.name = friendlyName
	user.module.cyborg_base_icon = disguise
	user.module.cyborg_icon_override = disguise_icon_override
	user.module.cyborg_pixel_offset = disguise_pixel_offset
	user.bubble_icon = "robot"
	active = TRUE
	user.update_icons()

	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, signalCache)
	RegisterSignal(user, signalCache, PROC_REF(disrupt))
	listeningTo = user

/obj/item/borg_chameleon/proc/deactivate(mob/living/silicon/robot/target, silent = FALSE)
	STOP_PROCESSING(SSobj, src)
	if(listeningTo && !QDELETED(listeningTo))
		UnregisterSignal(listeningTo, signalCache)
	listeningTo = null
	var/was_active = active
	active = FALSE
	if(was_active && !QDELETED(target))
		if(!silent)
			do_sparks(5, FALSE, target)
		if(target.name == friendlyName)
			target.name = savedName
		if(target.module == saved_module && !QDELETED(saved_module))
			saved_module.cyborg_base_icon = saved_base_icon
			saved_module.cyborg_icon_override = saved_icon_override
			saved_module.cyborg_pixel_offset = saved_pixel_offset
		if(target.bubble_icon == "robot")
			target.bubble_icon = saved_bubble_icon
		target.update_icons()
	src.user = null
	saved_module = null

/obj/item/borg_chameleon/proc/disrupt(mob/living/silicon/robot/target)
	if(active)
		if(!QDELETED(target))
			to_chat(target, "<span class='danger'>Your chameleon field deactivates.</span>")
		deactivate(src.user)
