GLOBAL_LIST_EMPTY(lighting_update_lights) // List of lighting sources  queued for update.
GLOBAL_LIST_EMPTY(lighting_update_corners) // List of lighting corners  queued for update.
GLOBAL_LIST_EMPTY(lighting_update_objects) // List of lighting objects queued for update.
GLOBAL_LIST_EMPTY(lighting_update_blends) // List of lighting objects queued for area blend recalculation.
GLOBAL_LIST_EMPTY(all_light_sources) // All live light sources — used for bulk operations like falloff mode toggle.
GLOBAL_LIST_EMPTY(starlight) // List of space turfs currently emitting starlight.
GLOBAL_LIST_EMPTY(lighting_sheets) // Cached pre-computed falloff lookup tables, keyed by "[range]-[height]".
GLOBAL_VAR_INIT(lighting_defer_active, FALSE) // When TRUE, ChangeTurf skips synchronous lighting_object.update() and starlight iteration.
GLOBAL_LIST_EMPTY(lighting_deferred_starlight) // Turfs that need starlight recalc after deferred batch completes.
GLOBAL_LIST_EMPTY(lighting_starlight_queue) // Space turfs queued for deferred update_starlight() — filled by shuttle docking, drained by SSlighting Phase -1.
GLOBAL_LIST_EMPTY(lighting_deferred_shadow_turfs) // Turfs queued for deferred shadow + blend recalc — filled by shuttle docking, drained by SSlighting Phase -0.5.
GLOBAL_LIST_EMPTY(lighting_deferred_atoms) // Atoms whose light_source creation was deferred because their z-level was skipped during init.
GLOBAL_VAR_INIT(starlight_color_dirty, FALSE) // Set by SSnightshift when solar starlight color/power changes. Drained incrementally by SSlighting.
GLOBAL_LIST_EMPTY(nightshift_apc_queue) // APCs queued for batched indoor nightshift propagation.
GLOBAL_LIST_EMPTY(nightshift_light_queue) // Lamps queued for batched indoor nightshift refresh.

/// Admin verb: change the global starlight color at runtime, or reset to solar cycle.
/client/proc/cmd_admin_set_starlight()
	set name = "Set Starlight Color"
	set category = "Admin"
	if(!check_rights(R_ADMIN))
		return
	var/list/options = list("Выбрать цвет", "Сбросить (авто цикл)")
	var/choice = tgui_alert(src, "Управление звёздным светом:", "Звёздный свет", options)
	if(choice == "Сбросить (авто цикл)")
		SSnightshift.starlight_override = FALSE
		SSnightshift.last_starlight_color = null
		log_admin("[key_name(src)] reset starlight to solar cycle")
		message_admins("[key_name_admin(src)] сбросил цвет звёздного света на солнечный цикл")
		return
	if(choice != "Выбрать цвет")
		return
	var/new_color = input(src, "Выберите цвет освещения космоса:", "Цвет звёздного света", COLOR_STARLIGHT) as color|null
	if(!new_color)
		return
	SSnightshift.starlight_override = TRUE
	set_starlight(new_color)
	log_admin("[key_name(src)] changed starlight color to [new_color] (override)")
	message_admins("[key_name_admin(src)] изменил цвет звёздного света на <font color='[new_color]'>[new_color]</font> (переопределение)")

/// Updates the starlight color and/or power on all active starlight turfs.
/proc/set_starlight(star_color, star_power)
	var/list/stale_refs = list()
	for(var/turf/open/space/S as anything in GLOB.starlight)
		if(QDELETED(S))
			stale_refs += S
			continue
		var/color_changed = !isnull(star_color) && S.light_color != star_color
		var/power_changed = !isnull(star_power) && S.light_power != star_power
		if(color_changed || power_changed)
			S.set_light(l_color = star_color, l_power = star_power)
		CHECK_TICK
	if(length(stale_refs))
		GLOB.starlight -= stale_refs

