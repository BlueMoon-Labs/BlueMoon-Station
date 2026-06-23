/obj/item/integrated_circuit/output
	category_text = "Output"

/obj/item/integrated_circuit/output/screen
	name = "screen"
	extended_desc = " use &lt;br&gt; to start a new line"
	desc = "Takes any data type as an input, and displays it to the user upon examining."
	icon_state = "screen"
	inputs = list("displayed data" = IC_PINTYPE_STRING)
	outputs = list()
	activators = list("load data" = IC_PINTYPE_PULSE_IN)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 10
	var/eol = "&lt;br&gt;"
	var/stuff_to_display = null

/obj/item/integrated_circuit/output/screen/disconnect_all()
	..()
	stuff_to_display = null

/obj/item/integrated_circuit/output/screen/power_fail()
	. = ..()
	stuff_to_display = null

/obj/item/integrated_circuit/output/screen/any_examine(mob/user)
	var/shown_label = ""
	if(displayed_name && displayed_name != name)
		shown_label = " labeled '[displayed_name]'"

	return "There is \a [src][shown_label], which displays [stuff_to_display ? "'[stuff_to_display]'" : "nothing"]."

/obj/item/integrated_circuit/output/screen/do_work()
	var/datum/integrated_io/I = inputs[1]
	if(isweakref(I.data))
		var/datum/d = I.data_as_type(/datum)
		if(d)
			stuff_to_display = "[d]"
	else
		stuff_to_display = replacetext("[I.data]", eol , "<br>")

/obj/item/integrated_circuit/output/screen/large
	name = "medium screen"
	desc = "Takes string data type as an input and displays it to the user upon examining, and to all nearby beings in a small area when pulsed."
	icon_state = "screen_medium"
	power_draw_per_use = 20

/obj/item/integrated_circuit/output/screen/large/do_work()
	..()

	var/atom/host = assembly || src
	var/list/mobs = list()
	for(var/mob/M in viewers(2, host.loc))
		mobs += M
	to_chat(mobs, "<span class='notice'>[icon2html(host.icon, world, host.icon_state)] flashes a message: [stuff_to_display]</span>")
	host.investigate_log("displayed \"[html_encode(stuff_to_display)]\" as [type].", INVESTIGATE_CIRCUIT)

/obj/item/integrated_circuit/output/screen/extralarge // the subtype is called "extralarge" because tg brought back medium screens and they named the subtype /screen/large
	name = "large screen"
	desc = "Takes string data type as an input and displays it to the user upon examining, and to all nearby beings when pulsed."
	icon_state = "screen_large"
	power_draw_per_use = 40
	cooldown_per_use = 10

/obj/item/integrated_circuit/output/screen/extralarge/do_work()
	..()
	var/atom/host = assembly || src
	var/list/mobs = list()
	for(var/mob/M in viewers(7, host.loc))
		mobs += M
	to_chat(mobs, "<span class='notice'>[icon2html(host.icon, world, host.icon_state)] flashes a message: [stuff_to_display]</span>")
	host.investigate_log("displayed \"[html_encode(stuff_to_display)]\" as [type].", INVESTIGATE_CIRCUIT)

/obj/item/integrated_circuit/output/light
	name = "light"
	desc = "A basic light which can be toggled on/off when pulsed."
	icon_state = "light"
	complexity = 4
	inputs = list()
	outputs = list()
	activators = list("toggle light" = IC_PINTYPE_PULSE_IN)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/light_toggled = 0
	var/light_brightness = 3
	var/light_rgb = "#FFFFFF"
	power_draw_idle = 0 // Adjusted based on brightness.

/obj/item/integrated_circuit/output/light/do_work()
	light_toggled = !light_toggled
	update_lighting()

/obj/item/integrated_circuit/output/light/proc/update_lighting()
	if(light_toggled)
		if(assembly)
			assembly.set_light(l_range = light_brightness, l_power = 1, l_color = light_rgb)
	else
		if(assembly)
			assembly.set_light(0)
	power_draw_idle = light_toggled ? light_brightness * 2 : 0

/obj/item/integrated_circuit/output/light/power_fail() // Turns off the flashlight if there's no power left.
	light_toggled = FALSE
	update_lighting()

/obj/item/integrated_circuit/output/light/disconnect_all()
	light_toggled = FALSE
	update_lighting()
	. = ..()

