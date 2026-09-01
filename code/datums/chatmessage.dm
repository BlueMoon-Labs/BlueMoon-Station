/// How long the chat message's spawn-in animation will occur for
#define CHAT_MESSAGE_SPAWN_TIME		0.2 SECONDS
/// How long the chat message will exist prior to any exponential decay
#define CHAT_MESSAGE_LIFESPAN		5 SECONDS
/// How long the chat message's end of life fading animation will occur for
#define CHAT_MESSAGE_EOL_FADE		0.7 SECONDS
/// Factor of how much the message index (number of messages) will account to exponential decay
#define CHAT_MESSAGE_EXP_DECAY		0.7
/// Factor of how much height will account to exponential decay
#define CHAT_MESSAGE_HEIGHT_DECAY	0.9
/// Approximate height in pixels of an 'average' line, used for height decay
#define CHAT_MESSAGE_APPROX_LHEIGHT	11
/// Max width of chat message in pixels
#define CHAT_MESSAGE_WIDTH			96
/// Max length of chat message in characters
#define CHAT_MESSAGE_MAX_LENGTH		110
/// The dimensions of the chat message icons
#define CHAT_MESSAGE_ICON_SIZE 9
/// Maximum precision of float before rounding errors occur (in this context)
#define CHAT_LAYER_Z_STEP			0.0001
/// The number of z-layer 'slices' usable by the chat message layering
#define CHAT_LAYER_MAX_Z			(CHAT_LAYER_MAX - CHAT_LAYER) / CHAT_LAYER_Z_STEP

#define RUNECHAT_ANIM_NONE			0
#define RUNECHAT_ANIM_RISE			1
#define RUNECHAT_ANIM_TYPEWRITER	2
#define CHAT_MESSAGE_RISE_OFFSET	8
#define CHAT_MESSAGE_RISE_TIME		0.4 SECONDS
#define CHAT_MESSAGE_TYPING_TIME	2 SECONDS
/**
 * Сколько КАДРОВ печатной машинки рисуется за это время.
 *
 * Каждое присваивание maptext - отдельная растровая поверхность у клиента размером
 * maptext_width * maptext_height * 4 байта, и живёт она столько же, сколько appearance,
 * в который попала. Раньше шаг равнялся world.tick_lag, то есть одна реплика давала СОРОК
 * уникальных поверхностей вместо одной: текст-то на каждом кадре разный.
 *
 * Потолок в восемь кадров сохраняет и длительность анимации, и саму печатную машинку -
 * шаг просто становится крупнее, - но режет число поверхностей впятеро.
 */
#define CHAT_MESSAGE_TYPEWRITER_MAX_FRAMES	8

/**
  * # Chat Message Overlay
  *
  * Datum for generating a message overlay on the map
  */
/datum/chatmessage
	/// The visual element of the chat messsage
	var/image/message
	/// The location in which the message is appearing
	var/atom/message_loc
	/// The client who heard this message
	var/client/owned_by
	/// Contains the scheduled destruction time, used for scheduling EOL
	var/scheduled_destruction
	/// Contains the time that the EOL for the message will be complete, used for qdel scheduling
	var/eol_complete
	/// Contains the approximate amount of lines for height decay
	var/approx_lines
	/// Contains the reference to the next chatmessage in the bucket, used by runechat subsystem
	var/datum/chatmessage/next
	/// Contains the reference to the previous chatmessage in the bucket, used by runechat subsystem
	var/datum/chatmessage/prev
	/// TRUE while this message is registered in SSrunechat
	var/in_runechat_queue = FALSE
	/// TRUE if SSrunechat currently stores this message in second_queue instead of buckets
	var/in_runechat_second_queue = FALSE
	/// Индекс бакета SSrunechat, в который сообщение положили при вставке. BUCKET_POS_NONE, если оно не в колесе.
	/// Пересчитать по scheduled_destruction нельзя: head_offset прыгает вперёд на целое колесо,
	/// а сообщение остаётся лежать в своём слоте. См. тот же var/bucket_pos у /datum/timedevent.
	var/runechat_bucket_pos = BUCKET_POS_NONE
	/// TRUE once we have inserted into owned_by.seen_messages
	var/in_seen_messages = FALSE
	/// TRUE once we have inserted the image into owned_by.images
	var/in_client_images = FALSE
	/// The current index used for adjusting the layer of each sequential chat message such that recent messages will overlay older ones
	var/static/current_z_idx = 0
	/// Current logical integer pixel_y of the message, kept whole to avoid subpixel text rendering
	var/current_y = 0

