/obj/item/integrated_circuit/output
	category_text = "Вывод"

/obj/item/integrated_circuit/output/screen
	name = "screen"
	extended_desc = " используйте &lt;br&gt; чтобы начать новую строку"
	desc = "Принимает в качестве входных данных любой тип данных и отображает их пользователю после проверки."
	icon_state = "screen"
	inputs = list("отображаемые данные" = IC_PINTYPE_STRING)
	outputs = list()
	activators = list("загрузить данные" = IC_PINTYPE_PULSE_IN)
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

	return "Здесь находится [src][shown_label], который отображает [stuff_to_display ? "'[stuff_to_display]'" : "ничего"]."

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
	desc = "Принимает в качестве входных данных строковый тип и отображает его пользователю при просмотре, а при подаче импульса - всем существам, находящимся в непосредственной близости."
	icon_state = "screen_medium"
	power_draw_per_use = 20

/obj/item/integrated_circuit/output/screen/large/do_work()
	..()

	var/atom/host = assembly || src
	var/list/mobs = list()
	for(var/mob/M in viewers(2, host.loc))
		mobs += M
	to_chat(mobs, "<span class='notice'>[icon2html(host.icon, world, host.icon_state)] показывает сообщение: [stuff_to_display]</span>")
	host.investigate_log("displayed \"[html_encode(stuff_to_display)]\" as [type].", INVESTIGATE_CIRCUIT)

/obj/item/integrated_circuit/output/screen/extralarge // the subtype is called "extralarge" because tg brought back medium screens and they named the subtype /screen/large
	name = "large screen"
	desc = "Принимает строковый тип данных в качестве входных данных и отображает их пользователю при просмотре, а также всем находящимся поблизости существам при подаче импульса."
	icon_state = "screen_large"
	power_draw_per_use = 40
	cooldown_per_use = 10

/obj/item/integrated_circuit/output/screen/extralarge/do_work()
	..()
	var/atom/host = assembly || src
	var/list/mobs = list()
	for(var/mob/M in viewers(7, host.loc))
		mobs += M
	to_chat(mobs, "<span class='notice'>[icon2html(host.icon, world, host.icon_state)] показывает сообщение: [stuff_to_display]</span>")
	host.investigate_log("displayed \"[html_encode(stuff_to_display)]\" as [type].", INVESTIGATE_CIRCUIT)

