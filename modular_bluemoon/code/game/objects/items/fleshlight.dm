GLOBAL_LIST_EMPTY(portalpanties)
GLOBAL_LIST_EMPTY(fleshlight_portallight)
/// Panties in PUBLIC mode - for fast lookup without scanning all portalpanties
GLOBAL_LIST_EMPTY(public_portal_panties)

// BLUEMOON ADD: Action for controlling portal devices when inserted in genitals
/datum/action/portal_device_control
	name = "Портальное Управление"
	desc = "Открыть меню настроек портального устройства."
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "yourorgans"
	/// The portal device this action controls
	var/obj/item/portal_device

/datum/action/portal_device_control/New(Target)
	. = ..()
	if(istype(Target, /obj/item/portallight))
		var/obj/item/portallight/PL = Target
		name = "Портальный Фонарик"
		desc = "Открыть настройки вставленного портального фонарика."
		portal_device = PL
	else if(istype(Target, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = Target
		name = "Портальные Трусики"
		desc = "Открыть настройки вставленных портальных трусиков."
		portal_device = PP

/datum/action/portal_device_control/Destroy()
	portal_device = null
	return ..()

/datum/action/portal_device_control/Trigger()
	if(!..())
		return FALSE
	if(!owner || !portal_device)
		return FALSE
	portal_device.ui_interact(owner)
	return TRUE

/datum/action/portal_device_control/IsAvailable(silent = FALSE)
	if(!portal_device)
		return FALSE
	// Check if device is still inserted OR worn
	var/datum/component/genital_equipment/equipment = portal_device.GetComponent(/datum/component/genital_equipment)
	if(equipment?.holder_genital)
		return ..()
	// Check if panties are worn as underwear or mask
	if(istype(portal_device, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = portal_device
		if(PP.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK))
			return ..()
	// Check if fleshlight is held
	if(istype(portal_device, /obj/item/portallight))
		if(ishuman(portal_device.loc))
			return ..()
	return FALSE

/datum/action/portal_device_control/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force)
	if(!portal_device || !current_button)
		return
	// Use the portal device's appearance for the action button
	var/old_layer = portal_device.layer
	var/old_plane = portal_device.plane
	portal_device.layer = FLOAT_LAYER
	portal_device.plane = FLOAT_PLANE
	current_button.cut_overlays()
	current_button.add_overlay(portal_device)
	portal_device.layer = old_layer
	portal_device.plane = old_plane
	current_button.appearance_cache = portal_device.appearance

// BLUEMOON ADD: Action for switching portal device target without using Z key
/datum/action/portal_target_switch
	name = "Сменить Цель"
	desc = "Переключиться между доступными портальными целями."
	check_flags = AB_CHECK_CONSCIOUS
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "aim"
	/// The portal device this action controls
	var/obj/item/portal_device
	/// Is this for panties (TRUE) or fleshlight (FALSE)
	var/is_panties = FALSE

/datum/action/portal_target_switch/New(Target)
	. = ..()
	if(istype(Target, /obj/item/portallight))
		var/obj/item/portallight/PL = Target
		portal_device = PL
		is_panties = FALSE
		name = "Цель Фонарика"
		desc = "Нажмите для смены цели. Текущая: [PL.targetting]"
	else if(istype(Target, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = Target
		portal_device = PP
		is_panties = TRUE
		name = "Цель Трусиков"
		desc = "Нажмите для смены цели. Текущая: [PP.targetting]"

/datum/action/portal_target_switch/Destroy()
	portal_device = null
	return ..()

/datum/action/portal_target_switch/Trigger()
	if(!..())
		return FALSE
	if(!owner || !portal_device)
		return FALSE
	var/new_target
	if(is_panties)
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = portal_device
		// Check if inserted in genital - target is locked to that genital type
		var/datum/component/genital_equipment/pp_equipment = PP.GetComponent(/datum/component/genital_equipment)
		if(pp_equipment?.holder_genital)
			owner.balloon_alert(owner, "извлеките для смены режима")
			return FALSE
		var/is_worn_underwear = PP.current_equipped_slot == ITEM_SLOT_UNDERWEAR
		var/is_worn_mask = PP.current_equipped_slot == ITEM_SLOT_MASK

		// If worn as mask, can only target MOUTH - no cycling allowed
		if(is_worn_mask)
			owner.balloon_alert(owner, "снимите маску для смены режима")
			return FALSE

		// Cycle through targets, skip MOUTH if worn as underwear
		switch(PP.targetting)
			if(CUM_TARGET_VAGINA)
				PP.targetting = CUM_TARGET_ANUS
			if(CUM_TARGET_ANUS)
				PP.targetting = CUM_TARGET_PENIS
			if(CUM_TARGET_PENIS)
				PP.targetting = CUM_TARGET_URETHRA
			if(CUM_TARGET_URETHRA)
				// Skip MOUTH if worn as underwear
				PP.targetting = is_worn_underwear ? CUM_TARGET_VAGINA : CUM_TARGET_MOUTH
			if(CUM_TARGET_MOUTH)
				PP.targetting = CUM_TARGET_VAGINA
		new_target = PP.targetting

		// Only update slot_flags/name if NOT currently worn
		if(!is_worn_underwear && !is_worn_mask)
			PP.slot_flags = PP.targetting == CUM_TARGET_MOUTH ? ITEM_SLOT_MASK : ITEM_SLOT_UNDERWEAR
			PP.flags_cover = PP.targetting == CUM_TARGET_MOUTH ? MASKCOVERSMOUTH : NONE
			PP.visor_flags_cover = PP.targetting == CUM_TARGET_MOUTH ? MASKCOVERSMOUTH : NONE
			// Update name
			if(PP.targetting == CUM_TARGET_MOUTH)
				PP.name = replacetext(PP.name, "Трусики", "Маска")
				PP.name = replacetext(PP.name, "Портальные", "Портальная")
			else
				PP.name = replacetext(PP.name, "Маска", "Трусики")
				PP.name = replacetext(PP.name, "Портальная", "Портальные")
		PP.update_portal()
	else
		var/obj/item/portallight/PL = portal_device
		// Check if inserted in genital - target is locked to that genital type
		var/datum/component/genital_equipment/pl_equipment = PL.GetComponent(/datum/component/genital_equipment)
		if(pl_equipment?.holder_genital)
			owner.balloon_alert(owner, "извлеките для смены режима")
			return FALSE
		switch(PL.targetting)
			if(CUM_TARGET_PENIS)
				PL.targetting = CUM_TARGET_VAGINA
			if(CUM_TARGET_VAGINA)
				PL.targetting = CUM_TARGET_ANUS
			if(CUM_TARGET_ANUS)
				PL.targetting = CUM_TARGET_URETHRA
			if(CUM_TARGET_URETHRA)
				PL.targetting = CUM_TARGET_PENIS
		new_target = PL.targetting
	// Update description and notify
	desc = "Нажмите для смены цели. Текущая: [new_target]"
	owner.balloon_alert(owner, "цель: [new_target]")
	UpdateButtons()
	return TRUE

/datum/action/portal_target_switch/IsAvailable(silent = FALSE)
	if(!portal_device)
		return FALSE
	// Check if device is still inserted OR worn OR held
	var/datum/component/genital_equipment/equipment = portal_device.GetComponent(/datum/component/genital_equipment)
	if(equipment?.holder_genital)
		return ..()
	if(is_panties)
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = portal_device
		if(PP.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK))
			return ..()
	else
		if(ishuman(portal_device.loc))
			return ..()
	return FALSE

/datum/action/portal_target_switch/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force)
	if(!current_button)
		return
	current_button.cut_overlays()
	// Add target indicator overlay based on current target
	var/current_target
	if(is_panties)
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = portal_device
		current_target = PP?.targetting
	else
		var/obj/item/portallight/PL = portal_device
		current_target = PL?.targetting
	// Create a text overlay showing current target letter
	var/target_letter = "?"
	switch(current_target)
		if(CUM_TARGET_VAGINA)
			target_letter = "V"
		if(CUM_TARGET_ANUS)
			target_letter = "A"
		if(CUM_TARGET_PENIS)
			target_letter = "P"
		if(CUM_TARGET_URETHRA)
			target_letter = "U"
		if(CUM_TARGET_MOUTH)
			target_letter = "M"
	current_button.maptext = MAPTEXT("<span style='font-size:8pt;color:#ff88cc;font-weight:bold;text-shadow:1px 1px #000;'>[target_letter]</span>")
	current_button.maptext_x = 12
	current_button.maptext_y = 12

/obj/item/clothing/underwear/briefs/panties/portalpanties
	body_parts_covered = NONE	// Коль что сами через настройки выставят для себя
	var/seamless = FALSE 		// Закрытие трусиков на латексный ключ
	interactable_in_strip_menu = TRUE
	/// Action for controlling the portal device when inserted in a genital
	var/datum/action/portal_device_control/inserted_control_action
	/// Action for controlling the portal device when worn as underwear
	var/datum/action/portal_device_control/worn_control_action
	/// Action for switching target when inserted
	var/datum/action/portal_target_switch/inserted_target_action
	/// Action for switching target when worn
	var/datum/action/portal_target_switch/worn_target_action
	/// Portal settings datum (initialized in _portal_toys.dm)
	var/datum/portal_settings/portal_settings
	/// Private paired fleshlight
	var/obj/item/portallight/private_pair
	/// Ассоциативный список активных удалённых вибраций от fleshlights
	/// Формат: list(REF(fleshlight) = list("nickname", "intensity", "pattern"))
	var/list/remote_vibrations
	/// Accumulated delta time for throttled processing (performance optimization)
	var/process_accumulated_time = 0

/// Check if panties are in passive mode (worn or inserted - limited control)
/// Returns FALSE when held in hand (setup mode - full control)
/// Control depends on control_mode setting:
/// - PORTAL_CONTROL_SELF: owner always has full control
/// - PORTAL_CONTROL_PARTNER: owner is passive when worn/inserted, partner has control
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/is_passive_mode(mob/user = null)
	// Check if device is worn or inserted
	var/is_active = FALSE
	if(current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK))
		is_active = TRUE
	else
		var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
		if(equipment?.holder_genital)
			is_active = TRUE

	// If not worn/inserted, never passive (setup mode)
	if(!is_active)
		return FALSE

	// Now check control mode
	if(user && portal_settings?.owner == user)
		// Owner using their own device
		switch(portal_settings.control_mode)
			if(PORTAL_CONTROL_SELF)
				// Self control mode - owner always has full control
				return FALSE
			if(PORTAL_CONTROL_PARTNER)
				// Partner control mode - owner is passive when device is active
				return TRUE

	// Non-owner is always in passive mode when interacting with worn/inserted device
	return TRUE

/mob/living/carbon/human
	var/fleshlight_nickname //Используется для анонимизации персонажа

// Использование эмоутов через фонарик
/obj/item/portallight/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Возможен более точный <b>контроль ситуации</b>. (Ctrl+Click для кастомного эмоута)</span>"
	. += span_notice("<b>Ctrl+Shift+Click</b> для открытия меню настроек.")

/obj/item/portallight/CtrlClick(mob/user)
	. = ..()
	if(GLOB.say_disabled)
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	user.emote("fleshlight")

/obj/item/portallight/CtrlShiftClick(mob/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE))
		return
	ui_interact(user)

