/**
 * Modular PDA
 *
 * A handheld computer that replaces the legacy /obj/item/modular_computer/pda system.
 * Uses the modular_computer framework with TGUI-based programs.
 */
/obj/item/modular_computer/pda
	name = "pda"
	desc = "Портативный микрокомпьютер от Thinktronic Systems, LTD. Функционал определяется препрограммированными ROM картриджами."
	icon = 'icons/obj/pda_alt.dmi'
	icon_state = "pda"
	base_icon_state = "pda"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	item_state = "electronic"
	item_flags = NOBLUDGEON

	overlays_icon = 'icons/obj/pda_alt.dmi'

	icon_state_menu = "screen_default"
	show_program_icon = FALSE
	hardware_flag = PROGRAM_PDA
	max_hardware_size = 1
	max_bays = 1
	max_idle_programs = 2
	/// HDD capacity for this PDA type (32 for assistant, 64 for others)
	var/hdd_capacity = 64
	/// Programs installed by the currently inserted cartridge (typepaths for removal on eject)
	var/list/cartridge_programs = list()
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_ID | ITEM_SLOT_BELT
	actions_types = list(/datum/action/item_action/toggle_light/pda)
	has_light = TRUE //LED flashlight!
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	comp_light_luminosity = 2.3
	comp_light_color = "#FFCC66"
	looping_sound = FALSE
	long_ranged = TRUE

	///The item currently inserted into the PDA, starts with a pen.
	var/obj/item/inserted_item = /obj/item/pen
	///Internal battery cell.
	var/obj/item/stock_parts/cell/cell

	///Whether the PDA should have 'pda_programs' apps installed on Initialize.
	var/has_pda_programs = TRUE
	///Static list of default PDA apps to install on Initialize.
	var/static/list/datum/computer_file/pda_programs = list(
		/datum/computer_file/program/messenger,
		/datum/computer_file/program/notepad,
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/banking,
	)
	///List of items that can be stored in a PDA
	var/static/list/contained_item = list(
		/obj/item/pen,
		/obj/item/toy/crayon,
		/obj/item/lipstick,
		/obj/item/flashlight/pen,
		/obj/item/reagent_containers/hypospray/medipen,
		/obj/item/clothing/mask/cigarette,
	)

	// ---- Legacy compatibility aliases ----
	// These bridge old system code that references /obj/item/pda properties.

	/// Legacy alias for saved_identification
	var/owner
	/// Legacy alias for saved_job
	var/ownjob
	/// Legacy messaging-off flag (checked by subsystem/job.dm)
	var/toff = FALSE
	/// Legacy hidden flag (for syndicate PDAs to not appear in PDA lists)
	var/hidden = FALSE
	/// Legacy ID card reference alias — use stored_id instead
	var/obj/item/card/id/id
	/// Legacy silent flag — if TRUE, PDA won't beep on messages
	var/silent = FALSE
	/// Legacy text note buffer (used by AI/borg message log)
	var/tnote
	/// Legacy flashlight-on flag
	var/fon = FALSE
	/// New message alert overlay flag
	var/new_alert = FALSE
	/// Legacy flashlight luminosity
	var/f_lum = 2.3
	/// Legacy photo datum
	var/datum/picture/picture
	/// Stores the job-specific icon_state for PDA skins that support it
	var/job_icon_state
	/// Legacy HTML note text (used by camera.dm when holding PDA up to camera)
	var/notehtml = ""

	/// Legacy note text (raw text, used by map objects)
	var/note
	/// Legacy UI mode number (used by old cart.dm Browser/Topic UI — dead code)
	var/mode = 0

	/// Legacy detonatable flag (used by syndicate virus cart)
	var/detonatable = TRUE
	/// Legacy EMP flag — if TRUE, messages get garbled
	var/emped = FALSE
	/// Legacy emoji flag — if TRUE, emojis are parsed in messages
	var/allow_emojis = TRUE
	/// Legacy mime virus counter
	var/mimeamt = 0
	/// Legacy paper scan flag
	var/notescanned = FALSE
	/// Legacy anti-spam: last direct message time
	var/last_text
	/// Legacy anti-spam: last mass message time
	var/last_everyone
	/// Legacy anti-spam: last noise time
	var/last_noise
	/// Legacy flashlight power
	var/f_pow = 0.6
	/// Legacy flashlight color
	var/f_col = "#FFCC66"
	/// Legacy blocked PDA list (owner names)
	var/list/blocked_pdas
	/// First-pickup guard for update_style
	var/equipped = FALSE

// Override to sync legacy owner/ownjob aliases with saved_identification/saved_job.
/obj/item/modular_computer/pda/update_id_imprint(new_name, new_job)
	. = ..()
	owner = new_name
	ownjob = new_job

/// Legacy stub for old cart.dm UI (dead code)
/obj/item/modular_computer/pda/proc/msg_input(mob/living/U = usr)
	var/t = tgui_input_text(U, "Введите сообщение", name)
	if(!t || toff)
		return
	if(!U.canUseTopic(src, BE_CLOSE, FALSE, NO_TK, FALSE))
		return
	if(emped)
		t = Gibberish(t, 100)
	return t

/obj/item/modular_computer/pda/Initialize(mapload)
	// Create HDD before parent init so install_default_programs can use it
	var/obj/item/computer_hardware/hard_drive/hdd = new(src)
	hdd.max_capacity = hdd_capacity
	install_component(hdd)
	// Install network card for NTNet access
	var/obj/item/computer_hardware/network_card/netcard = new(src)
	install_component(netcard)
	. = ..()
	if(inserted_item)
		inserted_item = new inserted_item(src)
	if(cell)
		cell = new cell(src)
	else
		cell = new /obj/item/stock_parts/cell/high(src)
	// Sync legacy aliases
	owner = saved_identification
	ownjob = saved_job
	id = stored_id
	GLOB.PDAs += src
	if(icon == 'icons/obj/pda_alt.dmi' && icon_state != base_icon_state)
		job_icon_state = icon_state