/**
  * Constructs a chat message overlay
  *
  * Arguments:
  * * text - The text content of the overlay
  * * target - The target atom to display the overlay at
  * * owner - The mob that owns this overlay, only this mob will be able to view it
  * * language - The language this message was spoken in
  * * extra_classes - Extra classes to apply to the span that holds the text
  * * lifespan - The lifespan of the message in deciseconds
  */
/datum/chatmessage/New(text, atom/target, mob/owner, datum/language/language, list/extra_classes = list(), lifespan = CHAT_MESSAGE_LIFESPAN)
	. = ..()
	if (!istype(target))
		CRASH("Invalid target given for chatmessage")
	if(QDELETED(owner) || !istype(owner) || !owner.client)
		stack_trace("/datum/chatmessage created with [isnull(owner) ? "null" : "invalid"] mob owner")
		qdel(src)
		return
	INVOKE_ASYNC(src, PROC_REF(generate_image), text, target, owner, language, extra_classes, lifespan)

/datum/chatmessage/Destroy()
	if (owned_by)
		UnregisterSignal(owned_by, COMSIG_PARENT_QDELETING)
		if (in_seen_messages && owned_by.seen_messages)
			LAZYREMOVEASSOC(owned_by.seen_messages, message_loc, src)
			in_seen_messages = FALSE
		if (in_client_images && message)
			owned_by.images.Remove(message)
			in_client_images = FALSE
	owned_by = null
	if(in_runechat_queue)
		leave_subsystem()
	else
		prev = next = null
	message_loc = null
	message = null
	return ..()

/**
  * Calls qdel on the chatmessage when its parent is deleted, used to register qdel signal
  */
/datum/chatmessage/proc/on_parent_qdel()
	qdel(src)

/**
  * Generates a chat message image representation
  *
  * Arguments:
  * * text - The text content of the overlay
  * * target - The target atom to display the overlay at
  * * owner - The mob that owns this overlay, only this mob will be able to view it
  * * language - The language this message was spoken in
  * * extra_classes - Extra classes to apply to the span that holds the text
  * * lifespan - The lifespan of the message in deciseconds
  */