/obj/item/integrated_circuit/output/light/advanced
	name = "advanced light"
	desc = "A light that takes a hexadecimal color value and a brightness value, and can be toggled on/off by pulsing it."
	icon_state = "light_adv"
	complexity = 8
	inputs = list(
		"color" = IC_PINTYPE_COLOR,
		"brightness" = IC_PINTYPE_NUMBER
	)
	outputs = list()
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/output/light/advanced/on_data_written()
	update_lighting()

/obj/item/integrated_circuit/output/light/advanced/update_lighting()
	var/new_color = get_pin_data(IC_INPUT, 1)
	var/brightness = get_pin_data(IC_INPUT, 2)

	if(new_color && isnum(brightness))
		brightness = clamp(brightness, 0, 10)
		light_rgb = new_color
		light_brightness = brightness

	..()

/obj/item/integrated_circuit/output/sound
	name = "speaker circuit"
	desc = "A miniature speaker is attached to this component."
	icon_state = "speaker"
	complexity = 8
	cooldown_per_use = 4 SECONDS
	inputs = list(
		"sound ID" = IC_PINTYPE_STRING,
		"volume" = IC_PINTYPE_NUMBER,
		"frequency" = IC_PINTYPE_BOOLEAN
	)
	outputs = list()
	activators = list("play sound" = IC_PINTYPE_PULSE_IN)
	power_draw_per_use = 10
	var/list/sounds = list()

/obj/item/integrated_circuit/output/sound/Initialize(mapload)
	.= ..()
	extended_desc = list()
	extended_desc += "The first input pin determines which sound is used. The choices are; "
	extended_desc += jointext(sounds, ", ")
	extended_desc += ". The second pin determines the volume of sound that is played"
	extended_desc += ", and the third determines if the frequency of the sound will vary with each activation."
	extended_desc = jointext(extended_desc, null)

/obj/item/integrated_circuit/output/sound/do_work()
	var/ID = get_pin_data(IC_INPUT, 1)
	var/vol = get_pin_data(IC_INPUT, 2)
	var/freq = get_pin_data(IC_INPUT, 3)
	if(!isnull(ID) && !isnull(vol))
		var/selected_sound = sounds[ID]
		if(!selected_sound)
			return
		vol = clamp(vol ,0 , 100)
		playsound(get_turf(src), selected_sound, vol, freq, -1)
		var/atom/A = get_object()
		A.investigate_log("played a sound ([selected_sound]) as [type].", INVESTIGATE_CIRCUIT)

/obj/item/integrated_circuit/output/sound/on_data_written()
	power_draw_per_use =  get_pin_data(IC_INPUT, 2) * 15

/obj/item/integrated_circuit/output/sound/beeper
	name = "beeper circuit"
	desc = "Takes a sound name as an input, and will play said sound when pulsed. This circuit has a variety of beeps, boops, and buzzes to choose from."
	sounds = list(
		"beep"			= 'sound/machines/twobeep.ogg',
		"chime"			= 'sound/machines/chime.ogg',
		"buzz sigh"		= 'sound/machines/buzz-sigh.ogg',
		"buzz twice"	= 'sound/machines/buzz-two.ogg',
		"ping"			= 'sound/machines/ping.ogg',
		"synth yes"		= 'sound/machines/synth_yes.ogg',
		"synth no"		= 'sound/machines/synth_no.ogg',
		"warning buzz"	= 'sound/machines/warning-buzzer.ogg'
		)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/output/sound/beepsky
	name = "securitron sound circuit"
	desc = "Takes a sound name as an input, and will play said sound when pulsed. This circuit is similar to those used in Securitrons."
	sounds = list(
		"creep"			= 'sound/voice/beepsky/creep.ogg',
		"criminal"		= 'sound/voice/beepsky/criminal.ogg',
		"freeze"		= 'sound/voice/beepsky/freeze.ogg',
		"god"			= 'sound/voice/beepsky/god.ogg',
		"i am the law"	= 'sound/voice/beepsky/iamthelaw.ogg',
		"insult"		= 'sound/voice/beepsky/insult.ogg',
		"radio"			= 'sound/voice/beepsky/radio.ogg',
		"secure day"	= 'sound/voice/beepsky/secureday.ogg',
		)
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/output/sound/medbot
	name = "medbot sound circuit"
	desc = "Takes a sound name as an input, and will play said sound when pulsed. This circuit is often found in medical robots."
	sounds = list(
		"surgeon"		= 'sound/voice/medbot/surgeon.ogg',
		"radar"			= 'sound/voice/medbot/radar.ogg',
		"feel better"	= 'sound/voice/medbot/feelbetter.ogg',
		"patched up"	= 'sound/voice/medbot/patchedup.ogg',
		"injured"		= 'sound/voice/medbot/injured.ogg',
		"insult"		= 'sound/voice/medbot/insult.ogg',
		"coming"		= 'sound/voice/medbot/coming.ogg',
		"help"			= 'sound/voice/medbot/help.ogg',
		"live"			= 'sound/voice/medbot/live.ogg',
		"lost"			= 'sound/voice/medbot/lost.ogg',
		"flies"			= 'sound/voice/medbot/flies.ogg',
		"catch"			= 'sound/voice/medbot/catch.ogg',
		"delicious"		= 'sound/voice/medbot/delicious.ogg',
		"apple"			= 'sound/voice/medbot/apple.ogg',
		"no"			= 'sound/voice/medbot/no.ogg',
		)
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/output/sound/vox
	name = "Female ai vox sound circuit"
	desc = "Takes a sound name as an input, and will play said sound when pulsed. This circuit is often found in AI announcement systems."
	spawn_flags = IC_SPAWN_RESEARCH
	var/voice_type = "Female"