/// Admin verb: toggle between linear and inverse-square light falloff at runtime.
/client/proc/cmd_admin_toggle_falloff()
	set name = "Toggle Light Falloff"
	set category = "Admin"
	if(!check_rights(R_ADMIN))
		return
	var/new_mode = GLOB.lighting_falloff_mode == LIGHTING_FALLOFF_LINEAR ? LIGHTING_FALLOFF_INVERSE_SQUARE : LIGHTING_FALLOFF_LINEAR
	var/mode_name = new_mode == LIGHTING_FALLOFF_INVERSE_SQUARE ? "Inverse-Square" : "Linear"
	GLOB.lighting_falloff_mode = new_mode
	GLOB.lighting_sheets.Cut() // Invalidate all cached falloff sheets
	// Force all active light sources to recalculate with new falloff
	for(var/datum/light_source/L as anything in GLOB.all_light_sources)
		if(L.needs_update == LIGHTING_NO_UPDATE)
			GLOB.lighting_update_lights += L
		L.needs_update = LIGHTING_FORCE_UPDATE
	log_admin("[key_name(src)] toggled lighting falloff to [mode_name]")
	message_admins("[key_name_admin(src)] переключил режим затухания света на [mode_name]")

SUBSYSTEM_DEF(lighting)
	name = "Lighting"
	wait = 1
	init_order = INIT_ORDER_LIGHTING
	flags = SS_TICKER
	/// Adaptive source processing cap (adjusted per fire based on server load)
	var/sources_cap = LIGHTING_SOURCES_BASE_CAP
	/// Adaptive corners processing cap (proportional to sources processed)
	var/corners_cap = LIGHTING_CORNERS_MIN_CAP
	/// Adaptive objects processing cap (proportional to corners processed)
	var/objects_cap = LIGHTING_OBJECTS_MIN_CAP
	/// MC_AVERAGE tracked cost of sources phase (ms)
	var/cost_sources = 0
	/// MC_AVERAGE tracked cost of corners phase (ms)
	var/cost_corners = 0
	/// MC_AVERAGE tracked cost of objects phase (ms)
	var/cost_objects = 0
	/// Peak queue lengths (high watermarks) — reset via VV
	var/peak_sources = 0
	var/peak_corners = 0
	var/peak_objects = 0
	/// Worst single-fire total cost (ms)
	var/worst_fire_cost = 0
	/// MC_AVERAGE tracked sources processed per fire
	var/avg_sources_processed = 0
	/// Temporary additive cap boost — set by shuttle docking, decays each fire
	var/temp_cap_boost = 0
	/// MC_AVERAGE tracked cost of starlight phase (ms)
	var/cost_starlight = 0
	/// MC_AVERAGE tracked cost of batched indoor nightshift lamp refresh (ms)
	var/cost_nightshift = 0
	/// Peak starlight queue length
	var/peak_starlight = 0
	/// Peak indoor nightshift lamp queue length
	var/peak_nightshift = 0
	/// Progress index for incremental solar starlight color propagation (0 = idle)
	var/starlight_color_index = 0
	/// APCs processed by the most recent nightshift queue phase.
	var/nightshift_apcs_processed = 0
	/// Lamps processed by the most recent nightshift queue phase.
	var/nightshift_lights_processed = 0
	/// Average cascade ratio: corners queued per source processed
	var/avg_cascade_corners = 0
	/// Average cascade ratio: objects queued per corner processed
	var/avg_cascade_objects = 0
	/// Queue growth rate tracking: objects added to queue between fires
	var/objects_queue_growth = 0
	var/last_objects_queue_len = 0
	/// When TRUE, lighting_object/New() defers starlight to a batch (set during create_all_lighting_objects)
	var/init_in_progress = FALSE
	/// Queue of z-levels to initialize in the background (populated after main init)
	var/list/bg_queued_zlevels
	/// Z-level currently being background-initialized (0 = none)
	var/bg_current_zlevel = 0
	/// Current phase of background init: 0=atoms, 1=objects, 2=starlight, 3=done
	var/bg_phase = 0
	/// Cached turf list for Phase 1 (block() result for current z-level)
	var/list/bg_turfs
	/// Progress index through bg_turfs
	var/bg_turf_index = 0