/obj/item/clothing/underwear/briefs/panties/portalpanties/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Возможен более точный <b>контроль ситуации</b>. (Ctrl+Click для кастомного эмоута)</span>"
	. += span_notice("<b>Ctrl+Shift+Click</b> для открытия меню настроек.")
	. += span_notice("При надевании появится <b>кнопка действия</b> для открытия меню настроек.")

/obj/item/clothing/underwear/briefs/panties/portalpanties/CtrlClick(mob/user)
	. = ..()
	if(GLOB.say_disabled)
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	user.emote("fleshlight")

/obj/item/clothing/underwear/briefs/panties/portalpanties/CtrlShiftClick(mob/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE))
		return
	ui_interact(user)

/datum/emote/sound/human/fleshlight
	key = "fleshlight"
	key_third_person = "fleshlight"
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)

/datum/emote/sound/human/fleshlight/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, "<span class='danger'>Некорректный эмоут.</span>")
		return TRUE
	return FALSE

/datum/emote/sound/human/fleshlight/run_emote(mob/user, params, type_override = null)
	if(jobban_isbanned(user, "emote"))
		to_chat(user, "Вы не можете отправлять эмоуты (забанены).")
		return FALSE
	else if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, "Вы не можете отправлять IC сообщения (заглушены).")
		return FALSE
	var/mob/living/carbon/human/H_user = user

	var/list/select = list()
	for(var/obj/item/I in H_user.held_items + H_user.r_store + H_user.l_store)
		if(istype(I, /obj/item/portallight))
			select |= I
	if(H_user.wear_mask && istype(H_user.wear_mask, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		select |= H_user.wear_mask
	if(H_user.w_underwear && istype(H_user.w_underwear, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		select |= H_user.w_underwear
	// BLUEMOON ADD: Check for portal devices inserted in genitals
	for(var/obj/item/organ/genital/G in H_user.internal_organs)
		for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP in G.contents)
			select |= PP
		for(var/obj/item/portallight/PL in G.contents)
			select |= PL

	var/choosen_flesh
	if(!select)
		return FALSE
	else if(select.len == 1)
		choosen_flesh = select[1]
	else
		choosen_flesh = tgui_input_list(user, "Выберите что использовать:", "Предпочтения", select)
		if(!choosen_flesh)
			return FALSE

	var/list/show_to = list()

	if(istype(choosen_flesh, /obj/item/portallight))
		var/obj/item/portallight/PF = choosen_flesh
		if(PF.portalunderwear && ishuman(PF.portalunderwear.loc))
			var/mob/living/carbon/human/H = PF.portalunderwear.loc
			// BLUEMOON EDIT: Also check for genital insertion
			var/is_worn = (H.w_underwear == PF.portalunderwear || H.wear_mask == PF.portalunderwear)
			var/is_inserted = FALSE
			if(!is_worn)
				var/datum/component/genital_equipment/equipment = PF.portalunderwear.GetComponent(/datum/component/genital_equipment)
				is_inserted = equipment?.holder_genital != null
			if(is_worn || is_inserted)
				show_to |= H
		// BLUEMOON ADD: Also check for inserted panties (loc may be genital, not human)
		else if(PF.portalunderwear)
			var/datum/component/genital_equipment/equipment = PF.portalunderwear.GetComponent(/datum/component/genital_equipment)
			if(equipment?.holder_genital)
				var/mob/living/carbon/human/H = equipment.get_wearer()
				if(H)
					show_to |= H

	else if(istype(choosen_flesh, /obj/item/clothing/underwear/briefs/panties/portalpanties))
		var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = choosen_flesh
		for(var/obj/item/portallight/PL in PP.portallight)
			if(ishuman(PL.loc))
				var/mob/living/carbon/human/H = PL.loc
				show_to |= H
			else
				// BLUEMOON ADD: Check if fleshlight is inserted in a genital
				var/datum/component/genital_equipment/equipment = PL.GetComponent(/datum/component/genital_equipment)
				if(equipment?.holder_genital)
					var/mob/living/carbon/human/H = equipment.get_wearer()
					if(H)
						show_to |= H

	if(!show_to.len)
		to_chat(user, span_warning("На другой стороне никого нет."))
		return FALSE

	else if(!params)
		var/subtle_emote = stripped_multiline_input_or_reflect(user, "Введите эмоут для отображения.", "[choosen_flesh]" , null, MAX_MESSAGE_LEN)
		if(subtle_emote && !check_invalid(user, subtle_emote))
			message = subtle_emote
		else
			return FALSE
	else
		message = params
		if(type_override)
			emote_type = type_override
	. = TRUE
	if(!can_run_emote(user))
		return FALSE

	user.log_message("[message] (FLESHLIGH)", LOG_SUBTLER)
	var/display_name = get_portal_nickname(H_user)
	message = "<span class='emote'><b>[display_name]</b> <i>[user.say_emphasis(message)]</i></span>"

	for(var/mob/living/L in range(user, 1))
		show_to |= L

	for(var/i in show_to)
		var/mob/M = i
		M.show_message(message)

// Закрытие трусиков на латексные ключ
/obj/item/clothing/underwear/briefs/panties/portalpanties/attack_hand(mob/user)
	if(!ishuman(user))
		return ..()
	if(seamless && (user.get_item_by_slot(ITEM_SLOT_UNDERWEAR) == src || user.get_item_by_slot(ITEM_SLOT_MASK) == src))
		to_chat(user, span_purple(pick("Вы дёргаете трусики в поисках выхода.",
									"Вы не можете найти способ снять эти трусики!",
									"Ваши бесполезные попытки только сильнее затягивают их.")))
		return
	return ..()

/obj/item/clothing/underwear/briefs/panties/portalpanties/MouseDrop(atom/over_object)
	return FALSE

/obj/item/clothing/underwear/briefs/panties/portalpanties/attackby(obj/item/K, mob/user, params)
	if(istype(K, /obj/item/key/latex))
		// Get wearer if panties are worn or inserted
		var/mob/living/carbon/human/wearer
		if(ishuman(loc))
			var/mob/living/carbon/human/H = loc
			if(H.w_underwear == src || H.wear_mask == src)
				wearer = H
		// Also check if inserted in genital
		if(!wearer)
			var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
			if(equipment?.holder_genital)
				wearer = equipment.get_wearer()
		// Consent check for LOCKING only (not unlocking)
		if(!seamless && wearer && wearer != user)
			if(!(wearer.client?.prefs?.toggles & VERB_CONSENT))
				to_chat(user, span_warning("Они не хотят, чтобы вы это делали!"))
				return
		seamless = !seamless
		to_chat(user, span_warning("Трусики внезапно [seamless ? "затягиваются" : "ослабляются"]!"))
		if(HAS_TRAIT(src, TRAIT_NODROP))
			REMOVE_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)
		else if(current_equipped_slot == ITEM_SLOT_UNDERWEAR || current_equipped_slot == ITEM_SLOT_MASK)
			ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)
	return ..()

/obj/item/clothing/underwear/briefs/panties/portalpanties/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_UNDERWEAR || slot == ITEM_SLOT_MASK)
		if(seamless)
			ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)
		// Portal settings setup
		if(ishuman(user))
			portal_settings?.owner = user
			START_PROCESSING(SSobj, src)
			RegisterSignal(user, COMSIG_MOVABLE_HEAR, PROC_REF(on_owner_hear), override = TRUE)
			// Grant control action for worn panties
			if(!worn_control_action)
				worn_control_action = new /datum/action/portal_device_control(src)
			worn_control_action.Grant(user)
			// Grant target switch action for worn panties
			if(!worn_target_action)
				worn_target_action = new /datum/action/portal_target_switch(src)
			worn_target_action.Grant(user)

