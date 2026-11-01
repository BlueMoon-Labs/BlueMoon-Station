GLOBAL_LIST_EMPTY(mod_link_ids)
GLOBAL_LIST_INIT(mod_link_digits, list("0", "1", "2", "3", "4", "5", "6", "7", "8", "9"))

/datum/mod_link
	var/name = "MODlink"
	var/id
	var/display_name
	var/frequency
	var/atom/movable/holder
	var/datum/mod_link_call/link_call
	var/datum/weakref/user_ref
	var/obj/effect/overlay/modlink/visual
	var/list/visual_overlays
	var/appearance_timer

/datum/mod_link/New(atom/movable/holder, frequency)
	..()
	src.holder = holder
	src.frequency = frequency
	var/length = MODLINK_ID_LENGTH
	var/attempts = 0
	do
		id = random_string(length, GLOB.mod_link_digits)
		if(++attempts >= MODLINK_ID_ATTEMPTS)
			length++
			attempts = 0
	while(GLOB.mod_link_ids[id])
	GLOB.mod_link_ids[id] = src
	RegisterSignal(holder, COMSIG_PARENT_QDELETING, PROC_REF(on_holder_deleted))

/datum/mod_link/Destroy()
	end_call()
	GLOB.mod_link_ids -= id
	UnregisterSignal(holder, COMSIG_PARENT_QDELETING)
	holder = null
	user_ref = null
	visual_overlays = null
	QDEL_NULL(visual)
	return ..()

/datum/mod_link/proc/on_holder_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/mod_link/proc/get_user()
	if(istype(holder, /obj/item/mod/control))
		var/obj/item/mod/control/mod = holder
		return mod.wearer
	if(istype(holder, /obj/item/clothing/neck/link_scryer))
		var/obj/item/clothing/neck/link_scryer/scryer = holder
		return scryer.get_user()

/datum/mod_link/proc/can_call()
	var/mob/living/user = get_user()
	if(QDELETED(holder) || !user || user.stat == DEAD)
		return FALSE
	if(istype(holder, /obj/item/mod/control))
		var/obj/item/mod/control/mod = holder
		return mod.get_charge() && mod.check_charge(mod.cell_drain)
	if(istype(get_area(user), /area/centcom/holding))
		return FALSE
	var/obj/item/item = holder
	var/obj/item/stock_parts/cell/cell = item.get_cell()
	return cell?.charge > 0

/datum/mod_link/proc/get_other()
	RETURN_TYPE(/datum/mod_link)
	if(!link_call)
		return
	return link_call.link_caller == src ? link_call.receiver : link_call.link_caller

/datum/mod_link/proc/get_display_name()
	return display_name || id

/datum/mod_link/proc/rename(mob/user)
	if(user != get_user())
		return FALSE
	var/new_name = stripped_input(user, "Имя устройства. Пустая строка вернёт номер.", "MODlink", display_name, MAX_NAME_LEN)
	if(QDELETED(src) || isnull(new_name) || user != get_user())
		return FALSE
	display_name = new_name
	if(visual)
		visual.name = "[user] ([get_display_name()])"
	return TRUE

/datum/mod_link/proc/can_connect(datum/mod_link/other)
	if(QDELETED(other) || other == src || !frequency || frequency != other.frequency)
		return FALSE
	if(link_call || other.link_call || !can_call() || !other.can_call())
		return FALSE
	var/mob/living/user = get_user()
	var/mob/living/other_user = other.get_user()
	return user != other_user && !HAS_TRAIT(user, TRAIT_MODLINK_CALL) && !HAS_TRAIT(other_user, TRAIT_MODLINK_CALL)

/datum/mod_link/proc/choose_call(mob/user)
	if(user != get_user())
		return
	if(link_call)
		end_call()
		return
	var/list/choices = list()
	for(var/id in GLOB.mod_link_ids)
		var/datum/mod_link/other = GLOB.mod_link_ids[id]
		if(can_connect(other))
			var/label = "[other.holder] ([other.get_display_name()])"
			if(label in choices)
				label += " #[id]"
			choices[label] = id
	if(!length(choices))
		holder.balloon_alert(user, "нет доступных устройств!")
		return
	var/choice = tgui_input_list(user, "Выберите устройство на частоте [frequency]", "MODlink", choices)
	if(QDELETED(src) || !choice || user != get_user())
		return
	request_call(GLOB.mod_link_ids[choices[choice]])