/obj/item/modular_computer/pda/equipped(mob/user, slot)
	. = ..()
	if(equipped || !user.client)
		return
	equipped = TRUE
	update_style(user.client)
	update_pda_prefs(user.client)

/obj/item/modular_computer/pda/examine(mob/user)
	. = ..()
	if(owner)
		. += "<span class='notice'>Владелец: <b>[owner]</b>, [ownjob].</span>"
	var/battery = get_battery_percent()
	if(battery != null)
		. += "<span class='notice'>Заряд батареи: [battery]%.</span>"
	if(device_theme)
		. += "<span class='notice'>Тема: [device_theme].</span>"
	. += stored_id ? "<span class='notice'>Alt-click для извлечения ID-карты.</span>" : ""
	if(inserted_item && (!isturf(loc)))
		. += "<span class='notice'>Ctrl-click для извлечения [inserted_item].</span>"
	. += "<span class='notice'>Ctrl-Shift-click для смены скина.</span>"

/obj/item/modular_computer/pda/suicide_act(mob/living/carbon/user)
	var/deathMessage = tgui_input_text(user, "Введите предсмертное сообщение", "PDA Suicide")
	if(!deathMessage)
		deathMessage = "i ded"
	user.visible_message("<span class='suicide'>[user] отправляет сообщение Жнецу! Похоже, [user.p_theyre()] пытается покончить с собой!</span>")
	tnote += "<i><b>&rarr; To The Grim Reaper:</b></i><br>[deathMessage]<br>"
	return BRUTELOSS

/obj/item/modular_computer/pda/emp_act(severity)
	. = ..()
	if(!(. & EMP_PROTECT_CONTENTS))
		for(var/atom/A in src)
			A.emp_act(severity)
	if(!(. & EMP_PROTECT_SELF))
		emped += 1
		spawn(2 * severity)
			emped -= 1

/obj/item/modular_computer/pda/handle_atom_del(atom/A)
	if(A == stored_id)
		stored_id = null
		id = null
	if(A == inserted_pai)
		inserted_pai = null
	if(A == inserted_item)
		inserted_item = null
	if(A == inserted_disk)
		if(istype(inserted_disk, /obj/item/cartridge))
			uninstall_cartridge_programs()
		inserted_disk = null
	return ..()

/obj/item/modular_computer/pda/AltClick(mob/user)
	. = ..()
	if(stored_id)
		var/obj/item/card/id/removed = RemoveID()
		if(removed)
			user.put_in_hands(removed)
			to_chat(user, "<span class='notice'>Вы извлекли ID-карту из [name].</span>")
			playsound(src, 'sound/machines/terminal_eject_disc.ogg', 50, TRUE)
		return TRUE
	else if(inserted_disk)
		if(istype(inserted_disk, /obj/item/cartridge))
			uninstall_cartridge_programs()
		user.put_in_hands(inserted_disk)
		to_chat(user, "<span class='notice'>Вы извлекли [inserted_disk] из [name].</span>")
		inserted_disk = null
		playsound(src, 'sound/machines/terminal_eject_disc.ogg', 50, TRUE)
		return TRUE
	else
		remove_pen(user)
		return TRUE

/obj/item/modular_computer/pda/MouseDrop(mob/over, src_location, over_location)
	var/mob/M = usr
	if((M == over) && usr.canUseTopic(src, BE_CLOSE, FALSE, NO_TK, check_resting = FALSE))
		return attack_self(M)
	return ..()

/obj/item/modular_computer/pda/attack_self_tk(mob/user)
	to_chat(user, "<span class='warning'>Сенсорный экран PDA не реагирует на телекинез!</span>")
	return

/obj/item/modular_computer/pda/verb/verb_toggle_light()
	set category = "Object"
	set name = "Toggle Flashlight"
	set src in usr
	if(!usr.canUseTopic(src, BE_CLOSE, no_tk = TRUE))
		return
	toggle_light()

/obj/item/modular_computer/pda/verb/verb_remove_id()
	set category = "Object"
	set name = "Eject ID"
	set src in usr
	if(!usr.canUseTopic(src, BE_CLOSE, no_tk = TRUE))
		return
	if(stored_id)
		var/obj/item/card/id/removed = RemoveID()
		if(removed)
			usr.put_in_hands(removed)
			to_chat(usr, "<span class='notice'>Вы извлекли ID-карту из [name].</span>")
	else
		to_chat(usr, "<span class='warning'>Этот PDA не имеет ID-карты в себе!</span>")

/obj/item/modular_computer/pda/verb/verb_remove_pen()
	set category = "Object"
	set name = "Remove Pen"
	set src in usr
	remove_pen()

/obj/item/modular_computer/pda/use_power(amount = 0)
	if(cell)
		if(cell.use(amount * GLOB.CELLRATE))
			return TRUE
		cell.use(min(amount * GLOB.CELLRATE, cell.charge))
	return FALSE

/obj/item/modular_computer/pda/get_battery_percent()
	if(cell)
		return cell.percent()
	return null

/obj/item/modular_computer/pda/get_cell()
	return cell

// PDAs store the ID directly instead of using card_slot hardware.
/obj/item/modular_computer/pda/GetAccess()
	if(stored_id)
		return stored_id.GetAccess()
	return ..()

/obj/item/modular_computer/pda/GetID()
	return stored_id || ..()

/obj/item/modular_computer/pda/RemoveID()
	if(!stored_id)
		return ..()
	var/obj/item/card/id/removed = stored_id
	stored_id = null
	id = null
	update_label(null, null)
	update_appearance()
	if(ishuman(loc))
		var/mob/living/carbon/human/human_wearer = loc
		if(human_wearer.wear_id == src)
			human_wearer.sec_hud_set_ID()
	else if(istype(loc, /obj/item/storage/wallet))
		var/obj/item/storage/wallet/W = loc
		W.refreshID()
	return removed