/obj/item/clothing/underwear/briefs/panties/portalpanties/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOVABLE_HEAR)
	// Notify connected flashlights that panties are being removed
	if(LAZYLEN(portallight))
		for(var/obj/item/portallight/PL in portallight)
			var/mob/living/carbon/human/holder = get_fleshlight_holder(PL)
			if(holder)
				to_chat(holder, span_warning("Портальное соединение потеряно - трусики были сняты!"))
			// Clear the flashlight's connection to us
			unregister_remote_vibration(PL)
			PL.portalunderwear = null
			PL.icon_state = "unpaired"
			PL.update_appearance()
		LAZYCLEARLIST(portallight)
	// Clear any remaining remote vibrations
	LAZYCLEARLIST(remote_vibrations)
	portal_settings?.owner = null
	STOP_PROCESSING(SSobj, src)
	// Revoke control action for worn panties
	if(worn_control_action)
		worn_control_action.Remove(user)
	// Revoke target switch action for worn panties
	if(worn_target_action)
		worn_target_action.Remove(user)

// Открытие меню настроек через AltClick
/obj/item/clothing/underwear/briefs/panties/portalpanties/AltClick(mob/user)
	. = ..()
	if(do_mob(user, src, 2 SECONDS))
		ui_interact(user)

/obj/item/portallight/New()
	..()
	GLOB.fleshlight_portallight += src
	// Copy public panties from the global indexed list (no scan needed)
	available_panties = GLOB.public_portal_panties.Copy()

