// ============================================================================
// Neural Interface Component - Universal visual display system for user's screen
// ============================================================================
// Provides text-based visual information display through the neural interface,
// supporting logs, data panels, notifications, and custom templates.
// ============================================================================

// ---------------------------------------------------------------------------
// Utility Procs
// ---------------------------------------------------------------------------
proc/string_repeat(string, count)
	var/result = ""
	for(var/i in range(1, count))
		result += string

	return result

/datum/action/toggle_interface
	name = "Выключить нейронный интерфейс"
	button_icon_state = "choose_module"
	background_icon_state = "bg_tech_blue"
	button_icon = 'icons/mob/actions/actions.dmi'
	icon_icon = 'icons/mob/actions/actions.dmi'

/datum/action/report/IsAvailable()
	return TRUE

/datum/action/toggle_interface/Trigger()
	var/datum/component/neural_interface/interface = owner.GetComponent(/datum/component/neural_interface)
	if(interface)
		interface.toggle()
	UpdateButtons()

// ---------------------------------------------------------------------------
// Neural Interface Component - Main component for visual display
// ---------------------------------------------------------------------------
/datum/component/neural_interface
	// Host mob reference
	var/mob/living/host_mob
	var/list/sources = list()

	// UI customization
	var/display_title = "NEURAL INTERFACE"
	var/header_color = "#4ad1fa86"
	var/separator_color = "#6b7280"
	var/font_size = 12
	var/visible = TRUE

	// Client tracking
	var/client/attached_client
	var/is_client_attached = FALSE

	// Monitor instances - composition pattern
	var/list/datum/neural_monitor/monitors = list()

	var/list/datum/neural_interface_module/modules = list()

	// Signal registration handles
	var/list/signal_registrations = list()

	var/datum/action/toggle_interface/toggle_button

/datum/component/neural_interface/Initialize(mob/user, display_title_p = "NEURAL INTERFACE")

	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	host_mob = parent
	display_title = display_title_p

	toggle_button = new

	if(host_mob?.client)
		attach_client()

	register_client_signals()

	START_PROCESSING(SSfastprocess, src)

	if(!host_mob.client?.prefs?.neural_interface_visibility)
		hide()

	var/datum/neural_interface_module/logs/log_module = new(src)
	var/datum/neural_interface_module/data/data_module = new(src)
	var/datum/neural_interface_module/image_highlight/image_module = new(src)

	modules = list(
		"log" = log_module,
		"data" = data_module,
		"image" = image_module)

	return ..()

/datum/component/neural_interface/process(delta_time)
	compile_display()

/datum/component/neural_interface/Destroy(force, silent)
	STOP_PROCESSING(SSfastprocess, src)
	hide()
	unregister_all_modules()
	unregister_all_signals()
	unregister_all_monitors()
	delete_user()

	return ..()

// ---------------------------------------------------------------------------
// User Management
// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/attach_client()
	attached_client = host_mob.client
	is_client_attached = TRUE
	toggle_button.Grant(host_mob)

/datum/component/neural_interface/proc/delete_user()
	if(!host_mob)
		return

	toggle_button.Remove(host_mob)

	attached_client = null
	is_client_attached = FALSE
	host_mob = null
	QDEL_NULL(toggle_button)