/datum/chatmessage/proc/generate_image(text, atom/target, mob/owner, datum/language/language, list/extra_classes, lifespan)
	/// Cached icons to show what language the user is speaking
	var/static/list/language_icons

	// Register client who owns this message
	owned_by = owner.client
	if(!owned_by)
		return
	if(isnull(target) || QDELETED(target))
		qdel(src)
		return
	RegisterSignal(owned_by, COMSIG_PARENT_QDELETING, PROC_REF(on_parent_qdel))

	// Clip message
	var/maxlen = owned_by.prefs.max_chat_length
	if (length_char(text) > maxlen)
		text = copytext_char(text, 1, maxlen + 1) + "..." // BYOND index moment

	//SKYRAT CHANGES BEGIND
	// Цвет по умолчанию выводится из имени и лежит в общем кэше: одинаковые имена дают
	// одинаковый цвет, и держать его копию на каждом атоме мира незачем. Личный цвет,
	// назначенный вручную (режимы модульной лазерной винтовки), перебивает кэш и живёт
	// на самом атоме - но только на движимом, турфы своим цветом не говорят.
	var/target_color
	var/manual_color = FALSE
	if(ismovable(target))
		var/atom/movable/movable_target = target
		target_color = movable_target.chat_color
		// Именно непустота, а не !isnull: chat_color = "" - легальный вареедит, и цвет для
		// такого атома всё равно берётся из общего кэша. Считать его ручным значило бы
		// платить color_shift() на каждое курсивное сообщение и никогда не наполнять кэш.
		manual_color = !!target_color
	if(!target_color)
		target_color = GLOB.runechat_color_names[target.name]
	if(!target_color)
		var/mob/speaker = target
		if (ismob(target) && speaker.client?.prefs?.enable_personal_chat_color && speaker.name == speaker.real_name && speaker.name == speaker.client.prefs.real_name)
			target_color = speaker.client.prefs.personal_chat_color
			GLOB.runechat_color_names[target.name] = target_color
		else
			target_color = colorize_string(target.name)
	//SKYRAT CHANGES END

	// Get rid of any URL schemes that might cause BYOND to automatically wrap something in an anchor tag
	var/static/regex/url_scheme = new(@"[A-Za-z][A-Za-z0-9+-\.]*:\/\/", "g")
	text = replacetext(text, url_scheme, "")

	// Reject whitespace
	var/static/regex/whitespace = new(@"^\s*$")
	if (whitespace.Find(text))
		qdel(src)
		return

	// Non mobs speakers can be small
	if (!ismob(target))
		extra_classes |= "small"

	var/list/prefixes

	// Append radio icon if from a virtual speaker
	/// Cached chat prefix icons (radio, emote) — use icon() + Scale() for consistent maptext rendering
	var/static/list/chat_prefix_icons
	if (extra_classes.Find("virtual-speaker"))
		var/icon/r_icon = LAZYACCESS(chat_prefix_icons, "radio")
		if (isnull(r_icon))
			r_icon = icon('icons/ui_icons/chat/chat_icons.dmi', icon_state = "radio")
			r_icon.Scale(CHAT_MESSAGE_ICON_SIZE, CHAT_MESSAGE_ICON_SIZE)
			LAZYSET(chat_prefix_icons, "radio", r_icon)
		LAZYADD(prefixes, "\icon[r_icon]")
	else if (extra_classes.Find("emote"))
		var/icon/r_icon = LAZYACCESS(chat_prefix_icons, "emote")
		if (isnull(r_icon))
			r_icon = icon('icons/ui_icons/chat/chat_icons.dmi', icon_state = "emote")
			r_icon.Scale(CHAT_MESSAGE_ICON_SIZE, CHAT_MESSAGE_ICON_SIZE)
			LAZYSET(chat_prefix_icons, "emote", r_icon)
		LAZYADD(prefixes, "\icon[r_icon]")

	// Append language icon if the language uses one
	var/datum/language/language_instance = GLOB.language_datum_instances[language]
	if (language_instance?.display_icon(owner))
		var/icon/language_icon = LAZYACCESS(language_icons, language)
		if (isnull(language_icon))
			language_icon = icon(language_instance.icon, icon_state = language_instance.icon_state)
			language_icon.Scale(CHAT_MESSAGE_ICON_SIZE, CHAT_MESSAGE_ICON_SIZE)
			LAZYSET(language_icons, language, language_icon)
		LAZYADD(prefixes, "\icon[language_icon]")

	text = "[prefixes?.Join("&nbsp;")][text]"

	// We dim italicized text to make it more distinguishable from regular text.
	// Затемнение кэшируется тем же ключом - именем; вручную назначенный цвет в общий кэш
	// не пишется, иначе он утёк бы на всех однофамильцев.
	var/tgt_color = target_color
	if(extra_classes.Find("italics"))
		// Ключ кэша разный, а кэш один. Выведенный из имени цвет кэшируется по ИМЕНИ:
		// одинаковые имена дают одинаковый цвет по построению. Назначенный вручную - по
		// самому ЦВЕТУ: по имени он утёк бы на однофамильцев, а по цвету не утекает никуда
		// и при этом перестаёт считать rgb2hsl на каждое курсивное сообщение.
		var/darkened_key = manual_color ? target_color : target.name
		tgt_color = GLOB.runechat_color_names_darkened[darkened_key]
		if(!tgt_color)
			tgt_color = color_shift(target_color, 0.85, 0.85)
			GLOB.runechat_color_names_darkened[darkened_key] = tgt_color

	// Approximate text height
	var/complete_text = "<span class='center maptext [extra_classes.Join(" ")]' style='color: [tgt_color]'>[owner.say_emphasis(text)]</span>"

	var/mheight
	WXH_TO_HEIGHT(owned_by.MeasureText(complete_text, null, CHAT_MESSAGE_WIDTH), mheight)
	approx_lines = max(1, mheight / CHAT_MESSAGE_APPROX_LHEIGHT)

	// Translate any existing messages upwards, apply exponential decay factors to timers
	if(isnull(target) || QDELETED(target))
		qdel(src)
		return
	if(isturf(target))
		message_loc = target
	else if(ismovable(target))
		message_loc = get_atom_on_turf(target)
	else
		qdel(src)
		return
	// BLUEMOON EDIT START - sanity check
	// Я БЕЗ ПОНЯТИЯ, как owned_by исчезает в процессе вызова прока и проходит проверку на строке 104
	if(isnull(owned_by) || QDELETED(owned_by))
		return
	// BLUEMOON EDIT END
	if (owned_by.seen_messages)
		var/idx = 1
		var/combined_height = approx_lines
		for(var/msg in owned_by.seen_messages[message_loc])
			var/datum/chatmessage/m = msg
			m.current_y += round(mheight)
			animate(m.message, pixel_y = m.current_y, time = CHAT_MESSAGE_SPAWN_TIME)
			combined_height += m.approx_lines

			// When choosing to update the remaining time we have to be careful not to update the
			// scheduled time once the EOL completion time has been set.
			var/sched_remaining = m.scheduled_destruction - world.time
			if (!m.eol_complete)
				var/remaining_time = (sched_remaining) * (CHAT_MESSAGE_EXP_DECAY ** idx++) * (CHAT_MESSAGE_HEIGHT_DECAY ** combined_height)
				m.enter_subsystem(world.time + remaining_time) // push updated time to runechat SS

	// Reset z index if relevant
	if (current_z_idx >= CHAT_LAYER_MAX_Z)
		current_z_idx = 0

	// Build message image
	var/anim_mode = owned_by.prefs ? owned_by.prefs.runechat_anim : RUNECHAT_ANIM_NONE
	var/final_pixel_y = round(owner.bound_height * 0.95)

	message = image(loc = message_loc, layer = CHAT_LAYER + CHAT_LAYER_Z_STEP * current_z_idx++)
	message.plane = CHAT_PLANE
	message.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA | KEEP_APART
	message.alpha = 0
	message.pixel_y = anim_mode == RUNECHAT_ANIM_RISE ? final_pixel_y - CHAT_MESSAGE_RISE_OFFSET : final_pixel_y
	current_y = final_pixel_y
	message.maptext_width = CHAT_MESSAGE_WIDTH
	// Высота по сетке строки, а не сырой замер: клиент платит за ОБЪЯВЛЕННУЮ коробку
	// (width*height*4) и держит поверхность до конца сессии, а MeasureText отдаёт
	// пиксельную высоту, у которой на одинаковом тексте бывают соседние значения.
	message.maptext_height = CEILING(mheight, CHAT_MESSAGE_APPROX_LHEIGHT)
	message.maptext_x = round((CHAT_MESSAGE_WIDTH - owner.bound_width) * -0.5)
	message.maptext = MAPTEXT(anim_mode == RUNECHAT_ANIM_TYPEWRITER ? "" : complete_text)

	// View the message
	LAZYADDASSOC(owned_by.seen_messages, message_loc, src)
	in_seen_messages = TRUE
	owned_by.images |= message
	in_client_images = TRUE
	switch(anim_mode)
		if(RUNECHAT_ANIM_RISE)
			animate(message, alpha = 255, pixel_y = final_pixel_y, time = CHAT_MESSAGE_RISE_TIME, easing = SINE_EASING | EASE_OUT)
		if(RUNECHAT_ANIM_TYPEWRITER)
			animate(message, alpha = 255, time = CHAT_MESSAGE_SPAWN_TIME)
			var/list/steps = typewriter_build_steps(complete_text)
			if(length(steps) < 2)
				message.maptext = MAPTEXT(complete_text)
			else
				INVOKE_ASYNC(src, PROC_REF(typewriter_reveal), steps)
		else
			animate(message, alpha = 255, time = CHAT_MESSAGE_SPAWN_TIME)

	// Register with the runechat SS to handle EOL and destruction
	scheduled_destruction = world.time + (lifespan - CHAT_MESSAGE_EOL_FADE)
	enter_subsystem()