/obj/item/integrated_circuit/output/sound/vox/Initialize(mapload)
	sounds = GLOB.vox_types[voice_type]
	. = ..()
	extended_desc = "The first input pin determines which sound is used. It uses the AI Vox Broadcast word list. So either experiment to find words that work, or ask the AI to help in figuring them out. The second pin determines the volume of sound that is played, and the third determines if the frequency of the sound will vary with each activation."

/obj/item/integrated_circuit/output/sound/vox/male
	name = "Male ai vox sound circuit"
	desc = "Takes a sound name as an input, and will play said sound when pulsed. This circuit is often found in AI announcement systems."
	spawn_flags = IC_SPAWN_RESEARCH
	voice_type = "Male"

/obj/item/integrated_circuit/output/sound/vox/military
	name = "Military ai vox sound circuit"
	desc = "Takes a sound name as an input, and will play said sound when pulsed. This circuit is often found in AI announcement systems."
	spawn_flags = IC_SPAWN_RESEARCH
	voice_type = "Military"

/obj/item/integrated_circuit/output/text_to_speech
	name = "text-to-speech circuit"
	desc = "Takes any string as an input and will make the device say the string when pulsed."
	extended_desc = "This unit is more advanced than the plain speaker circuit, able to transpose any valid text to speech."
	icon_state = "speaker"
	cooldown_per_use = 10
	complexity = 12
	inputs = list("text" = IC_PINTYPE_STRING)
	outputs = list()
	activators = list("to speech" = IC_PINTYPE_PULSE_IN)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 60

/obj/item/integrated_circuit/output/text_to_speech/do_work()
	text = get_pin_data(IC_INPUT, 1)
	if(!isnull(text))
		var/atom/movable/A = get_object()
		var/sanitized_text = sanitize(text)
		A.say(sanitized_text)
		if (assembly)
			log_say("[assembly] [REF(assembly)] : [sanitized_text]")
		else
			log_say("[name] ([type]) : [sanitized_text]")

/obj/item/integrated_circuit/output/video_camera
	name = "video camera circuit"
	desc = "Takes a string as a name and a boolean to determine whether it is on, and uses this to be a camera linked to a list of networks you choose."
	extended_desc = "The camera is linked to a list of camera networks of your choosing. Common choices are 'rd' for the research network, 'ss13' for the main station network (visible to AI), 'mine' for the mining network, and 'thunder' for the thunderdome network (viewable from bar)."
	icon_state = "video_camera"
	w_class = WEIGHT_CLASS_TINY
	complexity = 10
	inputs = list(
		"camera name" = IC_PINTYPE_STRING,
		"camera active" = IC_PINTYPE_BOOLEAN,
		"camera fast mode" = IC_PINTYPE_BOOLEAN,
		"camera network" = IC_PINTYPE_LIST
		)
	inputs_default = list("1" = "video camera circuit", "4" = list("rd"))
	outputs = list()
	activators = list()
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_LONG_RANGE
	power_draw_idle = 0 // Raises to 20 when on.
	var/obj/machinery/camera/camera
	var/updating = FALSE

	var/update_speed = 10 // How often to update the camera