/datum/controller/subsystem/lighting/stat_entry(msg)
	var/total_cost = cost_sources + cost_corners + cost_objects
	var/pct_s = total_cost > 0 ? round(cost_sources / total_cost * 100) : 0
	var/pct_c = total_cost > 0 ? round(cost_corners / total_cost * 100) : 0
	var/pct_o = total_cost > 0 ? round(cost_objects / total_cost * 100) : 0
	var/avg_cost_per = avg_sources_processed >= 0.5 ? round(cost_sources / avg_sources_processed, 0.01) : 0
	msg = "NS:[length(GLOB.nightshift_apc_queue)]/[length(GLOB.nightshift_light_queue)]/[SSnightshift.last_nightshift_apcs_touched]/[SSnightshift.last_nightshift_lights_queued]/[nightshift_apcs_processed]/[nightshift_lights_processed]|SL:[length(GLOB.lighting_starlight_queue)]|L:[length(GLOB.lighting_update_lights)]|C:[length(GLOB.lighting_update_corners)]|O:[length(GLOB.lighting_update_objects)]|Cap:[sources_cap]/[corners_cap]/[objects_cap]|NS:[round(cost_nightshift,0.1)]ms|SL:[round(cost_starlight,0.1)]ms|S:[round(cost_sources,0.1)]([pct_s]%)|C:[round(cost_corners,0.1)]([pct_c]%)|O:[round(cost_objects,0.1)]([pct_o]%)|Avg:[avg_cost_per]ms/src([round(avg_sources_processed)])|Cas:[round(avg_cascade_corners,0.1)]/[round(avg_cascade_objects,0.1)]|Gro:[round(objects_queue_growth)]|Pk:[peak_nightshift]/[peak_starlight]/[peak_sources]/[peak_corners]/[peak_objects]|Wst:[round(worst_fire_cost,0.1)]ms"
	if(bg_current_zlevel)
		msg += "|BG:Z[bg_current_zlevel]P[bg_phase]"
	else if(bg_queued_zlevels?.len)
		msg += "|BG:[bg_queued_zlevels.len]q"
	return ..()

/datum/controller/subsystem/lighting/Initialize(timeofday)
	if(!initialized)
		if (CONFIG_GET(flag/starlight))
			for(var/I in GLOB.sortedAreas)
				var/area/A = I
				if (A.dynamic_lighting == DYNAMIC_LIGHTING_IFSTARLIGHT)
					A.luminosity = 0

		create_all_lighting_objects()
		initialized = TRUE
		// All queued sources/corners/objects are batch-processed inside create_all_lighting_objects()
		// No need for fire() here — queues are already drained

	return ..()