// ---------------------------------------------------------------------------
// Client Tracking - Client attach/detach signals
// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/register_client_signals()
	if(!host_mob)
		return

	if(!attached_client)
		attached_client = host_mob?.client

	if(attached_client)
		RegisterSignal(host_mob, COMSIG_MOB_GHOSTIZE, PROC_REF(on_mob_ghostize))
		RegisterSignal(host_mob, COMSIG_MOB_KEY_CHANGE, PROC_REF(on_mob_key_change))
		RegisterSignal(host_mob, COMSIG_MOB_PRE_PLAYER_CHANGE, PROC_REF(on_mob_key_change))
		RegisterSignal(host_mob, COMSIG_CLIENT_MOB_LOGIN, PROC_REF(on_client_reconnect))

		RegisterSignal(host_mob, COMSIG_NEURAL_INTERFACE_ADD_SOURCE, PROC_REF(on_add_source))
		RegisterSignal(host_mob, COMSIG_NEURAL_INTERFACE_REMOVE_SOURCE, PROC_REF(on_remove_source))
		RegisterSignal(host_mob, COMSIG_NEURAL_INTERFACE_WRITE_LOG, PROC_REF(on_write_log))
		RegisterSignal(host_mob, COMSIG_NEURAL_INTERFACE_WRITE_DATA, PROC_REF(on_write_data))
		RegisterSignal(host_mob, COMSIG_NEURAL_INTERFACE_WRITE_IMAGE_DATA, PROC_REF(on_write_image_data))

		RegisterSignal(src, COMSIG_NEURAL_INTERFACE_ADD_SOURCE, PROC_REF(on_add_source))
		RegisterSignal(src, COMSIG_NEURAL_INTERFACE_REMOVE_SOURCE, PROC_REF(on_remove_source))
		RegisterSignal(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, PROC_REF(on_write_log))
		RegisterSignal(src, COMSIG_NEURAL_INTERFACE_WRITE_DATA, PROC_REF(on_write_data))
		RegisterSignal(src, COMSIG_NEURAL_INTERFACE_WRITE_IMAGE_DATA, PROC_REF(on_write_image_data))

		signal_registrations += list(
			COMSIG_MOB_GHOSTIZE,
			COMSIG_MOB_KEY_CHANGE,
			COMSIG_MOB_PRE_PLAYER_CHANGE,
			COMSIG_CLIENT_MOB_LOGIN,
			COMSIG_NEURAL_INTERFACE_ADD_SOURCE,
			COMSIG_NEURAL_INTERFACE_REMOVE_SOURCE,
			COMSIG_NEURAL_INTERFACE_WRITE_LOG,
			COMSIG_NEURAL_INTERFACE_WRITE_DATA,
			COMSIG_NEURAL_INTERFACE_WRITE_IMAGE_DATA
		)
		is_client_attached = TRUE

// ---------------------------------------------------------------------------
// Signal unregistration
// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/unregister_all_signals()
	for(var/signal_handle in signal_registrations)
		UnregisterSignal(host_mob, signal_handle)
	UnregisterSignal(src, COMSIG_NEURAL_INTERFACE_ADD_SOURCE)
	UnregisterSignal(src, COMSIG_NEURAL_INTERFACE_REMOVE_SOURCE)
	UnregisterSignal(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG)
	UnregisterSignal(src, COMSIG_NEURAL_INTERFACE_WRITE_DATA)
	UnregisterSignal(src, COMSIG_NEURAL_INTERFACE_WRITE_IMAGE_DATA)
	signal_registrations = list()


// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/on_mob_key_change(mob/M, mob/new_mob, old_mob)
	SIGNAL_HANDLER

	if(!host_mob)
		return

	attach_client()

// ---------------------------------------------------------------------------
// Client Reconnect - Re-attach display
// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/on_client_reconnect(client/C)
	SIGNAL_HANDLER

	if(!host_mob)
		return

	attach_client()

// ---------------------------------------------------------------------------
// Client Ghost - De-attach display
// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/on_mob_ghostize(mob/M, can_reenter, special, penalize)
	SIGNAL_HANDLER

	if(!host_mob)
		return

	attached_client = null
	is_client_attached = FALSE

// ---------------------------------------------------------------------------
// Signals
// ---------------------------------------------------------------------------

/datum/component/neural_interface/proc/on_add_source(datum/source, id)
	return AddSource(id)

/datum/component/neural_interface/proc/on_remove_source(datum/source, id)
	return RemoveSource(id)


/datum/component/neural_interface/proc/on_write_log(datum/source, text, key="LOG", color="#4ad1fa86", size=12, speed=0)
	var/datum/neural_interface_module/logs/module = modules["log"]
	return module.write_log(text, key, color, size, speed)

/datum/component/neural_interface/proc/on_write_data(datum/source, key, value, decay_duration=3 SECONDS, priority=0)
	var/datum/neural_interface_module/data/module = modules["data"]
	return module.write_data(key, value, decay_duration, priority)