/obj/item/modular_computer/pda/InsertID(obj/item/inserting_item)
	var/obj/item/card/id/inserting_id = inserting_item.RemoveID()
	if(!inserting_id)
		return FALSE
	if(stored_id)
		return FALSE
	inserting_id.forceMove(src)
	stored_id = inserting_id
	id = inserting_id
	update_label(inserting_id.registered_name, inserting_id.get_assignment_name())
	update_appearance()
	if(ishuman(loc))
		var/mob/living/carbon/human/human_wearer = loc
		if(human_wearer.wear_id == src)
			human_wearer.sec_hud_set_ID()
	else if(istype(loc, /obj/item/storage/wallet))
		var/obj/item/storage/wallet/W = loc
		W.refreshID()
	return TRUE

/obj/item/modular_computer/pda/Destroy()
	GLOB.PDAs -= src
	if(istype(inserted_item))
		QDEL_NULL(inserted_item)
	if(istype(inserted_pai))
		QDEL_NULL(inserted_pai)
	if(istype(inserted_disk))
		QDEL_NULL(inserted_disk)
	if(istype(cell))
		QDEL_NULL(cell)
	return ..()

/// Legacy compat: update_label syncs owner/ownjob and updates device name.
/obj/item/modular_computer/pda/proc/update_label(new_name, new_job)
	if(!isnull(new_name) && new_name != "")
		owner = new_name
		saved_identification = new_name
	else if(owner)
		saved_identification = owner

	if(!isnull(new_job) && new_job != "")
		ownjob = new_job
		saved_job = new_job
	else if(ownjob)
		saved_job = ownjob

	if(owner)
		name = "[owner]'s PDA ([ownjob])"
	else
		name = initial(name)
	update_id_imprint(saved_identification, saved_job)

/obj/item/modular_computer/pda/proc/imprint_id(new_name, new_job)
	update_label(new_name, new_job)

/// Legacy compat: send_message is a no-op stub (messaging uses programs now).
/obj/item/modular_computer/pda/proc/send_message(message, flash = TRUE)
	return

/// Legacy compat: receive_message is a no-op stub (messaging uses programs now).
/obj/item/modular_computer/pda/proc/receive_message(datum/signal/subspace/pda/signal)
	new_alert = TRUE
	update_appearance()

/// Legacy compat: create_message wraps send_message (used by AI/borg code).
/obj/item/modular_computer/pda/proc/create_message(mob/living/user, obj/item/modular_computer/pda/target)
	send_message(user, list(target))

/// Legacy compat: send_to_all wraps send_message for mass messaging.
/obj/item/modular_computer/pda/proc/send_to_all(mob/living/U)
	if(last_everyone && world.time < last_everyone + 2 MINUTES)
		to_chat(U, "<span class='warning'>Функция \"Отправить Всем\" всё ещё перезаряжается.")
		return
	send_message(U, get_viewable_pdas(), TRUE)

/// Legacy compat: toggle_blocking toggles a PDA owner in the blocked list.
/obj/item/modular_computer/pda/proc/toggle_blocking(mob/user, target)
	if(target in blocked_pdas)
		unblock_pda(user, target)
	else
		block_pda(user, target)

/// Legacy compat: block_pda adds an owner to the blocked list.
/obj/item/modular_computer/pda/proc/block_pda(mob/user, target)
	to_chat(user, "<span class='notice'>Сообщения [target] заблокированы.</span>")
	LAZYOR(blocked_pdas, target)

/// Legacy compat: unblock_pda removes an owner from the blocked list.
/obj/item/modular_computer/pda/proc/unblock_pda(mob/user, target)
	to_chat(user, "<span class='notice'>Сообщения [target] разблокированы.</span>")
	LAZYREMOVE(blocked_pdas, target)

/// Legacy compat wrapper for the LED flashlight toggle.
/obj/item/modular_computer/pda/proc/toggle_light()
	toggle_flashlight()
	update_icon()

/obj/item/modular_computer/pda/attack(mob/living/carbon/C, mob/living/user)
	if(istype(inserted_disk, /obj/item/cartridge))
		var/obj/item/cartridge/installed_cartridge = inserted_disk
		if(installed_cartridge.access & CART_MEDICAL)
			user.visible_message("<span class='notice'>[user] analyzes [C]'s vitals.</span>", \
								"<span class='notice'>You analyze [C]'s vitals.</span>")
			healthscan(user, C, 1, FALSE)
			return
	return ..()

/obj/item/modular_computer/pda/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(istype(target, /obj/item/paper) && owner)
		var/obj/item/paper/PP = target
		if(!PP.default_raw_text)
			to_chat(user, "<span class='warning'>Невозможно просканировать! Лист пуст.</span>")
			return
		notehtml = PP.default_raw_text
		note = replacetext(notehtml, "<BR>", "\[br\]")
		note = replacetext(note, "<br>", "\[br\]")
		note = replacetext(note, "<li>", "\[*\]")
		note = replacetext(note, "<ul>", "\[list\]")
		note = replacetext(note, "</ul>", "\[/list\]")
		note = html_encode(note)
		notescanned = TRUE
		to_chat(user, "<span class='notice'>Лист отсканирован. Сохранено в блокнот PDA.</span>")