/datum/controller/subsystem/lighting/fire(resumed, init_tick_checks)
	// A bulk operation (shuttle docking / transit generation) is deferring lighting work.
	// Skip this fire cycle — the originating proc will clear the flag and queue work for us.
	if(GLOB.lighting_defer_active)
		return
	MC_SPLIT_TICK_INIT(6)
	var/fire_start_timer = TICK_USAGE_REAL
	nightshift_apcs_processed = 0
	nightshift_lights_processed = 0
	// Track queue growth between fires
	if(!resumed && !init_tick_checks)
		objects_queue_growth = MC_AVERAGE(objects_queue_growth, GLOB.lighting_update_objects.len - last_objects_queue_len)
		last_objects_queue_len = GLOB.lighting_update_objects.len

	process_nightshift_queues(init_tick_checks, !resumed && !init_tick_checks)

	if(!init_tick_checks)
		MC_SPLIT_TICK

	// Phase -2: Solar starlight color propagation (from SSnightshift)
	// Processes GLOB.starlight incrementally instead of all-at-once in SSnightshift.fire().
	if(GLOB.starlight_color_dirty || starlight_color_index)
		var/sc_timer = TICK_USAGE_REAL
		var/sl_color = GLOB.current_starlight_color
		var/sl_power = GLOB.current_starlight_power
		if(GLOB.starlight_color_dirty)
			starlight_color_index = 1 // Start (or restart) from beginning
			GLOB.starlight_color_dirty = FALSE
		var/slen = length(GLOB.starlight)
		var/list/stale_refs
		while(starlight_color_index <= slen)
			var/turf/open/space/S = GLOB.starlight[starlight_color_index]
			starlight_color_index++
			if(QDELETED(S))
				LAZYADD(stale_refs, S)
				continue
			var/color_changed = !isnull(sl_color) && S.light_color != sl_color
			var/power_changed = !isnull(sl_power) && S.light_power != sl_power
			if(color_changed || power_changed)
				S.set_light(l_color = sl_color, l_power = sl_power)
			if(init_tick_checks)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				break
		if(starlight_color_index > slen)
			starlight_color_index = 0
		if(length(stale_refs))
			GLOB.starlight -= stale_refs
		if(!init_tick_checks)
			cost_starlight = MC_AVERAGE(cost_starlight, TICK_USAGE_TO_MS(sc_timer))

	// Phase -1: Deferred starlight (from shuttle docking / bulk turf changes)
	// update_starlight() calls set_light() which queues into lighting_update_lights,
	// so we process this BEFORE Phase 1 (sources) to drain them in the same tick.
	if(GLOB.lighting_starlight_queue.len)
		var/sl_timer = TICK_USAGE_REAL
		var/k = 0
		for(k in 1 to GLOB.lighting_starlight_queue.len)
			var/turf/open/space/S = GLOB.lighting_starlight_queue[k]
			if(!QDELETED(S) && istype(S))
				S.update_starlight()
			if(init_tick_checks)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				break
		if(k)
			GLOB.lighting_starlight_queue.Cut(1, min(k + 1, length(GLOB.lighting_starlight_queue) + 1))
		if(!init_tick_checks)
			cost_starlight = MC_AVERAGE(cost_starlight, TICK_USAGE_TO_MS(sl_timer))

	// Phase -0.5: Deferred shadow + blend recalc (from shuttle docking / bulk turf changes)
	// recalc_atom_opacity() may queue into lighting_update_lights (via reconsider_lights),
	// so we process this BEFORE Phase 1 (sources).
	if(GLOB.lighting_deferred_shadow_turfs.len)
		var/m = 0
		for(m in 1 to GLOB.lighting_deferred_shadow_turfs.len)
			var/turf/shadow_turf = GLOB.lighting_deferred_shadow_turfs[m]
			if(!QDELETED(shadow_turf))
				var/old_opaque = shadow_turf.has_opaque_atom
				shadow_turf.recalc_atom_opacity()
				if(shadow_turf.has_opaque_atom != old_opaque)
					shadow_turf.reconsider_lights()
				if(shadow_turf.lighting_object)
					GLOB.lighting_update_blends |= shadow_turf.lighting_object
					if(!shadow_turf.lighting_object.needs_update)
						shadow_turf.lighting_object.needs_update = TRUE
						GLOB.lighting_update_objects += shadow_turf.lighting_object
			if(init_tick_checks)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				break
		if(m)
			GLOB.lighting_deferred_shadow_turfs.Cut(1, min(m + 1, length(GLOB.lighting_deferred_shadow_turfs) + 1))

	if(!init_tick_checks)
		MC_SPLIT_TICK

	// Track peak queue lengths
	if(!resumed)
		var/nsq = GLOB.nightshift_apc_queue.len + GLOB.nightshift_light_queue.len
		var/ssl = GLOB.lighting_starlight_queue.len
		var/sl = GLOB.lighting_update_lights.len
		var/sc = GLOB.lighting_update_corners.len
		var/so = GLOB.lighting_update_objects.len
		if(nsq > peak_nightshift) peak_nightshift = nsq
		if(ssl > peak_starlight) peak_starlight = ssl
		if(sl > peak_sources) peak_sources = sl
		if(sc > peak_corners) peak_corners = sc
		if(so > peak_objects) peak_objects = so

	// Adaptive cap: adjust based on queue size and server load
	if(!resumed && !init_tick_checks && SStime_track?.initialized)
		var/queue_len = GLOB.lighting_update_lights.len
		if(queue_len <= LIGHTING_SOURCES_UNCAPPED_THRESHOLD)
			sources_cap = queue_len
		else
			var/dilation = SStime_track.time_dilation_avg_fast
			if(dilation > LIGHTING_DILATION_HIGH)
				sources_cap = LIGHTING_SOURCES_MIN_CAP
			else if(dilation > LIGHTING_DILATION_MEDIUM)
				sources_cap = max(LIGHTING_SOURCES_MIN_CAP, LIGHTING_SOURCES_BASE_CAP - LIGHTING_SOURCES_MEDIUM_REDUCTION)
			else
				sources_cap = LIGHTING_SOURCES_BASE_CAP
			// Backlog drain: if queue is much larger than cap, boost to prevent starvation
			// Hard ceiling prevents lag spikes from processing too many heavy sources in one fire
			if(queue_len > sources_cap * LIGHTING_BACKLOG_THRESHOLD_MULT)
				var/boost = min((queue_len - sources_cap) / LIGHTING_BACKLOG_DRAIN_DIVISOR, sources_cap)
				sources_cap = min(LIGHTING_SOURCES_HARD_CEILING, sources_cap + boost)
		// Temporary cap boost from shuttle docking — decays by 10 per fire
		if(temp_cap_boost > 0)
			sources_cap = min(LIGHTING_SOURCES_HARD_CEILING, sources_cap + temp_cap_boost)
			temp_cap_boost = max(0, temp_cap_boost - 10)

	// Phase 0: Area blend recalculations (batched from zone changes)
	var/j = 0
	for(j in 1 to GLOB.lighting_update_blends.len)
		var/atom/movable/lighting_object/blend_obj = GLOB.lighting_update_blends[j]
		if(!QDELETED(blend_obj))
			blend_obj.calculate_area_blend()
		if(init_tick_checks)
			CHECK_TICK
		else if(MC_TICK_CHECK)
			break
	if(j)
		GLOB.lighting_update_blends.Cut(1, min(j + 1, length(GLOB.lighting_update_blends) + 1))

	if(!init_tick_checks)
		MC_SPLIT_TICK

	// Phase 1: Light sources
	var/corners_before = GLOB.lighting_update_corners.len
	var/timer = TICK_USAGE_REAL
	var/i = 0
	var/phase_limit = init_tick_checks ? GLOB.lighting_update_lights.len : min(GLOB.lighting_update_lights.len, sources_cap)
	for (i in 1 to phase_limit)
		if (i > GLOB.lighting_update_lights.len)
			break
		var/datum/light_source/L = GLOB.lighting_update_lights[i]
		if (QDELETED(L))
			continue

		L.update_corners()

		L.needs_update = LIGHTING_NO_UPDATE

		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	var/sources_done = i
	if (i)
		GLOB.lighting_update_lights.Cut(1, min(i + 1, length(GLOB.lighting_update_lights) + 1))
		i = 0
	if(!init_tick_checks)
		cost_sources = MC_AVERAGE(cost_sources, TICK_USAGE_TO_MS(timer))
		avg_sources_processed = MC_AVERAGE(avg_sources_processed, sources_done)
		// Track cascade: how many NEW corners were queued by the sources we just processed
		if(sources_done > 0)
			avg_cascade_corners = MC_AVERAGE(avg_cascade_corners, (GLOB.lighting_update_corners.len - corners_before) / max(1, sources_done))

	if(!init_tick_checks)
		MC_SPLIT_TICK

	// Phase 2: Corners (adaptive cap proportional to sources processed)
	if(!init_tick_checks)
		corners_cap = clamp(max(LIGHTING_CORNERS_MIN_CAP, sources_done * LIGHTING_CORNERS_CAP_MULT), LIGHTING_CORNERS_MIN_CAP, LIGHTING_CORNERS_HARD_CEILING)
	var/objects_before = GLOB.lighting_update_objects.len
	timer = TICK_USAGE_REAL
	var/corners_limit = init_tick_checks ? GLOB.lighting_update_corners.len : min(GLOB.lighting_update_corners.len, corners_cap)
	for (i in 1 to corners_limit)
		if(i > GLOB.lighting_update_corners.len)
			break
		var/datum/lighting_corner/C = GLOB.lighting_update_corners[i]

		C.update_objects()
		C.needs_update = FALSE
		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	var/corners_done = i
	if (i)
		GLOB.lighting_update_corners.Cut(1, min(i + 1, length(GLOB.lighting_update_corners) + 1))
		i = 0
	if(!init_tick_checks)
		cost_corners = MC_AVERAGE(cost_corners, TICK_USAGE_TO_MS(timer))
		// Track cascade: how many NEW objects were queued by the corners we just processed
		if(corners_done > 0)
			avg_cascade_objects = MC_AVERAGE(avg_cascade_objects, (GLOB.lighting_update_objects.len - objects_before) / max(1, corners_done))

	if(!init_tick_checks)
		MC_SPLIT_TICK

	// Phase 3: Lighting objects (adaptive cap proportional to corners processed)
	// Pre-build z-level client bitmask — replaces 3 comparisons + length() per object with 1 list lookup
	var/list/clients_by_z = !init_tick_checks ? SSmobs.clients_by_zlevel : null
	var/list/z_has_clients
	if(clients_by_z)
		var/_cbz_len = length(clients_by_z)
		z_has_clients = new /list(_cbz_len)
		for(var/_zz in 1 to _cbz_len)
			z_has_clients[_zz] = !!length(clients_by_z[_zz])
	if(!init_tick_checks)
		objects_cap = clamp(max(LIGHTING_OBJECTS_MIN_CAP, corners_done * LIGHTING_OBJECTS_CAP_MULT), LIGHTING_OBJECTS_MIN_CAP, LIGHTING_OBJECTS_HARD_CEILING)
		// Proactive budget check: reduce cap if previous phases consumed most of the tick
		var/remaining_pct = 1 - (TICK_USAGE / Master.current_ticklimit)
		if(remaining_pct < 0.15)
			objects_cap = min(objects_cap, 50)
		else if(remaining_pct < 0.3)
			objects_cap = min(objects_cap, objects_cap / 2)
	timer = TICK_USAGE_REAL
	var/objects_limit = init_tick_checks ? GLOB.lighting_update_objects.len : min(GLOB.lighting_update_objects.len, objects_cap)
	var/skip_invisible_threshold = objects_limit * 0.7
	for (i in 1 to objects_limit)
		if(i > GLOB.lighting_update_objects.len)
			break
		var/atom/movable/lighting_object/O = GLOB.lighting_update_objects[i]

		if (QDELETED(O))
			continue

		if(!O.affected_turf)
			qdel(O, force = TRUE)
			continue

		var/obj_z = O.affected_turf.z
		var/is_visible = z_has_clients && obj_z <= length(z_has_clients) && z_has_clients[obj_z]
		// When budget is tight (past 70% of cap), defer invisible z-level objects to next fire
		if(!init_tick_checks && !is_visible && i > skip_invisible_threshold)
			GLOB.lighting_update_objects += O // re-queue for next fire (Cut will remove from current position)
			continue
		O.update(use_animate = is_visible)
		O.needs_update = FALSE
		if(init_tick_checks)
			CHECK_TICK
		else if (MC_TICK_CHECK)
			break
	if (i)
		GLOB.lighting_update_objects.Cut(1, min(i + 1, length(GLOB.lighting_update_objects) + 1))
	if(!init_tick_checks)
		cost_objects = MC_AVERAGE(cost_objects, TICK_USAGE_TO_MS(timer))
		last_objects_queue_len = GLOB.lighting_update_objects.len

	// Phase 4: Background z-level initialization
	// Gradually creates lighting infrastructure for deferred z-levels
	// Only runs when normal queues are mostly drained (won't starve active lighting)
	if(!init_tick_checks && (bg_queued_zlevels?.len || bg_current_zlevel))
		var/bg_pending = GLOB.lighting_update_lights.len + GLOB.lighting_update_corners.len + GLOB.lighting_update_objects.len
		if(bg_pending < LIGHTING_BG_INIT_PENDING_THRESHOLD)
			process_bg_zlevel_init()

	// Track worst single-fire total cost (real measurement, not MC_AVERAGE sum)
	if(!init_tick_checks)
		var/fire_total = TICK_USAGE_TO_MS(fire_start_timer)
		if(fire_total > worst_fire_cost)
			worst_fire_cost = fire_total

	// Dynamic wait: tick every frame when there's work, relax when idle
	if(!init_tick_checks)
		var/pending = GLOB.nightshift_apc_queue.len + GLOB.nightshift_light_queue.len + GLOB.lighting_deferred_shadow_turfs.len + GLOB.lighting_starlight_queue.len + GLOB.lighting_update_blends.len + GLOB.lighting_update_lights.len + GLOB.lighting_update_corners.len + GLOB.lighting_update_objects.len + (bg_queued_zlevels?.len ? 1 : 0) + (bg_current_zlevel ? 1 : 0) + (starlight_color_index ? 1 : 0)
		wait = pending > LIGHTING_IDLE_WAIT_THRESHOLD ? 1 : 2