/datum/component/neural_interface/proc/on_write_image_data(datum/source, key, image/overlay, atom/target, text, decay_duration=30 SECONDS, pixel_x_text = 0, pixel_y_text = 0, text_size=12)
	var/datum/neural_interface_module/image_highlight/module = modules["image"]
	return module.write_image_data(key, overlay, target, text, decay_duration, pixel_x_text, pixel_y_text, text_size)


/datum/component/neural_interface/proc/write_log(text, key="LOG", color="#4ad1fa86", size=12, speed=0)
	var/datum/neural_interface_module/logs/module = modules["log"]
	return module.write_log(text, key, color, size, speed)

/datum/component/neural_interface/proc/write_data(key, value, decay_duration=3 SECONDS, priority=0)
	var/datum/neural_interface_module/data/module = modules["data"]
	return module.write_data(key, value, decay_duration, priority)

/datum/component/neural_interface/proc/write_image_data(key, image/overlay, atom/target, text, decay_duration=30 SECONDS, pixel_x_text = 0, pixel_y_text = 0, text_size=12)
	var/datum/neural_interface_module/image_highlight/module = modules["image"]
	return module.write_image_data(key, overlay, target, text, decay_duration, pixel_x_text, pixel_y_text, text_size)

// ---------------------------------------------------------------------------
// Monitor Management
// ---------------------------------------------------------------------------

/datum/component/neural_interface/proc/AddSource(id)
	LAZYINITLIST(sources)
	LAZYADD(sources, id)
	return TRUE

/datum/component/neural_interface/proc/RemoveSource(id)
	LAZYINITLIST(sources)
	LAZYREMOVE(sources, id)
	var/list/types = list()

	for(var/datum/neural_monitor/monitor in monitors)
		if(monitor.source != id)
			continue

		monitor.disable()
		monitors -= monitor
		types += monitor.type
		QDEL_NULL(monitor)

	if(!sources)
		qdel(src)
		return

	for(var/type in types)
		enable_monitor_by_type(type)

	return TRUE

/datum/component/neural_interface/proc/unregister_all_modules()
	for(var/key in modules)
		var/datum/neural_interface_module/module = modules[key]
		module.hide_module(host_mob)
		module.UpdateVision(host_mob)
		QDEL_NULL(module)
	modules = list()

/datum/component/neural_interface/proc/unregister_all_monitors()
	LAZYINITLIST(monitors)
	for(var/datum/neural_monitor/monitor in monitors)
		monitor.disable()
	QDEL_LIST(monitors)

/datum/component/neural_interface/proc/add_monitor_by_type(source, type, atom/monitor_atom, ...)
	LAZYINITLIST(sources)
	if(!LAZYFIND(sources, source))
		AddSource(source)
	LAZYINITLIST(monitors)
	var/list/arguments = args.Copy()
	arguments.Splice(1, 4)
	if(!monitor_atom)
		monitor_atom = host_mob
	var/datum/neural_monitor/monitor = new type(arglist(list(src, monitor_atom, source) + arguments))
	if(!istype(monitor))
		return FALSE
	monitors += monitor
	if(!get_enabled_monitor_by_type(type))
		return
	if(!visible)
		return
	monitor.enable()

/datum/component/neural_interface/proc/add_monitors_by_types(source, list/types)
	LAZYINITLIST(monitors)
	LAZYINITLIST(types)
	for(var/type in types)
		var/list/arguments = list(host_mob)
		if(types[type])
			arguments = types[type]
		add_monitor_by_type(arglist(list(source, type) + arguments))


/datum/component/neural_interface/proc/remove_monitors_by_types(source, list/types)
	LAZYINITLIST(types)
	for(var/type in types)
		remove_monitor_by_type(source, type)

/datum/component/neural_interface/proc/remove_monitor_by_type(source, type)
	LAZYINITLIST(monitors)
	for(var/datum/neural_monitor/monitor in monitors)
		if(istype(monitor, type) && monitor.source == source)
			monitor.disable()
			monitors -= monitor
			QDEL_NULL(monitor)
			enable_monitor_by_type(type)
			break