/**
  * Applies final animations to overlay CHAT_MESSAGE_EOL_FADE deciseconds prior to message deletion
  * Arguments:
  * * fadetime - The amount of time to animate the message's fadeout for
  */
/datum/chatmessage/proc/end_of_life(fadetime = CHAT_MESSAGE_EOL_FADE)
	eol_complete = scheduled_destruction + fadetime
	animate(message, alpha = 0, time = fadetime, flags = ANIMATION_PARALLEL)
	enter_subsystem(eol_complete) // re-enter the runechat SS with the EOL completion time to QDEL self

/datum/chatmessage/proc/typewriter_reveal(list/steps)
	// Число кадров под потолком, а шаг по времени - производный от него, чтобы анимация
	// заняла те же две секунды. Считать кадры по world.tick_lag значило платить клиенту
	// поверхностью за каждый: см. CHAT_MESSAGE_TYPEWRITER_MAX_FRAMES.
	var/total_ticks = clamp(CEILING(CHAT_MESSAGE_TYPING_TIME / world.tick_lag, 1), 1, CHAT_MESSAGE_TYPEWRITER_MAX_FRAMES)
	var/frame_time = max(world.tick_lag, CHAT_MESSAGE_TYPING_TIME / total_ticks)
	var/per_tick = max(1, CEILING(length(steps) / total_ticks, 1))
	var/index = 1
	while(index < length(steps))
		if(!owned_by || QDELETED(src) || !message || eol_complete)
			return
		index = min(index + per_tick, length(steps))
		message.maptext = MAPTEXT(steps[index])
		sleep(frame_time)