/datum/controller/subsystem/lighting/proc/process_nightshift_queues(init_tick_checks = FALSE, track_peak = FALSE)
	// Phase -3: Batched indoor nightshift APC propagation.
	// Runs before lamp refresh so APC refreshes can enqueue lights and have them
	// processed in the same fire.
	// Phase -2.5 then drains the lamp queue before light sources.
	if(!(GLOB.nightshift_apc_queue.len || GLOB.nightshift_light_queue.len))
		return
	if(track_peak)
		var/ns_queue_len = GLOB.nightshift_apc_queue.len + GLOB.nightshift_light_queue.len
		if(ns_queue_len > peak_nightshift)
			peak_nightshift = ns_queue_len
	var/ns_timer = TICK_USAGE_REAL
	if(GLOB.nightshift_apc_queue.len)
		var/k = 0
		for(k in 1 to GLOB.nightshift_apc_queue.len)
			if(k > GLOB.nightshift_apc_queue.len) // Queue may shrink if CHECK_TICK yields and fire() re-enters
				break
			var/obj/machinery/power/apc/APC = GLOB.nightshift_apc_queue[k]
			if(!QDELETED(APC))
				SSnightshift.last_nightshift_lights_queued += APC.apply_queued_nightshift_refresh()
				nightshift_apcs_processed++
			if(init_tick_checks)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				break
		if(k)
			GLOB.nightshift_apc_queue.Cut(1, min(k + 1, length(GLOB.nightshift_apc_queue) + 1))
	if(GLOB.nightshift_light_queue.len)
		var/k = 0
		for(k in 1 to GLOB.nightshift_light_queue.len)
			if(k > GLOB.nightshift_light_queue.len) // Queue may shrink if CHECK_TICK yields and fire() re-enters
				break
			var/obj/machinery/light/L = GLOB.nightshift_light_queue[k]
			if(!QDELETED(L))
				L.nightshift_update_queued = FALSE
				L.update(FALSE, TRUE)
				nightshift_lights_processed++
			if(init_tick_checks)
				CHECK_TICK
			else if(MC_TICK_CHECK)
				break
		if(k)
			GLOB.nightshift_light_queue.Cut(1, min(k + 1, length(GLOB.nightshift_light_queue) + 1))
	if(!init_tick_checks)
		cost_nightshift = MC_AVERAGE(cost_nightshift, TICK_USAGE_TO_MS(ns_timer))