/obj/item/portallight/Destroy()
	..()
	GLOB.fleshlight_portallight -= src

/obj/item/clothing/underwear/briefs/panties/portalpanties/New()
	..()
	GLOB.portalpanties += src

/obj/item/clothing/underwear/briefs/panties/portalpanties/Destroy()
	QDEL_NULL(worn_control_action)
	QDEL_NULL(worn_target_action)
	QDEL_NULL(inserted_control_action)
	QDEL_NULL(inserted_target_action)
	..()
	GLOB.portalpanties -= src
	GLOB.public_portal_panties -= src

// Переименование трусиков
/obj/item/clothing/underwear/briefs/panties/portalpanties/verb/rename()
	set name = "Переименовать трусики"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_UNDERWEAR) == src)
		to_chat(usr, span_purple("Сначала снимите их!"))
		return

	var/input = input("Как вы хотите их назвать?") as text
	if(input)
		name = input

// Маскировка трусиков под маску и трусики
/obj/item/clothing/underwear/briefs/panties/portalpanties/Initialize(mapload)
	. = ..()
	var/datum/action/item_action/chameleon/change/chameleon_panties = new(src)
	chameleon_panties.chameleon_type = /obj/item/clothing/underwear/briefs
	chameleon_panties.chameleon_name = "Panties"
	chameleon_panties.initialize_disguises()
	var/datum/action/item_action/chameleon/change/chameleon_mask = new(src)
	chameleon_mask.chameleon_type = /obj/item/clothing/mask
	chameleon_mask.chameleon_name = "Mask"
	chameleon_mask.initialize_disguises()

// BLUEMOON ADD: Genital equipment integration for portal panties
/obj/item/clothing/underwear/briefs/panties/portalpanties/ComponentInitialize()
	. = ..()
	var/list/procs_list = list(
		"before_inserting" = CALLBACK(src, PROC_REF(genital_inserting)),
		"after_inserting" = CALLBACK(src, PROC_REF(genital_inserted)),
		"before_removing" = CALLBACK(src, PROC_REF(genital_removing)),
		"after_removing" = CALLBACK(src, PROC_REF(genital_removed))
	)
	AddComponent(/datum/component/genital_equipment, list(
		ORGAN_SLOT_VAGINA,
		ORGAN_SLOT_ANUS,
		ORGAN_SLOT_PENIS
	), procs_list)

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/genital_inserting(datum/source, obj/item/organ/genital/G, mob/user)
	// Consent check
	if(!(G.owner.client?.prefs?.toggles & VERB_CONSENT))
		to_chat(user, span_warning("Они не хотят, чтобы вы это делали!"))
		return FALSE
	// Already wearing check - can't insert if worn as underwear/mask
	if(current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK))
		to_chat(user, span_warning("Сначала снимите их!"))
		return FALSE
	// Check if there's already a portal device in this genital
	for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/existing in G.contents)
		to_chat(user, span_warning("Внутри уже есть портальные трусики!"))
		return FALSE
	for(var/obj/item/portallight/existing in G.contents)
		to_chat(user, span_warning("Внутри уже есть портальный фонарик! Сначала удалите его."))
		return FALSE
	// Check if a connected fleshlight is already inside this person (prevent self-loop)
	for(var/obj/item/portallight/PL in portallight)
		var/datum/component/genital_equipment/fl_eq = PL.GetComponent(/datum/component/genital_equipment)
		if(fl_eq?.holder_genital?.owner == G.owner)
			to_chat(user, span_warning("Подключённый фонарик уже внутри этого человека! Это создаст портальную петлю."))
			return FALSE
	if(private_pair)
		var/datum/component/genital_equipment/fl_eq = private_pair.GetComponent(/datum/component/genital_equipment)
		if(fl_eq?.holder_genital?.owner == G.owner)
			to_chat(user, span_warning("Сопряжённый фонарик уже внутри этого человека! Это создаст портальную петлю."))
			return FALSE
	return TRUE

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/genital_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	// Set target based on which genital it was inserted into
	switch(G.slot)
		if(ORGAN_SLOT_VAGINA)
			targetting = CUM_TARGET_VAGINA
		if(ORGAN_SLOT_ANUS)
			targetting = CUM_TARGET_ANUS
		if(ORGAN_SLOT_PENIS)
			targetting = CUM_TARGET_PENIS
	// Update connected fleshlights
	update_portal()
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
	// Grant control action to the genital owner and register signals
	if(G.owner)
		inserted_control_action = new /datum/action/portal_device_control(src)
		inserted_control_action.Grant(G.owner)
		// Grant target switch action
		inserted_target_action = new /datum/action/portal_target_switch(src)
		inserted_target_action.Grant(G.owner)
		register_climax_signal(G.owner)
		// Register for safeword hearing
		RegisterSignal(G.owner, COMSIG_MOVABLE_HEAR, PROC_REF(on_owner_hear), override = TRUE)
		portal_settings?.owner = G.owner
		START_PROCESSING(SSobj, src)
	return TRUE

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/genital_removing(datum/source, obj/item/organ/genital/G, mob/user)
	if(seamless)
		to_chat(user, span_purple("Трусики заблокированы! Нужен латексный ключ для снятия."))
		return FALSE
	return TRUE

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/genital_removed(datum/source, obj/item/organ/genital/G, mob/user)
	// Reset target to default
	targetting = CUM_TARGET_VAGINA
	update_portal()
	// Notify connected flashlights that panties are being removed
	if(LAZYLEN(portallight))
		for(var/obj/item/portallight/PL in portallight)
			var/mob/living/carbon/human/holder = get_fleshlight_holder(PL)
			if(holder)
				to_chat(holder, span_warning("Портальное соединение потеряно - трусики были извлечены!"))
			// Clear the flashlight's connection to us
			unregister_remote_vibration(PL)
			PL.portalunderwear = null
			PL.icon_state = "unpaired"
			PL.update_appearance()
		LAZYCLEARLIST(portallight)
	// Clear any remaining remote vibrations
	LAZYCLEARLIST(remote_vibrations)
	// Remove control action and unregister signals
	if(G.owner)
		unregister_climax_signal(G.owner)
		UnregisterSignal(G.owner, COMSIG_MOVABLE_HEAR)
		portal_settings?.owner = null
		STOP_PROCESSING(SSobj, src)
	if(inserted_control_action)
		QDEL_NULL(inserted_control_action)
	if(inserted_target_action)
		QDEL_NULL(inserted_target_action)
	return TRUE

