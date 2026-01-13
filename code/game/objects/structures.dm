/obj/structure
	icon = 'icons/obj/structures.dmi'
	pressure_resistance = 8
	max_integrity = 300
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT
	var/climb_time = 20
	var/climb_stun = 20
	var/climbable = FALSE
	var/mob/living/structureclimber
	var/broken = 0 //similar to machinery's stat BROKEN
	layer = BELOW_OBJ_LAYER
	//ricochets on structures commented out for now because there's a lot of structures that /shouldnt/ be ricocheting and those need to be reviewed first
	//With the addition of [pass_flags_self] the ricocheting of structures /shouldnt/ happen by default thus the existing code could be uncommented out - Solaris-Shade
	//flags_1 = DEFAULT_RICOCHET_1
	//flags_ricochet = RICOCHET_HARD
	//ricochet_chance_mod = 0.5
	pass_flags_self = PASSSTRUCTURE

/obj/structure/Initialize(mapload)
	if (!armor)
		armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)
	. = ..()
	if(smooth)
		queue_smooth(src)
		queue_smooth_neighbors(src)
		icon_state = ""
	GLOB.cameranet.updateVisibility(src)

/obj/structure/Destroy()
	GLOB.cameranet.updateVisibility(src)
	if(smooth)
		queue_smooth_neighbors(src)
	return ..()

/obj/structure/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(structureclimber && structureclimber != user)
		user.DelayNextAction(CLICK_CD_MELEE)
		user.do_attack_animation(src)
		structureclimber.DefaultCombatKnockdown(40)
		structureclimber.visible_message("<span class='warning'>[structureclimber] был[structureclimber.ru_a()] сброшен[structureclimber.ru_a()] c [src].", "Вас сбросили с [src]!", "Вы видите как [structureclimber] сбрасывают с [src].</span>")

/obj/structure/ui_act(action, params)
	. = ..()
	add_fingerprint(usr)

/obj/structure/MouseDrop_T(atom/movable/O, mob/user)
	. = ..()
	if(. & COMSIG_MOB_CANCEL_CLICKON) //SPLURT edit
		return
	if(!climbable)
		return
	if(user == O && iscarbon(O))
		var/mob/living/L = O
		if(CHECK_MOBILITY(L, MOBILITY_MOVE))
			climb_structure(user)
			return
	if(!istype(O, /obj/item) || user.get_active_held_item() != O)
		return
	if(iscyborg(user))
		return
	if(!user.dropItemToGround(O))
		return
	if (O.loc != src.loc)
		step(O, get_dir(O, src))

/obj/structure/proc/do_climb(atom/movable/A)
	if(climbable)
		density = FALSE
		. = step(A, (A.loc == loc ? dir : get_dir(A,src.loc)))
		density = TRUE

/obj/structure/proc/climb_structure(mob/living/user)
	src.add_fingerprint(user)
	user.visible_message("<span class='warning'>[user] начинает взбираться на [src].</span>", \
								"<span class='notice'>Вы начали взбираться на [src]...</span>")
	var/adjusted_climb_time = climb_time
	var/user_has_gravity = user.has_gravity() // BLUEMOON ADD
	if(user_has_gravity)
		if(user.restrained()) //climbing takes twice as long when restrained.
			adjusted_climb_time *= 2
		if(isalien(user))
			adjusted_climb_time *= 0.25 //aliens are terrifyingly fast
		if(HAS_TRAIT(user, TRAIT_FREERUNNING)) //do you have any idea how fast I am???
			adjusted_climb_time *= 0.8
		// BLUEMOON ADDITION взаимодействия квирков и размеров на скорость залезания на стол
		if(get_size(user) < 0.8) //BLUEMOON ADD персонажи меньше 0.8 дольше забираются на столы
			adjusted_climb_time *= 2 - get_size(user) //x1.75 при размере 25%; x1.2 при размере 80%
		// тяжёлые (но не очень тяжёлые) персонажи медленее забираются на преграды
		if(user.mob_weight == MOB_WEIGHT_HEAVY)
			adjusted_climb_time *= 2
	else
		adjusted_climb_time *= 0.2
	// BLUEMOON ADDITION END
	structureclimber = user
	if(do_mob(user, user, adjusted_climb_time))
		if(src.loc) //Checking if structure has been destroyed
			if(do_climb(user))
				// BLUEMOON ADDITION AHEAD - сверхтяжёлые персонажи пересекают преграды быстро, но в процессе ломают их
				if(user_has_gravity && user.mob_weight > MOB_WEIGHT_HEAVY && !istype(src, /obj/structure/closet/crate))
					visible_message(span_warning("[src] ломается под весом [user]!"))
					playsound(src, 'modular_bluemoon/sound/effects/chair_break.ogg', 70, TRUE)
					deconstruct(FALSE)
					return
				// BLUEMOON ADDITION END
				user.visible_message("<span class='warning'>[user] взбирается на [src].</span>", \
									"<span class='notice'>Вы взобрались на [src].</span>")
				log_combat(user, src, "climbed onto")
				if(climb_stun && user_has_gravity)
					user.Stun(climb_stun)
				. = 1
			else
				to_chat(user, "<span class='warning'>You fail to climb onto [src].</span>")
	structureclimber = null

/obj/structure/examine(mob/user)
	. = ..()
	if(!(resistance_flags & INDESTRUCTIBLE))
		if(resistance_flags & ON_FIRE)
			. += "<span class='warning'>Оно горит!</span>"
		if(broken)
			. += "<span class='notice'>Похоже, что [src] не работает.</span>"
		var/examine_status = examine_status(user)
		if(examine_status)
			. +=  examine_status

/obj/structure/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()

	if(mover.pass_flags & PASSSTRUCTURE)
		return TRUE

/obj/structure/proc/examine_status(mob/user) //An overridable proc, mostly for falsewalls.
	var/healthpercent = (obj_integrity/max_integrity) * 100
	switch(healthpercent)
		if(50 to 99)
			return  "Выглядит слегка повреждённым."
		if(25 to 50)
			return  "Выглядит тяжело повреждённым."
		if(0 to 25)
			if(!broken)
				return  "<span class='warning'>Оно разваливается на части!</span>"

/obj/structure/rust_heretic_act()
	take_damage(500, BRUTE, MELEE, 1)