/datum/controller/subsystem/lighting/proc/admin_nightshift_refresh_pending()
	return GLOB.nightshift_apc_queue.len || GLOB.nightshift_light_queue.len || GLOB.lighting_update_blends.len || GLOB.lighting_update_lights.len || GLOB.lighting_update_corners.len || GLOB.lighting_update_objects.len

/datum/controller/subsystem/lighting/proc/process_admin_nightshift_refresh_now(max_passes = 20)
	for(var/pass in 1 to max_passes)
		if(!admin_nightshift_refresh_pending())
			return

		process_nightshift_queues(TRUE)

		if(GLOB.lighting_update_blends.len)
			var/list/pending_blends = GLOB.lighting_update_blends.Copy()
			GLOB.lighting_update_blends.Cut()
			for(var/atom/movable/lighting_object/blend_obj as anything in pending_blends)
				if(!QDELETED(blend_obj))
					blend_obj.calculate_area_blend()

		if(GLOB.lighting_update_lights.len)
			var/list/pending_sources = GLOB.lighting_update_lights.Copy()
			GLOB.lighting_update_lights.Cut()
			for(var/datum/light_source/light_source as anything in pending_sources)
				if(QDELETED(light_source))
					continue
				light_source.update_corners()
				light_source.needs_update = LIGHTING_NO_UPDATE

		if(GLOB.lighting_update_corners.len)
			var/list/pending_corners = GLOB.lighting_update_corners.Copy()
			GLOB.lighting_update_corners.Cut()
			for(var/datum/lighting_corner/corner as anything in pending_corners)
				if(QDELETED(corner))
					continue
				corner.update_objects()
				corner.needs_update = FALSE

		if(GLOB.lighting_update_objects.len)
			var/list/pending_objects = GLOB.lighting_update_objects.Copy()
			GLOB.lighting_update_objects.Cut()
			for(var/atom/movable/lighting_object/lighting_object as anything in pending_objects)
				if(QDELETED(lighting_object))
					continue
				lighting_object.update(use_animate = FALSE)
				lighting_object.needs_update = FALSE