/datum/mod_link/proc/request_call(datum/mod_link/other)
	if(!can_connect(other))
		return FALSE
	var/mob/living/user = other.get_user()
	playsound(other.holder, 'sound/weapons/ring.ogg', MODLINK_RING_VOLUME, TRUE)
	var/atom/movable/screen/alert/modlink_call/alert = user.throw_alert("[REF(src)]_modlink", /atom/movable/screen/alert/modlink_call)
	alert.desc = "[holder] ([get_display_name()]) вызывает вас. ЛКМ — принять, ПКМ — отклонить."
	alert.caller_ref = WEAKREF(src)
	alert.receiver_ref = WEAKREF(other)
	return TRUE

/datum/mod_link/proc/end_call()
	if(link_call)
		qdel(link_call)

/datum/mod_link/proc/enter_call()
	var/mob/living/user = get_user()
	user_ref = WEAKREF(user)
	ADD_TRAIT(user, TRAIT_MODLINK_CALL, REF(src))
	visual = new()
	visual.name = "[user] ([get_display_name()])"
	visual_overlays = user.overlays.Copy()
	visual.add_overlay(visual_overlays)
	RegisterSignal(user, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_direction_changed))
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_deleted))
	RegisterSignal(user, COMSIG_MODLINK_APPEARANCE_CHANGED, PROC_REF(on_appearance_changed))
	update_scryer(user)
	RegisterSignal(holder, COMSIG_MOVABLE_HEAR, PROC_REF(on_hear))
	holder.become_hearing_sensitive(REF(src))

/datum/mod_link/proc/show_visual()
	var/datum/mod_link/other = get_other()
	var/mob/living/user = get_user()
	other.visual.forceMove(user)
	user.add_vis_on_floor(other.visual)
	other.visual.alpha = 0
	animate(other.visual, time = 0.5 SECONDS, alpha = 255)
	update_direction(user.dir)

/datum/mod_link/proc/leave_call()
	var/mob/living/user = user_ref?.resolve()
	var/datum/mod_link/other = get_other()
	if(user)
		user.vis_contents -= other?.visual
		REMOVE_TRAIT(user, TRAIT_MODLINK_CALL, REF(src))
		UnregisterSignal(user, list(COMSIG_ATOM_DIR_CHANGE, COMSIG_PARENT_QDELETING, COMSIG_MODLINK_APPEARANCE_CHANGED))
		update_scryer(user)
	deltimer(appearance_timer)
	appearance_timer = null
	UnregisterSignal(holder, COMSIG_MOVABLE_HEAR)
	holder?.lose_hearing_sensitivity(REF(src))
	user_ref = null
	visual_overlays = null
	QDEL_NULL(visual)

/datum/mod_link/proc/on_user_deleted(datum/source)
	SIGNAL_HANDLER
	end_call()

/datum/mod_link/proc/on_direction_changed(datum/source, old_direction, new_direction)
	SIGNAL_HANDLER
	update_direction(new_direction)

/datum/mod_link/proc/update_direction(direction)
	var/datum/mod_link/other = get_other()
	var/obj/effect/overlay/modlink/display = other?.visual
	if(!display)
		return
	display.setDir(SOUTH)
	display.pixel_x = 0
	display.pixel_y = 0
	var/matrix/rotation = matrix()
	if(direction & NORTH)
		display.pixel_y = MODLINK_NORTH_OFFSET
		display.layer = BELOW_MOB_LAYER
	if(direction & SOUTH)
		display.pixel_y = MODLINK_SOUTH_OFFSET
		display.layer = ABOVE_MOB_LAYER
		rotation.Scale(-1, 1)
		rotation.Translate(MODLINK_MIRROR_OFFSET, 0)
	if(direction & EAST)
		display.pixel_x = MODLINK_SIDE_OFFSET
		display.layer = BELOW_MOB_LAYER
		rotation.b = MODLINK_SHEAR
		rotation.Scale(MODLINK_SIDE_SCALE, 1)
	if(direction & WEST)
		display.pixel_x = -MODLINK_SIDE_OFFSET
		display.layer = BELOW_MOB_LAYER
		rotation.b = -MODLINK_SHEAR
		rotation.Scale(MODLINK_SIDE_SCALE, 1)
	display.transform = rotation

/datum/mod_link/proc/on_hear(datum/source, list/hear_args)
	SIGNAL_HANDLER
	var/mob/living/user = get_user()
	if(!visual)
		return
	var/obj/item/mod/control/mod = holder
	var/mob/speaker = hear_args[MODLINK_SPEAKER_ARG]
	if(speaker != user && (!istype(mod) || speaker != mod.ai))
		return
	visual.send_speech(hear_args[MODLINK_MESSAGE_ARG], MODLINK_VOICE_RANGE, visual, spans = hear_args[MODLINK_SPANS_ARG], message_language = hear_args[MODLINK_LANGUAGE_ARG])