/// Returns the sound file for a given ringtone name.
/obj/item/modular_computer/pda/proc/get_ringtone_sound(ringtone)
	switch(ringtone)
		if("Beep")
			return 'sound/machines/twobeep.ogg'
		if("Boom")
			return 'sound/effects/explosion1.ogg'
		if("Honk")
			return 'sound/items/bikehorn.ogg'
		if("SKREE")
			return 'sound/voice/shriek1.ogg'
		if("Xeno")
			return 'sound/voice/hiss2.ogg'
		if("Clown")
			return 'sound/items/AirHorn2.ogg'
		if("Bzzt")
			return 'sound/machines/buzz-sigh.ogg'
		if("Ding")
			return 'sound/machines/ding.ogg'
		if("Chirp")
			return 'sound/machines/chime.ogg'
		if("Pew")
			return 'sound/weapons/laser.ogg'
		if("Boop")
			return 'sound/machines/terminal_select.ogg'
		if("Ping")
			return 'sound/machines/ping.ogg'
		if("Synth")
			return 'sound/misc/interference.ogg'
		if("Stalker")
			return 'sound/items/PDA/stalk1.ogg'
		if("NewQuest")
			return 'sound/items/PDA/stalk2.ogg'
		else
			return 'sound/machines/twobeep.ogg'

/obj/item/modular_computer/pda/install_default_programs()
	var/list/apps_to_download = list()
	if(has_pda_programs)
		apps_to_download += default_programs + pda_programs
	apps_to_download += starting_programs

	var/obj/item/computer_hardware/hard_drive/hdd = all_components[MC_HDD]
	for(var/programs in apps_to_download)
		var/datum/computer_file/program/program_type = new programs
		program_type.computer = src
		if(hdd)
			hdd.store_file(program_type)
		else
			store_file(program_type)

/obj/item/modular_computer/pda/update_overlays()
	. = ..()
	if(new_alert)
		. += mutable_appearance(overlays_icon, "pda-r")
	if(stored_id)
		. += mutable_appearance(overlays_icon, "id_overlay")
	if(inserted_item)
		. += mutable_appearance(overlays_icon, "insert_overlay")
	if(light_on)
		. += mutable_appearance(overlays_icon, "light_overlay")
	if(inserted_pai)
		if(inserted_pai.pai)
			. += mutable_appearance(overlays_icon, "pai_overlay")
		else
			. += mutable_appearance(overlays_icon, "pai_overlay_off")

/obj/item/modular_computer/pda/interact(mob/user)
	if(new_alert)
		new_alert = FALSE
		update_appearance()
	. = ..()
	if(HAS_TRAIT(src, TRAIT_PDA_MESSAGE_MENU_RIGGED))
		explode(user, from_message_menu = TRUE)

/obj/item/modular_computer/pda/attack_self(mob/user)
	// bypass literacy checks to access syndicate uplink
	var/datum/component/uplink/hidden_uplink = GetComponent(/datum/component/uplink)
	if(hidden_uplink?.owner && HAS_TRAIT(user, TRAIT_ILLITERATE))
		if(hidden_uplink.owner != user.key)
			return ..()

		hidden_uplink.locked = FALSE
		hidden_uplink.interact(null, user)
		return COMPONENT_CANCEL_ATTACK_CHAIN

	return ..()

/obj/item/modular_computer/pda/pre_attack(atom/target, mob/living/user, list/modifiers, list/attack_modifiers)
	if(!inserted_disk || !ismachinery(target))
		return ..()

	var/obj/machinery/target_machine = target
	if(!target_machine.panel_open && !istype(target, /obj/machinery/computer))
		return ..()

	if(!istype(inserted_disk, /obj/item/cartridge/virus/clown))
		return ..()
	var/obj/item/cartridge/virus/clown/installed_cartridge = inserted_disk
	if(!installed_cartridge.charges)
		to_chat(user, span_notice("Out of virus charges."))
		return ..()

	to_chat(user, span_notice("You upload the virus to [target]!"))
	installed_cartridge.charges--
	return TRUE

/obj/item/modular_computer/pda/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(held_item)
		if(istype(held_item, /obj/item/paicard) && !inserted_pai)
			context[SCREENTIP_CONTEXT_LMB] = "Insert pAI"
			. = CONTEXTUAL_SCREENTIP_SET
		else if(istype(held_item, /obj/item/card/id) && !stored_id)
			context[SCREENTIP_CONTEXT_LMB] = "Insert ID"
			. = CONTEXTUAL_SCREENTIP_SET
		else if((istype(held_item, /obj/item/computer_disk) || istype(held_item, /obj/item/cartridge)) && !inserted_disk)
			context[SCREENTIP_CONTEXT_LMB] = "Insert disk"
			. = CONTEXTUAL_SCREENTIP_SET
		else if(istype(held_item, /obj/item/photo))
			context[SCREENTIP_CONTEXT_LMB] = "Scan photo"
			. = CONTEXTUAL_SCREENTIP_SET
		else if(is_type_in_list(held_item, contained_item) && !inserted_item)
			context[SCREENTIP_CONTEXT_LMB] = "Insert [held_item]"
			. = CONTEXTUAL_SCREENTIP_SET

	if(stored_id)
		context[SCREENTIP_CONTEXT_ALT_LMB] = "Remove ID"
		. = CONTEXTUAL_SCREENTIP_SET
	else if(inserted_disk)
		context[SCREENTIP_CONTEXT_ALT_LMB] = "Remove disk"
		. = CONTEXTUAL_SCREENTIP_SET
	else if(inserted_item)
		context[SCREENTIP_CONTEXT_ALT_LMB] = "Remove [inserted_item]"
		. = CONTEXTUAL_SCREENTIP_SET

	if(inserted_item)
		context[SCREENTIP_CONTEXT_CTRL_LMB] = "Remove [inserted_item]"
		. = CONTEXTUAL_SCREENTIP_SET

	return . || NONE