// BLUEMOON ADD: Genital equipment integration for portal fleshlight
/obj/item/portallight
	/// Action for controlling the portal device when inserted in a genital
	var/datum/action/portal_device_control/inserted_control_action
	/// Action for switching target when inserted
	var/datum/action/portal_target_switch/inserted_target_action
	/// Action for switching target when held in hand
	var/datum/action/portal_target_switch/held_target_action
	/// Portal settings datum (initialized in _portal_toys.dm)
	var/datum/portal_settings/portal_settings
	/// Private paired panties
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/private_pair
	/// Accumulated delta time for throttled processing (performance optimization)
	var/process_accumulated_time = 0

/obj/item/portallight/ComponentInitialize()
	. = ..()
	var/list/procs_list = list(
		"before_inserting" = CALLBACK(src, PROC_REF(genital_inserting)),
		"after_inserting" = CALLBACK(src, PROC_REF(genital_inserted)),
		"before_removing" = CALLBACK(src, PROC_REF(genital_removing)),
		"after_removing" = CALLBACK(src, PROC_REF(genital_removed))
	)
	AddComponent(/datum/component/genital_equipment, list(
		ORGAN_SLOT_VAGINA,
		ORGAN_SLOT_ANUS,
		ORGAN_SLOT_PENIS
	), procs_list)

/obj/item/portallight/proc/genital_inserting(datum/source, obj/item/organ/genital/G, mob/user)
	// Consent check
	if(!(G.owner.client?.prefs?.toggles & VERB_CONSENT))
		to_chat(user, span_warning("Они не хотят, чтобы вы это делали!"))
		return FALSE
	// Check if there's already a portal device in this genital
	for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/existing in G.contents)
		to_chat(user, span_warning("Внутри уже есть портальные трусики! Сначала удалите их."))
		return FALSE
	for(var/obj/item/portallight/existing in G.contents)
		to_chat(user, span_warning("Внутри уже есть портальный фонарик!"))
		return FALSE
	// Check if connected panties are worn/inserted by this person (prevent self-loop)
	if(portalunderwear)
		// Check if worn as underwear/mask
		if(ishuman(portalunderwear.loc))
			var/mob/living/carbon/human/panty_wearer = portalunderwear.loc
			if(panty_wearer == G.owner && (portalunderwear.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)))
				to_chat(user, span_warning("Подключённые трусики уже надеты на этого человека! Это создаст портальную петлю."))
				return FALSE
		// Check if inserted in genital
		var/datum/component/genital_equipment/pp_eq = portalunderwear.GetComponent(/datum/component/genital_equipment)
		if(pp_eq?.holder_genital?.owner == G.owner)
			to_chat(user, span_warning("Подключённые трусики уже внутри этого человека! Это создаст портальную петлю."))
			return FALSE
	if(private_pair)
		// Check if worn as underwear/mask
		if(ishuman(private_pair.loc))
			var/mob/living/carbon/human/panty_wearer = private_pair.loc
			if(panty_wearer == G.owner && (private_pair.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)))
				to_chat(user, span_warning("Сопряжённые трусики уже надеты на этого человека! Это создаст портальную петлю."))
				return FALSE
		// Check if inserted in genital
		var/datum/component/genital_equipment/pp_eq = private_pair.GetComponent(/datum/component/genital_equipment)
		if(pp_eq?.holder_genital?.owner == G.owner)
			to_chat(user, span_warning("Сопряжённые трусики уже внутри этого человека! Это создаст портальную петлю."))
			return FALSE
	return TRUE