/obj/item/integrated_circuit/output/light
	name = "light"
	desc = "Простой индикатор, который включается и выключается при подаче импульсного сигнала."
	icon_state = "light"
	complexity = 4
	inputs = list()
	outputs = list()
	activators = list("переключить свет" = IC_PINTYPE_PULSE_IN)
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
	desc = "Индикатор, который принимает шестнадцатеричное значение цвета и значение яркости, а также может включаться и выключаться с помощью импульсного сигнала."
	icon_state = "light_adv"
	complexity = 8
	inputs = list(
		"цвет" = IC_PINTYPE_COLOR,
		"яркость" = IC_PINTYPE_NUMBER
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
	desc = "К этой схеме прикреплен миниатюрный динамик."
	icon_state = "speaker"
	complexity = 8
	cooldown_per_use = 4 SECONDS
	inputs = list(
		"звуковой идентификатор" = IC_PINTYPE_STRING,
		"громкость" = IC_PINTYPE_NUMBER,
		"частота" = IC_PINTYPE_BOOLEAN
	)
	outputs = list()
	activators = list("проиграть звук" = IC_PINTYPE_PULSE_IN)
	power_draw_per_use = 10
	var/list/sounds = list()

/obj/item/integrated_circuit/output/sound/Initialize(mapload)
	.= ..()
	extended_desc = list()
	extended_desc += "Первый входной пин определяет, какой звук будет использоваться. Возможные варианты: "
	extended_desc += jointext(sounds, ", ")
	extended_desc += ". Второй пин определяет громкость звука."
	extended_desc += ", а третий определяет, будет ли частота звука меняться при каждом срабатывании."
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
	desc = "Принимает в качестве входных данных название звука и воспроизводит его при подаче импульса. В этой схеме доступно множество различных звуковых сигналов, писков и гудков."
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
	desc = "Принимает в качестве входного сигнала название звука и воспроизводит его при подаче импульса. Эта схема аналогична схемам, используемым в устройствах Securitron."
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
	desc = "Принимает в качестве входного сигнала название звука и воспроизводит его при подаче импульса. Такая схема часто используется в медицинских роботах."
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
	desc = "Принимает в качестве входного сигнала название звука и воспроизводит его при подаче импульса. Такая схема часто используется в системах голосовых объявлений с искусственным интеллектом."
	spawn_flags = IC_SPAWN_RESEARCH
	var/voice_type = "Female"

/obj/item/integrated_circuit/output/sound/vox/Initialize(mapload)
	sounds = GLOB.vox_types[voice_type]
	. = ..()
	extended_desc = "Первый входной пин определяет, какой звук будет использоваться. Он использует словарь AI Vox Broadcast. Поэтому либо попробуйте самостоятельно найти подходящие слова, либо попросите ИИ помочь вам в их подборе. Второй пин регулирует громкость воспроизводимого звука, а третий - определяет, будет ли частота звука меняться при каждой активации."

/obj/item/integrated_circuit/output/sound/vox/male
	name = "Male ai vox sound circuit"
	desc = "Принимает в качестве входного сигнала название звука и воспроизводит его при подаче импульса. Такая схема часто используется в системах голосовых объявлений с искусственным интеллектом."
	spawn_flags = IC_SPAWN_RESEARCH
	voice_type = "Male"

/obj/item/integrated_circuit/output/sound/vox/military
	name = "Military ai vox sound circuit"
	desc = "Принимает в качестве входного сигнала название звука и воспроизводит его при подаче импульса. Такая схема часто используется в системах голосовых объявлений с искусственным интеллектом."
	spawn_flags = IC_SPAWN_RESEARCH
	voice_type = "Military"

/obj/item/integrated_circuit/output/text_to_speech
	name = "text-to-speech circuit"
	desc = "Принимает любую строку в качестве входных данных и заставляет устройство произносить эту строку при подаче импульса."
	extended_desc = "Это устройство более совершенное, чем простая схема динамика, и способно преобразовывать любой допустимый текст в речь."
	icon_state = "speaker"
	cooldown_per_use = 10
	complexity = 12
	inputs = list("текст" = IC_PINTYPE_STRING)
	outputs = list()
	activators = list("в речь" = IC_PINTYPE_PULSE_IN)
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
	desc = "Принимает строку в качестве имени и логическое значение для определения, включена ли она, и использует эти данные для создания камеры, связанной со списком сетей, выбранных вами."
	extended_desc = "Камера подключена к выбранной вами сети камер. Чаще всего выбирают 'rd' для исследовательской сети, 'ss13' для сети главной станции (доступной для ИИ), 'mine' для горнодобывающей сети и 'thunder' для сети 'Thunderdome' (доступной из бара)."
	icon_state = "video_camera"
	w_class = WEIGHT_CLASS_TINY
	complexity = 10
	inputs = list(
		"имя камеры" = IC_PINTYPE_STRING,
		"активна ли камера" = IC_PINTYPE_BOOLEAN,
		"быстрый режим камеры" = IC_PINTYPE_BOOLEAN,
		"сеть камеры" = IC_PINTYPE_LIST
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
	desc = "Светодиод RGB. Принимает в качестве аргумента логическое значение, и если оно равно 'true', то при осмотре светодиод будет отображаться как горящий."
	extended_desc = "Значениями, эквивалентными TRUE, являются: непустые строки, числа, отличные от нуля, и допустимые ссылки."
	complexity = 0.1
	icon_state = "led"
	inputs = list(
		"горит?" = IC_PINTYPE_BOOLEAN,
		"цвет" = IC_PINTYPE_COLOR
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
	. = "Здесь "

	if(name == displayed_name)
		. += "[name]"
	else
		. += "["\improper[name]"] названное '[displayed_name]'"
	. += " который на данный момент [get_pin_data(IC_INPUT, 1) ? "горит <font color=[led_color]>*</font>" : "не горит"]."

/obj/item/integrated_circuit/output/diagnostic_hud
	name = "AR interface"
	desc = "Принимает в качестве входных данных имя значка и обновляет индикатор состояния при записи данных."
	extended_desc = "Принимает в качестве входных данных название значка и обновляет индикатор состояния при записи данных. Это означает, что он может изменить значок, и значок останется в таком виде даже после удаления схемы. Допустимые значения: 'alert', 'move', 'working', 'patrol', 'called' и 'heart'. Любое другое значение вернет значок в исходное состояние."
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
		"значок" = IC_PINTYPE_STRING
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


//Hippie Ported Code--------------------------------------------------------------------------------------------------------

/obj/item/radio/headset/integrated
