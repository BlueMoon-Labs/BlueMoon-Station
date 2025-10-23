/atom/movable/screen/shadekin
	name = "Элемент худа шедекина"
	icon = 'icons/mob/screen_shadekin.dmi'
	icon_state = ""

	var/mob/living/carbon/human/owner
	var/client/client_link
	var/is_active = TRUE
	//var/datum/hud/our_hud

/atom/movable/screen/shadekin/proc/death_with_parent(datum/source)
	SIGNAL_HANDLER
	owner = null

	if(!QDELETED(src))
		return
	qdel(src)
//Технически тут только одна ссылка, поэтому при убирании из screen будет мягкое удаление
/atom/movable/screen/shadekin/Destroy()
	if(client_link)
		client_link.screen -= src
		client_link = null

	if(!owner)
		return ..()
	UnregisterSignal(owner, list(
		COMSIG_PARENT_QDELETING,
		COMSIG_SHADEKIN_SCREENS_SHOW,
		COMSIG_SHADEKIN_SCREENS_HIDE,
		COMSIG_SHADEKIN_SCREEN_QDEL
	))
	DelUnregister()

	owner = null
	screen_loc = null

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

/atom/movable/screen/shadekin/proc/force_self_del(datum/source)
	SIGNAL_HANDLER
	if(!QDELETED(src))
		return
	qdel(src)

/atom/movable/screen/shadekin/proc/set_owner(client/client_to_append, mob/living/carbon/human/new_owner)
	owner = new_owner
	if(!client_to_append && !QDELETED(src))
		qdel(src)
	client_to_append.screen += src
	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(death_with_parent))
	RegisterSignal(owner, COMSIG_SHADEKIN_SCREENS_SHOW, PROC_REF(show_screen))
	RegisterSignal(owner, COMSIG_SHADEKIN_SCREENS_HIDE, PROC_REF(hide_screen))
	RegisterSignal(owner, COMSIG_SHADEKIN_SCREEN_QDEL, PROC_REF(force_self_del))
	SetRegister()

	on_gain()

/atom/movable/screen/shadekin/proc/on_gain()

/atom/movable/screen/shadekin/proc/SetRegister()

/atom/movable/screen/shadekin/proc/DelUnregister()