/obj/item/portallight/proc/genital_inserted(datum/source, obj/item/organ/genital/G, mob/user)
	// Set target based on which genital it was inserted into
	switch(G.slot)
		if(ORGAN_SLOT_VAGINA)
			targetting = CUM_TARGET_VAGINA
		if(ORGAN_SLOT_ANUS)
			targetting = CUM_TARGET_ANUS
		if(ORGAN_SLOT_PENIS)
			targetting = CUM_TARGET_PENIS
	update_appearance()
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
	// Grant control action to the genital owner and register signals
	if(G.owner)
		inserted_control_action = new /datum/action/portal_device_control(src)
		inserted_control_action.Grant(G.owner)
		// Grant target switch action
		inserted_target_action = new /datum/action/portal_target_switch(src)
		inserted_target_action.Grant(G.owner)
		register_climax_signal(G.owner)
		// Register for safeword hearing
		RegisterSignal(G.owner, COMSIG_MOVABLE_HEAR, PROC_REF(on_owner_hear), override = TRUE)
		portal_settings?.owner = G.owner
		START_PROCESSING(SSobj, src)
	return TRUE

/obj/item/portallight/proc/genital_removing(datum/source, obj/item/organ/genital/G, mob/user)
	return TRUE

/obj/item/portallight/proc/genital_removed(datum/source, obj/item/organ/genital/G, mob/user)
	// Reset target to default
	targetting = CUM_TARGET_PENIS
	update_appearance()
	// Remove control action and unregister signals
	if(G.owner)
		unregister_climax_signal(G.owner)
		UnregisterSignal(G.owner, COMSIG_MOVABLE_HEAR)
		portal_settings?.owner = null
		STOP_PROCESSING(SSobj, src)
	if(inserted_control_action)
		QDEL_NULL(inserted_control_action)
	if(inserted_target_action)
		QDEL_NULL(inserted_target_action)
	return TRUE

// BLUEMOON ADD: Hook into handle_post_sex to relay sensations through portal devices
// This allows threesome scenarios where e.g. someone has sex with a vagina containing portal panties
/mob/living/carbon/human/handle_post_sex(amount, orifice, mob/living/partner, organ = null, cum_inside = FALSE, anonymous = FALSE)
	. = ..()
	// Check if any of our genitals involved contain portal devices
	if(!amount || !ishuman(partner))
		return
	// Get the genital organ involved in this interaction
	var/obj/item/organ/genital/involved_genital
	if(organ)
		if(istext(organ))
			involved_genital = getorganslot(organ)
		else if(istype(organ, /obj/item/organ/genital))
			involved_genital = organ
	if(involved_genital)
		involved_genital.relay_portal_sensations(partner, amount, orifice, FALSE)

// BLUEMOON ADD: Relay sensations through portal devices during regular intercourse
/obj/item/organ/genital/proc/relay_portal_sensations(mob/living/partner, lust_amount, orifice_type, is_climax = FALSE)
	// Find any portal devices inside this genital
	for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP in contents)
		PP.relay_intercourse_sensations(owner, partner, lust_amount, orifice_type, is_climax, slot)
	for(var/obj/item/portallight/PL in contents)
		PL.relay_intercourse_sensations(owner, partner, lust_amount, orifice_type, is_climax, slot)

// Portal panties relay - sends sensations to all connected fleshlights
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/relay_intercourse_sensations(mob/living/wearer, mob/living/partner, lust_amount, orifice_type, is_climax, genital_slot)
	if(!portallight?.len)
		return
	var/panty_location_text = get_insertion_location_text()
	var/panties_are_inserted = !!panty_location_text
	for(var/obj/item/portallight/PL in portallight)
		var/mob/living/carbon/human/fl_holder
		var/fleshlight_is_inserted = FALSE
		if(ishuman(PL.loc))
			fl_holder = PL.loc
		else
			var/datum/component/genital_equipment/fl_equipment = PL.GetComponent(/datum/component/genital_equipment)
			if(fl_equipment?.holder_genital)
				fl_holder = fl_equipment.get_wearer()
				fleshlight_is_inserted = TRUE
		// Only relay if flashlight is actively engaged (inserted or vibration enabled)
		if(!fleshlight_is_inserted && !PL.portal_settings?.vibration_enabled)
			continue  // Skip inactive held flashlights - don't send sensations to devices just sitting in pocket
		if(!fl_holder || fl_holder == wearer || fl_holder == partner)
			continue
		if(!(fl_holder.client?.prefs?.toggles & VERB_CONSENT))
			continue
		// Build contextual sensation message
		var/sensation_msg
		var/fl_location_text = PL.get_insertion_location_text()
		if(is_climax)
			if(panties_are_inserted && fleshlight_is_inserted)
				// Both devices inserted - full portal sex experience
				sensation_msg = "Мощные волны оргазма проходят сквозь портальное соединение! Кто-то кончает, и вы ощущаете это [fl_location_text] - полная портальная связь!"
			else if(fleshlight_is_inserted)
				// Only fleshlight inserted
				sensation_msg = "Сквозь портал вы ощущаете волны оргазма [fl_location_text] - кто-то на другой стороне кончает!"
			else
				// Fleshlight held
				sensation_msg = "Сквозь портальный фонарик в ваших руках вы ощущаете мощные волны оргазма - кто-то кончает [panty_location_text ? "с трусиками [panty_location_text]" : "в портальных трусиках"]!"
		else
			if(panties_are_inserted && fleshlight_is_inserted)
				// Both devices inserted - full portal sex experience
				sensation_msg = "Ритмичные движения передаются через портальное соединение - вы ощущаете их [fl_location_text], словно кто-то занимается сексом прямо с вами!"
			else if(fleshlight_is_inserted)
				// Only fleshlight inserted
				sensation_msg = "Сквозь портал вы ощущаете ритмичные движения [fl_location_text] - кто-то на другой стороне занимается сексом!"
			else
				// Fleshlight held
				sensation_msg = "Сквозь портальный фонарик в ваших руках вы ощущаете ритмичные движения - кто-то занимается сексом [panty_location_text ? "с трусиками [panty_location_text]" : "в портальных трусиках"]!"
		to_chat(fl_holder, span_lewd(sensation_msg))
		// Give reduced lust
		fl_holder.handle_post_sex(round(lust_amount * 0.5), null, partner, null, FALSE, TRUE)
		// Jitter if appropriate
		if(fl_holder.client?.prefs.cit_toggles & SEX_JITTER)
			fl_holder.do_jitter_animation()

