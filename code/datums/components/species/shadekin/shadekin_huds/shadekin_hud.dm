/atom/movable/screen/shadekin
	name = "Элемент худа шедекина"
	icon = 'icons/mob/screen_shadekin.dmi'
	icon_state = ""

	var/mob/living/carbon/human/owner
	var/is_active = TRUE
	//var/datum/hud/our_hud

/atom/movable/screen/shadekin/proc/death_with_parent(datum/source)
	SIGNAL_HANDLER
	source = null
	owner = null

	if(!QDELETED(src))
		return
	qdel(src)

/atom/movable/screen/shadekin/Destroy()
	if(!owner)
		return ..()
	UnregisterSignal(owner, list(
		COMSIG_PARENT_QDELETING,
		COMSIG_SHADEKIN_SCREENS_SHOW,
		COMSIG_SHADEKIN_SCREENS_HIDE
	))
	DelUnregister()
	return ..()

/atom/movable/screen/shadekin/proc/show_screen(datum/source)
	SIGNAL_HANDLER
	invisibility = interact(invisibility)
	if(is_active)
		return
	is_active = TRUE
	SetRegister()

/atom/movable/screen/shadekin/proc/hide_screen(datum/source)
	SIGNAL_HANDLER
	invisibility = INVISIBILITY_ABSTRACT
	if(!is_active)
		return
	is_active = FALSE
	DelUnregister()

/atom/movable/screen/shadekin/proc/set_owner(mob/living/carbon/human/new_owner)
	owner = new_owner
	if(!owner.client && !QDELETED(src))
		qdel(src)
	owner.client.screen += src
	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(death_with_parent))
	RegisterSignal(owner, COMSIG_SHADEKIN_SCREENS_SHOW, PROC_REF(show_screen))
	RegisterSignal(owner, COMSIG_SHADEKIN_SCREENS_HIDE, PROC_REF(hide_screen))

	on_gain()

/atom/movable/screen/shadekin/proc/on_gain()

/atom/movable/screen/shadekin/proc/SetRegister()

/atom/movable/screen/shadekin/proc/DelUnregister()
