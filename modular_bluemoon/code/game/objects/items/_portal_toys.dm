// BLUEMOON: Expanded Portal Toy System
// Adds: Private pairing, vibration modes, intensity settings, chat, safety features, mood indicators
// Defines are in code/__BLUEMOONCODE/_DEFINES/portal_toys.dm

// Global network list
GLOBAL_LIST_EMPTY(portal_networks)

/// Get portal nickname for a mob, with fallback to default value
/// Handles null/empty string/zero correctly to avoid DM's null->0 conversion
/proc/get_portal_nickname(mob/living/carbon/human/H, fallback = "Аноним")
	if(!ishuman(H))
		return "[fallback]"
	var/nick = H.fleshlight_nickname
	// Check for null, empty string, numeric zero, and string representations of invalid values
	if(isnull(nick) || nick == "" || nick == 0 || "[nick]" == "0" || "[nick]" == "null")
		return "[fallback]"
	return "[nick]"

/// Check if telecomms server is available for portal whispers
/// Supports both dedicated server and allinone (compact telecomms)
/// In Extended mode - always returns TRUE (no antag interference expected)
/proc/can_portal_telecomms()
	if(GLOB.master_mode == "Extended")
		return TRUE
	for(var/obj/machinery/telecomms/server/S in GLOB.telecomms_list)
		if(S.on)
			return TRUE
	// Check for all-in-one unit (compact telecomms used on some maps)
	for(var/obj/machinery/telecomms/allinone/A in GLOB.telecomms_list)
		if(A.on)
			return TRUE
	return FALSE