// Portal fleshlight relay - sends sensations to panties wearer
/obj/item/portallight/proc/relay_intercourse_sensations(mob/living/wearer, mob/living/partner, lust_amount, orifice_type, is_climax, genital_slot)
	if(!portalunderwear)
		return
	var/mob/living/carbon/human/panty_wearer
	var/panties_are_inserted = FALSE
	if(ishuman(portalunderwear.loc) && (portalunderwear.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)))
		panty_wearer = portalunderwear.loc
	else
		var/datum/component/genital_equipment/equipment = portalunderwear.GetComponent(/datum/component/genital_equipment)
		if(equipment?.holder_genital)
			panty_wearer = equipment.get_wearer()
			panties_are_inserted = TRUE
	if(!panty_wearer || panty_wearer == wearer || panty_wearer == partner)
		return
	if(!(panty_wearer.client?.prefs?.toggles & VERB_CONSENT))
		return
	var/fl_location_text = get_insertion_location_text()
	var/fleshlight_is_inserted = !!fl_location_text
	var/panty_location_text = portalunderwear.get_insertion_location_text()
	// Build contextual sensation message
	var/sensation_msg
	if(is_climax)
		if(panties_are_inserted && fleshlight_is_inserted)
			// Both devices inserted - full portal sex experience
			sensation_msg = "Мощные волны оргазма проходят сквозь портальное соединение! Кто-то кончает, и вы ощущаете это [panty_location_text] - полная портальная связь!"
		else if(panties_are_inserted)
			// Only panties inserted
			sensation_msg = "Сквозь портал вы ощущаете волны оргазма [panty_location_text] - кто-то на другой стороне кончает!"
		else
			// Panties worn
			sensation_msg = "Сквозь ваши портальные трусики вы ощущаете мощные волны оргазма - кто-то кончает [fl_location_text ? "с фонариком [fl_location_text]" : "в портальном фонарике"]!"
	else
		if(panties_are_inserted && fleshlight_is_inserted)
			// Both devices inserted - full portal sex experience
			sensation_msg = "Ритмичные движения передаются через портальное соединение - вы ощущаете их [panty_location_text], словно кто-то занимается сексом прямо с вами!"
		else if(panties_are_inserted)
			// Only panties inserted
			sensation_msg = "Сквозь портал вы ощущаете ритмичные движения [panty_location_text] - кто-то на другой стороне занимается сексом!"
		else
			// Panties worn
			sensation_msg = "Сквозь ваши портальные трусики вы ощущаете ритмичные движения - кто-то занимается сексом [fl_location_text ? "с фонариком [fl_location_text]" : "используя портальный фонарик"]!"
	to_chat(panty_wearer, span_lewd(sensation_msg))
	// Give reduced lust
	panty_wearer.handle_post_sex(round(lust_amount * 0.5), null, partner, null, FALSE, TRUE)
	// Jitter if appropriate
	if(panty_wearer.client?.prefs.cit_toggles & SEX_JITTER)
		panty_wearer.do_jitter_animation()

// Register signal when portal device is inserted
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/register_climax_signal(mob/living/carbon/human/H)
	RegisterSignal(H, COMSIG_MOB_CLIMAX, PROC_REF(on_wearer_climax))

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/unregister_climax_signal(mob/living/carbon/human/H)
	UnregisterSignal(H, COMSIG_MOB_CLIMAX)

/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/on_wearer_climax(datum/source, datum/reagents/senders_cum, atom/target, obj/item/organ/genital/sender, obj/item/organ/genital/receiver, spill, anonymous)
	SIGNAL_HANDLER
	// Relay climax through portal to connected fleshlights
	var/mob/living/carbon/human/wearer = source
	// Validate target is a mob - it could be a turf or item if climaxing outside a partner
	var/mob/living/carbon/human/partner_mob = ishuman(target) ? target : null
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/item/clothing/underwear/briefs/panties/portalpanties, relay_intercourse_sensations), wearer, partner_mob, HIGH_LUST, sender?.slot, TRUE, sender?.slot)

/obj/item/portallight/proc/register_climax_signal(mob/living/carbon/human/H)
	RegisterSignal(H, COMSIG_MOB_CLIMAX, PROC_REF(on_wearer_climax))

/obj/item/portallight/proc/unregister_climax_signal(mob/living/carbon/human/H)
	UnregisterSignal(H, COMSIG_MOB_CLIMAX)

/obj/item/portallight/proc/on_wearer_climax(datum/source, datum/reagents/senders_cum, atom/target, obj/item/organ/genital/sender, obj/item/organ/genital/receiver, spill, anonymous)
	SIGNAL_HANDLER
	// Relay climax through portal to connected panties
	var/mob/living/carbon/human/wearer = source
	// Validate target is a mob - it could be a turf or item if climaxing outside a partner
	var/mob/living/carbon/human/partner_mob = ishuman(target) ? target : null
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/item/portallight, relay_intercourse_sensations), wearer, partner_mob, HIGH_LUST, sender?.slot, TRUE, sender?.slot)

// BLUEMOON ADD: Examine text for inserted portal devices
/obj/item/organ/genital/examine(mob/user)
	. = ..()
	if(!is_exposed() && !always_accessible && owner != user)
		return
	// Check for portal devices inside this genital
	var/list/portal_items = list()
	for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP in contents)
		portal_items += PP
	for(var/obj/item/portallight/PL in contents)
		portal_items += PL
	if(portal_items.len)
		. += span_notice("Внутри виднеется что-то светящееся - похоже на портальное устройство.")

// BLUEMOON ADD: Enhanced examine for portal panties showing insertion state
/obj/item/clothing/underwear/briefs/panties/portalpanties/examine(mob/user)
	. = ..()
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	if(equipment?.holder_genital)
		var/obj/item/organ/genital/G = equipment.holder_genital
		. += span_purple("В данный момент вставлены в [G.name].")
		if(portallight?.len)
			. += span_notice("Подключено фонариков: [portallight.len]")
	if(seamless)
		. += span_warning("Заблокированы латексным ключом.")

// BLUEMOON ADD: Enhanced examine for portal fleshlight showing insertion state
/obj/item/portallight/examine(mob/user)
	. = ..()
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	if(equipment?.holder_genital)
		var/obj/item/organ/genital/G = equipment.holder_genital
		. += span_purple("В данный момент вставлен в [G.name].")