/datum/mod_link/proc/on_appearance_changed()
	SIGNAL_HANDLER
	if(!appearance_timer)
		appearance_timer = addtimer(CALLBACK(src, PROC_REF(update_visual)), 0, TIMER_STOPPABLE)

/datum/mod_link/proc/update_scryer(mob/living/carbon/user)
	if(istype(user) && istype(holder, /obj/item/clothing/neck/link_scryer))
		user.update_inv_neck()

/datum/mod_link/proc/update_visual()
	appearance_timer = null
	var/mob/living/user = user_ref?.resolve()
	if(!user || !visual)
		return
	visual.cut_overlay(visual_overlays)
	visual_overlays = user.overlays.Copy()
	visual.add_overlay(visual_overlays)

/datum/mod_link/proc/sync_frequency(mob/user, obj/item/multitool/tool)
	var/datum/weakref/link_ref = tool.buffer
	var/datum/mod_link/buffer = istype(link_ref) ? link_ref.resolve() : null
	if(!buffer?.frequency)
		if(frequency)
			tool.buffer = WEAKREF(src)
			holder.balloon_alert(user, "частота скопирована")
		return TRUE
	var/choice = frequency ? tgui_alert(user, "Скопировать или записать частоту?", "MODlink", list("Копировать", "Записать")) : "Записать"
	if(QDELETED(src) || QDELETED(buffer) || !user.is_holding(tool))
		return TRUE
	if(choice == "Записать")
		end_call()
		frequency = buffer.frequency
	else if(choice == "Копировать")
		tool.buffer = WEAKREF(src)
	return TRUE

/datum/mod_link_call
	var/datum/mod_link/link_caller
	var/datum/mod_link/receiver

/datum/mod_link_call/New(datum/mod_link/link_caller, datum/mod_link/receiver)
	..()
	src.link_caller = link_caller
	src.receiver = receiver
	link_caller.link_call = src
	receiver.link_call = src
	link_caller.enter_call()
	receiver.enter_call()
	link_caller.show_visual()
	receiver.show_visual()
	START_PROCESSING(SSobj, src)

/datum/mod_link_call/Destroy()
	STOP_PROCESSING(SSobj, src)
	link_caller.leave_call()
	receiver.leave_call()
	link_caller.link_call = null
	receiver.link_call = null
	link_caller = null
	receiver = null
	return ..()

/datum/mod_link_call/process(delta_time)
	if(!link_caller.can_call() || !receiver.can_call() || link_caller.frequency != receiver.frequency)
		qdel(src)
		return

/obj/effect/overlay/modlink
	name = "MODlink hologram"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = KEEP_TOGETHER

/obj/effect/overlay/modlink/Initialize(mapload)
	. = ..()
	add_overlay(mutable_appearance('icons/effects/modlink.dmi', "modlink", ABOVE_ALL_MOB_LAYER))
	add_overlay(mutable_appearance('icons/effects/modlink.dmi', "static_base", ABOVE_NORMAL_TURF_LAYER))
	add_filter("holo_color", 1, color_matrix_filter(MODLINK_RGBA))
	add_hologram_effects()
	add_filter("crop_square", 1, alpha_mask_filter(icon = icon('icons/effects/modlink.dmi', "modlink_filter")))

/obj/effect/overlay/modlink/proc/add_hologram_effects()
	var/atom/movable/scanline = new()
	scanline.icon = 'icons/effects/modlink.dmi'
	scanline.icon_state = "scanline"
	scanline.appearance_flags = RESET_TRANSFORM
	scanline.render_target = "*MODscan[REF(src)]"
	add_filter("holo_scanline", 2, alpha_mask_filter(render_source = scanline.render_target))
	add_overlay(scanline)
	qdel(scanline)
	render_target = "MODhologram[REF(src)]"
	var/atom/movable/glow = new()
	glow.render_source = render_target
	glow.plane = EMISSIVE_PLANE
	glow.color = GLOB.emissive_color
	glow.appearance_flags = EMISSIVE_APPEARANCE_FLAGS
	var/mutable_appearance/appearance = new(glow)
	add_floor_overlay(appearance)
	qdel(glow)

/atom/movable/screen/alert/modlink_call
	name = "MODlink: входящий вызов"
	icon = 'icons/mob/modlink_alert.dmi'
	icon_state = "called"
	timeout = 10 SECONDS
	clickable_glow = TRUE
	var/datum/weakref/caller_ref
	var/datum/weakref/receiver_ref