/obj/item/modular_computer/pda/attackby(obj/item/tool, mob/user, params)
	if(istype(tool, /obj/item/paicard) && !inserted_pai)
		if(!user.transferItemToLoc(tool, src))
			return
		inserted_pai = tool
		to_chat(user, "<span class='notice'>Вы установили [tool] в [src].</span>")
		update_appearance()
		playsound(src, 'sound/machines/pda_button/pda_button1.ogg', 50, TRUE)
		return

	if(istype(tool, /obj/item/card/id))
		var/obj/item/card/id/idcard = tool
		if(!idcard.registered_name)
			to_chat(user, "<span class='warning'>[src] отвергает ID-карту!</span>")
			playsound(src, 'sound/machines/terminal_error.ogg', 15, TRUE)
			return
		if(user.canUseTopic(src, BE_CLOSE))
			if(!stored_id)
				if(!owner && !saved_identification)
					owner = idcard.registered_name
					ownjob = idcard.get_assignment_name()
					update_label()
				InsertID(tool)
				to_chat(user, "<span class='notice'>Вы вставили ID-карту в слот [src].</span>")
				playsound(src, 'sound/machines/pda_button/pda_button1.ogg', 50, TRUE)
			else
				to_chat(user, span_warning("В [src] уже есть ID-карта!"))
		return

	if(istype(tool, /obj/item/stack/metadollar))
		var/obj/item/stack/metadollar/M = tool
		if(M.deposit_to_lobby_prefs(user, src))
			playsound(src, 'sound/machines/terminal_success.ogg', 15, TRUE)
		return

	if(stored_id && (istype(tool, /obj/item/holochip) || istype(tool, /obj/item/stack/spacecash) || istype(tool, /obj/item/coin)))
		stored_id.insert_money(tool, user)
		return

	if(istype(tool, /obj/item/photo))
		var/obj/item/photo/P = tool
		picture = P.picture
		to_chat(user, "<span class='notice'>Вы просканировали [tool].</span>")
		return

	if(istype(tool, /obj/item/computer_disk) || istype(tool, /obj/item/cartridge))
		if(inserted_disk)
			to_chat(user, span_warning("В [src] уже установлен диск!"))
			return
		if(!user.transferItemToLoc(tool, src))
			return
		inserted_disk = tool
		to_chat(user, span_notice("Вы вставили [tool] в [src]."))
		playsound(src, 'sound/machines/pda_button/pda_button1.ogg', 50, TRUE)
		if(istype(tool, /obj/item/cartridge))
			install_cartridge_programs(tool)
		return

	if(is_type_in_list(tool, contained_item))
		if(tool.w_class >= WEIGHT_CLASS_SMALL)
			to_chat(user, span_warning("[tool] is too big to fit in [src]!"))
			return
		if(!user.transferItemToLoc(tool, src))
			return
		if(inserted_item)
			swap_pen(user, tool)
		else
			to_chat(user, span_notice("You insert [tool] into [src]."))
			inserted_item = tool
			playsound(src, 'sound/machines/pda_button/pda_button1.ogg', 50, TRUE)
		return
	return ..()

/obj/item/modular_computer/pda/CtrlClick(mob/user)
	if(isturf(loc))
		return ..()
	remove_pen(user)

///Finds how hard it is to send a virus to this tablet, checking all programs downloaded.
/obj/item/modular_computer/pda/proc/get_detomatix_difficulty()
	var/detomatix_difficulty
	for(var/datum/computer_file/program/downloaded_apps in get_all_files())
		detomatix_difficulty += downloaded_apps.detomatix_resistance
	return detomatix_difficulty

/obj/item/modular_computer/pda/proc/remove_pen(mob/user = usr)
	if(!user || issilicon(user) || !user.canUseTopic(src, BE_CLOSE, no_tk = TRUE))
		return
	if(inserted_item)
		balloon_alert(user, "removed [inserted_item]")
		user.put_in_hands(inserted_item)
		inserted_item = null
		update_appearance()
		playsound(src, 'sound/machines/pda_button/pda_button2.ogg', 50, TRUE)

/obj/item/modular_computer/pda/proc/swap_pen(mob/user, obj/item/tool)
	if(inserted_item)
		balloon_alert(user, "swapped pens")
		user.put_in_hands(inserted_item)
		inserted_item = tool
		update_appearance()
		playsound(src, 'sound/machines/pda_button/pda_button1.ogg', 50, TRUE)

/obj/item/modular_computer/pda/proc/explode(mob/target, mob/bomber, from_message_menu = FALSE)
	var/turf/current_turf = get_turf(src)

	if(from_message_menu)
		var/log_text = "[key_name(target)]'s tablet exploded as [target.p_they()] tried to open their tablet message menu because of a recent tablet bomb."
		log_game(log_text)
		message_admins(log_text)
	else
		var/log_text = "[key_name(bomber)] successfully tablet-bombed [key_name(target)] as [target.p_they()] tried to reply to a rigged tablet message"
		log_game(log_text)
		message_admins(log_text)

	if(ismob(loc))
		var/mob/loc_mob = loc
		loc_mob.show_message(\
			msg = span_userdanger("Your [src] explodes!"),\
			type = MSG_VISUAL,\
			alt_msg = span_warning("You hear a loud *pop*!"),\
			alt_type = MSG_AUDIBLE,\
		)
	else
		visible_message(span_danger("[src] explodes!"), span_warning("You hear a loud *pop*!"))

	if(current_turf)
		current_turf.hotspot_expose(700, 125)
		if(istype(inserted_disk, /obj/item/cartridge/virus/detomatix))
			explosion(src, devastation_range = -1, heavy_impact_range = 1, light_impact_range = 3, flash_range = 4)
		else
			explosion(src, devastation_range = -1, heavy_impact_range = -1, light_impact_range = 2, flash_range = 3)
	qdel(src)

/**
 * Applies the client's ringtone and skin prefs to the PDA.
 */
/obj/item/modular_computer/pda/proc/update_pda_prefs(client/owner_client)
	if(!owner_client)
		return

	var/new_ringtone = owner_client.prefs?.pda_ringtone
	if(new_ringtone && (new_ringtone != MESSENGER_RINGTONE_DEFAULT))
		update_ringtone(new_ringtone)

	var/new_skin = owner_client.prefs?.pda_skin
	if(new_skin)
		var/list/skin_data = GLOB.pda_reskins[new_skin]
		if(skin_data && skin_data["icon"])
			icon = skin_data["icon"]
			overlays_icon = skin_data["icon"]
			icon_state = base_icon_state
			if(job_icon_state)
				icon_state = job_icon_state
			if("icon_state_menu" in skin_data)
				icon_state_menu = skin_data["icon_state_menu"]
			update_appearance()

	var/new_color = owner_client.prefs?.pda_color
	if(new_color)
		pda_color = new_color

	var/new_theme = owner_client.prefs?.pda_theme
	if(new_theme)
		device_theme = new_theme