/obj/item/integrated_circuit/output/video_camera/New()
	..()
	camera = new(src)
	camera.network = list("rd")
	on_data_written()

/obj/item/integrated_circuit/output/video_camera/Destroy()
	QDEL_NULL(camera)
	return ..()

/obj/item/integrated_circuit/output/video_camera/proc/set_camera_status(status)
	if(camera)
		camera.status = status
		GLOB.cameranet.updatePortableCamera(camera)
		power_draw_idle = camera.status ? (20 / (update_speed * 0.1)) : 0
		if(camera.status) // Ensure that there's actually power.
			if(!draw_idle_power())
				power_fail()

/obj/item/integrated_circuit/output/video_camera/on_data_written()
	if(camera)
		var/cam_name = get_pin_data(IC_INPUT, 1)
		var/cam_active = get_pin_data(IC_INPUT, 2)
		update_speed = get_pin_data(IC_INPUT, 3) ? 5 : 10
		var/list/new_network = get_pin_data(IC_INPUT, 4)
		if(!isnull(cam_name))
			camera.c_tag = cam_name
		if(!isnull(new_network))
			camera.network = new_network
		set_camera_status(cam_active)

/obj/item/integrated_circuit/output/video_camera/power_fail()
	if(camera)
		set_camera_status(0)
		set_pin_data(IC_INPUT, 2, FALSE)

/obj/item/integrated_circuit/output/video_camera/disconnect_all()
	if(camera)
		set_camera_status(0)
		set_pin_data(IC_INPUT, 2, FALSE)
	. = ..()

/obj/item/integrated_circuit/output/video_camera/ext_moved(oldLoc, dir)
	. = ..()
	update_camera_location(oldLoc)

/obj/item/integrated_circuit/output/video_camera/proc/update_camera_location(oldLoc)
	oldLoc = get_turf(oldLoc)
	if(!QDELETED(camera) && !updating && oldLoc != get_turf(src))
		updating = TRUE
		addtimer(CALLBACK(src, PROC_REF(do_camera_update), oldLoc), update_speed)

/obj/item/integrated_circuit/output/video_camera/proc/do_camera_update(oldLoc)
	if(!QDELETED(camera) && oldLoc != get_turf(src))
		GLOB.cameranet.updatePortableCamera(camera)
	updating = FALSE

/obj/item/integrated_circuit/output/led
	name = "light-emitting diode"
	desc = "RGB LED. Takes a boolean value in, and if the boolean value is 'true-equivalent', the LED will be marked as lit on examine."
	extended_desc = "TRUE-equivalent values are: Non-empty strings, non-zero numbers, and valid refs."
	complexity = 0.1
	icon_state = "led"
	inputs = list(
		"lit" = IC_PINTYPE_BOOLEAN,
		"color" = IC_PINTYPE_COLOR
	)
	outputs = list()
	activators = list()
	inputs_default = list(
		"2" = "#FF0000"
	)
	power_draw_idle = 0 // Raises to 1 when lit.
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/led_color = "#FF0000"

/obj/item/integrated_circuit/output/led/on_data_written()
	power_draw_idle = get_pin_data(IC_INPUT, 1) ? 1 : 0
	led_color = get_pin_data(IC_INPUT, 2)

/obj/item/integrated_circuit/output/led/power_fail()
	set_pin_data(IC_INPUT, 1, FALSE)

/obj/item/integrated_circuit/output/led/disconnect_all()
	set_pin_data(IC_INPUT, 1, FALSE)
	. = ..()

/obj/item/integrated_circuit/output/led/external_examine(mob/user)
	. = "There is "

	if(name == displayed_name)
		. += "\an [name]"
	else
		. += "\an ["\improper[name]"] labeled '[displayed_name]'"
	. += " which is currently [get_pin_data(IC_INPUT, 1) ? "lit <font color=[led_color]>*</font>" : "unlit"]."