/// Get portal_settings for a mob (from their held/inserted portal device)
/proc/get_portal_settings_for_mob(mob/living/carbon/human/H)
	if(!ishuman(H))
		return null
	for(var/obj/item/portallight/PL in H.held_items)
		if(PL.portal_settings)
			return PL.portal_settings
	// Check inserted devices in genitals
	for(var/obj/item/organ/genital/G in H.internal_organs)
		for(var/obj/item/portallight/PL in G.contents)
			if(PL.portal_settings)
				return PL.portal_settings
		for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP in G.contents)
			if(PP.portal_settings)
				return PP.portal_settings
	// Check worn panties
	if(istype(H.w_underwear, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = H.w_underwear
		return PP.portal_settings
	// Check panties worn as mask
	if(istype(H.wear_mask, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = H.wear_mask
		return PP.portal_settings
	return null

// Portal settings datum
/datum/portal_settings
	/// Owner of these settings
	var/mob/living/carbon/human/owner
	/// Weak reference to the parent device (panties or fleshlight)
	var/datum/weakref/parent_device
	/// Connection mode (disabled by default for safety)
	var/connection_mode = PORTAL_MODE_DISABLED
	/// Private partner (for private mode)
	var/datum/weakref/private_partner_ref
	/// Group network (for group mode)
	var/datum/portal_network/network
	/// Vibration enabled
	var/vibration_enabled = FALSE
	/// Current vibration pattern
	var/vibration_pattern = VIBE_PATTERN_CONSTANT
	/// Vibration intensity (1-10)
	var/vibration_intensity = 5
	/// Relay intensity (percentage of sensations relayed)
	var/relay_intensity = 100
	/// Current mood/status
	var/current_mood = PORTAL_MOOD_IDLE
	/// Do not disturb mode
	var/do_not_disturb = FALSE
	/// Blocked users list (by portal nickname - anonymous)
	var/list/blocked_nicknames = list()
	/// Allowed users list (by portal nickname) - if not empty, only these can connect
	var/list/allowed_nicknames = list()
	/// Connection history (last 10)
	var/list/connection_history = list()
	/// Safeword - instant disconnect phrase
	var/safeword = "красный"
	/// Whether safeword detection is enabled (disabled by default)
	var/safeword_enabled = FALSE
	/// Last activity time
	var/last_activity = 0
	// Control mode (D/s support)
	/// Control mode - who can adjust settings (default to Partner/subordinate mode)
	var/control_mode = PORTAL_CONTROL_PARTNER
	/// Lock intensity changes (for sub mode)
	var/intensity_locked = FALSE
	/// Maximum allowed intensity (for sub mode limits)
	var/max_allowed_intensity = 10
	/// Minimum forced intensity (for sub mode floor)
	var/min_forced_intensity = 0
	// Quick messages
	/// Custom quick message presets
	var/list/quick_messages
	// Tease mode tracking
	/// Last tease pulse time (for tease pattern)
	var/last_tease_pulse = 0
	/// Tease cooldown (random between pulses)
	var/tease_next_pulse = 0
	// Public emotes
	/// Enable public emotes visible to nearby players
	var/public_emotes_enabled = TRUE
	/// Last time a public emote was shown (for cooldown)
	var/last_public_emote = 0
	// Edging mode
	/// Enable edging mode (auto-reduce intensity near climax)
	var/edging_enabled = FALSE
	/// Track if we already notified partner about edging
	var/edging_notified = FALSE
	// Network sensation relay toggles
	/// Relay vibration sensations to network members
	var/relay_vibrations = TRUE
	/// Relay edging notifications to network members
	var/relay_edging = TRUE
	/// Relay climax sensations to network members
	var/relay_climax = TRUE
	/// Last time we relayed vibration to network (for throttling)
	var/last_network_vibration_relay = 0
	/// Настройка приватности публичного режима - что видят подключённые о других
	var/public_privacy_mode = PORTAL_PRIVACY_COUNT_ONLY

/datum/portal_settings/New(mob/living/carbon/human/H)
	owner = H
	quick_messages = PORTAL_QUICK_MESSAGES

/datum/portal_settings/Destroy()
	owner = null
	private_partner_ref = null
	if(network)
		network.remove_member(src)
	return ..()

/datum/portal_settings/proc/set_private_partner(mob/living/carbon/human/partner)
	if(partner)
		private_partner_ref = WEAKREF(partner)
		connection_mode = PORTAL_MODE_PRIVATE
	else
		private_partner_ref = null

/datum/portal_settings/proc/get_private_partner()
	return private_partner_ref?.resolve()

/datum/portal_settings/proc/can_connect_to(mob/living/carbon/human/target)
	if(do_not_disturb)
		return FALSE
	// Check by portal nickname (anonymous) - use "Аноним" as fallback for null nicknames
	var/target_nickname = get_portal_nickname(target)
	if(target_nickname in blocked_nicknames)
		return FALSE
	if(allowed_nicknames.len && !(target_nickname in allowed_nicknames))
		return FALSE
	switch(connection_mode)
		if(PORTAL_MODE_DISABLED)
			return FALSE
		if(PORTAL_MODE_PRIVATE)
			var/mob/living/carbon/human/partner = get_private_partner()
			return partner == target
		if(PORTAL_MODE_GROUP)
			if(!network)
				return FALSE
			return network.is_member(target)
	return TRUE

/// Check if a user can connect TO this device (called on panties when fleshlight tries to connect)
/// connector = the mob trying to connect (holding the fleshlight)
/datum/portal_settings/proc/can_connect_from(mob/living/carbon/human/connector)
	if(do_not_disturb)
		return FALSE
	// Check by portal nickname (anonymous) - use "Аноним" as fallback for null nicknames
	var/connector_nickname = get_portal_nickname(connector)
	if(connector_nickname in blocked_nicknames)
		return FALSE
	if(allowed_nicknames.len && !(connector_nickname in allowed_nicknames))
		return FALSE
	switch(connection_mode)
		if(PORTAL_MODE_DISABLED)
			return FALSE
		if(PORTAL_MODE_PRIVATE)
			var/mob/living/carbon/human/partner = get_private_partner()
			return partner == connector
		if(PORTAL_MODE_GROUP)
			if(!network)
				return FALSE
			// Connector must also be in the same network
			var/datum/portal_settings/connector_settings = get_portal_settings_for_mob(connector)
			if(!connector_settings)
				return FALSE
			return connector_settings.network == network
		if(PORTAL_MODE_PUBLIC)
			return TRUE
	return TRUE

/// Check if a specific nickname is blocked
/datum/portal_settings/proc/is_nickname_blocked(nickname)
	return nickname in blocked_nicknames

/// Check if a specific nickname is allowed (empty list means everyone allowed)
/datum/portal_settings/proc/is_nickname_allowed(nickname)
	if(!allowed_nicknames.len)
		return TRUE
	return nickname in allowed_nicknames

/datum/portal_settings/proc/add_to_history(mob/living/carbon/human/partner, action)
	// Use portal nickname for anonymity, fallback to "Аноним"
	var/partner_nick = get_portal_nickname(partner)
	var/entry = list(
		"time" = world.time,
		"time_text" = time2text(world.time, "hh:mm"),
		"partner" = partner_nick,
		"action" = action
	)
	connection_history.Insert(1, list(entry))
	if(connection_history.len > 10)
		connection_history.Cut(11)

/datum/portal_settings/proc/update_mood()
	var/old_mood = current_mood
	if(do_not_disturb)
		current_mood = PORTAL_MOOD_DND
		return
	if(!owner || !owner.client)
		current_mood = PORTAL_MOOD_IDLE
		return
	var/lust = owner.get_lust()
	var/climax_threshold = owner.get_climax_threshold()
	if(lust >= climax_threshold)
		current_mood = PORTAL_MOOD_CLIMAX
	else if(lust >= climax_threshold * 0.7)
		current_mood = PORTAL_MOOD_AROUSED
	else if(world.time - last_activity < 30 SECONDS)
		current_mood = PORTAL_MOOD_ACTIVE
	else
		current_mood = PORTAL_MOOD_IDLE
	// Broadcast sensation to network when entering climax
	if(current_mood == PORTAL_MOOD_CLIMAX && old_mood != PORTAL_MOOD_CLIMAX)
		// Show public emote for climax
		show_climax_emote()
		// Broadcast to network if connected and relay_climax is enabled
		if(network && relay_climax)
			network.broadcast_sensation(owner, PORTAL_SENSATION_CLIMAX, lust, relay_intensity)

/datum/portal_settings/proc/get_mood_color()
	switch(current_mood)
		if(PORTAL_MOOD_IDLE)
			return "#4488ff"  // Blue
		if(PORTAL_MOOD_ACTIVE)
			return "#ff88cc"  // Pink
		if(PORTAL_MOOD_AROUSED)
			return "#ff4444"  // Red
		if(PORTAL_MOOD_CLIMAX)
			return "#aa44ff"  // Purple
		if(PORTAL_MOOD_DND)
			return "#888888"  // Gray
	return "#ffffff"

/datum/portal_settings/proc/get_mood_text()
	switch(current_mood)
		if(PORTAL_MOOD_IDLE)
			return "В ожидании"
		if(PORTAL_MOOD_ACTIVE)
			return "Активен"
		if(PORTAL_MOOD_AROUSED)
			return "Возбуждён"
		if(PORTAL_MOOD_CLIMAX)
			return "Оргазм!"
		if(PORTAL_MOOD_DND)
			return "Не беспокоить"
	return "Неизвестно"

// Vibration processing

/// Process vibration and return lust gain
/datum/portal_settings/proc/process_vibration(delta_time, location_text = "")
	if(!owner || !owner.client || !vibration_enabled)
		return 0
	var/lust_gain = 0
	var/intensity = vibration_intensity
	// Apply D/s intensity limits
	intensity = clamp(intensity, min_forced_intensity, max_allowed_intensity)

	// Edging mode - reduce intensity when approaching climax
	if(edging_enabled)
		var/current_lust = owner.get_lust()
		var/climax_thresh = owner.get_climax_threshold()
		if(current_lust >= climax_thresh * PORTAL_EDGING_THRESHOLD)
			intensity = max(1, intensity - PORTAL_EDGING_INTENSITY_REDUCTION)
			// Notify partner once when edging activates
			if(!edging_notified)
				edging_notified = TRUE
				notify_partners_edging()
		else
			edging_notified = FALSE

	switch(vibration_pattern)
		if(VIBE_PATTERN_CONSTANT)
			lust_gain = intensity * 0.5 * delta_time
		if(VIBE_PATTERN_PULSE)
			if(prob(50))
				lust_gain = intensity * delta_time
		if(VIBE_PATTERN_WAVE)
			var/wave = sin(world.time / 10) * 0.5 + 0.5
			lust_gain = intensity * wave * delta_time
		if(VIBE_PATTERN_RANDOM)
			lust_gain = rand(0, intensity) * delta_time * 0.5
		if(VIBE_PATTERN_ESCALATE)
			var/escalation = min((world.time - last_activity) / 600, 2)
			lust_gain = intensity * escalation * delta_time * 0.3
		if(VIBE_PATTERN_HEARTBEAT)
			var/lust_ratio = owner.get_lust() / max(owner.get_climax_threshold(), 1)
			lust_gain = intensity * (0.5 + lust_ratio) * delta_time * 0.3
		if(VIBE_PATTERN_TEASE)
			// Tease pattern: rare unpredictable pulses with long random delays
			if(world.time >= tease_next_pulse)
				if(prob(15))
					lust_gain = intensity * rand(50, 150) / 100 * delta_time
					if(prob(10))
						// Rare surprise spike!
						lust_gain *= 2
						to_chat(owner, span_lewd("<b>Неожиданный сильный импульс заставляет вас вздрогнуть!</b>"))
				// Much longer random cooldown: 5-60 seconds for true unpredictability
				tease_next_pulse = world.time + rand(50, 600)

	if(lust_gain > 0)
		owner.add_lust(lust_gain)
		last_activity = world.time
		// Relay to network if conditions met
		if(network && relay_vibrations && intensity >= PORTAL_NETWORK_VIBRATION_THRESHOLD)
			if(world.time >= last_network_vibration_relay + PORTAL_NETWORK_RELAY_INTERVAL)
				last_network_vibration_relay = world.time
				network.broadcast_sensation(owner, PORTAL_SENSATION_VIBRATION, intensity, relay_intensity)
		// Visible feedback - periodic messages and effects
		if(prob(5 * intensity))
			show_vibration_feedback(intensity, location_text)
		// Jitter effects scaled by intensity
		if(owner.client?.prefs.cit_toggles & SEX_JITTER)
			apply_vibration_jitter(intensity)
		// Public emotes visible to nearby players
		if(public_emotes_enabled && intensity >= PORTAL_EMOTE_MIN_INTENSITY)
			try_show_public_emote(intensity)

	return lust_gain

/// Apply jitter effects based on vibration intensity
/datum/portal_settings/proc/apply_vibration_jitter(intensity)
	if(!owner)
		return
	// At max intensity, chance to show pleasure emote
	if(intensity >= 8 && prob(intensity - 5))
		// Используем свои эмоции вместо стандартных, чтобы избежать неуместного "задыхается"
		var/list/pleasure_emotes = list(
			list("third" = "тихо стонет", "self" = "тихо стонете"),
			list("third" = "сдавленно охает", "self" = "сдавленно охаете"),
			list("third" = "прерывисто выдыхает", "self" = "прерывисто выдыхаете")
		)
		var/list/emote = pick(pleasure_emotes)
		owner.visible_message(
			"<span class='emote'><b>[owner]</b> [emote["third"]].</span>",
			"<span class='emote'>Вы [emote["self"]].</span>",
			vision_distance = 1
		)
	// Jitter probability increases with intensity: 5% at 5, 15% at 7, 30% at 10
	var/jitter_chance = max(0, (intensity - 4) * 5)
	if(prob(jitter_chance))
		owner.Jitter(intensity)
	// At very high intensity (9-10), chance to stumble
	if(intensity >= 9 && prob(3) && !owner.buckled && !owner.lying && owner.body_position == STANDING_UP)
		to_chat(owner, span_lewd("Мощная вибрация заставляет ваши ноги подкоситься!"))
		owner.Knockdown(0.5 SECONDS)

/// Show vibration feedback messages based on intensity
/datum/portal_settings/proc/show_vibration_feedback(intensity, location_text = "")
	if(!owner?.client)
		return
	var/list/messages
	// Если location_text пустой (просто надето), не добавляем лишний текст
	if(!location_text)
		if(intensity <= 3)
			messages = list("слегка вибрирует", "мягко жужжит", "нежно пульсирует")
		else if(intensity <= 6)
			messages = list("приятно вибрирует", "ритмично пульсирует", "настойчиво жужжит")
		else if(intensity <= 9)
			messages = list("интенсивно вибрирует", "мощно пульсирует, заставляя вас вздрагивать", "сильно жужжит, отвлекая ваше внимание")
		else
			messages = list("безумно вибрирует, заставляя ваши ноги подкашиваться!", "пульсирует на максимуме, заставляя вас стонать!", "вибрирует так сильно, что вы едва можете думать!")
	else
		// С указанием локации (внутри вагины, в анусе и т.д.)
		if(intensity <= 3)
			messages = list("слегка вибрирует [location_text]", "мягко жужжит [location_text]", "нежно пульсирует [location_text]")
		else if(intensity <= 6)
			messages = list("приятно вибрирует [location_text]", "ритмично пульсирует [location_text]", "настойчиво жужжит [location_text]")
		else if(intensity <= 9)
			messages = list("интенсивно вибрирует [location_text]", "мощно пульсирует [location_text], заставляя вас вздрагивать", "сильно жужжит [location_text], отвлекая ваше внимание")
		else
			messages = list("безумно вибрирует [location_text], заставляя ваши ноги подкашиваться!", "пульсирует на максимуме [location_text], заставляя вас стонать!", "вибрирует так сильно [location_text], что вы едва можете думать!")
	to_chat(owner, span_lewd("Портальное устройство [pick(messages)]"))

// Public emotes and edging helpers

/// Try to show a public emote to nearby players (with cooldown)
/datum/portal_settings/proc/try_show_public_emote(intensity)
	if(!owner?.client)
		return
	// Check cooldown
	if(world.time < last_public_emote + PORTAL_EMOTE_COOLDOWN)
		return
	// Probability increases with intensity: 5% at 7, 10% at 8, 15% at 9, 20% at 10
	var/emote_chance = (intensity - 6) * 5
	if(!prob(emote_chance))
		return
	// Show emote - pick returns a list with "third" and "self" keys
	var/list/emote_data = pick(PORTAL_PUBLIC_EMOTES)
	show_public_emote(emote_data)
	last_public_emote = world.time

/// Show a public emote visible to players in adjacent tiles (3x3 area)
/// emote_data is a list with "third" (3rd person) and "self" (2nd person) forms
/datum/portal_settings/proc/show_public_emote(list/emote_data)
	if(!owner || !islist(emote_data))
		return
	// Use visible_message with limited range for 3x3 area
	owner.visible_message(
		"<span class='emote'><b>[owner]</b> [emote_data["third"]].</span>",
		"<span class='emote'>Вы [emote_data["self"]].</span>",
		vision_distance = 1  // 3x3 area (1 tile in each direction)
	)

/// Show a climax emote when reaching orgasm
/datum/portal_settings/proc/show_climax_emote()
	if(!owner?.client || !public_emotes_enabled)
		return
	var/list/emote_data = pick(PORTAL_CLIMAX_EMOTES)
	show_public_emote(emote_data)
	last_public_emote = world.time

/// Notify connected partners that edging mode activated
/datum/portal_settings/proc/notify_partners_edging()
	if(!owner?.client)
		return
	// Use sensation system if in network and relay_edging is enabled
	if(network && relay_edging)
		network.broadcast_sensation(owner, PORTAL_SENSATION_EDGING, 0, relay_intensity)

// Control mode helpers

/// Check if the given user can control this device
/datum/portal_settings/proc/can_user_control(mob/user, is_partner = FALSE)
	if(!user)
		return FALSE
	switch(control_mode)
		if(PORTAL_CONTROL_SELF)
			return user == owner
		if(PORTAL_CONTROL_PARTNER)
			return is_partner
	return user == owner

/// Check if intensity can be changed
/datum/portal_settings/proc/can_change_intensity(mob/user, is_partner = FALSE)
	// When intensity is locked, the PARTNER cannot change it (owner locked it against partner)
	if(intensity_locked && is_partner)
		return FALSE
	return can_user_control(user, is_partner)

/// Get list of available vibration patterns with metadata for TGUI
/datum/portal_settings/proc/get_available_patterns_data()
	return list(
		list("id" = VIBE_PATTERN_CONSTANT, "name" = "Постоянная", "desc" = "Равномерная вибрация на выбранной интенсивности", "icon" = "bolt"),
		list("id" = VIBE_PATTERN_PULSE, "name" = "Пульсация", "desc" = "Прерывистые импульсы с паузами между ними", "icon" = "heartbeat"),
		list("id" = VIBE_PATTERN_WAVE, "name" = "Волна", "desc" = "Плавное нарастание и затухание по синусоиде", "icon" = "water"),
		list("id" = VIBE_PATTERN_RANDOM, "name" = "Случайная", "desc" = "Непредсказуемые изменения интенсивности", "icon" = "dice"),
		list("id" = VIBE_PATTERN_ESCALATE, "name" = "Нарастающая", "desc" = "Постепенное усиление со временем", "icon" = "chart-line"),
		list("id" = VIBE_PATTERN_HEARTBEAT, "name" = "Сердцебиение", "desc" = "Ритм ускоряется с ростом возбуждения", "icon" = "heart"),
		list("id" = VIBE_PATTERN_TEASE, "name" = "Дразнящая", "desc" = "Редкие неожиданные импульсы - никогда не знаешь когда!", "icon" = "theater-masks")
	)

/// Check if a message contains the safeword
/datum/portal_settings/proc/check_safeword(raw_message)
	if(!safeword_enabled)
		return FALSE
	if(!safeword)
		return FALSE
	return findtext(raw_message, safeword)

/// Send a quick message through the portal
/datum/portal_settings/proc/send_quick_message(index, mob/living/carbon/human/sender, list/recipients)
	// Check telecomms availability
	if(!can_portal_telecomms())
		if(sender)
			to_chat(sender, span_warning("Нет связи с сервером! Сообщения недоступны."))
		return FALSE
	if(index < 1 || index > quick_messages.len)
		return FALSE
	var/message = quick_messages[index]
	var/sender_nickname = get_portal_nickname(sender)
	var/list/already_heard = list()

	// Always show sender confirmation with recipient names
	if(sender)
		if(!length(recipients))
			to_chat(sender, span_warning("Некому отправить сообщение - нет подключённых устройств."))
			return FALSE
		var/list/recipient_names = list()
		for(var/mob/living/carbon/human/R in recipients)
			recipient_names += get_portal_nickname(R)
		var/names_text = recipient_names.Join(", ")
		var/parsed_preview = parse_message_template(message, sender_nickname, names_text)
		to_chat(sender, span_lewd("<i>Вы отправили через портал для [names_text]:</i> \"[parsed_preview]\""))
		already_heard |= sender

	for(var/mob/living/carbon/human/receiver in recipients)
		if(!receiver)
			continue
		var/receiver_nickname = get_portal_nickname(receiver)
		// Parse template placeholders
		var/parsed_message = parse_message_template(message, sender_nickname, receiver_nickname)

		// Broadcast to nearby mobs around recipient's location (range 1 = 3x3)
		var/turf/broadcast_turf = get_turf(receiver)
		if(!broadcast_turf)
			continue
		for(var/mob/living/L in range(broadcast_turf, 1))
			if(L in already_heard)
				continue
			if(L == sender)
				// Echo back to sender if nearby
				to_chat(L, span_lewd("<i>Ваше сообщение доносится из портала:</i> \"[parsed_message]\""))
				already_heard |= L
				continue
			to_chat(L, span_lewd("<i>Быстрое сообщение от [sender_nickname]:</i> \"[parsed_message]\""))
			already_heard |= L
	return TRUE

/// Parse message template placeholders
/// Supported: {partner} = recipient nickname, {me} = sender nickname, {intensity} = current intensity, {mood} = current mood
/datum/portal_settings/proc/parse_message_template(message, sender_nickname, partner_nickname)
	var/result = message
	result = replacetext(result, "{partner}", partner_nickname)
	result = replacetext(result, "{me}", sender_nickname)
	result = replacetext(result, "{intensity}", "[vibration_intensity]")
	result = replacetext(result, "{mood}", get_mood_text())
	return result

// Portal network
/datum/portal_network
	var/name = "Portal Network"
	var/owner_ckey
	var/password
	var/list/members = list()  // list of datum/portal_settings
	var/max_members = 10
	/// Panties that are in GROUP mode within this network - for fast lookup
	var/list/group_mode_panties = list()

/datum/portal_network/New(network_name, mob/living/carbon/human/creator, pass = null)
	name = network_name
	owner_ckey = creator?.ckey
	password = pass

/datum/portal_network/Destroy()
	GLOB.portal_networks -= src
	for(var/datum/portal_settings/PS in members)
		PS.network = null
	members.Cut()
	return ..()

/datum/portal_network/proc/add_member(datum/portal_settings/PS, pass = null)
	if(password && password != pass)
		return FALSE
	if(members.len >= max_members)
		return FALSE
	if(PS in members)
		return TRUE
	members += PS
	PS.network = src
	// If member is panties in GROUP mode, add to fast lookup list
	update_group_panties_index(PS)
	return TRUE

/datum/portal_network/proc/remove_member(datum/portal_settings/PS)
	members -= PS
	// Remove from group mode panties list if present
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/panties = PS.parent_device?.resolve()
	if(panties)
		group_mode_panties -= panties
	if(PS.network == src)
		PS.network = null
	if(!members.len)
		qdel(src)

/// Update group_mode_panties index for a portal_settings
/// Call this when connection_mode changes or when member joins/leaves
/datum/portal_network/proc/update_group_panties_index(datum/portal_settings/PS)
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/panties = PS.parent_device?.resolve()
	if(!panties)
		return
	if(PS.connection_mode == PORTAL_MODE_GROUP && (PS in members))
		group_mode_panties |= panties
	else
		group_mode_panties -= panties

/datum/portal_network/proc/is_member(mob/living/carbon/human/H)
	for(var/datum/portal_settings/PS in members)
		if(PS.owner == H)
			return TRUE
	return FALSE

/datum/portal_network/proc/broadcast_message(mob/sender, message)
	// Check telecomms availability
	if(!can_portal_telecomms())
		if(sender)
			to_chat(sender, span_warning("Нет связи с сервером! Трансляция недоступна."))
		return

	var/list/already_heard = list()
	if(sender)
		already_heard |= sender

	for(var/datum/portal_settings/PS in members)
		var/atom/device = get_device_for_settings(PS)
		if(!device)
			continue

		var/turf/broadcast_turf = get_turf(device)
		if(!broadcast_turf)
			continue

		// Broadcast from device location to nearby mobs (range 1 = 3x3)
		for(var/mob/living/L in range(broadcast_turf, 1))
			if(L in already_heard)
				continue
			to_chat(L, span_notice("<i>Голос из портального устройства:</i> [message]"))
			already_heard |= L

/// Helper to find the device associated with portal_settings
/datum/portal_network/proc/get_device_for_settings(datum/portal_settings/PS)
	if(!PS?.owner)
		return null
	var/mob/living/carbon/human/H = PS.owner
	if(!ishuman(H))
		return null
	// Check portallight in hands
	for(var/obj/item/portallight/PL in H.held_items)
		if(PL.portal_settings == PS)
			return PL
	// Check portalpanties worn
	if(istype(H.w_underwear, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = H.w_underwear
		if(PP.portal_settings == PS)
			return PP
	if(istype(H.wear_mask, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = H.wear_mask
		if(PP.portal_settings == PS)
			return PP
	// Check inserted devices in genitals
	for(var/obj/item/organ/genital/G in H.internal_organs)
		for(var/obj/item/portallight/PL in G.contents)
			if(PL.portal_settings == PS)
				return PL
		for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP in G.contents)
			if(PP.portal_settings == PS)
				return PP
	return null

/// Broadcast whisper to all network members
/datum/portal_network/proc/broadcast_whisper(mob/sender, nickname, message)
	// Check telecomms availability
	if(!can_portal_telecomms())
		if(sender)
			to_chat(sender, span_warning("Нет связи с сервером! Сетевой шёпот недоступен."))
		return

	var/list/already_heard = list()

	for(var/datum/portal_settings/PS in members)
		var/atom/device = get_device_for_settings(PS)
		if(!device)
			continue

		var/turf/broadcast_turf = get_turf(device)
		if(!broadcast_turf)
			continue

		// Broadcast from device location to nearby mobs (range 1 = 3x3)
		for(var/mob/living/L in range(broadcast_turf, 1))
			if(L in already_heard)
				continue
			if(L == sender)
				// Echo back to sender if they're near a network device
				to_chat(L, span_lewd("<i>Ваш шёпот доносится из сети:</i> \"[message]\""))
				already_heard |= L
				continue
			to_chat(L, span_lewd("<i>Шёпот через сеть от [nickname]:</i> \"[message]\""))
			already_heard |= L

/// Broadcast sensations to all network members
/// sensation_type: PORTAL_SENSATION_VIBRATION, PORTAL_SENSATION_EDGING, or PORTAL_SENSATION_CLIMAX
/// intensity: vibration intensity (1-10) or lust amount for climax
/// relay_percent: sender's relay_intensity setting (25-100), defaults to 100
/datum/portal_network/proc/broadcast_sensation(mob/sender, sensation_type, intensity, relay_percent = 100)
	var/relay_multiplier = clamp(relay_percent, 25, 100) / 100
	var/mob/living/carbon/human/human_sender = ishuman(sender) ? sender : null
	var/sender_nick = get_portal_nickname(human_sender, "Кто-то")

	for(var/datum/portal_settings/PS in members)
		if(!PS.owner || !PS.owner.client || PS.owner == sender)
			continue
		// Check if recipient wants this sensation type
		if(!recipient_accepts_sensation(PS, sensation_type))
			continue

		switch(sensation_type)
			if(PORTAL_SENSATION_VIBRATION)
				// Small lust gain based on relayed intensity
				var/relayed_intensity = round(intensity * relay_multiplier)
				var/lust_gain = relayed_intensity * 0.3
				PS.owner.add_lust(lust_gain)
				to_chat(PS.owner, span_lewd("<i>Вы чувствуете вибрацию от [sender_nick] (интенсивность: [relayed_intensity])...</i>"))
				// Jitter at high intensity
				if(relayed_intensity >= 7 && PS.owner.client?.prefs.cit_toggles & SEX_JITTER)
					PS.owner.Jitter(relayed_intensity / 2)

			if(PORTAL_SENSATION_EDGING)
				to_chat(PS.owner, span_lewd("<i>[sender_nick] приближается к грани...</i>"))

			if(PORTAL_SENSATION_CLIMAX)
				var/relayed_lust = round(intensity * relay_multiplier)
				PS.owner.handle_post_sex(relayed_lust, null, sender, null, FALSE, TRUE)
				to_chat(PS.owner, span_lewd("<b>[sender_nick] испытывает оргазм! Волна удовольствия проходит через сеть...</b>"))
				if(PS.owner.client?.prefs.cit_toggles & SEX_JITTER)
					PS.owner.do_jitter_animation()

/// Check if recipient accepts this type of sensation
/datum/portal_network/proc/recipient_accepts_sensation(datum/portal_settings/PS, sensation_type)
	switch(sensation_type)
		if(PORTAL_SENSATION_VIBRATION)
			return PS.relay_vibrations
		if(PORTAL_SENSATION_EDGING)
			return PS.relay_edging
		if(PORTAL_SENSATION_CLIMAX)
			return PS.relay_climax
	return TRUE

/// Get list of member nicknames for display
/datum/portal_network/proc/get_member_list()
	var/list/result = list()
	for(var/datum/portal_settings/PS as anything in members)
		var/nickname = get_portal_nickname(PS.owner)
		var/mood_color = PS.get_mood_color()
		var/mood_text = PS.get_mood_text()
		result += list(list(
			"nickname" = nickname,
			"mood_color" = mood_color,
			"mood_text" = mood_text,
			"is_owner" = (PS.owner?.ckey == owner_ckey)
		))
	return result

// Extended portal panties
// NOTE: Variables portal_settings and private_pair are declared in fleshlight.dm

/obj/item/clothing/underwear/briefs/panties/portalpanties/Initialize(mapload)
	. = ..()
	portal_settings = new()
	portal_settings.parent_device = WEAKREF(src)

/obj/item/clothing/underwear/briefs/panties/portalpanties/Destroy()
	QDEL_NULL(portal_settings)
	private_pair = null
	return ..()

/// Check if spoken message contains the safeword
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/on_owner_hear(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	var/raw_message = hearing_args[HEARING_RAW_MESSAGE]
	if(portal_settings?.check_safeword(raw_message))
		INVOKE_ASYNC(src, PROC_REF(trigger_safeword), portal_settings.owner)

/obj/item/clothing/underwear/briefs/panties/portalpanties/process(delta_time)
	if(!portal_settings?.owner)
		return PROCESS_KILL

	// Throttle processing to reduce per-tick overhead (process 10 times per second)
	process_accumulated_time += delta_time
	if(process_accumulated_time < 0.1)
		return
	var/accumulated_delta = process_accumulated_time
	process_accumulated_time = 0

	portal_settings.update_mood()

	// Determine effective vibration - use MAX of local and remote intensities
	var/effective_intensity = 0
	var/effective_pattern = portal_settings.vibration_pattern
	var/use_vibration = FALSE

	// Check local vibration intensity
	if(portal_settings.vibration_enabled)
		effective_intensity = portal_settings.vibration_intensity
		use_vibration = TRUE

	// Check remote vibrations and use if higher
	if(LAZYLEN(remote_vibrations))
		var/list/remote_effective = get_effective_remote_vibration()
		if(remote_effective["intensity"] > effective_intensity)
			effective_intensity = remote_effective["intensity"]
			effective_pattern = remote_effective["pattern"]
			use_vibration = TRUE

	// Process vibration ONCE with the highest effective intensity
	if(use_vibration && effective_intensity > 0)
		var/saved_enabled = portal_settings.vibration_enabled
		var/saved_intensity = portal_settings.vibration_intensity
		var/saved_pattern = portal_settings.vibration_pattern

		portal_settings.vibration_enabled = TRUE
		portal_settings.vibration_intensity = effective_intensity
		portal_settings.vibration_pattern = effective_pattern

		portal_settings.process_vibration(accumulated_delta, get_insertion_location_text())

		portal_settings.vibration_enabled = saved_enabled
		portal_settings.vibration_intensity = saved_intensity
		portal_settings.vibration_pattern = saved_pattern

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/start_vibration(mob/living/carbon/human/initiator = null)
	portal_settings.vibration_enabled = TRUE
	portal_settings.last_activity = world.time
	if(portal_settings.owner)
		to_chat(portal_settings.owner, span_lewd("Портальные трусики начинают вибрировать!"))
	if(initiator && initiator != portal_settings.owner)
		portal_settings.add_to_history(initiator, "включил вибрацию")

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/stop_vibration()
	portal_settings.vibration_enabled = FALSE
	if(portal_settings.owner)
		to_chat(portal_settings.owner, span_notice("Вибрация портальных трусиков прекращается."))

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/send_portal_whisper(mob/living/carbon/human/sender, message)
	// Check telecomms availability
	if(!can_portal_telecomms())
		to_chat(sender, span_warning("Нет связи с сервером! Шёпот недоступен."))
		return

	var/nickname = get_portal_nickname(sender)

	// ALWAYS show the sender whispering into the device (visible to nearby for RP)
	sender.visible_message(
		span_lewd("<b>[sender]</b> шепчет что-то в портальное устройство..."),
		span_lewd("<i>Вы шепчете сквозь портал:</i> \"[message]\""),
		vision_distance = 1
	)

	var/any_delivered = FALSE
	var/list/already_heard = list() // Don't add sender initially - they should hear echo if nearby

	// Broadcast whisper to all connected fleshlight locations
	for(var/obj/item/portallight/PL in portallight)
		var/turf/broadcast_turf = get_turf(PL)
		if(!broadcast_turf)
			continue
		any_delivered = TRUE
		// Broadcast to nearby mobs (range 1 = 3x3 area)
		for(var/mob/living/L in range(broadcast_turf, 1))
			if(L == sender)
				// Sender hears echo only if not already heard from another device
				if(!(L in already_heard))
					to_chat(L, span_lewd("<i>Ваш шёпот доносится из портала:</i> \"[message]\""))
					already_heard |= L
				continue
			if(L in already_heard)
				continue
			to_chat(L, span_lewd("<i>Шёпот сквозь портал от [nickname]:</i> \"[message]\""))
			already_heard |= L

	// Also broadcast to private pair location if exists
	if(private_pair)
		var/turf/broadcast_turf = get_turf(private_pair)
		if(broadcast_turf)
			any_delivered = TRUE
			for(var/mob/living/L in range(broadcast_turf, 1))
				if(L == sender)
					// Sender hears echo only if not already heard from another device
					if(!(L in already_heard))
						to_chat(L, span_lewd("<i>Ваш шёпот доносится из портала:</i> \"[message]\""))
						already_heard |= L
					continue
				if(L in already_heard)
					continue
				to_chat(L, span_lewd("<i>Шёпот сквозь портал от [nickname]:</i> \"[message]\""))
				already_heard |= L

	// Network delivery (if in network)
	if(portal_settings?.network)
		portal_settings.network.broadcast_whisper(sender, nickname, message)
		any_delivered = TRUE

	if(!any_delivered)
		to_chat(sender, span_warning("На другой стороне никого нет."))

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/get_fleshlight_holder(obj/item/portallight/PL)
	if(ishuman(PL.loc))
		return PL.loc
	var/datum/component/genital_equipment/equipment = PL.GetComponent(/datum/component/genital_equipment)
	if(equipment?.holder_genital)
		return equipment.get_wearer()
	return null

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/trigger_safeword(mob/living/carbon/human/user)
	// Instantly disconnect all connections
	to_chat(user, span_warning("СТОП-СЛОВО АКТИВИРОВАНО! Все соединения разорваны."))
	// Notify all connected partners and record history
	for(var/obj/item/portallight/PL in portallight)
		var/mob/living/carbon/human/partner = get_fleshlight_holder(PL)
		if(partner)
			to_chat(partner, span_warning("Партнёр использовал стоп-слово. Соединение разорвано."))
			PL.portal_settings?.add_to_history(user, "стоп-слово")
	portal_settings.add_to_history(user, "активировал стоп-слово")
	// Disconnect
	LAZYCLEARLIST(portallight)
	LAZYCLEARLIST(remote_vibrations)  // Clear remote vibrations to stop all incoming effects
	private_pair = null
	stop_vibration()
	portal_settings.connection_mode = PORTAL_MODE_DISABLED
	// Unlock latex key if locked (safety escape mechanism)
	if(seamless)
		seamless = FALSE
		REMOVE_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)
		to_chat(user, span_warning("Латексный замок был снят!"))
	portal_settings.do_not_disturb = TRUE
	// 5 minute cooldown
	addtimer(CALLBACK(src, PROC_REF(clear_safeword_cooldown)), 5 MINUTES)

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/clear_safeword_cooldown()
	portal_settings.do_not_disturb = FALSE
	if(portal_settings.owner)
		to_chat(portal_settings.owner, span_notice("Портальные трусики снова готовы к подключению."))

/// Регистрация удалённой вибрации от fleshlight
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/register_remote_vibration(obj/item/portallight/PL, intensity, pattern)
	if(!PL)
		return
	var/ref = REF(PL)
	var/mob/living/carbon/human/holder
	if(ishuman(PL.loc))
		holder = PL.loc
	else
		var/datum/component/genital_equipment/equipment = PL.GetComponent(/datum/component/genital_equipment)
		if(equipment?.holder_genital)
			holder = equipment.get_wearer()
	var/nickname = get_portal_nickname(holder, "Аноним")
	LAZYSET(remote_vibrations, ref, list(
		"nickname" = nickname,
		"intensity" = intensity,
		"pattern" = pattern
	))
	SStgui.update_uis(src)

/// Обновление параметров удалённой вибрации
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/update_remote_vibration(obj/item/portallight/PL, intensity = null, pattern = null)
	if(!PL)
		return
	var/ref = REF(PL)
	if(!LAZYACCESS(remote_vibrations, ref))
		return
	if(!isnull(intensity))
		remote_vibrations[ref]["intensity"] = intensity
	if(!isnull(pattern))
		remote_vibrations[ref]["pattern"] = pattern
	SStgui.update_uis(src)

/// Снятие удалённой вибрации
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/unregister_remote_vibration(obj/item/portallight/PL)
	if(!PL)
		return
	LAZYREMOVE(remote_vibrations, REF(PL))
	SStgui.update_uis(src)

/// Получить эффективную (максимальную) вибрацию от всех удалённых источников
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/get_effective_remote_vibration()
	var/max_intensity = 0
	var/max_pattern = VIBE_PATTERN_CONSTANT
	for(var/ref in remote_vibrations)
		var/list/vibe_data = remote_vibrations[ref]
		if(vibe_data["intensity"] > max_intensity)
			max_intensity = vibe_data["intensity"]
			max_pattern = vibe_data["pattern"]
	return list("intensity" = max_intensity, "pattern" = max_pattern)

/// Получить список активных вибраторов для UI
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/get_active_vibrators_data()
	var/list/result = list()
	for(var/ref in remote_vibrations)
		var/list/vibe_data = remote_vibrations[ref]
		result += list(list(
			"ref" = ref,
			"nickname" = vibe_data["nickname"],
			"intensity" = vibe_data["intensity"],
			"pattern" = vibe_data["pattern"]
		))
	return result

/// Получить никнеймы всех подключённых fleshlights
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/get_connected_nicknames()
	var/list/nicknames = list()
	for(var/obj/item/portallight/PL in portallight)
		var/mob/living/carbon/human/holder
		if(ishuman(PL.loc))
			holder = PL.loc
		else
			var/datum/component/genital_equipment/equipment = PL.GetComponent(/datum/component/genital_equipment)
			if(equipment?.holder_genital)
				holder = equipment.get_wearer()
		nicknames += get_portal_nickname(holder, "Аноним")
	return nicknames

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/set_private_pair(obj/item/portallight/PL)
	private_pair = PL
	portal_settings.connection_mode = PORTAL_MODE_PRIVATE
	if(PL)
		PL.private_pair = src
		PL.portal_settings?.connection_mode = PORTAL_MODE_PRIVATE

// Extended portal fleshlight
// NOTE: Variables portal_settings and private_pair are declared in fleshlight.dm

/obj/item/portallight/Initialize(mapload)
	. = ..()
	portal_settings = new()
	portal_settings.parent_device = WEAKREF(src)

/obj/item/portallight/Destroy()
	// Clean up connections before destruction
	if(portalunderwear)
		portalunderwear.unregister_remote_vibration(src)
		portalunderwear.portallight -= src
		portalunderwear = null
	QDEL_NULL(portal_settings)
	QDEL_NULL(held_target_action)
	private_pair = null
	return ..()

/obj/item/portallight/pickup(mob/user)
	. = ..()
	if(ishuman(user))
		portal_settings.owner = user
		START_PROCESSING(SSobj, src)
		RegisterSignal(user, COMSIG_MOVABLE_HEAR, PROC_REF(on_owner_hear))
		// Grant target switch action when picked up
		if(!held_target_action)
			held_target_action = new /datum/action/portal_target_switch(src)
		held_target_action.Grant(user)

/obj/item/portallight/dropped(mob/user)
	. = ..()
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	if(!equipment?.holder_genital)
		UnregisterSignal(user, COMSIG_MOVABLE_HEAR)
		portal_settings.owner = null
		STOP_PROCESSING(SSobj, src)
		// Revoke target switch action when dropped
		if(held_target_action)
			held_target_action.Remove(user)

/// Check if spoken message contains the safeword
/obj/item/portallight/proc/on_owner_hear(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	var/raw_message = hearing_args[HEARING_RAW_MESSAGE]
	if(portal_settings?.check_safeword(raw_message))
		INVOKE_ASYNC(src, PROC_REF(trigger_safeword), portal_settings.owner)

/obj/item/portallight/process(delta_time)
	if(!portal_settings?.owner)
		return PROCESS_KILL

	// Throttle processing to reduce per-tick overhead (process 10 times per second)
	process_accumulated_time += delta_time
	if(process_accumulated_time < 0.1)
		return
	var/accumulated_delta = process_accumulated_time
	process_accumulated_time = 0

	portal_settings.update_mood()
	// Handle vibration using shared code
	if(portal_settings.vibration_enabled)
		portal_settings.process_vibration(accumulated_delta, get_insertion_location_text())

/obj/item/portallight/proc/start_vibration(mob/living/carbon/human/initiator = null)
	portal_settings.vibration_enabled = TRUE
	portal_settings.last_activity = world.time
	if(portal_settings.owner)
		to_chat(portal_settings.owner, span_lewd("Портальный фонарик начинает вибрировать!"))
	if(initiator && initiator != portal_settings.owner)
		portal_settings.add_to_history(initiator, "включил вибрацию")

/obj/item/portallight/proc/stop_vibration()
	portal_settings.vibration_enabled = FALSE
	if(portal_settings.owner)
		to_chat(portal_settings.owner, span_notice("Вибрация портального фонарика прекращается."))

/obj/item/portallight/proc/send_portal_whisper(mob/living/carbon/human/sender, message)
	// Check telecomms availability
	if(!can_portal_telecomms())
		to_chat(sender, span_warning("Нет связи с сервером! Шёпот недоступен."))
		return

	var/nickname = get_portal_nickname(sender)

	// ALWAYS show the sender whispering into the device (visible to nearby for RP)
	sender.visible_message(
		span_lewd("<b>[sender]</b> шепчет что-то в портальное устройство..."),
		span_lewd("<i>Вы шепчете сквозь портал:</i> \"[message]\""),
		vision_distance = 1
	)

	var/any_delivered = FALSE
	var/list/already_heard = list() // Don't add sender initially - they should hear echo if nearby

	// Direct connection delivery
	var/obj/target_panties = portalunderwear || private_pair
	if(target_panties)
		var/turf/broadcast_turf = get_turf(target_panties)
		if(broadcast_turf)
			any_delivered = TRUE
			// Broadcast from panties location to nearby mobs (range 1 = 3x3 area)
			for(var/mob/living/L in range(broadcast_turf, 1))
				if(L == sender)
					// Sender hears echo only if not already heard from another device
					if(!(L in already_heard))
						to_chat(L, span_lewd("<i>Ваш шёпот доносится из портала:</i> \"[message]\""))
						already_heard |= L
					continue
				if(L in already_heard)
					continue
				to_chat(L, span_lewd("<i>Шёпот сквозь портал от [nickname]:</i> \"[message]\""))
				already_heard |= L

	// Network delivery (if in network)
	if(portal_settings?.network)
		portal_settings.network.broadcast_whisper(sender, nickname, message)
		any_delivered = TRUE

	if(!any_delivered)
		to_chat(sender, span_warning("На другой стороне никого нет."))

/obj/item/portallight/proc/get_panties_wearer(obj/item/clothing/underwear/briefs/panties/portalpanties/PP)
	// Check if panties are worn (as underwear or mask) - must check mob slots directly
	if(ishuman(PP.loc))
		var/mob/living/carbon/human/H = PP.loc
		if(H.w_underwear == PP || H.wear_mask == PP)
			return H
	// Check if panties are inside a genital organ
	if(istype(PP.loc, /obj/item/organ/genital))
		var/obj/item/organ/genital/G = PP.loc
		return G.owner
	// Check if panties are held by a human (in hand/pocket/etc.)
	if(ishuman(PP.loc))
		return PP.loc
	return null

/obj/item/portallight/proc/trigger_safeword(mob/living/carbon/human/user)
	to_chat(user, span_warning("СТОП-СЛОВО АКТИВИРОВАНО! Соединение разорвано."))
	// Notify partner and record history
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/target_panties = portalunderwear || private_pair
	if(target_panties)
		var/mob/living/carbon/human/partner = get_panties_wearer(target_panties)
		if(partner)
			to_chat(partner, span_warning("Партнёр использовал стоп-слово. Соединение разорвано."))
		target_panties.portal_settings?.add_to_history(user, "стоп-слово")
		target_panties.unregister_remote_vibration(src)  // Remove our remote vibration before disconnecting
		target_panties.portallight -= src
	portal_settings.add_to_history(user, "активировал стоп-слово")
	// Disconnect
	portalunderwear = null
	private_pair = null
	stop_vibration()
	portal_settings.do_not_disturb = TRUE
	icon_state = "unpaired"
	update_appearance()
	// 5 minute cooldown
	addtimer(CALLBACK(src, PROC_REF(clear_safeword_cooldown)), 5 MINUTES)

/obj/item/portallight/proc/clear_safeword_cooldown()
	portal_settings.do_not_disturb = FALSE
	if(portal_settings.owner)
		to_chat(portal_settings.owner, span_notice("Портальный фонарик снова готов к подключению."))

/obj/item/portallight/proc/set_private_pair(obj/item/clothing/underwear/briefs/panties/portalpanties/PP)
	private_pair = PP
	portal_settings.connection_mode = PORTAL_MODE_PRIVATE
	if(PP)
		PP.private_pair = src
		PP.portal_settings?.connection_mode = PORTAL_MODE_PRIVATE

// TGUI interface
/obj/item/clothing/underwear/briefs/panties/portalpanties/ui_state(mob/user)
	return GLOB.portal_device_state

// Override ui_status directly for more reliable control
// This bypasses the state system's distance/view checks when item is inserted or worn
/obj/item/clothing/underwear/briefs/panties/portalpanties/ui_status(mob/user, datum/ui_state/state)
	// When inserted into owner's genital, give full control
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	if(equipment?.holder_genital?.owner == user)
		if(!user.client)
			return UI_CLOSE
		if(user.stat)
			return UI_DISABLED
		if(user.incapacitated())
			return UI_UPDATE
		return UI_INTERACTIVE

	// When worn as underwear or mask by user
	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		if(H == user && (current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)))
			if(!user.client)
				return UI_CLOSE
			if(user.stat)
				return UI_DISABLED
			if(user.incapacitated())
				return UI_UPDATE
			return UI_INTERACTIVE

	// Fall back to default for standard checks (in hands, nearby, etc.)
	return ..()

// Same for fleshlight
/obj/item/portallight/ui_status(mob/user, datum/ui_state/state)
	// When inserted into owner's genital, give full control
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	if(equipment?.holder_genital?.owner == user)
		if(!user.client)
			return UI_CLOSE
		if(user.stat)
			return UI_DISABLED
		if(user.incapacitated())
			return UI_UPDATE
		return UI_INTERACTIVE

	// Fall back to default for standard checks (in hands, nearby, etc.)
	return ..()

/obj/item/clothing/underwear/briefs/panties/portalpanties/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PortalDevice")
		ui.open()

/obj/item/clothing/underwear/briefs/panties/portalpanties/ui_data(mob/user)
	var/list/data = list()
	data["device_type"] = "panties"
	data["device_name"] = name
	data["is_owner"] = (portal_settings?.owner == user)
	// Passive mode: worn or inserted - limited control (read-only status + safety only)
	data["is_passive_mode"] = is_passive_mode(user)
	// Connection info
	data["connection_mode"] = portal_settings?.connection_mode || PORTAL_MODE_DISABLED
	data["telecomms_available"] = can_portal_telecomms()
	data["connected_count"] = portallight?.len || 0
	data["has_private_pair"] = !!private_pair
	// List of connected fleshlights with details
	var/list/connected_devices = list()
	for(var/obj/item/portallight/PL in portallight)
		var/mob/living/carbon/human/holder = get_fleshlight_holder(PL)
		var/holder_nick = get_portal_nickname(holder)
		connected_devices += list(list(
			"ref" = REF(PL),
			"name" = holder_nick,
			"mood_color" = PL.portal_settings?.get_mood_color() || "#888888",
			"mood_text" = PL.portal_settings?.get_mood_text() || "Неизвестно"
		))
	data["connected_devices"] = connected_devices
	// Remote vibrations data (for multiple simultaneous connections)
	data["active_vibrations"] = get_active_vibrators_data()
	data["has_remote_vibration"] = LAZYLEN(remote_vibrations) > 0
	var/list/effective = get_effective_remote_vibration()
	data["effective_intensity"] = effective["intensity"]
	data["effective_pattern"] = effective["pattern"]
	// Privacy settings for public mode
	data["public_privacy_mode"] = portal_settings?.public_privacy_mode || PORTAL_PRIVACY_COUNT_ONLY
	// Vibration settings - use !! to ensure proper boolean conversion
	data["vibration_enabled"] = !!(portal_settings?.vibration_enabled)
	data["vibration_pattern"] = portal_settings?.vibration_pattern || VIBE_PATTERN_CONSTANT
	data["vibration_intensity"] = portal_settings?.vibration_intensity || 5
	data["relay_intensity"] = portal_settings?.relay_intensity || 100
	// Status
	data["mood"] = portal_settings?.current_mood || PORTAL_MOOD_IDLE
	data["mood_color"] = portal_settings?.get_mood_color() || "#ffffff"
	data["mood_text"] = portal_settings?.get_mood_text() || "Неизвестно"
	data["do_not_disturb"] = !!(portal_settings?.do_not_disturb)
	// Public emotes and edging
	data["public_emotes_enabled"] = portal_settings ? !!(portal_settings.public_emotes_enabled) : TRUE
	data["edging_enabled"] = !!(portal_settings?.edging_enabled)
	// Customization
	data["safeword"] = portal_settings?.safeword || "красный"
	data["safeword_enabled"] = !!(portal_settings?.safeword_enabled)
	// Latex key lock status (panties only) - use !! to ensure boolean, not 0
	data["seamless_locked"] = !!seamless
	// Owner's portal nickname for display
	var/mob/living/carbon/human/H = user
	if(ishuman(user))
		data["owner_nickname"] = get_portal_nickname(H, "")
	// Lists - using nicknames instead of ckeys for anonymity
	data["blocked_nicknames"] = portal_settings?.blocked_nicknames || list()
	data["allowed_nicknames"] = portal_settings?.allowed_nicknames || list()
	data["connection_history"] = portal_settings?.connection_history || list()
	// Vibration patterns with descriptions
	data["available_patterns"] = portal_settings?.get_available_patterns_data() || list()
	// Control mode settings (D/s support)
	data["control_mode"] = portal_settings?.control_mode || PORTAL_CONTROL_SELF
	data["intensity_locked"] = !!(portal_settings?.intensity_locked)
	data["max_allowed_intensity"] = portal_settings?.max_allowed_intensity
	data["min_forced_intensity"] = portal_settings?.min_forced_intensity
	// Quick messages
	data["quick_messages"] = portal_settings?.quick_messages || PORTAL_QUICK_MESSAGES
	// Network data
	data["in_network"] = !!portal_settings?.network
	data["network_name"] = portal_settings?.network?.name || ""
	data["network_members"] = portal_settings?.network?.get_member_list() || list()
	data["is_network_owner"] = portal_settings?.network?.owner_ckey == user?.ckey
	// Network relay toggles
	data["relay_vibrations"] = portal_settings?.relay_vibrations
	data["relay_edging"] = portal_settings?.relay_edging
	data["relay_climax"] = portal_settings?.relay_climax
	// Available networks for joining
	var/list/available_networks = list()
	for(var/datum/portal_network/net in GLOB.portal_networks)
		if(!(portal_settings in net.members) && net.members.len < net.max_members)
			available_networks += list(list("name" = net.name, "has_password" = !!net.password, "ref" = REF(net)))
	data["available_networks"] = available_networks
	return data

/obj/item/clothing/underwear/briefs/panties/portalpanties/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/user = usr
	if(!ishuman(user))
		return FALSE

	// Passive mode restrictions: only safety and communication actions allowed
	var/passive_mode = is_passive_mode(user)
	if(passive_mode)
		var/static/list/passive_allowed = list(
			"trigger_safeword",
			"toggle_dnd",
			"set_safeword",
			"disconnect_one",
			"disconnect_all",
			"send_whisper",
			"send_emote",
			"send_quick_message",
			"add_blocked",
			"remove_blocked",
			"add_allowed",
			"remove_allowed",
			"clear_allowed",
			"debug_dump"
		)
		if(!(action in passive_allowed))
			to_chat(user, span_warning("Снимите трусики для доступа к настройкам!"))
			return FALSE

	switch(action)
		if("debug_dump")
			debug_output_to_chat(user)
			return TRUE
		if("set_connection_mode")
			if(!portal_settings)
				return FALSE
			var/mode = params["mode"]
			// GROUP mode requires being in a network
			if(mode == PORTAL_MODE_GROUP && !portal_settings.network)
				to_chat(user, span_warning("Сначала создайте или присоединитесь к сети!"))
				return FALSE
			if(!(mode in list(PORTAL_MODE_PUBLIC, PORTAL_MODE_PRIVATE, PORTAL_MODE_GROUP, PORTAL_MODE_DISABLED)))
				return FALSE
			var/old_mode = portal_settings.connection_mode
			portal_settings.connection_mode = mode
			// Handle mode change notifications
			if(mode == PORTAL_MODE_PUBLIC && old_mode != PORTAL_MODE_PUBLIC)
				// Add to global public panties index
				GLOB.public_portal_panties |= src
				// Notify all fleshlights about new public device
				for(var/obj/item/portallight/P in GLOB.fleshlight_portallight)
					P.audible_message("[icon2html(P, hearers(P))] *beep* *beep* *beep* - Обнаружено новое публичное устройство!", hearing_distance = 2)
					playsound(P, 'sound/machines/triple_beep.ogg', ASSEMBLY_BEEP_VOLUME, TRUE)
					P.available_panties |= src
			else if(old_mode == PORTAL_MODE_PUBLIC && mode != PORTAL_MODE_PUBLIC)
				// Remove from global public panties index
				GLOB.public_portal_panties -= src
				// Remove from available_panties and disconnect
				for(var/obj/item/portallight/P in GLOB.fleshlight_portallight)
					P.available_panties -= src
					if(P.portalunderwear == src)
						P.portalunderwear = null
						P.updatesleeve()
						P.icon_state = "unpaired"
				// Disconnect all current connections if switching away from public
				if(mode == PORTAL_MODE_DISABLED)
					notify_all_connected("Подключения отключены владельцем устройства.")
					// Unregister all remote vibrations before clearing
					for(var/obj/item/portallight/PL in portallight)
						unregister_remote_vibration(PL)
					LAZYCLEARLIST(portallight)
					LAZYCLEARLIST(remote_vibrations)  // Clear any orphaned remote vibrations
			// Update network GROUP mode index when mode changes
			if(portal_settings.network && (old_mode == PORTAL_MODE_GROUP || mode == PORTAL_MODE_GROUP))
				portal_settings.network.update_group_panties_index(portal_settings)
			return TRUE
		if("set_privacy_mode")
			// Set privacy mode for public connections
			if(!portal_settings)
				return FALSE
			var/new_mode = params["mode"]
			if(new_mode in list(PORTAL_PRIVACY_COUNT_ONLY, PORTAL_PRIVACY_SHOW_NAMES))
				portal_settings.public_privacy_mode = new_mode
			return TRUE
		if("toggle_dnd")
			portal_settings.do_not_disturb = !portal_settings.do_not_disturb
			return TRUE
		if("toggle_public_emotes")
			if(!portal_settings)
				return FALSE
			portal_settings.public_emotes_enabled = !portal_settings.public_emotes_enabled
			return TRUE
		if("toggle_edging")
			if(!portal_settings)
				return FALSE
			portal_settings.edging_enabled = !portal_settings.edging_enabled
			portal_settings.edging_notified = FALSE  // Reset notification state
			return TRUE
		if("toggle_vibration")
			if(portal_settings.vibration_enabled)
				stop_vibration()
			else
				start_vibration()
			return TRUE
		if("set_pattern")
			if(!portal_settings)
				return FALSE
			var/pattern = params["pattern"]
			if(pattern in PORTAL_VALID_PATTERNS)
				portal_settings.vibration_pattern = pattern
			return TRUE
		if("set_intensity")
			if(!portal_settings)
				return FALSE
			var/intensity = clamp(params["intensity"], 1, 10)
			portal_settings.vibration_intensity = intensity
			return TRUE
		if("set_relay_intensity")
			if(!portal_settings)
				return FALSE
			var/relay = clamp(params["relay"], 25, 100)
			portal_settings.relay_intensity = relay
			return TRUE
		if("set_nickname", "set_device_nickname")
			// Update the user's portal nickname (used for emotes, whispers, etc.)
			var/new_nick = tgui_input_text(user, "Введите ваш портальный никнейм", "Портальный никнейм", user.fleshlight_nickname, 32)
			if(new_nick)
				new_nick = reject_bad_name(new_nick, allow_numbers = TRUE)
				if(new_nick)
					user.fleshlight_nickname = new_nick
			return TRUE
		if("set_safeword")
			if(!portal_settings)
				return FALSE
			var/new_word = tgui_input_text(user, "Введите стоп-слово", "Стоп-слово", portal_settings.safeword, 20)
			if(new_word)
				portal_settings.safeword = new_word
			return TRUE
		if("toggle_safeword_enabled")
			if(!portal_settings)
				return FALSE
			portal_settings.safeword_enabled = !portal_settings.safeword_enabled
			return TRUE
		if("trigger_safeword")
			trigger_safeword(user)
			return TRUE
		if("send_whisper")
			var/message = tgui_input_text(user, "Введите сообщение", "Шёпот сквозь портал", "", 200)
			if(message)
				send_portal_whisper(user, message)
			return TRUE
		if("add_blocked")
			if(!portal_settings)
				return FALSE
			var/nickname = tgui_input_text(user, "Введите никнейм для блокировки", "Блокировка")
			if(nickname)
				portal_settings.blocked_nicknames |= nickname
			return TRUE
		if("remove_blocked")
			if(!portal_settings)
				return FALSE
			var/nickname = params["nickname"]
			portal_settings.blocked_nicknames -= nickname
			return TRUE
		if("add_allowed")
			if(!portal_settings)
				return FALSE
			var/nickname = tgui_input_text(user, "Введите никнейм для разрешения", "Белый список")
			if(nickname)
				portal_settings.allowed_nicknames |= nickname
			return TRUE
		if("remove_allowed")
			if(!portal_settings)
				return FALSE
			var/nickname = params["nickname"]
			portal_settings.allowed_nicknames -= nickname
			return TRUE
		if("clear_allowed")
			if(!portal_settings)
				return FALSE
			portal_settings.allowed_nicknames.Cut()
			return TRUE
		if("send_emote")
			user.emote("fleshlight")
			return TRUE
		if("disconnect_one")
			var/ref = params["ref"]
			var/obj/item/portallight/PL = locate(ref)
			if(!PL || !(PL in portallight))
				return FALSE
			// Notify the disconnected device holder
			var/mob/living/carbon/human/holder = get_fleshlight_holder(PL)
			if(holder)
				to_chat(holder, span_warning("Портальное соединение разорвано."))
			// Record history
			portal_settings?.add_to_history(holder, "отключён")
			PL.portal_settings?.add_to_history(user, "отключил")
			// Remove remote vibration and from list
			unregister_remote_vibration(PL)
			portallight -= PL
			PL.portalunderwear = null
			PL.icon_state = "unpaired"
			PL.update_appearance()
			playsound(PL, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
			return TRUE
		if("disconnect_all")
			// Notify all before clearing
			for(var/obj/item/portallight/PL in portallight)
				var/mob/living/carbon/human/holder = get_fleshlight_holder(PL)
				if(holder)
					to_chat(holder, span_warning("Портальное соединение разорвано."))
				unregister_remote_vibration(PL)
				PL.portalunderwear = null
				PL.icon_state = "unpaired"
				PL.update_appearance()
			LAZYCLEARLIST(portallight)
			LAZYCLEARLIST(remote_vibrations)  // Clear any orphaned remote vibrations
			private_pair = null
			return TRUE
		// Control mode actions (only Self and Partner modes - mutual removed as redundant)
		if("set_control_mode")
			if(!portal_settings)
				return FALSE
			var/mode = params["mode"]
			if(mode in list(PORTAL_CONTROL_SELF, PORTAL_CONTROL_PARTNER))
				portal_settings.control_mode = mode
			return TRUE
		if("toggle_intensity_lock")
			if(!portal_settings)
				return FALSE
			portal_settings.intensity_locked = !portal_settings.intensity_locked
			return TRUE
		if("set_intensity_limits")
			if(!portal_settings)
				return FALSE
			var/min_val = clamp(params["min"] || 0, 0, 10)
			var/max_val = clamp(params["max"] || 10, 0, 10)
			// Ensure min <= max
			if(min_val > max_val)
				var/temp = min_val
				min_val = max_val
				max_val = temp
			portal_settings.min_forced_intensity = min_val
			portal_settings.max_allowed_intensity = max_val
			return TRUE
		// Quick message actions
		if("send_quick_message")
			if(!portal_settings)
				return FALSE
			var/index = params["index"]
			var/list/recipients = list()
			for(var/obj/item/portallight/PL in portallight)
				var/mob/living/carbon/human/holder = get_fleshlight_holder(PL)
				if(holder)
					recipients += holder
			portal_settings.send_quick_message(index, user, recipients)
			return TRUE
		if("edit_quick_message")
			if(!portal_settings)
				return FALSE
			var/index = params["index"]
			if(index < 1 || index > portal_settings.quick_messages.len)
				return FALSE
			var/new_msg = tgui_input_text(user, "Введите новое быстрое сообщение", "Быстрое сообщение", portal_settings.quick_messages[index], 50)
			if(new_msg)
				portal_settings.quick_messages[index] = new_msg
			return TRUE
		// Network relay toggles
		if("toggle_relay_vibrations")
			if(!portal_settings)
				return FALSE
			portal_settings.relay_vibrations = !portal_settings.relay_vibrations
			return TRUE
		if("toggle_relay_edging")
			if(!portal_settings)
				return FALSE
			portal_settings.relay_edging = !portal_settings.relay_edging
			return TRUE
		if("toggle_relay_climax")
			if(!portal_settings)
				return FALSE
			portal_settings.relay_climax = !portal_settings.relay_climax
			return TRUE
		// Network actions
		if("create_network")
			if(!portal_settings)
				return FALSE
			var/net_name = tgui_input_text(user, "Название сети", "Создать сеть", "", 32)
			if(!net_name)
				return FALSE
			var/net_pass = tgui_input_text(user, "Пароль (оставьте пустым для открытой сети)", "Пароль", "", 20)
			var/datum/portal_network/new_net = new(net_name, user, net_pass)
			new_net.add_member(portal_settings)
			GLOB.portal_networks += new_net
			portal_settings.connection_mode = PORTAL_MODE_GROUP
			to_chat(user, span_notice("Сеть '[net_name]' создана!"))
			return TRUE
		if("join_network")
			if(!portal_settings)
				return FALSE
			var/ref = params["ref"]
			var/datum/portal_network/net = locate(ref) in GLOB.portal_networks
			if(!net)
				return FALSE
			if(net.password)
				var/entered_pass = tgui_input_text(user, "Введите пароль", "Пароль сети", "", 20)
				if(!net.add_member(portal_settings, entered_pass))
					to_chat(user, span_warning("Неверный пароль или сеть полна!"))
					return FALSE
			else
				if(!net.add_member(portal_settings))
					to_chat(user, span_warning("Не удалось присоединиться к сети!"))
					return FALSE
			portal_settings.connection_mode = PORTAL_MODE_GROUP
			to_chat(user, span_notice("Вы присоединились к сети '[net.name]'!"))
			return TRUE
		if("leave_network")
			if(!portal_settings?.network)
				return FALSE
			var/net_name = portal_settings.network.name
			portal_settings.network.remove_member(portal_settings)
			portal_settings.connection_mode = PORTAL_MODE_DISABLED
			to_chat(user, span_notice("Вы покинули сеть '[net_name]'."))
			return TRUE
		if("network_broadcast")
			if(!portal_settings?.network)
				return FALSE
			if(!can_portal_telecomms())
				to_chat(user, span_warning("Нет связи с сервером! Трансляция недоступна."))
				return FALSE
			var/message = tgui_input_text(user, "Сообщение для всей сети", "Трансляция", "", 200)
			if(message)
				var/nickname = get_portal_nickname(user)
				// Show sender speaking into device
				user.visible_message(
					span_notice("<b>[user]</b> говорит что-то в портальное устройство..."),
					span_notice("<i>Вы говорите в сеть:</i> \"[message]\""),
					vision_distance = 1
				)
				portal_settings.network.broadcast_message(user, "<b>[nickname]:</b> [message]")
			return TRUE
	return FALSE

/// Debug output proc - outputs all internal state to chat for debugging TGUI
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/debug_output_to_chat(mob/user)
	to_chat(user, span_boldnotice("=== PORTAL DEVICE DEBUG (PANTIES) ==="))

	// Section 1: Device Identity
	to_chat(user, span_notice("<b>--- Device Identity ---</b>"))
	to_chat(user, "  type: panties")
	to_chat(user, "  ref: [REF(src)]")
	to_chat(user, "  name: [name]")
	to_chat(user, "  loc: [loc] ([loc?.type])")
	var/mob/living/carbon/human/owner_mob = portal_settings?.owner
	to_chat(user, "  portal_settings: [portal_settings ? REF(portal_settings) : "NULL"]")
	to_chat(user, "  owner_mob: [owner_mob ? "[owner_mob] [REF(owner_mob)]" : "NULL"]")
	to_chat(user, "  owner_nickname: [owner_mob?.fleshlight_nickname || "NOT SET"]")
	to_chat(user, "  owner_ckey: [owner_mob?.ckey || "NULL"]")
	to_chat(user, "  is_passive_mode: [is_passive_mode(user)]")
	to_chat(user, "  is_owner: [portal_settings?.owner == user]")

	// Section 2: Connection State
	to_chat(user, span_notice("<b>--- Connection State ---</b>"))
	to_chat(user, "  connection_mode: [portal_settings?.connection_mode || "NULL"]")
	to_chat(user, "  telecomms_available: [can_portal_telecomms()]")
	to_chat(user, "  public_privacy_mode: [portal_settings?.public_privacy_mode || "NULL"]")
	to_chat(user, "  portallight list length: [LAZYLEN(portallight)]")
	if(LAZYLEN(portallight))
		var/idx = 1
		for(var/obj/item/portallight/PL as anything in portallight)
			var/mob/living/carbon/human/holder = get_fleshlight_holder(PL)
			to_chat(user, "    #[idx]: ref=[REF(PL)] holder=[holder?.fleshlight_nickname || "NONE"] mood=[PL.portal_settings?.current_mood || "?"]")
			idx++
	to_chat(user, "  private_pair: [private_pair ? REF(private_pair) : "NULL"]")
	to_chat(user, "  has_private_pair: [!!private_pair]")

	// Section 3: Vibration State
	to_chat(user, span_notice("<b>--- Vibration State ---</b>"))
	to_chat(user, "  vibration_enabled: [portal_settings?.vibration_enabled]")
	to_chat(user, "  vibration_pattern: [portal_settings?.vibration_pattern || "NULL"]")
	to_chat(user, "  vibration_intensity: [portal_settings?.vibration_intensity]")
	to_chat(user, "  relay_intensity: [portal_settings?.relay_intensity]%")

	// Remote vibrations
	to_chat(user, "  remote_vibrations count: [LAZYLEN(remote_vibrations)]")
	if(LAZYLEN(remote_vibrations))
		for(var/ref in remote_vibrations)
			var/list/vibe_data = remote_vibrations[ref]
			to_chat(user, "    [ref]: intensity=[vibe_data["intensity"]], pattern=[vibe_data["pattern"]]")

	// Calculate effective vibration
	var/has_remote = LAZYLEN(remote_vibrations) > 0
	var/effective_intensity = portal_settings?.vibration_intensity || 0
	var/effective_pattern = portal_settings?.vibration_pattern || VIBE_PATTERN_CONSTANT
	if(has_remote)
		for(var/ref in remote_vibrations)
			var/list/vibe_data = remote_vibrations[ref]
			if(vibe_data["intensity"] > effective_intensity)
				effective_intensity = vibe_data["intensity"]
				effective_pattern = vibe_data["pattern"]
	to_chat(user, "  has_remote_vibration: [has_remote]")
	to_chat(user, "  effective_intensity: [effective_intensity]")
	to_chat(user, "  effective_pattern: [effective_pattern]")

	// Section 4: Mood & Status
	to_chat(user, span_notice("<b>--- Mood and Status ---</b>"))
	to_chat(user, "  current_mood: [portal_settings?.current_mood || "NULL"]")
	to_chat(user, "  do_not_disturb: [portal_settings?.do_not_disturb]")
	to_chat(user, "  last_activity: [portal_settings?.last_activity] (world.time=[world.time])")
	if(owner_mob)
		var/datum/component/mood/mood_component = owner_mob.GetComponent(/datum/component/mood)
		to_chat(user, "  owner lust: [owner_mob.lust]")
		to_chat(user, "  owner climax_threshold: [owner_mob.get_climax_threshold()]")
		to_chat(user, "  owner mood_component: [mood_component ? "EXISTS" : "NULL"]")

	// Section 5: Control Mode (D/s)
	to_chat(user, span_notice("<b>--- Control Mode ---</b>"))
	to_chat(user, "  control_mode: [portal_settings?.control_mode || "NULL"]")
	to_chat(user, "  intensity_locked: [portal_settings?.intensity_locked]")
	to_chat(user, "  max_allowed_intensity: [portal_settings?.max_allowed_intensity]")
	to_chat(user, "  min_forced_intensity: [portal_settings?.min_forced_intensity]")

	// Section 6: RP Settings
	to_chat(user, span_notice("<b>--- RP Settings ---</b>"))
	to_chat(user, "  public_emotes_enabled: [portal_settings?.public_emotes_enabled]")
	to_chat(user, "  last_public_emote: [portal_settings?.last_public_emote] (cooldown: [PORTAL_EMOTE_COOLDOWN])")
	to_chat(user, "  edging_enabled: [portal_settings?.edging_enabled]")
	to_chat(user, "  edging_notified: [portal_settings?.edging_notified]")

	// Section 7: Network State
	to_chat(user, span_notice("<b>--- Network State ---</b>"))
	var/datum/portal_network/net = portal_settings?.network
	to_chat(user, "  in_network: [!!net]")
	if(net)
		to_chat(user, "  network_ref: [REF(net)]")
		to_chat(user, "  network_name: [net.name]")
		to_chat(user, "  network_owner_ckey: [net.owner_ckey]")
		to_chat(user, "  is_network_owner: [net.owner_ckey == user.ckey]")
		to_chat(user, "  network_members count: [net.members.len]")
		var/midx = 1
		for(var/datum/portal_settings/PS as anything in net.members)
			to_chat(user, "    #[midx]: [PS.owner?.fleshlight_nickname || "?"] (owner_ref=[PS.owner ? REF(PS.owner) : "NULL"])")
			midx++
	to_chat(user, "  relay_vibrations: [portal_settings?.relay_vibrations]")
	to_chat(user, "  relay_edging: [portal_settings?.relay_edging]")
	to_chat(user, "  relay_climax: [portal_settings?.relay_climax]")
	to_chat(user, "  last_network_vibration_relay: [portal_settings?.last_network_vibration_relay]")

	// Available networks
	to_chat(user, "  available_networks (GLOB): [GLOB.portal_networks.len]")
	for(var/datum/portal_network/available_net as anything in GLOB.portal_networks)
		to_chat(user, "    - [available_net.name] (members=[available_net.members.len], has_pass=[!!available_net.password])")

	// Section 8: Safety
	to_chat(user, span_notice("<b>--- Safety ---</b>"))
	to_chat(user, "  safeword: [portal_settings?.safeword || "NOT SET"]")
	to_chat(user, "  safeword_enabled: [portal_settings?.safeword_enabled]")
	to_chat(user, "  seamless (latex lock): [seamless]")
	to_chat(user, "  blocked_nicknames: [portal_settings?.blocked_nicknames?.len || 0] - [json_encode(portal_settings?.blocked_nicknames)]")
	to_chat(user, "  allowed_nicknames: [portal_settings?.allowed_nicknames?.len || 0] - [json_encode(portal_settings?.allowed_nicknames)]")

	// Section 9: History
	to_chat(user, span_notice("<b>--- Connection History ---</b>"))
	to_chat(user, "  history entries: [portal_settings?.connection_history?.len || 0]")
	if(portal_settings?.connection_history?.len)
		for(var/list/entry in portal_settings.connection_history)
			to_chat(user, "    [entry["time_text"]] - [entry["partner_nick"]]: [entry["action"]]")

	// Section 10: Quick Messages
	to_chat(user, span_notice("<b>--- Quick Messages ---</b>"))
	if(portal_settings?.quick_messages?.len)
		var/qidx = 1
		for(var/msg in portal_settings.quick_messages)
			to_chat(user, "    #[qidx]: [msg]")
			qidx++

	to_chat(user, span_boldnotice("=== END DEBUG ==="))

// Same TGUI for fleshlight
/obj/item/portallight/ui_state(mob/user)
	return GLOB.portal_device_state

/obj/item/portallight/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PortalDevice")
		ui.open()

/obj/item/portallight/ui_data(mob/user)
	var/list/data = list()
	data["device_type"] = "fleshlight"
	data["device_name"] = name
	data["is_owner"] = (portal_settings?.owner == user)
	// Connection info
	data["connection_mode"] = portal_settings?.connection_mode || PORTAL_MODE_DISABLED
	data["telecomms_available"] = can_portal_telecomms()
	data["connected"] = !!portalunderwear
	// Show partner's portal nickname for connected panties
	var/mob/living/carbon/human/partner = portalunderwear ? get_panties_wearer(portalunderwear) : null
	data["connected_name"] = get_portal_nickname(partner, "Не подключено")
	data["has_private_pair"] = !!private_pair
	// Partner mood info (for fleshlight showing connected panties wearer mood)
	data["partner_mood_color"] = portalunderwear?.portal_settings?.get_mood_color() || "#888888"
	data["partner_mood_text"] = portalunderwear?.portal_settings?.get_mood_text() || "Не подключено"
	// Info about other connected devices
	if(portalunderwear)
		data["target_connected_count"] = LAZYLEN(portalunderwear.portallight)
		// Show names only if privacy allows
		if(portalunderwear.portal_settings?.public_privacy_mode == PORTAL_PRIVACY_SHOW_NAMES)
			data["target_connected_names"] = portalunderwear.get_connected_nicknames()
		else
			data["target_connected_names"] = null
		// Check if our remote vibration is active
		data["our_remote_vibration_active"] = !!LAZYACCESS(portalunderwear.remote_vibrations, REF(src))
	else
		data["target_connected_count"] = 0
		data["target_connected_names"] = null
		data["our_remote_vibration_active"] = FALSE
	// Partner vibration info (for remote control)
	data["partner_vibration_enabled"] = portalunderwear?.portal_settings?.vibration_enabled || FALSE
	data["partner_vibration_intensity"] = portalunderwear?.portal_settings?.vibration_intensity || 5
	data["partner_vibration_pattern"] = portalunderwear?.portal_settings?.vibration_pattern || VIBE_PATTERN_CONSTANT
	// Vibration settings - use !! to ensure proper boolean conversion
	data["vibration_enabled"] = !!(portal_settings?.vibration_enabled)
	data["vibration_pattern"] = portal_settings?.vibration_pattern || VIBE_PATTERN_CONSTANT
	data["vibration_intensity"] = portal_settings?.vibration_intensity || 5
	data["relay_intensity"] = portal_settings?.relay_intensity || 100
	// Status
	data["mood"] = portal_settings?.current_mood || PORTAL_MOOD_IDLE
	data["mood_color"] = portal_settings?.get_mood_color() || "#ffffff"
	data["mood_text"] = portal_settings?.get_mood_text() || "Неизвестно"
	data["do_not_disturb"] = !!(portal_settings?.do_not_disturb)
	// Public emotes and edging
	data["public_emotes_enabled"] = portal_settings ? !!(portal_settings.public_emotes_enabled) : TRUE
	data["edging_enabled"] = !!(portal_settings?.edging_enabled)
	// Customization
	data["safeword"] = portal_settings?.safeword || "красный"
	data["safeword_enabled"] = !!(portal_settings?.safeword_enabled)
	// Owner's portal nickname for display
	var/mob/living/carbon/human/H = user
	if(ishuman(user))
		data["owner_nickname"] = get_portal_nickname(H, "")
	// Lists - using nicknames instead of ckeys for anonymity
	data["blocked_nicknames"] = portal_settings?.blocked_nicknames || list()
	data["allowed_nicknames"] = portal_settings?.allowed_nicknames || list()
	data["connection_history"] = portal_settings?.connection_history || list()
	// Available panties for connection
	var/list/available = list()
	var/list/added_refs = list()  // Track already added to avoid duplicates
	// Add panties from static available_panties list (PUBLIC mode)
	for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP in available_panties)
		var/pp_ref = REF(PP)
		if(pp_ref in added_refs)
			continue
		added_refs += pp_ref
		var/mob/living/carbon/human/wearer = get_panties_wearer(PP)
		var/display_name = get_portal_nickname(wearer, PP.name)
		// Add location suffix if inserted to distinguish multiple devices from same owner
		var/location_suffix = PP.get_short_location_suffix()
		if(location_suffix)
			display_name += " [location_suffix]"
		available += list(list("name" = display_name, "ref" = pp_ref))
	// Add panties in GROUP mode from the network's indexed list (no global scan needed)
	if(portal_settings?.network)
		for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP as anything in portal_settings.network.group_mode_panties)
			var/pp_ref = REF(PP)
			if(pp_ref in added_refs)
				continue
			added_refs += pp_ref
			var/mob/living/carbon/human/wearer = get_panties_wearer(PP)
			var/display_name = get_portal_nickname(wearer, PP.name)
			// Add location suffix if inserted to distinguish multiple devices from same owner
			var/location_suffix = PP.get_short_location_suffix()
			if(location_suffix)
				display_name += " [location_suffix]"
			available += list(list("name" = display_name, "ref" = pp_ref))
	data["available_panties"] = available
	// Vibration patterns with descriptions
	data["available_patterns"] = portal_settings?.get_available_patterns_data() || list()
	// Partner control mode for remote control restrictions (fleshlight doesn't need its own control_mode)
	data["partner_control_mode"] = portalunderwear?.portal_settings?.control_mode || PORTAL_CONTROL_SELF
	data["partner_intensity_locked"] = portalunderwear?.portal_settings?.intensity_locked || FALSE
	// Quick messages
	data["quick_messages"] = portal_settings?.quick_messages || PORTAL_QUICK_MESSAGES
	// Network data
	data["in_network"] = !!portal_settings?.network
	data["network_name"] = portal_settings?.network?.name || ""
	data["network_members"] = portal_settings?.network?.get_member_list() || list()
	data["is_network_owner"] = portal_settings?.network?.owner_ckey == user?.ckey
	// Network relay toggles
	data["relay_vibrations"] = portal_settings?.relay_vibrations
	data["relay_edging"] = portal_settings?.relay_edging
	data["relay_climax"] = portal_settings?.relay_climax
	// Available networks for joining
	var/list/available_networks = list()
	for(var/datum/portal_network/net in GLOB.portal_networks)
		if(!(portal_settings in net.members) && net.members.len < net.max_members)
			available_networks += list(list("name" = net.name, "has_password" = !!net.password, "ref" = REF(net)))
	data["available_networks"] = available_networks
	return data

/obj/item/portallight/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/user = usr
	if(!ishuman(user))
		return FALSE
	switch(action)
		if("debug_dump")
			debug_output_to_chat(user)
			return TRUE
		if("connect")
			var/ref = params["ref"]
			var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = locate(ref)
			// Check if panties is in PUBLIC mode list OR in network GROUP mode list
			var/valid_connection = (PP in available_panties)
			if(!valid_connection && portal_settings?.network)
				valid_connection = (PP in portal_settings.network.group_mode_panties)
			if(!PP || !valid_connection)
				return FALSE
			if(!PP.portal_settings?.can_connect_from(user))
				to_chat(user, span_warning("Подключение запрещено настройками устройства!"))
				return FALSE
			portalunderwear = PP
			PP.portallight |= src
			PP.update_portal()
			PP.notify_all_connected("Новое устройство подключено!")
			// Record history on both devices
			portal_settings.add_to_history(PP.portal_settings?.owner, "подключился")
			PP.portal_settings?.add_to_history(user, "подключился")
			icon_state = "paired"
			update_appearance()
			playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
			return TRUE
		if("disconnect")
			if(portalunderwear)
				// Unregister remote vibration before disconnecting
				portalunderwear.unregister_remote_vibration(src)
				// Record history before disconnecting
				portal_settings.add_to_history(portalunderwear.portal_settings?.owner, "отключился")
				portalunderwear.portal_settings?.add_to_history(user, "отключился")
				portalunderwear.notify_all_connected("Устройство отключено.")
				portalunderwear.portallight -= src
				portalunderwear.update_portal()
				portalunderwear = null
			private_pair = null
			icon_state = "unpaired"
			update_appearance()
			playsound(src, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
			return TRUE
		if("toggle_dnd")
			portal_settings.do_not_disturb = !portal_settings.do_not_disturb
			return TRUE
		if("toggle_public_emotes")
			if(!portal_settings)
				return FALSE
			portal_settings.public_emotes_enabled = !portal_settings.public_emotes_enabled
			return TRUE
		if("toggle_edging")
			if(!portal_settings)
				return FALSE
			portal_settings.edging_enabled = !portal_settings.edging_enabled
			portal_settings.edging_notified = FALSE  // Reset notification state
			return TRUE
		if("toggle_vibration")
			if(portal_settings.vibration_enabled)
				stop_vibration()
			else
				start_vibration()
			return TRUE
		if("set_pattern")
			var/pattern = params["pattern"]
			if(pattern in PORTAL_VALID_PATTERNS)
				portal_settings.vibration_pattern = pattern
			return TRUE
		if("set_intensity")
			var/intensity = clamp(params["intensity"], 1, 10)
			portal_settings.vibration_intensity = intensity
			return TRUE
		if("set_relay_intensity")
			if(!portal_settings)
				return FALSE
			var/relay = clamp(params["relay"], 25, 100)
			portal_settings.relay_intensity = relay
			return TRUE
		if("set_nickname", "set_device_nickname")
			// Update the user's portal nickname (used for emotes, whispers, etc.)
			var/new_nick = tgui_input_text(user, "Введите ваш портальный никнейм", "Портальный никнейм", user.fleshlight_nickname, 32)
			if(new_nick)
				new_nick = reject_bad_name(new_nick, allow_numbers = TRUE)
				if(new_nick)
					user.fleshlight_nickname = new_nick
			return TRUE
		if("set_safeword")
			if(!portal_settings)
				return FALSE
			var/new_word = tgui_input_text(user, "Введите стоп-слово", "Стоп-слово", portal_settings.safeword, 20)
			if(new_word)
				portal_settings.safeword = new_word
			return TRUE
		if("toggle_safeword_enabled")
			if(!portal_settings)
				return FALSE
			portal_settings.safeword_enabled = !portal_settings.safeword_enabled
			return TRUE
		if("trigger_safeword")
			trigger_safeword(user)
			return TRUE
		if("send_whisper")
			var/message = tgui_input_text(user, "Введите сообщение", "Шёпот сквозь портал", "", 200)
			if(message)
				send_portal_whisper(user, message)
			return TRUE
		if("add_blocked")
			if(!portal_settings)
				return FALSE
			var/nickname = tgui_input_text(user, "Введите никнейм для блокировки", "Блокировка")
			if(nickname)
				portal_settings.blocked_nicknames |= nickname
			return TRUE
		if("remove_blocked")
			if(!portal_settings)
				return FALSE
			var/nickname = params["nickname"]
			portal_settings.blocked_nicknames -= nickname
			return TRUE
		if("add_allowed")
			if(!portal_settings)
				return FALSE
			var/nickname = tgui_input_text(user, "Введите никнейм для разрешения", "Белый список")
			if(nickname)
				portal_settings.allowed_nicknames |= nickname
			return TRUE
		if("remove_allowed")
			if(!portal_settings)
				return FALSE
			var/nickname = params["nickname"]
			portal_settings.allowed_nicknames -= nickname
			return TRUE
		if("clear_allowed")
			if(!portal_settings)
				return FALSE
			portal_settings.allowed_nicknames.Cut()
			return TRUE
		if("send_emote")
			user.emote("fleshlight")
			return TRUE
		if("remote_vibrate")
			// Toggle our remote vibration on connected panties
			var/obj/item/clothing/underwear/briefs/panties/portalpanties/target_panties = portalunderwear || private_pair
			if(!target_panties?.portal_settings)
				return FALSE
			// Check control mode - partner can only control if mode is PARTNER or MUTUAL
			if(!target_panties.portal_settings.can_user_control(user, TRUE))
				to_chat(user, span_warning("Партнёр ограничил удалённое управление!"))
				return FALSE
			var/ref = REF(src)
			if(LAZYACCESS(target_panties.remote_vibrations, ref))
				// Turn off our vibration
				target_panties.unregister_remote_vibration(src)
				portal_settings?.add_to_history(target_panties.portal_settings?.owner, "выключил вибрацию")
			else
				// Turn on our vibration with current settings
				target_panties.register_remote_vibration(src, portal_settings.vibration_intensity, portal_settings.vibration_pattern)
				portal_settings?.add_to_history(target_panties.portal_settings?.owner, "включил вибрацию")
			return TRUE
		if("set_remote_intensity")
			// Set our vibration intensity on connected panties
			var/obj/item/clothing/underwear/briefs/panties/portalpanties/target_panties = portalunderwear || private_pair
			if(!target_panties?.portal_settings)
				return FALSE
			// Check control mode and intensity lock
			if(!target_panties.portal_settings.can_change_intensity(user, TRUE))
				to_chat(user, span_warning("Партнёр заблокировал изменение интенсивности!"))
				return FALSE
			var/intensity = clamp(params["intensity"], 1, 10)
			// Apply owner's intensity limits
			var/datum/portal_settings/PS = target_panties.portal_settings
			intensity = clamp(intensity, PS.min_forced_intensity, PS.max_allowed_intensity)
			// Update our local settings
			portal_settings.vibration_intensity = intensity
			// Update our remote vibration if active
			target_panties.update_remote_vibration(src, intensity, null)
			return TRUE
		if("set_remote_pattern")
			// Set our vibration pattern on connected panties
			var/obj/item/clothing/underwear/briefs/panties/portalpanties/target_panties = portalunderwear || private_pair
			if(!target_panties?.portal_settings)
				return FALSE
			// Check control mode
			if(!target_panties.portal_settings.can_user_control(user, TRUE))
				to_chat(user, span_warning("Партнёр ограничил удалённое управление!"))
				return FALSE
			var/pattern = params["pattern"]
			if(pattern in PORTAL_VALID_PATTERNS)
				// Update our local settings
				portal_settings.vibration_pattern = pattern
				// Update our remote vibration if active
				target_panties.update_remote_vibration(src, null, pattern)
			return TRUE
		// NOTE: Control mode actions removed from fleshlight - it's always the controlling device
		// Control mode is only relevant for panties (the controlled device)
		// Quick message actions
		if("send_quick_message")
			if(!portal_settings)
				return FALSE
			var/index = params["index"]
			var/list/recipients = list()
			var/mob/living/carbon/human/partner = get_panties_wearer(portalunderwear)
			if(partner)
				recipients += partner
			portal_settings.send_quick_message(index, user, recipients)
			return TRUE
		if("edit_quick_message")
			if(!portal_settings)
				return FALSE
			var/index = params["index"]
			if(index < 1 || index > portal_settings.quick_messages.len)
				return FALSE
			var/new_msg = tgui_input_text(user, "Введите новое быстрое сообщение", "Быстрое сообщение", portal_settings.quick_messages[index], 50)
			if(new_msg)
				portal_settings.quick_messages[index] = new_msg
			return TRUE
		// Network relay toggles
		if("toggle_relay_vibrations")
			if(!portal_settings)
				return FALSE
			portal_settings.relay_vibrations = !portal_settings.relay_vibrations
			return TRUE
		if("toggle_relay_edging")
			if(!portal_settings)
				return FALSE
			portal_settings.relay_edging = !portal_settings.relay_edging
			return TRUE
		if("toggle_relay_climax")
			if(!portal_settings)
				return FALSE
			portal_settings.relay_climax = !portal_settings.relay_climax
			return TRUE
		// Network actions
		if("create_network")
			if(!portal_settings)
				return FALSE
			var/net_name = tgui_input_text(user, "Название сети", "Создать сеть", "", 32)
			if(!net_name)
				return FALSE
			var/net_pass = tgui_input_text(user, "Пароль (оставьте пустым для открытой сети)", "Пароль", "", 20)
			var/datum/portal_network/new_net = new(net_name, user, net_pass)
			new_net.add_member(portal_settings)
			GLOB.portal_networks += new_net
			portal_settings.connection_mode = PORTAL_MODE_GROUP
			to_chat(user, span_notice("Сеть '[net_name]' создана!"))
			return TRUE
		if("join_network")
			if(!portal_settings)
				return FALSE
			var/ref = params["ref"]
			var/datum/portal_network/net = locate(ref) in GLOB.portal_networks
			if(!net)
				return FALSE
			if(net.password)
				var/entered_pass = tgui_input_text(user, "Введите пароль", "Пароль сети", "", 20)
				if(!net.add_member(portal_settings, entered_pass))
					to_chat(user, span_warning("Неверный пароль или сеть полна!"))
					return FALSE
			else
				if(!net.add_member(portal_settings))
					to_chat(user, span_warning("Не удалось присоединиться к сети!"))
					return FALSE
			portal_settings.connection_mode = PORTAL_MODE_GROUP
			to_chat(user, span_notice("Вы присоединились к сети '[net.name]'!"))
			return TRUE
		if("leave_network")
			if(!portal_settings?.network)
				return FALSE
			var/net_name = portal_settings.network.name
			portal_settings.network.remove_member(portal_settings)
			portal_settings.connection_mode = PORTAL_MODE_DISABLED
			to_chat(user, span_notice("Вы покинули сеть '[net_name]'."))
			return TRUE
		if("network_broadcast")
			if(!portal_settings?.network)
				return FALSE
			if(!can_portal_telecomms())
				to_chat(user, span_warning("Нет связи с сервером! Трансляция недоступна."))
				return FALSE
			var/message = tgui_input_text(user, "Сообщение для всей сети", "Трансляция", "", 200)
			if(message)
				var/nickname = get_portal_nickname(user)
				// Show sender speaking into device
				user.visible_message(
					span_notice("<b>[user]</b> говорит что-то в портальное устройство..."),
					span_notice("<i>Вы говорите в сеть:</i> \"[message]\""),
					vision_distance = 1
				)
				portal_settings.network.broadcast_message(user, "<b>[nickname]:</b> [message]")
			return TRUE
	return FALSE

/// Debug output proc - outputs all internal state to chat for debugging TGUI
/obj/item/portallight/proc/debug_output_to_chat(mob/user)
	to_chat(user, span_boldnotice("=== PORTAL DEVICE DEBUG (FLESHLIGHT) ==="))
	var/mob/living/carbon/human/human_user = ishuman(user) ? user : null

	// Section 1: Device Identity
	to_chat(user, span_notice("<b>--- Device Identity ---</b>"))
	to_chat(user, "  type: fleshlight")
	to_chat(user, "  ref: [REF(src)]")
	to_chat(user, "  name: [name]")
	to_chat(user, "  loc: [loc] ([loc?.type])")
	to_chat(user, "  icon_state: [icon_state]")
	var/mob/living/carbon/human/owner_mob = portal_settings?.owner
	to_chat(user, "  portal_settings: [portal_settings ? REF(portal_settings) : "NULL"]")
	to_chat(user, "  owner_mob: [owner_mob ? "[owner_mob] [REF(owner_mob)]" : "NULL"]")
	to_chat(user, "  owner_nickname: [owner_mob?.fleshlight_nickname || "NOT SET"]")
	to_chat(user, "  owner_ckey: [owner_mob?.ckey || "NULL"]")
	to_chat(user, "  is_owner: [portal_settings?.owner == user]")
	to_chat(user, "  user_nickname: [human_user?.fleshlight_nickname || "NOT SET"]")

	// Section 2: Connection State
	to_chat(user, span_notice("<b>--- Connection State ---</b>"))
	to_chat(user, "  connection_mode: [portal_settings?.connection_mode || "NULL"]")
	to_chat(user, "  telecomms_available: [can_portal_telecomms()]")
	to_chat(user, "  portalunderwear (connected panties): [portalunderwear ? REF(portalunderwear) : "NULL"]")
	to_chat(user, "  private_pair: [private_pair ? REF(private_pair) : "NULL"]")
	to_chat(user, "  connected: [!!portalunderwear]")

	// If connected, show partner info
	if(portalunderwear)
		to_chat(user, span_notice("<b>--- Partner (Panties) Info ---</b>"))
		to_chat(user, "  panties_ref: [REF(portalunderwear)]")
		to_chat(user, "  panties_portal_settings: [portalunderwear.portal_settings ? REF(portalunderwear.portal_settings) : "NULL"]")
		var/mob/living/carbon/human/partner_mob = portalunderwear.portal_settings?.owner
		to_chat(user, "  partner_mob: [partner_mob ? "[partner_mob] [REF(partner_mob)]" : "NULL"]")
		to_chat(user, "  partner_nickname: [partner_mob?.fleshlight_nickname || "NOT SET"]")
		to_chat(user, "  partner_mood: [portalunderwear.portal_settings?.current_mood || "NULL"]")
		to_chat(user, "  partner_vibration_enabled: [portalunderwear.portal_settings?.vibration_enabled]")
		to_chat(user, "  partner_vibration_intensity: [portalunderwear.portal_settings?.vibration_intensity]")
		to_chat(user, "  partner_vibration_pattern: [portalunderwear.portal_settings?.vibration_pattern || "NULL"]")
		to_chat(user, "  partner_control_mode: [portalunderwear.portal_settings?.control_mode || "NULL"]")
		to_chat(user, "  partner_intensity_locked: [portalunderwear.portal_settings?.intensity_locked]")
		to_chat(user, "  partner_max_allowed_intensity: [portalunderwear.portal_settings?.max_allowed_intensity]")
		to_chat(user, "  partner_min_forced_intensity: [portalunderwear.portal_settings?.min_forced_intensity]")

		// Remote vibration status
		var/ref = REF(src)
		var/our_remote_active = LAZYACCESS(portalunderwear.remote_vibrations, ref)
		to_chat(user, "  our_remote_vibration_active: [!!our_remote_active]")
		if(our_remote_active)
			to_chat(user, "  our_remote_intensity: [our_remote_active["intensity"]]")
			to_chat(user, "  our_remote_pattern: [our_remote_active["pattern"]]")

		// Other connections to same panties
		to_chat(user, "  target_connected_count: [LAZYLEN(portalunderwear.portallight)]")
		if(LAZYLEN(portalunderwear.portallight) > 1)
			to_chat(user, "  other_connections:")
			for(var/obj/item/portallight/PL as anything in portalunderwear.portallight)
				if(PL != src)
					var/mob/living/carbon/human/other_holder = portalunderwear.get_fleshlight_holder(PL)
					to_chat(user, "    - [REF(PL)] holder=[other_holder?.fleshlight_nickname || "NONE"]")

	// Available panties (for connection)
	to_chat(user, span_notice("<b>--- Available Panties ---</b>"))
	to_chat(user, "  available_panties count: [LAZYLEN(available_panties)]")
	if(LAZYLEN(available_panties))
		for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP as anything in available_panties)
			var/mob/living/carbon/human/pp_owner = PP.portal_settings?.owner
			to_chat(user, "    - [REF(PP)] owner=[pp_owner?.fleshlight_nickname || "?"] mode=[PP.portal_settings?.connection_mode || "?"]")

	// Section 3: Our Vibration State
	to_chat(user, span_notice("<b>--- Our Vibration Settings ---</b>"))
	to_chat(user, "  vibration_enabled: [portal_settings?.vibration_enabled]")
	to_chat(user, "  vibration_pattern: [portal_settings?.vibration_pattern || "NULL"]")
	to_chat(user, "  vibration_intensity: [portal_settings?.vibration_intensity]")
	to_chat(user, "  relay_intensity: [portal_settings?.relay_intensity]%")

	// Section 4: Mood & Status
	to_chat(user, span_notice("<b>--- Mood and Status ---</b>"))
	to_chat(user, "  current_mood: [portal_settings?.current_mood || "NULL"]")
	to_chat(user, "  do_not_disturb: [portal_settings?.do_not_disturb]")
	to_chat(user, "  last_activity: [portal_settings?.last_activity] (world.time=[world.time])")

	// Section 5: RP Settings
	to_chat(user, span_notice("<b>--- RP Settings ---</b>"))
	to_chat(user, "  public_emotes_enabled: [portal_settings?.public_emotes_enabled]")
	to_chat(user, "  last_public_emote: [portal_settings?.last_public_emote]")
	to_chat(user, "  edging_enabled: [portal_settings?.edging_enabled]")
	to_chat(user, "  edging_notified: [portal_settings?.edging_notified]")

	// Section 6: Network State
	to_chat(user, span_notice("<b>--- Network State ---</b>"))
	var/datum/portal_network/net = portal_settings?.network
	to_chat(user, "  in_network: [!!net]")
	if(net)
		to_chat(user, "  network_ref: [REF(net)]")
		to_chat(user, "  network_name: [net.name]")
		to_chat(user, "  network_owner_ckey: [net.owner_ckey]")
		to_chat(user, "  is_network_owner: [net.owner_ckey == user.ckey]")
		to_chat(user, "  network_members count: [net.members.len]")
		var/midx = 1
		for(var/datum/portal_settings/PS as anything in net.members)
			to_chat(user, "    #[midx]: [PS.owner?.fleshlight_nickname || "?"] (owner_ref=[PS.owner ? REF(PS.owner) : "NULL"])")
			midx++
	to_chat(user, "  relay_vibrations: [portal_settings?.relay_vibrations]")
	to_chat(user, "  relay_edging: [portal_settings?.relay_edging]")
	to_chat(user, "  relay_climax: [portal_settings?.relay_climax]")

	// Available networks
	to_chat(user, "  available_networks (GLOB): [GLOB.portal_networks.len]")
	for(var/datum/portal_network/available_net as anything in GLOB.portal_networks)
		to_chat(user, "    - [available_net.name] (members=[available_net.members.len], has_pass=[!!available_net.password])")

	// Section 7: Safety
	to_chat(user, span_notice("<b>--- Safety ---</b>"))
	to_chat(user, "  safeword: [portal_settings?.safeword || "NOT SET"]")
	to_chat(user, "  safeword_enabled: [portal_settings?.safeword_enabled]")
	to_chat(user, "  blocked_nicknames: [portal_settings?.blocked_nicknames?.len || 0] - [json_encode(portal_settings?.blocked_nicknames)]")
	to_chat(user, "  allowed_nicknames: [portal_settings?.allowed_nicknames?.len || 0] - [json_encode(portal_settings?.allowed_nicknames)]")

	// Section 8: History
	to_chat(user, span_notice("<b>--- Connection History ---</b>"))
	to_chat(user, "  history entries: [portal_settings?.connection_history?.len || 0]")
	if(portal_settings?.connection_history?.len)
		for(var/list/entry in portal_settings.connection_history)
			to_chat(user, "    [entry["time_text"]] - [entry["partner_nick"]]: [entry["action"]]")

	// Section 9: Quick Messages
	to_chat(user, span_notice("<b>--- Quick Messages ---</b>"))
	if(portal_settings?.quick_messages?.len)
		var/qidx = 1
		for(var/msg in portal_settings.quick_messages)
			to_chat(user, "    #[qidx]: [msg]")
			qidx++

	// Section 10: GLOB info
	to_chat(user, span_notice("<b>--- GLOB Data ---</b>"))
	to_chat(user, "  GLOB.fleshlight_portallight count: [GLOB.fleshlight_portallight.len]")
	to_chat(user, "  GLOB.portalpanties count: [GLOB.portalpanties.len]")
	to_chat(user, "  GLOB.portal_networks count: [GLOB.portal_networks.len]")

	to_chat(user, span_boldnotice("=== END DEBUG ==="))

// Verb for opening TGUI
/obj/item/clothing/underwear/briefs/panties/portalpanties/verb/open_portal_menu()
	set name = "Portal Settings"
	set category = "Object"
	set src in usr
	ui_interact(usr)

/obj/item/portallight/verb/open_portal_menu()
	set name = "Portal Settings"
	set category = "Object"
	set src in usr
	ui_interact(usr)

