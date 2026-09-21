/obj/item/broadcast_camera
	name = "broadcast camera"
	desc = "A large camera that streams its live feed and audio to entertainment monitors across the station, allowing everyone to watch the broadcast."
	icon = 'modular_bluemoon/icons/obj/service/broadcast.dmi'
	icon_state = "broadcast_cam0"
	base_icon_state = "broadcast_cam"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	slot_flags = NONE
	light_system = OVERLAY_LIGHT
	light_color = COLOR_SOFT_RED
	light_range = 1
	light_power = 0.3
	light_on = FALSE
	var/active = FALSE
	var/active_microphone = TRUE
	var/broadcast_name = "Fink News"

/obj/item/broadcast_camera/update_icon_state()
	icon_state = "[base_icon_state][active]"
	return ..()

/obj/item/broadcast_camera/attack_self(mob/user, modifiers)
	. = ..()
	active = !active
	update_icon_state()
	if(active)
		set_light_on(TRUE)
		playsound(source = src, soundin = 'modular_bluemoon/sound/machines/terminal/terminal_processing.ogg', vol = 20, vary = FALSE, ignore_walls = FALSE)
		balloon_alert_to_viewers("live!")
	else
		set_light_on(FALSE)
		playsound(source = src, soundin = 'modular_bluemoon/sound/machines/terminal/terminal_prompt_deny.ogg', vol = 20, vary = FALSE, ignore_walls = FALSE)
		balloon_alert_to_viewers("offline")

/obj/item/broadcast_camera/AltClick(mob/user)
	broadcast_name = tgui_input_text(user = user, title = "Broadcast Name", message = "What will be the name of your broadcast?", default = "[broadcast_name]", max_length = MAX_CHARTER_LEN)

/obj/item/broadcast_camera/examine(mob/user)
	. = ..()
	. += span_notice("Broadcast name is <b>[broadcast_name]</b>")
	. += span_notice("The microphone is <b>[active_microphone ? "On" : "Off"]</b>")

/obj/item/broadcast_camera/on_enter_storage()
	. = ..()
	if(active)
		active = FALSE
		update_icon_state()
		set_light_on(FALSE)

/obj/item/broadcast_camera/dropped(mob/user, silent)
	. = ..()
	if(active)
		active = FALSE
		update_icon_state()
		set_light_on(FALSE)

/* добавим в карго и куратору раундстарт, когда доделаем tg систему вещания
/obj/item/broadcast_camera/cargo
	slowdown = 0.3
	item_flags = parent_type::item_flags | SLOWS_WHILE_IN_HAND
	broadcast_name = "Camera Broadcast"
*/

/obj/item/radio/microphone
	name = "microphone"
	desc = "A microphone used for broadcasting."
	icon = 'modular_bluemoon/icons/obj/service/broadcast.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/devices_righthand.dmi'
	icon_state = "microphone"
	canhear_range = 3