/datum/controller/subsystem/lighting/proc/process_bg_zlevel_init()
	// Pick a z-level to work on
	if(!bg_current_zlevel)
		if(!bg_queued_zlevels?.len)
			return
		bg_current_zlevel = bg_queued_zlevels[1]
		bg_queued_zlevels.Cut(1, 2)
		bg_phase = 0
		bg_turfs = null
		bg_turf_index = 0
		var/datum/space_level/level = SSmapping.get_level(bg_current_zlevel)
		if(level.lighting_initialized)
			bg_current_zlevel = 0
			return
		log_world("## LIGHTING: Background init starting for z-level [bg_current_zlevel] ([level.name])")

	var/z = bg_current_zlevel

	// Phase 0: Create lighting objects FIRST — corners must be active before sources process
	if(bg_phase == 0)
		if(!bg_turfs)
			bg_turfs = block(locate(1, 1, z), locate(world.maxx, world.maxy, z))
			bg_turf_index = 1
		init_in_progress = TRUE
		while(bg_turf_index <= bg_turfs.len)
			var/turf/T = bg_turfs[bg_turf_index++]
			var/area/A = T.loc
			if(!IS_DYNAMIC_LIGHTING(A) || !IS_DYNAMIC_LIGHTING(T) || T.lighting_object)
				continue
			new /atom/movable/lighting_object(T)
			if(T.lighting_corners_initialised)
				if(T.lc_topright) T.lc_topright.active = TRUE
				if(T.lc_bottomright) T.lc_bottomright.active = TRUE
				if(T.lc_bottomleft) T.lc_bottomleft.active = TRUE
				if(T.lc_topleft) T.lc_topleft.active = TRUE
			if(MC_TICK_CHECK)
				init_in_progress = FALSE
				return
		init_in_progress = FALSE
		bg_turfs = null
		var/datum/space_level/level = SSmapping.get_level(z)
		level.lighting_initialized = TRUE
		bg_phase = 1
		if(MC_TICK_CHECK)
			return

	// Phase 1: Create deferred light sources — objects exist now, corners are active
	if(bg_phase == 1)
		var/list/remaining = list()
		for(var/atom/A as anything in GLOB.lighting_deferred_atoms)
			if(QDELETED(A))
				continue
			var/turf/T = get_turf(A)
			if(T?.z == z)
				A.update_light()
			else
				remaining += A
			if(MC_TICK_CHECK)
				GLOB.lighting_deferred_atoms = remaining + GLOB.lighting_deferred_atoms.Copy(GLOB.lighting_deferred_atoms.Find(A) + 1)
				return
		GLOB.lighting_deferred_atoms = remaining
		bg_phase = 2
		if(MC_TICK_CHECK)
			return

	// Phase 2: Queue starlight
	if(bg_phase == 2)
		var/list/remaining_starlight = list()
		for(var/turf/open/space/S in GLOB.lighting_deferred_starlight)
			if(S.z == z)
				GLOB.lighting_starlight_queue |= S
			else
				remaining_starlight[S] = TRUE
			if(MC_TICK_CHECK)
				GLOB.lighting_deferred_starlight = remaining_starlight + GLOB.lighting_deferred_starlight.Copy(GLOB.lighting_deferred_starlight.Find(S) + 1)
				return
		GLOB.lighting_deferred_starlight = remaining_starlight
		bg_phase = 3

	// Phase 3: Done
	if(bg_phase == 3)
		log_world("## LIGHTING: Background init complete for z-level [z] ([SSmapping.get_level(z).name])")
		bg_current_zlevel = 0

/datum/controller/subsystem/lighting/Recover()
	initialized = SSlighting.initialized
	..()