/// Removes all programs that were installed by the current cartridge.
/obj/item/modular_computer/pda/proc/uninstall_cartridge_programs()
	for(var/datum/computer_file/program/P in cartridge_programs)
		if(P in stored_files)
			stored_files -= P
		var/obj/item/computer_hardware/hard_drive/hdd = all_components[MC_HDD]
		if(hdd && (P in hdd.stored_files))
			hdd.stored_files -= P
		if(P in idle_threads)
			idle_threads -= P
		if(active_program == P)
			active_program = null
		qdel(P)
	cartridge_programs.Cut()
	if(istype(inserted_disk, /obj/item/cartridge/lawyer))
		var/datum/computer_file/program/messenger/messenger_app = locate() in get_all_files()
		if(messenger_app)
			messenger_app.spam_mode = FALSE

/// Sets the ringtone on the messenger program.
/obj/item/modular_computer/pda/proc/update_ringtone(new_ringtone)
	if(!istext(new_ringtone))
		return
	var/obj/item/computer_hardware/hard_drive/hdd = all_components[MC_HDD]
	var/list/search_files = hdd ? hdd.stored_files : stored_files
	var/datum/computer_file/program/messenger/messenger_app = locate() in search_files
	if(messenger_app)
		messenger_app.ringtone = new_ringtone

/obj/item/modular_computer/pda/verb/change_pda_skin()
	set name = "Change PDA Skin"
	set category = "Object"
	set src in view(1)

	do_change_pda_skin(usr)

/obj/item/modular_computer/pda/proc/do_change_pda_skin(mob/user)
	if(!istype(user))
		return
	if(user.incapacitated())
		return
	if(owner && user.real_name != owner)
		to_chat(user, span_warning("You can only change the skin of your own PDA!"))
		return
	if(!length(GLOB.pda_reskins))
		to_chat(user, span_warning("No skins available."))
		return
	var/list/skin_names = list()
	for(var/skin in GLOB.pda_reskins)
		var/list/skin_data = GLOB.pda_reskins[skin]
		skin_names[skin_data["name"] || skin] = skin
	var/selected_name = input(user, "Choose a new PDA skin:", "PDA Skin") as null|anything in sort_list(skin_names)
	if(!selected_name)
		return
	var/selected_skin = skin_names[selected_name]
	var/list/skin_data = GLOB.pda_reskins[selected_skin]
	if(!skin_data || !skin_data["icon"])
		return
	icon = skin_data["icon"]
	overlays_icon = skin_data["icon"]
	icon_state = base_icon_state
	if(job_icon_state)
		icon_state = job_icon_state
	if("icon_state_menu" in skin_data)
		icon_state_menu = skin_data["icon_state_menu"]
	update_appearance()
	playsound(src, 'sound/machines/terminal_success.ogg', 50, TRUE)
	to_chat(user, span_notice("PDA skin changed to [selected_name]."))

/obj/item/modular_computer/pda/CtrlShiftClick(mob/user)
	if(!user.Adjacent(src) || user.incapacitated())
		return
	do_change_pda_skin(user)

/obj/item/modular_computer/pda/proc/install_cartridge_programs(obj/item/cartridge/C)
	if(!istype(C))
		return
	var/list/installed = list()
	var/obj/item/computer_hardware/hard_drive/hdd = all_components[MC_HDD]
	for(var/prog_type in C.get_programs())
		if(locate(prog_type) in get_all_files())
			continue
		var/datum/computer_file/program/P = new prog_type
		P.computer = src
		if(hdd)
			if(!hdd.can_store_file(P))
				qdel(P)
				continue
			hdd.store_file(P)
		else
			var/used = 0
			for(var/datum/computer_file/F in stored_files)
				used += F.size
			if((used + P.size) > max_capacity)
				qdel(P)
				continue
			store_file(P)
		cartridge_programs += P
		installed += P.filedesc
	if(length(installed))
		var/installed_text = english_list(installed)
		visible_message(span_notice("Programs installed: [installed_text]"), null, null, 1)
		if(ismob(loc))
			var/mob/M = loc
			to_chat(M, span_notice("[src] installs new programs from the cartridge: [installed_text]"))
		SStgui.update_uis(src)
	if(istype(C, /obj/item/cartridge/lawyer))
		var/datum/computer_file/program/messenger/messenger_app = locate() in get_all_files()
		if(messenger_app)
			messenger_app.spam_mode = TRUE

/**
 * Nuclear PDA — given to nukies for disk pinpointer.
 */
/obj/item/modular_computer/pda/nukeops
	name = "nuclear pda"
	icon_state = "pda-syndicate"
	device_theme = PDA_THEME_SYNDICATE
	comp_light_luminosity = 6.3
	light_color = COLOR_RED
	long_ranged = TRUE
	starting_programs = list(
		/datum/computer_file/program/radar/fission360,
	)

/obj/item/modular_computer/pda/nukeops/Initialize(mapload)
	. = ..()
	var/datum/computer_file/program/messenger/msg = locate() in get_all_files()
	if(istype(msg))
		msg.invisible = TRUE

/obj/item/modular_computer/pda/syndicate_contract_uplink
	name = "contractor tablet"
	icon_state = "pda-syndicate"
	icon_state_menu = "screen_default"
	device_theme = PDA_THEME_SYNDICATE
	comp_light_luminosity = 6.3
	has_pda_programs = FALSE

	starting_programs = list(
		/datum/computer_file/program/contract_uplink,
		/datum/computer_file/program/secureye,
	)

