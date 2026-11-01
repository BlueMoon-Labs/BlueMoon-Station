/// Connection state is independent of the permissions granted to this session.
/datum/netrun_connection
	var/datum/netrun_console/owner
	var/datum/component/netrun_node/jack
	var/wireless = TRUE
	/// Cleared at the end of every synchronous UI serialization pass.
	var/list/ui_refreshed_nodes

/datum/netrun_connection/New(datum/netrun_console/owner)
	src.owner = owner

/datum/netrun_connection/Destroy()
	set_jack(null)
	ui_refreshed_nodes = null
	owner = null
	return ..()

/datum/netrun_connection/proc/set_jack(datum/component/netrun_node/node)
	if(jack == node)
		return
	if(jack)
		UnregisterSignal(jack, COMSIG_PARENT_QDELETING)
	jack = QDELETED(node) ? null : node
	if(jack)
		RegisterSignal(jack, COMSIG_PARENT_QDELETING, PROC_REF(on_jack_deleted))

/datum/netrun_connection/proc/on_jack_deleted(datum/source)
	SIGNAL_HANDLER
	set_jack(null)

/datum/netrun_connection/proc/jack_valid()
	if(QDELETED(jack) || QDELETED(jack.parent))
		return FALSE
	var/turf/source_turf = owner?.physical_turf()
	var/turf/target_turf = jack.physical_turf()
	return source_turf && target_turf && source_turf.z == target_turf.z && get_dist(source_turf, target_turf) <= 1

/// Acquired grants belong to the session; ID credentials still come from its operator.
/datum/netrun_access_session
	var/datum/netrun_console/owner
	var/list/node_access = list()
	var/list/network_access = list()
	/// Адреса серверов сообщений, чей пароль уже извлечён этой сессией (разведданные, не грант).
	var/list/server_passwords = list()

/datum/netrun_access_session/New(datum/netrun_console/owner)
	src.owner = owner
	RegisterSignal(SSnetrun, COMSIG_NETRUN_FIREWALL_CHANGED, PROC_REF(on_firewall_changed))

/datum/netrun_access_session/Destroy()
	UnregisterSignal(SSnetrun, COMSIG_NETRUN_FIREWALL_CHANGED)
	clear_grant_scopes()
	node_access.Cut()
	network_access.Cut()
	server_passwords.Cut()
	owner = null
	return ..()

/datum/netrun_access_session/proc/revoke_all()
	node_access.Cut()
	network_access.Cut()
	clear_grant_scopes()

/datum/netrun_access_session/proc/revoke_node(address)
	node_access -= address
	var/datum/netrun_grant_scope/scope = node_grant_scopes[address]
	node_grant_scopes -= address
	qdel(scope)

/// The running breach and trace/lockout lifecycle have one owner.
/datum/netrun_intrusion_session
	var/datum/netrun_console/owner
	var/datum/netrun_breach/breach
	var/last_breach_tick = 0
	var/trace = 0
	var/trace_mult = 1
	var/last_illegal = -INFINITY
	var/lockout_until = 0
	var/can_breach = TRUE
	var/buffer_bonus = 0

/datum/netrun_intrusion_session/New(datum/netrun_console/owner)
	src.owner = owner

/datum/netrun_intrusion_session/Destroy()
	QDEL_NULL(breach)
	owner = null
	return ..()

/// Windows and physical viewing resources share the remote session's lifetime.
/datum/netrun_remote_session
	var/datum/netrun_console/owner
	var/list/windows = list()
	var/active_window
	var/mob/watch_viewer
	var/datum/component/netrun_node/watch_node
	var/obj/effect/netrun_view_eye/watch_eye
	var/web_site_id
	var/web_slug
	/// Cached text camera feed, scoped to this session and verified against live access.
	var/datum/component/netrun_node/feed_node
	var/atom/feed_eye
	var/turf/feed_turf
	var/mob/feed_operator
	var/feed_updated_at = -INFINITY
	var/list/feed_data

/datum/netrun_remote_session/New(datum/netrun_console/owner)
	src.owner = owner

/datum/netrun_remote_session/Destroy()
	stop_watch()
	windows.Cut()
	active_window = null
	web_site_id = null
	web_slug = null
	feed_node = null
	feed_eye = null
	feed_turf = null
	feed_operator = null
	feed_data = null
	owner = null
	return ..()

/datum/netrun_remote_session/proc/stop_watch()
	var/mob/previous_viewer = watch_viewer
	var/owns_perspective = previous_viewer?.client?.eye == watch_eye && watch_eye
	if(previous_viewer?.netrun_watch_console == owner)
		previous_viewer.netrun_watch_console = null
	watch_viewer = null
	watch_node = null
	QDEL_NULL(watch_eye)
	if(owns_perspective && previous_viewer?.client)
		previous_viewer.reset_perspective(null)
		if(istype(previous_viewer, /mob/camera/netrun_entity))
			var/mob/camera/netrun_entity/entity = previous_viewer
			entity.update_vision()