/datum/chatmessage/proc/typewriter_build_steps(complete_text)
	var/list/tokens = list()
	var/total_chars = length_char(complete_text)
	var/i = 1
	while(i <= total_chars)
		var/char = copytext_char(complete_text, i, i + 1)
		var/token_end = i
		if(char == "<")
			token_end = typewriter_scan_until(complete_text, i, ">")
		else if(char == "&")
			token_end = typewriter_scan_until(complete_text, i, ";")
		else if(char == "\\")
			token_end = typewriter_scan_until(complete_text, i, "]")
		tokens += copytext_char(complete_text, i, token_end + 1)
		i = token_end + 1

	var/list/steps = list()
	var/built = ""
	for(var/token in tokens)
		built += token
		steps += built
	return steps

/datum/chatmessage/proc/typewriter_scan_until(text, start, stop, max_chars = 64)
	var/limit = min(start + max_chars, length_char(text))
	for(var/j in start + 1 to limit)
		if(copytext_char(text, j, j + 1) == stop)
			return j
	return start

/**
  * Creates a message overlay at a defined location for a given speaker
  *
  * Arguments:
  * * speaker - The atom who is saying this message
  * * message_language - The language that the message is said in
  * * raw_message - The text content of the message
  * * spans - Additional classes to be added to the message
  * * message_mode - Bitflags relating to the mode of the message
  */
/mob/proc/create_chat_message(atom/movable/speaker, datum/language/message_language, raw_message, list/spans, message_mode)
	// Ensure the list we are using, if present, is a copy so we don't modify the list provided to us
	spans = spans ? spans.Copy() : list()

	// Add whisper class for reduced text size in runchat
	if(message_mode == MODE_WHISPER || message_mode == MODE_WHISPER_CRIT)
		spans |= "whisper"

	// Check for virtual speakers (aka hearing a message through a radio)
	var/atom/movable/originalSpeaker = speaker
	if (istype(speaker, /atom/movable/virtualspeaker))
		var/atom/movable/virtualspeaker/v = speaker
		speaker = v.source
		spans |= "virtual-speaker"
	if(isnull(speaker) || QDELETED(speaker))
		return

	// Ignore virtual speaker (most often radio messages) from ourself
	if (originalSpeaker != src && speaker == src)
		return

	// Lag switch: runechat is pure cosmetics and every viewer generates its own
	// message image, so it is the first thing to go when the server is dying
	if(SSlag_switch.measures[DISABLE_RUNECHAT] && !HAS_TRAIT(speaker, TRAIT_BYPASS_MEASURES))
		return
	if(SSlag_switch.measures[DISABLE_DEAD_RUNECHAT] && stat == DEAD && !client?.holder)
		return
	//Skyrat changes
	if(!message_language && (lang_treat(speaker, message_language, raw_message, spans, null, TRUE) == "makes a strange sound.") && !("emote" in spans))
		var/nospeak = "makes a strange sound."
		new /datum/chatmessage(nospeak, speaker, src, message_language, list("emote", "italics"))
	else if(message_language)
		new /datum/chatmessage(lang_treat(speaker, message_language, raw_message, spans, null, TRUE), speaker, src, message_language, spans)
	else
		new /datum/chatmessage(raw_message, speaker, src, message_language, spans)
	//End of skyrat changes