/datum/component/neural_interface/proc/enable_monitor_by_type(type)
	if(!visible)
		return
	for(var/datum/neural_monitor/monitor in monitors)
		if(!istype(monitor, type))
			continue

		monitor.enable()
		break

/datum/component/neural_interface/proc/get_enabled_monitor_by_type(type)
	for(var/datum/neural_monitor/monitor in monitors)
		if(!istype(monitor, type) && !monitor.enabled)
			continue
		return monitor

	return FALSE

/datum/component/neural_interface/proc/enable_monitors()
	if(!visible)
		return
	var/list/types = list()
	for(var/datum/neural_monitor/monitor in monitors)
		if(monitor.type in types)
			continue
		types += monitor.type
		if(monitor.enabled)
			continue
		monitor.enable()

/datum/component/neural_interface/proc/disable_monitors()
	for(var/datum/neural_monitor/monitor in monitors)
		if(!monitor.enabled)
			continue
		monitor.disable()

// ---------------------------------------------------------------------------
// Display Compilation - Generate HTML for screen rendering
// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/compile_display()
	if(!is_client_attached || attached_client == null)
		if(host_mob.client)
			attach_client()
		return

	if(!visible)
		return

	update_vision_modules()

// ---------------------------------------------------------------------------
// Display Sections - Build individual display parts
// ---------------------------------------------------------------------------

/datum/component/neural_interface/proc/get_display_header()
	var/write = {"<span style='font-family: \"TinyUnicode\"; font-size: [font_size]pt; color: [header_color]; line-height: 0.8; -dm-text-outline: 1px black;'>── [display_title] ──</span><br>"}
	write += {"<span style='font-family: \"TinyUnicode\"; font-size: [font_size]pt; color: [separator_color]; line-height: 0.8; -dm-text-outline: 1px black;'>[string_repeat("─", length(display_title) + 6)]</span><br>"}

	return write

// ---------------------------------------------------------------------------
// Visibility Control
// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/toggle()
	if(!isliving(host_mob))
		return
	if(host_mob.client?.prefs)
		host_mob.client.prefs.neural_interface_visibility = !visible
	if(visible)
		hide()
	else
		show()

/datum/component/neural_interface/proc/show()
	visible = TRUE
	toggle_button.name = "Выключить нейронный интерфейс"
	toggle_button.button_icon_state = "choose_module"
	toggle_button.UpdateButtons()
	enable_monitors()
	view_modules()
	compile_display()

/datum/component/neural_interface/proc/hide()
	visible = FALSE
	toggle_button.name = "Включить нейронный интерфейс"
	toggle_button.button_icon_state = "shadow_demon_bg"
	toggle_button.UpdateButtons()
	disable_monitors()
	hide_modules()

/datum/component/neural_interface/proc/update_vision_modules()
	for(var/key in modules)
		var/datum/neural_interface_module/module = modules[key]
		module.UpdateVision(host_mob)

/datum/component/neural_interface/proc/hide_modules()
	for(var/key in modules)
		hide_module(key)
	update_vision_modules()

/datum/component/neural_interface/proc/view_modules()
	for(var/key in modules)
		view_module(key)
	update_vision_modules()

/datum/component/neural_interface/proc/hide_module(key)
	var/datum/neural_interface_module/module = modules[key]
	module.hide_module(host_mob)

/datum/component/neural_interface/proc/view_module(key)
	var/datum/neural_interface_module/module = modules[key]
	module.view_module(host_mob)

// ---------------------------------------------------------------------------
// Quick Access - Common operations
// ---------------------------------------------------------------------------
/datum/component/neural_interface/proc/system_log(text)
	return write_log(text, "SYSTEM")

/datum/component/neural_interface/proc/warn_log(text)
	return write_log(text, "WARNING")

/datum/component/neural_interface/proc/error_log(text)
	return write_log(text, "ERROR")

/datum/component/neural_interface/proc/info_log(text)
	return write_log(text, "INFO")