/atom/movable/screen/alert/modlink_call/Click(location, control, params)
	if(usr != owner)
		return
	var/datum/mod_link/link_caller = caller_ref?.resolve()
	var/datum/mod_link/receiver = receiver_ref?.resolve()
	if(!link_caller || !receiver || receiver.get_user() != owner)
		return
	var/list/modifiers = params2list(params)
	if(!modifiers[RIGHT_CLICK] && link_caller.can_connect(receiver))
		new /datum/mod_link_call(link_caller, receiver)
	owner.clear_alert("[REF(link_caller)]_modlink")

/atom/movable/screen/alert/modlink_call/Destroy()
	caller_ref = null
	receiver_ref = null
	return ..()

/obj/item/clothing/neck/link_scryer
	name = "MODlink scryer"
	custom_price = 550
	desc = "Носимый голографический терминал для звонков на устройства MODlink."
	icon = 'icons/obj/clothing/modsuit/modlink.dmi'
	mob_overlay_icon = 'icons/mob/clothing/modsuit/modlink.dmi'
	icon_state = "modlink"
	actions_types = list(/datum/action/item_action/call_link)
	var/obj/item/stock_parts/cell/cell
	var/datum/mod_link/mod_link
	var/starting_frequency
	var/removable_cell = TRUE
	var/label

/obj/item/clothing/neck/link_scryer/Initialize(mapload)
	. = ..()
	mod_link = new(src, starting_frequency)
	START_PROCESSING(SSobj, src)

/obj/item/clothing/neck/link_scryer/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(mod_link)
	QDEL_NULL(cell)
	return ..()

/obj/item/clothing/neck/link_scryer/worn_overlays(isinhands = FALSE, icon_file)
	. = ..()
	var/mob/living/user = get_user()
	if(!isinhands && user && HAS_TRAIT(user, TRAIT_MODLINK_CALL))
		. += mutable_appearance(mob_overlay_icon, "modlink_active", -NECK_LAYER)

/obj/item/clothing/neck/link_scryer/get_cell()
	return cell

/obj/item/clothing/neck/link_scryer/proc/get_user()
	var/mob/living/carbon/user = loc
	return istype(user) && user.wear_neck == src ? user : null

/obj/item/clothing/neck/link_scryer/process(delta_time)
	if(mod_link.link_call)
		cell?.use(MODLINK_CELL_DRAIN * delta_time)

/obj/item/clothing/neck/link_scryer/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_NECK)
		mod_link?.end_call()

/obj/item/clothing/neck/link_scryer/dropped(mob/user)
	mod_link?.end_call()
	return ..()

/obj/item/clothing/neck/link_scryer/examine(mob/user)
	. = ..()
	. += span_notice("MODlink: [mod_link.get_display_name()]. Частота: [mod_link.frequency || "не задана"]. Батарея: [cell ? "[cell.percent()]%" : "отсутствует"].")
	. += span_notice("Мультитул копирует частоту. Используйте в руке для переименования.")
	if(removable_cell)
		. += span_notice("Alt-клик извлекает батарею.")

/obj/item/clothing/neck/link_scryer/attack_self(mob/user)
	var/new_label = stripped_input(user, "Название устройства", "MODlink", label, MAX_NAME_LEN)
	if(!new_label || !user.is_holding(src))
		return
	label = new_label
	mod_link.display_name = new_label
	name = "[initial(name)] - [label]"

/obj/item/clothing/neck/link_scryer/attackby(obj/item/item, mob/user, params)
	if(cell || !istype(item, /obj/item/stock_parts/cell))
		return ..()
	if(user.transferItemToLoc(item, src))
		cell = item

/obj/item/clothing/neck/link_scryer/AltClick(mob/user)
	if(!removable_cell || !cell || !user.canUseTopic(src, BE_CLOSE))
		return
	mod_link?.end_call()
	user.put_in_hands(cell)

/obj/item/clothing/neck/link_scryer/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == cell)
		mod_link?.end_call()
		cell = null

/obj/item/clothing/neck/link_scryer/multitool_act(mob/living/user, obj/item/multitool/tool)
	return mod_link.sync_frequency(user, tool)

/obj/item/clothing/neck/link_scryer/ui_action_click(mob/user)
	mod_link.choose_call(user)

/obj/item/clothing/neck/link_scryer/loaded
	starting_frequency = MODLINK_FREQ_NANOTRASEN

/obj/item/clothing/neck/link_scryer/loaded/Initialize(mapload)
	. = ..()
	cell = new /obj/item/stock_parts/cell/high(src)

/obj/item/clothing/neck/link_scryer/loaded/charlie
	starting_frequency = MODLINK_FREQ_CHARLIE

/datum/action/item_action/call_link
	name = "Call MODlink"

/obj/item/mod/control/multitool_act(mob/living/user, obj/item/multitool/tool)
	return mod_link.sync_frequency(user, tool)