// Tweak these defines to change the available color ranges
#define CM_COLOR_SAT_MIN	0.6
#define CM_COLOR_SAT_MAX	0.7
#define CM_COLOR_LUM_MIN	0.65
#define CM_COLOR_LUM_MAX	0.75

/**
  * Gets a color for a name, will return the same color for a given string consistently within a round.atom
  *
  * Note that this proc aims to produce pastel-ish colors using the HSL colorspace. These seem to be favorable for displaying on the map.
  *
  * Arguments:
  * * name - The name to generate a color for
  * * sat_shift - A value between 0 and 1 that will be multiplied against the saturation
  * * lum_shift - A value between 0 and 1 that will be multiplied against the luminescence
  */
/datum/chatmessage/proc/colorize_string(name, sat_shift = 1, lum_shift = 1)
	// seed to help randomness
	var/static/rseed = rand(1,26)

	// get hsl using the selected 6 characters of the md5 hash
	var/hash = copytext(md5(name + GLOB.round_id), rseed, rseed + 6)
	var/h = hex2num(copytext(hash, 1, 3)) * (360 / 255)
	var/s = (hex2num(copytext(hash, 3, 5)) >> 2) * ((CM_COLOR_SAT_MAX - CM_COLOR_SAT_MIN) / 63) + CM_COLOR_SAT_MIN
	var/l = (hex2num(copytext(hash, 5, 7)) >> 2) * ((CM_COLOR_LUM_MAX - CM_COLOR_LUM_MIN) / 63) + CM_COLOR_LUM_MIN

	// adjust for shifts
	s *= clamp(sat_shift, 0, 1)
	l *= clamp(lum_shift, 0, 1)

	// convert to rgb
	var/h_int = round(h/60) // mapping each section of H to 60 degree sections
	var/c = (1 - abs(2 * l - 1)) * s
	var/x = c * (1 - abs((h / 60) % 2 - 1))
	var/m = l - c * 0.5
	x = (x + m) * 255
	c = (c + m) * 255
	m *= 255
	//Skyrat changes begin
	var/final_val
	switch(h_int)
		if(0)
			final_val = "#[num2hex(c, 2)][num2hex(x, 2)][num2hex(m, 2)]"
		if(1)
			final_val = "#[num2hex(x, 2)][num2hex(c, 2)][num2hex(m, 2)]"
		if(2)
			final_val = "#[num2hex(m, 2)][num2hex(c, 2)][num2hex(x, 2)]"
		if(3)
			final_val = "#[num2hex(m, 2)][num2hex(x, 2)][num2hex(c, 2)]"
		if(4)
			final_val = "#[num2hex(x, 2)][num2hex(m, 2)][num2hex(c, 2)]"
		if(5)
			final_val = "#[num2hex(c, 2)][num2hex(m, 2)][num2hex(x, 2)]"

	GLOB.runechat_color_names[name] = final_val
	return final_val
	//End of skyrat changes

//Skyrat changes begin
/datum/chatmessage/proc/color_shift(color, sat_shift = 1, lum_shift = 1)
	var/list/HSL = rgb2hsl(hex2num(copytext(color, 2, 4)), hex2num(copytext(color, 4, 6)), hex2num(copytext(color, 6, 8)))
	HSL[2] = HSL[2] * sat_shift
	HSL[3] = HSL[3] * lum_shift
	var/list/RGB = hsl2rgb(arglist(HSL))
	return "#[num2hex(RGB[1],2)][num2hex(RGB[2],2)][num2hex(RGB[3],2)]"

//End of skyrat changes