/obj/item/integrated_circuit/output/diagnostic_hud
	name = "AR interface"
	desc = "Takes an icon name as an input, and will update the status hud when data is written to it."
	extended_desc = "Takes an icon name as an input, and will update the status hud when data is written to it, this means it can change the icon and have the icon stay that way even if the circuit is removed. The acceptable inputs are 'alert', 'move', 'working', 'patrol', 'called', and 'heart'. Any input other than that will return the icon to its default state."
	var/list/icons = list(
		"alert" = "hudalert",
		"move" = "hudmove",
		"working" = "hudworkingleft",
		"patrol" = "hudpatrolleft",
		"called" = "hudcalledleft",
		"heart" = "hudsentientleft"
		)
	complexity = 1
	icon_state = "led"
	inputs = list(
		"icon" = IC_PINTYPE_STRING
	)
	outputs = list()
	activators = list()
	power_draw_idle = 0
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/output/diagnostic_hud/on_data_written()
	var/ID = get_pin_data(IC_INPUT, 1)
	var/selected_icon = icons[ID]
	if(assembly)
		if(selected_icon)
			assembly.prefered_hud_icon = selected_icon
		else
			assembly.prefered_hud_icon = "hudstat"
		//update the diagnostic hud
		assembly.diag_hud_set_circuitstat()

/obj/item/integrated_circuit/output/neural_interface_log_write
	name = "HUD interface write log"
	desc = "A component responsible for outputting logs to the user's HUD interface (if available)"
	extended_desc = "The component is responsible for outputting logs to the user's HUD interface (if present). The interface target can be a reference to an entity with the interface, or a reference to the interface itself. The log type is sent as a key, from the available colored options: SYSTEM, WARNING, ERROR, INFO, DATA, SYNC, HEALTH, MODULE, ALERT, STATUS, DEBUG"
	complexity = 1
	size = 0.1
	icon_state = "video_camera"
	inputs = list(
		"target_interface" = IC_PINTYPE_REF,
		"text" = IC_PINTYPE_STRING,
		"key"  = IC_PINTYPE_STRING,
		"color" = IC_PINTYPE_COLOR,
		"size" = IC_PINTYPE_NUMBER
	)
	activators = list(
		"pulse in" = IC_PINTYPE_PULSE_IN,
		"on success" = IC_PINTYPE_PULSE_OUT,
		"on failure" = IC_PINTYPE_PULSE_OUT
	)
	outputs = list()
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 2

/obj/item/integrated_circuit/output/neural_interface_log_write/do_work(ord)
	var/atom/relay_interface = get_pin_data(IC_INPUT, 1)
	var/text = get_pin_data(IC_INPUT, 2)
	var/key = get_pin_data(IC_INPUT, 3)
	var/color = get_pin_data(IC_INPUT, 4)
	var/size = get_pin_data(IC_INPUT, 5)

	if(!relay_interface || !text || !key)
		activate_pin(3)
		return

	if(get_dist(get_turf(src),get_turf(relay_interface)) > 8)
		activate_pin(3)
		return

	var/result = SEND_SIGNAL(relay_interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, text, key, color, size)
	if(!result)
		activate_pin(3)
		return

	activate_pin(2)

/obj/item/integrated_circuit/output/neural_interface_data_write
	name = "HUD interface write data"
	desc = "A component responsible for displaying key and value information in the user's HUD interface (if present)."
	extended_desc = "A component responsible for displaying key and value information in the user's HUD interface (if present). The interface target can be either a reference to an entity with an interface or a reference to the interface itself. Unlike logs, when entering information for the same key, the information will be updated rather than appended."
	complexity = 1
	size = 0.1
	icon_state = "video_camera"
	inputs = list(
		"target_interface" = IC_PINTYPE_REF,
		"key" = IC_PINTYPE_STRING,
		"value"  = IC_PINTYPE_STRING,
		"decay duration"  = IC_PINTYPE_NUMBER,
	)
	activators = list(
		"pulse in" = IC_PINTYPE_PULSE_IN,
		"on success" = IC_PINTYPE_PULSE_OUT,
		"on failure" = IC_PINTYPE_PULSE_OUT
	)
	outputs = list()
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 2

/obj/item/integrated_circuit/output/neural_interface_data_write/do_work(ord)
	var/atom/relay_interface = get_pin_data(IC_INPUT, 1)
	var/key = get_pin_data(IC_INPUT, 2)
	var/value = get_pin_data(IC_INPUT, 3)
	var/decay_duration = get_pin_data(IC_INPUT, 4)

	if(!relay_interface || !key || !value)
		activate_pin(3)
		return

	if(get_dist(get_turf(src),get_turf(relay_interface)) > 8)
		activate_pin(3)
		return

	if(!decay_duration)
		decay_duration = 1 SECONDS

	var/result = SEND_SIGNAL(relay_interface, COMSIG_NEURAL_INTERFACE_WRITE_DATA, key, value, decay_duration)

	if(!result)
		activate_pin(3)
		return

	activate_pin(2)