// BLUEMOON ADD: Genitals menu interaction for portal devices
/datum/genitals_menu/ui_data(mob/user)
	. = ..()
	// Add portal device info for each genital
	var/mob/living/carbon/genital_holder = target || user
	var/list/genitals = .["genitals"]
	for(var/list/genital_entry in genitals)
		var/obj/item/organ/genital/genital = locate(genital_entry["key"]) in genital_holder.internal_organs
		if(!genital)
			continue
		// Check for portal devices
		var/list/portal_devices = list()
		for(var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP in genital.contents)
			var/list/device_info = list()
			device_info["name"] = PP.name
			device_info["key"] = REF(PP)
			device_info["type"] = "panties"
			device_info["connected"] = PP.portallight?.len || 0
			device_info["connection_mode"] = PP.portal_settings?.connection_mode || PORTAL_MODE_DISABLED
			portal_devices += list(device_info)
		for(var/obj/item/portallight/PL in genital.contents)
			var/list/device_info = list()
			device_info["name"] = PL.name
			device_info["key"] = REF(PL)
			device_info["type"] = "fleshlight"
			device_info["connected"] = PL.portalunderwear ? 1 : 0
			portal_devices += list(device_info)
		if(portal_devices.len)
			genital_entry["portal_devices"] = portal_devices

/datum/genitals_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("portal_emote")
			// Trigger fleshlight emote for the user
			var/mob/living/carbon/self = usr
			self.emote("fleshlight")
			return TRUE
		if("portal_toggle_privacy")
			var/mob/living/carbon/actual_target = target || usr
			var/obj/item/organ/genital/genital = locate(params["genital"]) in actual_target.internal_organs
			if(!genital)
				return FALSE
			var/obj/item/clothing/underwear/briefs/panties/portalpanties/PP = locate(params["device"]) in genital.contents
			if(!PP)
				return FALSE
			if(actual_target != usr)
				to_chat(usr, span_warning("Вы не можете изменить настройки чужого устройства!"))
				return FALSE
			PP.ui_interact(usr)
			return TRUE

// BLUEMOON ADD: Enhanced interaction messages when devices are inserted
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/get_insertion_location_text()
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	if(!equipment?.holder_genital)
		return ""  // Пустая строка для надетых трусиков - текст формируется без location
	var/obj/item/organ/genital/G = equipment.holder_genital
	switch(G.slot)
		if(ORGAN_SLOT_VAGINA)
			return "глубоко внутри вагины"
		if(ORGAN_SLOT_ANUS)
			return "глубоко в анусе"
		if(ORGAN_SLOT_PENIS)
			return "в уретре"
	return "внутри"

/// Get a short location suffix for display in device lists (e.g., "(вагина)")
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/get_short_location_suffix()
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	if(!equipment?.holder_genital)
		// Check if worn as mask or underwear to distinguish multiple devices from same owner
		if(ishuman(loc))
			var/mob/living/carbon/human/H = loc
			if(H.wear_mask == src)
				return "(маска)"
			if(H.w_underwear == src)
				return "(трусы)"
		return ""  // Not worn, not inserted
	var/obj/item/organ/genital/G = equipment.holder_genital
	switch(G.slot)
		if(ORGAN_SLOT_VAGINA)
			return "(вагина)"
		if(ORGAN_SLOT_ANUS)
			return "(анус)"
		if(ORGAN_SLOT_PENIS)
			return "(уретра)"
	return "(внутри)"

/obj/item/portallight/proc/get_insertion_location_text()
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	if(!equipment?.holder_genital)
		return "в руках"
	var/obj/item/organ/genital/G = equipment.holder_genital
	switch(G.slot)
		if(ORGAN_SLOT_VAGINA)
			return "глубоко внутри вагины"
		if(ORGAN_SLOT_ANUS)
			return "глубоко в анусе"
		if(ORGAN_SLOT_PENIS)
			return "в уретре"
	return "внутри"

// BLUEMOON ADD: Notify all connected users when connection state changes
/obj/item/clothing/underwear/briefs/panties/portalpanties/proc/notify_all_connected(message)
	// Notify wearer
	var/datum/component/genital_equipment/equipment = GetComponent(/datum/component/genital_equipment)
	var/mob/living/carbon/human/wearer
	if(equipment?.holder_genital)
		wearer = equipment.get_wearer()
	else if(ishuman(loc) && (current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)))
		wearer = loc
	if(wearer)
		to_chat(wearer, span_notice("[message]"))
	// Notify all connected fleshlights
	for(var/obj/item/portallight/PL in portallight)
		var/mob/living/carbon/human/fl_holder
		if(ishuman(PL.loc))
			fl_holder = PL.loc
		else
			var/datum/component/genital_equipment/fl_equipment = PL.GetComponent(/datum/component/genital_equipment)
			if(fl_equipment?.holder_genital)
				fl_holder = fl_equipment.get_wearer()
		if(fl_holder && fl_holder != wearer)
			to_chat(fl_holder, span_notice("[message]"))

/obj/item/portallight/AltClick(mob/user)
	. = ..()
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/to_connect
	if(available_panties.len)
		to_connect = tgui_input_list(user, "Выберите...", "Доступные трусики", available_panties, null)
	if(!to_connect)
		return FALSE

	if(to_connect == portalunderwear)
		to_chat(usr, "Conntection terminated!")
		to_connect.notify_all_connected("Портальное соединение разорвано.")
		portalunderwear = null
		to_connect.portallight -= src //upair the fleshlight
		to_connect.update_portal()
		icon_state = "unpaired"
		update_appearance()
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
		return FALSE
	if(!to_connect.portal_settings?.can_connect_from(usr))
		to_chat(usr, "Подключение запрещено настройками устройства!")
		return FALSE
	portalunderwear = to_connect //pair the panties on the fleshlight.
	to_connect.update_portal()
	to_connect.portallight |= src //pair the fleshlight (using |= to prevent duplicates)
	to_connect.notify_all_connected("Новое портальное устройство подключено!")
	icon_state = "paired"
	update_appearance()
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