/**
 * Silicon PDA — built-in to Silicons.
 */
/obj/item/modular_computer/pda/silicon
	name = "modular interface"
	icon = 'icons/obj/devices/modular_pda.dmi'
	icon_state = "tablet-silicon"
	base_icon_state = "tablet-silicon"

	has_light = FALSE
	comp_light_luminosity = 0
	inserted_item = null
	cell = null
	has_pda_programs = FALSE
	starting_programs = list(
		/datum/computer_file/program/messenger,
	)

	///Ref to the silicon we're installed in.
	var/mob/living/silicon/silicon_owner

/obj/item/modular_computer/pda/silicon/pai
	starting_programs = list(
		/datum/computer_file/program/messenger,
		/datum/computer_file/program/chatclient,
	)

/obj/item/modular_computer/pda/silicon/cyborg
	starting_programs = list(
		/datum/computer_file/program/filemanager,
		/datum/computer_file/program/ntnetdownload,
		/datum/computer_file/program/robotact,
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/messenger,
		/datum/computer_file/program/borg_monitor,
		/datum/computer_file/program/atmosscan,
	)

/obj/item/modular_computer/pda/silicon/Initialize(mapload)
	. = ..()
	vis_flags |= VIS_INHERIT_ID
	silicon_owner = loc
	if(!istype(silicon_owner))
		silicon_owner = null
		stack_trace("[type] initialized outside of a silicon, deleting.")
		return INITIALIZE_HINT_QDEL

/obj/item/modular_computer/pda/silicon/Destroy()
	silicon_owner = null
	return ..()

/obj/item/modular_computer/pda/silicon/turn_on(mob/user, open_ui = FALSE)
	if(silicon_owner?.stat != DEAD)
		return ..()
	return FALSE

// pAI PDA
/obj/item/modular_computer/pda/silicon/pai/kill_program(forced = FALSE)
	if(active_program)
		active_program.kill_program(forced)
		active_program = null
	update_appearance()

// pAI PDA
/obj/item/modular_computer/pda/silicon/pai/shutdown_computer(loud = 1)
	return

/obj/item/modular_computer/pda/silicon/use_power(amount = 0)
	if(!silicon_owner)
		return FALSE
	if(iscyborg(silicon_owner))
		var/mob/living/silicon/robot/robo = silicon_owner
		if(robo.cell && robo.cell.use(amount * GLOB.CELLRATE))
			return TRUE
		return FALSE
	return TRUE // AI and other silicons don't consume PDA power

/obj/item/modular_computer/pda/silicon/get_battery_percent()
	if(iscyborg(silicon_owner))
		var/mob/living/silicon/robot/robo = silicon_owner
		if(robo.cell)
			return robo.cell.percent()
	return null

/obj/item/modular_computer/pda/get_ntnet_status(specific_action = 0)
	. = ..()
	if(.)
		return .
	if(long_ranged)
		return SSnetworks.station_network?.check_function(specific_action)
	return FALSE

/obj/item/modular_computer/pda/silicon/get_ntnet_status()
	if(!silicon_owner)
		return FALSE
	var/mob/living/silicon/robot/cyborg_check = silicon_owner
	if(!istype(cyborg_check))
		return ..()
	if(cyborg_check.locked_down)
		return FALSE
	if(!cyborg_check.cell || cyborg_check.cell.charge == 0)
		return FALSE
	return ..()

/obj/item/modular_computer/pda/silicon/cyborg/ui_data(mob/user)
	. = ..()
	.["has_light"] = TRUE
	if(iscyborg(silicon_owner))
		var/mob/living/silicon/robot/robo = silicon_owner
		.["light_on"] = robo.lamp_enabled
		.["comp_light_color"] = robo.lamp_color

/obj/item/modular_computer/pda/silicon/cyborg/proc/get_department_access()
	if(!iscyborg(silicon_owner))
		return list()
	var/mob/living/silicon/robot/robo = silicon_owner
	if(!robo.module)
		return list()
	var/static/list/module_access_map = list(
		/obj/item/robot_module/engineering = list(ACCESS_ENGINE),
		/obj/item/robot_module/medical = list(ACCESS_MEDICAL),
		/obj/item/robot_module/security = list(ACCESS_SECURITY),
		/obj/item/robot_module/butler = list(ACCESS_JANITOR), // Service/Janitor
		/obj/item/robot_module/miner = list(ACCESS_MINING),
		/obj/item/robot_module/cargo = list(ACCESS_CARGO),
		/obj/item/robot_module/syndicate = list(ACCESS_SYNDICATE),
		/obj/item/robot_module/syndicate_medical = list(ACCESS_SYNDICATE),
		/obj/item/robot_module/saboteur = list(ACCESS_SYNDICATE),
	)
	for(var/module_type in module_access_map)
		if(istype(robo.module, module_type))
			return module_access_map[module_type]
	return list()

/obj/item/modular_computer/pda/silicon/toggle_flashlight(mob/user)
	if(!silicon_owner || QDELETED(silicon_owner))
		return FALSE
	if(iscyborg(silicon_owner))
		var/mob/living/silicon/robot/robo = silicon_owner
		robo.toggle_headlamp()
	return TRUE

/obj/item/modular_computer/pda/silicon/set_flashlight_color(color)
	if(!silicon_owner || QDELETED(silicon_owner) || !color)
		return FALSE
	if(iscyborg(silicon_owner))
		var/mob/living/silicon/robot/robo = silicon_owner
		robo.lamp_color = color
		robo.toggle_headlamp(FALSE, TRUE)
	return TRUE

/obj/item/modular_computer/pda/silicon/ui_state(mob/user)
	return GLOB.deep_inventory_state

/obj/item/modular_computer/pda/silicon/cyborg/syndicate
	icon_state = "tablet-silicon-syndicate"
	device_theme = PDA_THEME_SYNDICATE