/obj/item/integrated_circuit/output/neural_interface_image_data_write
	name = "HUD interface write image data"
	desc = "A component responsible for displaying visual information with a caption on a target in the user's HUD interface (if present)."
	extended_desc = "A component responsible for displaying visual information with a caption on a target in the user's HUD interface (if present). The interface target can be a reference to an entity with the interface, or a reference to the interface itself. The target for displaying visual information is a reference to an existing object in the world. A key is required to display specific information; if overlays with the same key are placed on two targets, the first will be removed and the second will be overlaid. An offset is required for the displayed text. Available overlays for output: target, circle, aiming, cross, warning, noise, scan, eye, target_conf, none"
	complexity = 1
	size = 0.1
	icon_state = "video_camera"
	inputs = list(
		"target_interface" = IC_PINTYPE_REF,
		"target" = IC_PINTYPE_REF,
		"key" = IC_PINTYPE_STRING,
		"text"  = IC_PINTYPE_STRING,
		"decay duration"  = IC_PINTYPE_NUMBER,
		"shift_x" = IC_PINTYPE_NUMBER,
		"shift_y" = IC_PINTYPE_NUMBER,
		"icon" = IC_PINTYPE_STRING,
		"color" = IC_PINTYPE_COLOR,
		"text_size" = IC_PINTYPE_NUMBER,
	)
	activators = list(
		"pulse in" = IC_PINTYPE_PULSE_IN,
		"on success" = IC_PINTYPE_PULSE_OUT,
		"on failure" = IC_PINTYPE_PULSE_OUT
	)
	outputs = list()
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 5
	var/list/icons = list(
		"target",
		"circle",
		"aiming",
		"cross",
		"warning",
		"noise",
		"scan",
		"eye",
		"target_conf",
		"none"
	)
	var/icon/overlay

/obj/item/integrated_circuit/output/neural_interface_image_data_write/Initialize(mapload)
	. = ..()
	overlay = new(icon='icons/effects/neural_interface_overlays.dmi')
	overlay.GrayScale()

/obj/item/integrated_circuit/output/neural_interface_image_data_write/Destroy()
	overlay = null
	. = ..()

/obj/item/integrated_circuit/output/neural_interface_image_data_write/do_work(ord)
	var/atom/relay_interface = get_pin_data(IC_INPUT, 1)
	var/atom/target = get_pin_data(IC_INPUT, 2)
	var/key = get_pin_data(IC_INPUT, 3)
	var/text = get_pin_data(IC_INPUT, 4)
	var/decay_duration = get_pin_data(IC_INPUT, 5)
	var/shift_x = get_pin_data(IC_INPUT, 6)
	var/shift_y = get_pin_data(IC_INPUT, 7)
	var/icon_state_overlay = get_pin_data(IC_INPUT, 8)
	var/color_overlay = get_pin_data(IC_INPUT, 9)
	var/text_size = get_pin_data(IC_INPUT, 10)

	if(!shift_x)
		shift_x = 0

	if(!shift_y)
		shift_y = 0

	if(!text_size)
		text_size = 12

	if(!color_overlay)
		color_overlay = "#00fff2"

	if(!icon_state_overlay)
		icon_state_overlay = "circle"

	if(!icons.Find(icon_state_overlay))
		activate_pin(3)
		return

	if(!relay_interface || !target || !key)
		activate_pin(3)
		return

	if(get_dist(get_turf(src),get_turf(relay_interface)) > 8)
		activate_pin(3)
		return

	if(get_dist(get_turf(src),get_turf(target)) > 8)
		activate_pin(3)
		return

	if(!decay_duration)
		decay_duration = 1 SECONDS

	var/image/overlay_image = image(icon = overlay, icon_state=icon_state_overlay)
	overlay_image.color = color_overlay
	var/result = SEND_SIGNAL(relay_interface, COMSIG_NEURAL_INTERFACE_WRITE_IMAGE_DATA, key, overlay_image, target, text, decay_duration, shift_x, shift_y, text_size)

	if(!result)
		activate_pin(3)
		return

	activate_pin(2)

//Hippie Ported Code--------------------------------------------------------------------------------------------------------

/obj/item/radio/headset/integrated
