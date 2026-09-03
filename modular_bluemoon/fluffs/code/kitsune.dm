/mob/living/carbon/wendigo/kitsune
	name = "Kitsune"
	icon = 'modular_bluemoon/fluffs/icons/mob/kitsune.dmi'
	icon_state = "base"
	gender = FEMALE
	var/current_lying_pose = "lying"
	var/aroused_state = "aroused"
	var/already_aroused = FALSE
	var/icon_living = "base"
	var/list/kitsune_abilities = list(
		new /datum/action/innate/kitsune/set_lying_pose,
		new /datum/action/innate/kitsune/toggle_aroused,
	)

/mob/living/carbon/wendigo/kitsune/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(initialize_abilities))

/mob/living/carbon/wendigo/kitsune/proc/initialize_abilities()
	SIGNAL_HANDLER
	for(var/datum/action/innate/ability in kitsune_abilities)
		ability.Grant(src)

/datum/action/innate/kitsune
	name = "kitsune action"
	background_icon_state = "bg_default"
	button_icon_state = "velvet_chords"
	var/mob/living/carbon/wendigo/kitsune/my_kitsune

/datum/action/innate/kitsune/toggle_aroused
	name = "Toggle_aroused"

/datum/action/innate/kitsune/set_lying_pose
	name = "Set lying pose"
	background_icon_state = "bg_default"
	var/list/avaible_poses = list(
		"lying_radial" = "lying",
		"sit_radial" = "sit",
		"sleep_radial" = "sleep"
	)

/datum/action/innate/kitsune/set_lying_pose/Activate()
	. = ..()
	var/list/choices = list()
	for(var/icon_state in avaible_poses)
		var/display_name = avaible_poses[icon_state]
		var/image/img = image(icon = my_kitsune.icon, icon_state = icon_state)
		choices[display_name] = img

	if(!length(choices))
		return
	var/pick = show_radial_menu(my_kitsune, my_kitsune, choices = choices)
	if(!pick)
		return
	my_kitsune.current_lying_pose = pick

/datum/action/innate/kitsune/toggle_aroused/Activate()
	. = ..()
	var/aroused = my_kitsune.already_aroused
	if(!aroused)
		my_kitsune.icon_state = my_kitsune.aroused_state
	else
		my_kitsune.icon_state = my_kitsune.icon_living
	my_kitsune.already_aroused = !aroused //инвертируется

/datum/action/innate/kitsune/Grant(mob/grant_to)
	. = ..()
	my_kitsune = grant_to

/mob/living/carbon/wendigo/kitsune/update_mobility()
	. = ..()
	transform = initial(transform)
	if(client && stat != DEAD)
		if(!CHECK_MOBILITY(src, MOBILITY_STAND))
			icon_state = current_lying_pose
		else
			icon_state = already_aroused ? "[aroused_state]" : "[icon_living]"
	regenerate_icons()

/mob/living/carbon/wendigo/kitsune/death(gibbed)
	. = ..()
	playsound(get_turf(src.loc), 'sound/magic/Repulse.ogg', 100, 1)

	src.ghostize(1, voluntary = TRUE)

	var/datum/effect_system/spark_spread/quantum/sparks = new
	sparks.set_up(10, 1, src)
	sparks.attach(src.loc)
	sparks.start()

	qdel(src)