/obj/item/modular_computer/pda/silicon/cyborg/syndicate/Initialize(mapload)
	. = ..()
	if(iscyborg(silicon_owner))
		var/mob/living/silicon/robot/robo = silicon_owner
		robo.lamp_color = COLOR_RED

// ---- Global PDA helpers ----

/// Returns a list of all PDAs whose owners are visible in the PDA messenger list.
/proc/get_viewable_pdas()
	. = list()
	for(var/obj/item/modular_computer/pda/P in GLOB.PDAs)
		if(!P.owner || P.toff || P.hidden)
			continue
		. += P

// ---- AI PDA messaging ----

/mob/living/silicon/ai/proc/cmd_send_pdamesg(mob/user)
	var/list/plist = list()
	var/list/namecounts = list()

	if(aiPDA.toff)
		to_chat(user, "Включите приём сообщений для работы мессенджера.")
		return

	for(var/obj/item/modular_computer/pda/P in get_viewable_pdas())
		if(P == aiPDA)
			continue
		plist[avoid_assoc_duplicate_keys(P.owner, namecounts)] = P

	var/c = input(user, "Выберите PDA") as null|anything in sort_list(plist)
	if(!c)
		return
	var/obj/item/modular_computer/pda/selected = plist[c]

	if(aicamera.stored.len)
		var/add_photo = input(user, "Хотите приложить фото?", "Фотография", "Нет") as null|anything in list("Да", "Нет")
		if(add_photo == "Да")
			var/datum/picture/Pic = aicamera.selectpicture(user)
			aiPDA.picture = Pic

	var/message = tgui_input_text(user, "Введите сообщение", "PDA сообщение", max_length = 1024, encode = FALSE)
	if(!message)
		return

	if(incapacitated())
		return

	var/datum/computer_file/program/messenger/ai_messenger = locate() in aiPDA.get_all_files()
	var/datum/computer_file/program/messenger/target_messenger = locate() in selected.get_all_files()
	if(!ai_messenger || !target_messenger)
		to_chat(user, span_notice("Мессенджер недоступен."))
		return

	ai_messenger.send_message(user, message, list(target_messenger))

/mob/living/silicon/ai/verb/cmd_toggle_pda_receiver()
	set category = "AI Commands"
	set name = "PDA - Toggle Sender/Receiver"
	if(usr.stat == DEAD)
		return
	if(!isnull(aiPDA))
		aiPDA.toff = !aiPDA.toff
		to_chat(usr, "<span class='notice'>Отправление/получение сообщений PDA переключёно на [(aiPDA.toff ? "Off" : "On")]!</span>")
	else
		to_chat(usr, "У вас нет PDA. Вам следует сделать донос о проблеме.")

/mob/living/silicon/ai/verb/cmd_toggle_pda_silent()
	set category = "AI Commands"
	set name = "PDA - Toggle Ringer"
	if(usr.stat == DEAD)
		return
	if(!isnull(aiPDA))
		aiPDA.silent = !aiPDA.silent
		to_chat(usr, "<span class='notice'>Уведомления PDA переключены на [(aiPDA.silent ? "Off" : "On")]!</span>")
	else
		to_chat(usr, "У вас нет PDA. Вам следует сделать донос о проблеме.")

/mob/living/silicon/ai/proc/cmd_show_message_log(mob/user)
	if(incapacitated())
		return
	if(!isnull(aiPDA))
		var/datum/computer_file/program/messenger/ai_messenger = locate() in aiPDA.get_all_files()
		if(!ai_messenger)
			to_chat(user, span_notice("Мессенджер недоступен."))
			return
		ai_messenger.ui_interact(user)
	else
		to_chat(user, "У вас нет PDA. Вам следует сделать донос о проблеме.")

// ---- Borg PDA messaging ----

/mob/living/silicon/robot/proc/cmd_send_pdamesg(mob/user)
	var/list/plist = list()
	var/list/namecounts = list()

	if(aiPDA.toff)
		to_chat(user, "Включите приём сообщений для работы мессенджера.")
		return

	for(var/obj/item/modular_computer/pda/P in get_viewable_pdas())
		if(P == aiPDA)
			continue
		plist[avoid_assoc_duplicate_keys(P.owner, namecounts)] = P

	var/c = input(user, "Выберите PDA") as null|anything in sort_list(plist)
	if(!c)
		return
	var/obj/item/modular_computer/pda/selected = plist[c]

	if(aicamera.stored.len)
		var/add_photo = input(user, "Хотите приложить фото?", "Фотография", "Нет") as null|anything in list("Да", "Нет")
		if(add_photo == "Да")
			var/datum/picture/Pic = aicamera.selectpicture(user)
			aiPDA.picture = Pic

	var/message = tgui_input_text(user, "Введите сообщение", "PDA сообщение", max_length = 1024, encode = FALSE)
	if(!message)
		return

	if(incapacitated())
		return

	var/datum/computer_file/program/messenger/borg_messenger = locate() in aiPDA.get_all_files()
	var/datum/computer_file/program/messenger/target_messenger = locate() in selected.get_all_files()
	if(!borg_messenger || !target_messenger)
		to_chat(user, span_notice("Мессенджер недоступен."))
		return

	borg_messenger.send_message(user, message, list(target_messenger))

/mob/living/silicon/robot/proc/cmd_show_message_log(mob/user)
	if(incapacitated())
		return
	if(!isnull(aiPDA))
		var/datum/computer_file/program/messenger/borg_messenger = locate() in aiPDA.get_all_files()
		if(!borg_messenger)
			to_chat(user, span_notice("Мессенджер недоступен."))
			return
		borg_messenger.ui_interact(user)
	else
		to_chat(user, "У вас нет PDA. Вам следует сделать донос о проблеме.")

/obj/item/modular_computer/pda/hotelstaff
	name = "hotel staff PDA"
	inserted_item = /obj/item/pen/fountain
