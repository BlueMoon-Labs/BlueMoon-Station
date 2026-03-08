// GC failure viewing datums, responsible for storing individual GC failure info
// and showing them to admins on demand.
//
// Modeled after error_viewer.dm. There are 3 different types used here:
//
// - gc_failure_cache keeps track of all failure sources, as well as all
//   individually logged failures. Only one instance should ever exist:

GLOBAL_DATUM_INIT(gc_failure_cache, /datum/gc_failure_viewer/gc_failure_cache, new)

// - gc_failure_source datums exist for each type path that generates a GC failure,
//   and keep track of all failures for that type.
//
// - gc_failure_entry datums exist for each logged GC failure, and keep track of
//   all relevant info about that failure.

// Common vars and procs are kept at the gc_failure_viewer level
/datum/gc_failure_viewer
	var/name = ""

/datum/gc_failure_viewer/proc/browse_to(client/user, html)
	var/datum/browser/browser = new(user.mob, "gc_failure_viewer", null, 900, 600)
	browser.set_content(html)
	browser.add_head_content({"
	<style>
	.gc_failure
	{
		background-color: #171717;
		border: solid 1px #202020;
		font-family: "Courier New";
		padding-left: 10px;
		color: #CCCCCC;
	}
	.gc_failure_line
	{
		margin-bottom: 10px;
		display: inline-block;
	}
	details
	{
		margin: 4px 0;
		border: 1px solid #333;
		border-radius: 4px;
		padding: 4px 8px;
		background-color: #1a1a1a;
	}
	summary
	{
		cursor: pointer;
		color: #8888FF;
		padding: 4px 0;
	}
	summary:hover
	{
		color: #AAAAFF;
	}
	.gc_stats
	{
		background-color: #1a1a1a;
		border: 1px solid #333;
		padding: 6px 10px;
		margin-bottom: 8px;
		color: #AAAAAA;
		font-family: "Courier New";
	}
	</style>
	"})
	browser.open()

/datum/gc_failure_viewer/proc/build_header(datum/gc_failure_viewer/back_to, linear)
	. = ""

	if (istype(back_to))
		. += back_to.make_link("<b>&lt;&lt;&lt;</b>", null, linear)

	. += "[make_link("Refresh")]<br><br>"

/datum/gc_failure_viewer/proc/show_to(user, datum/gc_failure_viewer/back_to, linear)
	return

/datum/gc_failure_viewer/proc/make_link(linktext, datum/gc_failure_viewer/back_to, linear)
	var/back_to_param = ""
	if (!linktext)
		linktext = name

	if (istype(back_to))
		back_to_param = ";viewgcfailure_backto=[REF(back_to)]"

	if (linear)
		back_to_param += ";viewgcfailure_linear=1"

	return "<a href='?_src_=holder;[HrefToken()];viewgcfailure=[REF(src)][back_to_param]'>[linktext]</a>"

/datum/gc_failure_viewer/gc_failure_cache
	var/list/failures = list()
	var/list/failure_sources = list()
	var/total_failures = 0

/datum/gc_failure_viewer/gc_failure_cache/show_to(user, datum/gc_failure_viewer/back_to, linear)
	var/html = build_header()
	html += "<b>[total_failures]</b> GC failures<br><br>"
	if (!linear)
		html += "organized | [make_link("linear", null, 1)]<hr>"
		for (var/type_key in failure_sources)
			var/datum/gc_failure_viewer/gc_failure_source/source = failure_sources[type_key]
			html += "[source.make_link(null, src)]<br>"

	else
		html += "[make_link("organized", null)] | linear<hr>"
		for (var/datum/gc_failure_viewer/gc_failure_entry/entry in failures)
			html += "[entry.make_link(null, src, 1)]<br>"

	browse_to(user, html)

/datum/gc_failure_viewer/gc_failure_cache/proc/log_gc_failure(datum/D, type_path, ref_id, queued_time, qdel_hint = null)
	total_failures++
	var/type_key = "[type_path]"
	var/datum/gc_failure_viewer/gc_failure_source/source = failure_sources[type_key]
	if (!source)
		source = new(type_path)
		failure_sources[type_key] = source

	var/datum/gc_failure_viewer/gc_failure_entry/entry = new(D, type_path, ref_id, queued_time, qdel_hint)
	entry.failure_source = source
	failures += entry
	source.failures += entry
	// In TESTING mode, auto-launch world scan while D is still guaranteed alive
	#ifdef TESTING
	INVOKE_ASYNC(entry, TYPE_PROC_REF(/datum/gc_failure_viewer/gc_failure_entry, trigger_world_scan), null, D)
	#endif

/datum/gc_failure_viewer/gc_failure_source
	var/list/failures = list()
	var/type_path

/datum/gc_failure_viewer/gc_failure_source/New(path)
	type_path = path
	name = "<b>[path]</b>"

/datum/gc_failure_viewer/gc_failure_source/make_link(linktext, datum/gc_failure_viewer/back_to, linear)
	if (!linktext)
		linktext = "<b>[type_path]</b> ([length(failures)] failure[length(failures) != 1 ? "s" : ""])"
	return ..(linktext, back_to, linear)

/datum/gc_failure_viewer/gc_failure_source/show_to(user, datum/gc_failure_viewer/back_to, linear)
	if (!istype(back_to))
		back_to = GLOB.gc_failure_cache

	var/html = build_header(back_to)
	html += "<b>[type_path]</b> - [length(failures)] failure[length(failures) != 1 ? "s" : ""]<hr>"

	// Aggregate qdel_item stats for this type
	var/datum/qdel_item/qi = SSgarbage.items[text2path("[type_path]")]
	if (qi)
		html += "<div class='gc_stats'>"
		html += "<b>Статистика типа:</b> qdels: [qi.qdels], фейлы: [qi.failures], hard dels: [qi.hard_deletes]<br>"
		html += "Destroy() время: [qi.destroy_time]ms"
		if (qi.hard_deletes)
			html += ", hard del время: [qi.hard_delete_time]ms (макс: [qi.hard_delete_max]ms)"
		if (qi.slept_destroy)
			html += ", слипов: [qi.slept_destroy]"
		if (qi.no_respect_force)
			html += ", игнорировал force: [qi.no_respect_force]"
		if (qi.no_hint)
			html += ", без hint: [qi.no_hint]"
		if (qi.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			html += " <b style='color:#FF4444'>SUSPENDED</b>"
		html += "</div>"

	for (var/datum/gc_failure_viewer/gc_failure_entry/entry in failures)
		html += "[entry.make_link(null, src)]<br>"

	browse_to(user, html)

// --- gc_failure_entry: individual GC failure record ---

/datum/gc_failure_viewer/gc_failure_entry
	var/datum/gc_failure_viewer/gc_failure_source/failure_source
	var/type_path
	var/ref_id
	var/obj_name
	var/failure_time
	var/queued_time
	var/extra_info
	var/datum_ref
	// --- Extended diagnostic data (always collected) ---
	/// The QDEL_HINT_* value returned by Destroy()
	var/qdel_hint
	/// String: types of attached components
	var/components_info
	/// String: registered signal summary
	var/signals_info
	/// Number of active timers at failure time
	var/active_timers_count = 0
	/// String: timer callback summaries
	var/timers_info
	/// String: status traits list
	var/traits_info
	/// Number of active cooldowns
	var/cooldowns_count = 0
	/// String: atom contents summary
	var/contents_info
	/// String: loc chain (loc -> loc -> ...)
	var/loc_chain_info
	/// String: aggregate qdel_item statistics for this type
	var/qdel_stats_info
	/// Found references: locations in GLOB where references to the failed datum were found
	var/list/found_references
	/// Whether the full world scan has been performed for this entry
	var/world_scan_done = FALSE
	/// Whether the world scan is currently running
	var/world_scan_in_progress = FALSE
	/// Results from the world scan, added to found_references when done
	var/world_scan_atom_count = 0
#ifdef TESTING
	/// Full variable dump as list of "varname = value" strings
	var/list/full_var_dump
	/// Signal handler details: signal -> proc mappings
	var/list/signal_handler_details
	/// Component details: type + vars per component
	var/list/component_details
	/// Timer details: full info per timer
	var/list/timer_details
#endif

/datum/gc_failure_viewer/gc_failure_entry/New(datum/D, path, refid, queuetime, hint)
	type_path = path
	ref_id = refid
	failure_time = world.time
	queued_time = queuetime
	qdel_hint = hint
	if (D)
		if (isatom(D))
			var/atom/A = D
			obj_name = A.name
		datum_ref = REF(D)
		extra_info = build_extra_info(D)
		build_extended_info(D)
		#ifdef TESTING
		build_reference_info(D)
		build_testing_info(D)
		#endif
	name = "<b>\[[TIME_STAMP("hh:mm:ss", FALSE)]]</b> GC failure: <b>[type_path]</b>[obj_name ? " \"[html_encode(obj_name)]\"" : ""] ([ref_id])"

/datum/gc_failure_viewer/gc_failure_entry/proc/build_extra_info(datum/D)
	var/list/info = list()

	if (istype(D, /atom/movable/screen))
		var/atom/movable/screen/S = D
		if (S.screen_loc)
			info += "screen_loc: [S.screen_loc]"
		if (S.assigned_map)
			info += "map: [S.assigned_map]"

	if (isatom(D))
		var/atom/A = D
		if (A.loc)
			var/loc_text = "[A.loc.type]"
			if (isatom(A.loc))
				var/atom/loc_atom = A.loc
				if (loc_atom.name)
					loc_text += " \"[loc_atom.name]\""
			info += "loc: [loc_text]"
		else
			info += "loc: null"
		if (isturf(A) || isturf(A.loc))
			info += "coords: [A.x],[A.y],[A.z]"

	if (ismob(D))
		var/mob/M = D
		if (M.ckey)
			info += "ckey: [M.ckey]"
		else if (M.key)
			info += "key: [M.key]"

	if (!length(info))
		return null
	return info.Join(" | ")

/// Production-safe extended data collection. Only reads lazy lists and capped iterations.
/datum/gc_failure_viewer/gc_failure_entry/proc/build_extended_info(datum/D)
	// Components attached to this datum
	if (length(D.datum_components))
		var/list/comp_types = list()
		for (var/comp_type in D.datum_components)
			if (comp_type == /datum/component)
				// Skip the aggregate key that holds the flat list of all components
				var/all_comps = D.datum_components[comp_type]
				if (islist(all_comps))
					continue
			var/comp_val = D.datum_components[comp_type]
			if (islist(comp_val))
				comp_types += "[comp_type] (x[length(comp_val)])"
			else
				comp_types += "[comp_type]"
		if (length(comp_types))
			components_info = comp_types.Join(", ")

	// Signals registered ON this datum (listeners)
	if (length(D.comp_lookup))
		var/list/sig_names = list()
		var/sig_count = 0
		for (var/sig in D.comp_lookup)
			sig_count++
			if (sig_count <= 10)
				sig_names += "[sig]"
		if (sig_count > 10)
			sig_names += "... (+[sig_count - 10] ещё)"
		signals_info = sig_names.Join(", ")

	// Active timers targeting this datum
	if (length(D.active_timers))
		active_timers_count = length(D.active_timers)
		var/list/timer_summaries = list()
		var/timer_idx = 0
		for (var/datum/timedevent/timer as anything in D.active_timers)
			timer_idx++
			if (timer_idx > 5)
				timer_summaries += "... (+[active_timers_count - 5] ещё)"
				break
			if (timer.callBack)
				var/obj_type = timer.callBack.object ? "[timer.callBack.object.type]" : "GLOBAL"
				timer_summaries += "[obj_type]->[timer.callBack.delegate] (wait:[timer.wait])"
			else
				timer_summaries += "(null callback)"
		timers_info = timer_summaries.Join("; ")

	// Status traits
	if (length(D.status_traits))
		var/list/trait_names = list()
		for (var/trait in D.status_traits)
			trait_names += "[trait]"
		traits_info = trait_names.Join(", ")

	// Cooldowns count
	if (length(D.cooldowns))
		cooldowns_count = length(D.cooldowns)

	// Atom-specific data
	if (isatom(D))
		var/atom/A = D
		// Contents summary
		if (length(A.contents))
			var/list/content_types = list()
			var/content_count = length(A.contents)
			var/shown = 0
			for (var/atom/child as anything in A.contents)
				shown++
				if (shown > 5)
					content_types += "... (+[content_count - 5] ещё)"
					break
				content_types += "[child.type][child.name ? " \"[child.name]\"" : ""]"
			contents_info = "[content_count] объектов: [content_types.Join(", ")]"

		// Loc chain (up to 5 levels)
		var/list/loc_parts = list()
		var/atom/current_loc = A.loc
		var/depth = 0
		while (current_loc && depth < 5)
			loc_parts += "[current_loc.type][current_loc.name ? " \"[current_loc.name]\"" : ""]"
			current_loc = current_loc.loc
			depth++
		if (length(loc_parts))
			loc_chain_info = loc_parts.Join(" -> ")

	// Aggregate qdel statistics for this type
	var/datum/qdel_item/qi = SSgarbage.items[D.type]
	if (qi)
		var/list/stats = list("qdels: [qi.qdels]", "фейлы: [qi.failures]", "hard dels: [qi.hard_deletes]", "destroy_time: [qi.destroy_time]ms")
		if (qi.hard_deletes)
			stats += "hard_del_time: [qi.hard_delete_time]ms (макс: [qi.hard_delete_max]ms)"
		if (qi.slept_destroy)
			stats += "слипов: [qi.slept_destroy]"
		if (qi.no_respect_force)
			stats += "игнорировал force: [qi.no_respect_force]"
		if (qi.no_hint)
			stats += "без hint: [qi.no_hint]"
		if (qi.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)
			stats += "SUSPENDED"
		qdel_stats_info = stats.Join(", ")

	// Reference scanning is too expensive for production hot path (scans all GLOB vars,
	// all subsystems, neighbor back-refs). Moved to TESTING auto-collect and on-demand button.

#ifdef TESTING
/// TESTING-only deep data collection. Full var dump, signal details, component details, timer details.
/datum/gc_failure_viewer/gc_failure_entry/proc/build_testing_info(datum/D)
	// Full variable dump
	full_var_dump = list()
	for (var/varname in D.vars)
		if (varname == "vars")
			continue
		var/value = D.vars[varname]
		var/value_text
		if (isnull(value))
			value_text = "null"
		else if (islist(value))
			var/list/L = value
			value_text = "/list (len=[length(L)])"
		else if (istype(value, /datum))
			var/datum/datum_val = value
			value_text = "[datum_val.type] [REF(datum_val)]"
		else
			value_text = "[value]"
		full_var_dump += "[varname] = [value_text]"

	// Detailed signal handler info from comp_lookup
	if (length(D.comp_lookup))
		signal_handler_details = list()
		for (var/sig in D.comp_lookup)
			var/registrees = D.comp_lookup[sig]
			var/list/handler_info = list()
			if (islist(registrees))
				for (var/datum/component/comp in registrees)
					handler_info += "[comp.type]"
			else if (istype(registrees, /datum/component))
				var/datum/component/comp = registrees
				handler_info += "[comp.type]"
			if (length(handler_info))
				signal_handler_details += "[sig]: [handler_info.Join(", ")]"

	// Detailed component info with their vars
	if (length(D.datum_components))
		component_details = list()
		for (var/comp_type in D.datum_components)
			if (comp_type == /datum/component)
				continue
			var/comp_val = D.datum_components[comp_type]
			if (islist(comp_val))
				for (var/datum/component/comp in comp_val)
					component_details += build_component_detail(comp)
			else if (istype(comp_val, /datum/component))
				component_details += build_component_detail(comp_val)

	// Detailed timer info
	if (length(D.active_timers))
		timer_details = list()
		for (var/datum/timedevent/timer as anything in D.active_timers)
			var/list/parts = list("id:[timer.id]", "wait:[timer.wait]", "timeToRun:[timer.timeToRun]")
			if (timer.callBack)
				var/obj_text = timer.callBack.object ? "[timer.callBack.object.type]([REF(timer.callBack.object)])" : "GLOBAL"
				parts += "callback: [obj_text]->[timer.callBack.delegate]"
			if (timer.source)
				parts += "source: [timer.source]"
			timer_details += parts.Join(", ")

/// Build a detail string for a single component, including its non-null vars.
/datum/gc_failure_viewer/gc_failure_entry/proc/build_component_detail(datum/component/comp)
	var/list/lines = list("[comp.type]")
	for (var/varname in comp.vars)
		if (varname == "vars" || varname == "parent" || varname == "type")
			continue
		var/value = comp.vars[varname]
		if (isnull(value))
			continue
		var/value_text
		if (istype(value, /datum))
			var/datum/datum_val = value
			value_text = "[datum_val.type] [REF(datum_val)]"
		else if (islist(value))
			var/list/L = value
			value_text = "/list (len=[length(L)])"
		else
			value_text = "[value]"
		lines += "  [varname] = [value_text]"
	return lines.Join(" | ")
#endif

/// Targeted reference search. Scans GLOB vars and reverse-checks neighbors for back-references.
/// Much faster than full find_references() — milliseconds instead of minutes. Safe for production.
/datum/gc_failure_viewer/gc_failure_entry/proc/build_reference_info(datum/D)
	found_references = list()
	// 1. Scan all GLOB vars (includes all global lists like mob_list, machines, etc.)
	for (var/varname in GLOB.vars)
		if (varname == "vars")
			continue
		var/value = GLOB.vars[varname]
		if (value == D)
			found_references += "GLOB.[varname] = [type_path]"
			continue
		if (islist(value))
			scan_list_for_ref(D, value, "GLOB.[varname]")

	// 2. Scan all subsystem controllers (SSair, SSmachines, etc.)
	if (Master?.subsystems)
		for (var/datum/controller/subsystem/SS in Master.subsystems)
			for (var/ssvar in SS.vars)
				if (ssvar == "vars" || ssvar == "vis_locs")
					continue
				var/ssval = SS.vars[ssvar]
				if (ssval == D)
					found_references += "[SS.type].[ssvar] = [type_path]"
					continue
				if (islist(ssval))
					scan_list_for_ref(D, ssval, "[SS.type].[ssvar]")

	// 3. Reverse neighbor scan: for each datum that D references,
	//    check if that datum holds a reference BACK to D.
	//    Catches circular references (A->B, B->A where B.Destroy() didn't clean up).
	for (var/varname in D.vars)
		if (varname == "vars" || varname == "vis_locs")
			continue
		var/value = D.vars[varname]
		if (isnull(value))
			continue
		if (istype(value, /datum))
			var/datum/neighbor = value
			if (neighbor == D) // self-reference, skip
				continue
			check_neighbor_for_backref(D, neighbor, "self.[varname]")
		else if (islist(value))
			var/list/L = value
			for (var/datum/neighbor in L)
				if (neighbor == D)
					continue
				check_neighbor_for_backref(D, neighbor, "self.[varname]")

	// 4. Scan SSgarbage queues — maybe queued multiple times?
	for (var/queue_idx in 1 to length(SSgarbage.queues))
		var/list/queue = SSgarbage.queues[queue_idx]
		var/found_count = 0
		for (var/list/entry in queue)
			if (length(entry) >= 2)
				var/datum/queued = locate(entry[2])
				if (queued == D)
					found_count++
		if (found_count > 1)
			found_references += "SSgarbage.queues\[[queue_idx]\]: найден [found_count] раз (дублирование в очереди!)"

/// Check if a neighbor datum holds a back-reference to the target.
/// context_path describes how we reached this neighbor from the failed datum.
/datum/gc_failure_viewer/gc_failure_entry/proc/check_neighbor_for_backref(datum/target, datum/neighbor, context_path)
	for (var/nvar in neighbor.vars)
		if (nvar == "vars" || nvar == "vis_locs")
			continue
		var/nval = neighbor.vars[nvar]
		if (nval == target)
			found_references += "[neighbor.type]([REF(neighbor)]).[nvar] -> через [context_path]"
			continue
		if (islist(nval))
			var/list/nlist = nval
			var/list_idx = 0
			for (var/item in nlist)
				list_idx++
				if (item == target)
					found_references += "[neighbor.type]([REF(neighbor)]).[nvar]\[[list_idx]\] -> через [context_path]"
					break // one hit per list is enough

/// Recursively scan a list for references to the target datum. Max depth 3 to stay fast.
/datum/gc_failure_viewer/gc_failure_entry/proc/scan_list_for_ref(datum/target, list/L, path, depth = 0)
	if (depth > 3 || !islist(L) || isnull(target))
		return
	var/idx = 0
	for (var/entry in L)
		idx++
		if (entry == target)
			found_references += "[path]\[[idx]\] = [type_path]"
			continue
		// Check associative values
		if (!isnum(entry) && IS_NORMAL_LIST(L))
			var/assoc_val = L[entry]
			if (assoc_val == target)
				found_references += "[path]\[[entry]\] = [type_path]"
				continue
			if (islist(assoc_val))
				scan_list_for_ref(target, assoc_val, "[path]\[[entry]\]", depth + 1)
		if (islist(entry))
			scan_list_for_ref(target, entry, "[path]\[[idx]\]", depth + 1)

/// Full world scan for references to the GC-failed datum.
/// Scans all atoms in world and (in TESTING) all datums. Uses CHECK_TICK to yield.
/// Can be called automatically (D passed directly) or on-demand via button (D = null, located by ref).
/// user can be null for automatic calls (no chat feedback).
/datum/gc_failure_viewer/gc_failure_entry/proc/trigger_world_scan(client/user, datum/D)
	if (world_scan_done || world_scan_in_progress)
		return
	// If D not passed directly, try to locate by saved ref (on-demand button click)
	if (!D)
		if (!datum_ref)
			if (user)
				to_chat(user, span_warning("Нет ссылки на объект для сканирования."))
			return
		D = locate(datum_ref)
		if (!D || D.type != text2path(type_path))
			if (user)
				to_chat(user, span_warning("Объект больше не существует, сканирование невозможно."))
			world_scan_done = TRUE
			return
	world_scan_in_progress = TRUE
	if (user)
		to_chat(user, span_boldnotice("Запуск полного сканирования мира... Это может занять 10-60 секунд."))
	// Scan ALL atoms (objs, turfs, mobs, areas).
	// Note: for(var/datum/thing in world) only iterates world.contents (mobs).
	// for(var/atom/thing) iterates every atom that exists — correct for a full scan.
	var/scan_count = 0
	for (var/atom/thing)
		if (isnull(D))
			break // D was hard-deleted during scan, stop
		if (thing == D)
			continue
		scan_count++
		for (var/tvar in thing.vars)
			if (tvar == "vars" || tvar == "vis_locs")
				continue
			var/tval = thing.vars[tvar]
			if (tval == D)
				found_references += "WORLD: [thing.type]([REF(thing)]).[tvar]"
				continue
			if (islist(tval))
				scan_list_for_ref(D, tval, "WORLD: [thing.type]([REF(thing)]).[tvar]", 1)
		CHECK_TICK
#ifdef TESTING
	// Also scan pure datums (not atoms) — only in TESTING
	for (var/datum/thing)
		if (isnull(D))
			break // D was hard-deleted during scan, stop
		if (thing == D)
			continue
		if (isatom(thing))
			continue // already covered by the world loop above
		scan_count++
		for (var/tvar in thing.vars)
			if (tvar == "vars" || tvar == "vis_locs")
				continue
			var/tval = thing.vars[tvar]
			if (tval == D)
				found_references += "DATUM: [thing.type]([REF(thing)]).[tvar]"
				continue
			if (islist(tval))
				scan_list_for_ref(D, tval, "DATUM: [thing.type]([REF(thing)]).[tvar]", 1)
		CHECK_TICK
#endif
	world_scan_atom_count = scan_count
	world_scan_in_progress = FALSE
	world_scan_done = TRUE
	if (user)
		to_chat(user, span_boldnotice("Сканирование завершено. Проверено [scan_count] объектов. Найдено ссылок: [length(found_references)]."))
		// Auto-refresh the view
		show_to(user)

/// Convert the numeric qdel hint to a human-readable Russian string.
/datum/gc_failure_viewer/gc_failure_entry/proc/qdel_hint_to_text()
	switch (qdel_hint)
		if (QDEL_HINT_QUEUE)
			return "QDEL_HINT_QUEUE (стандартная очередь)"
		if (QDEL_HINT_LETMELIVE)
			return "QDEL_HINT_LETMELIVE (просил оставить)"
		if (QDEL_HINT_IWILLGC)
			return "QDEL_HINT_IWILLGC (сам соберётся)"
		if (QDEL_HINT_HARDDEL)
			return "QDEL_HINT_HARDDEL (жёсткое удаление)"
		if (QDEL_HINT_HARDDEL_NOW)
			return "QDEL_HINT_HARDDEL_NOW (немедленное удаление)"
		#ifdef REFERENCE_TRACKING
		if (QDEL_HINT_FINDREFERENCE)
			return "QDEL_HINT_FINDREFERENCE (поиск ссылок)"
		if (QDEL_HINT_IFFAIL_FINDREFERENCE)
			return "QDEL_HINT_IFFAIL_FINDREFERENCE (поиск при фейле)"
		#endif
	if (isnull(qdel_hint))
		return "неизвестно (null)"
	return "неизвестный ([qdel_hint])"

/datum/gc_failure_viewer/gc_failure_entry/show_to(user, datum/gc_failure_viewer/back_to, linear)
	if (!istype(back_to))
		back_to = failure_source

	var/html = build_header(back_to, linear)

	// Core info section
	html += "<div class='gc_failure'>"
	html += "<span class='gc_failure_line'><b>Тип:</b> [type_path]</span><br>"
	html += "<span class='gc_failure_line'><b>Ref:</b> [ref_id]</span><br>"
	if (obj_name)
		html += "<span class='gc_failure_line'><b>Имя:</b> [html_encode(obj_name)]</span><br>"
	if (extra_info)
		html += "<span class='gc_failure_line'><b>Расположение:</b> [html_encode(extra_info)]</span><br>"
	html += "<span class='gc_failure_line'><b>Время фейла:</b> [DisplayTimeText(failure_time)] от начала раунда</span><br>"
	if (queued_time)
		html += "<span class='gc_failure_line'><b>В очереди GC:</b> ~[DisplayTimeText(failure_time - queued_time)]</span><br>"
	html += "<span class='gc_failure_line'><b>QDEL Hint:</b> [qdel_hint_to_text()]</span><br>"
	html += "</div>"

	// Components
	if (components_info)
		html += "<details><summary><b>Компоненты</b></summary>"
		html += "<div class='gc_failure'>[html_encode(components_info)]</div>"
		html += "</details>"

	// Signals
	if (signals_info)
		html += "<details><summary><b>Зарегистрированные сигналы</b></summary>"
		html += "<div class='gc_failure'>[html_encode(signals_info)]</div>"
		html += "</details>"

	// Timers
	if (timers_info)
		html += "<details><summary><b>Активные таймеры ([active_timers_count])</b></summary>"
		html += "<div class='gc_failure'>[html_encode(timers_info)]</div>"
		html += "</details>"

	// Traits
	if (traits_info)
		html += "<details><summary><b>Трейты</b></summary>"
		html += "<div class='gc_failure'>[html_encode(traits_info)]</div>"
		html += "</details>"

	// Cooldowns
	if (cooldowns_count)
		html += "<span class='gc_failure_line'><b>Активные кулдауны:</b> [cooldowns_count]</span><br>"

	// Contents (atoms only)
	if (contents_info)
		html += "<details><summary><b>Содержимое</b></summary>"
		html += "<div class='gc_failure'>[html_encode(contents_info)]</div>"
		html += "</details>"

	// Loc chain (atoms only)
	if (loc_chain_info)
		html += "<details><summary><b>Цепочка loc</b></summary>"
		html += "<div class='gc_failure'>[html_encode(loc_chain_info)]</div>"
		html += "</details>"

	// Aggregate qdel stats
	if (qdel_stats_info)
		html += "<details><summary><b>Статистика типа (qdel_item)</b></summary>"
		html += "<div class='gc_failure'>[html_encode(qdel_stats_info)]</div>"
		html += "</details>"

	// Found references — on-demand in production, auto-collected in TESTING
	if (length(found_references))
		html += "<details open><summary><b style='color:#FF6666'>Найденные ссылки ([length(found_references)])</b></summary>"
		html += "<div class='gc_failure'>"
		for (var/line in found_references)
			html += "[html_encode(line)]<br>"
		html += "</div></details>"
	else if (islist(found_references))
		html += "<span class='gc_failure_line'><b>Найденные ссылки:</b> не найдено быстрым сканированием (GLOB, подсистемы, соседи)</span><br>"
	else
		html += "<br><a href='?_src_=holder;[HrefToken()];viewgcfailure_refscan=[REF(src)]' style='background:#333;color:#88AAFF;padding:4px 12px;border:1px solid #555;border-radius:4px;text-decoration:none;font-family:Courier New'>"
		html += "Сканировать ссылки (GLOB, подсистемы, соседи) — может вызвать лаг!</a><br>"

	// World scan button / status
	if (world_scan_done)
		html += "<span class='gc_failure_line' style='color:#88FF88'><b>Полное сканирование мира:</b> проверено [world_scan_atom_count] объектов</span><br>"
	else if (world_scan_in_progress)
		html += "<span class='gc_failure_line' style='color:#FFFF44'><b>Полное сканирование мира:</b> выполняется...</span><br>"
	else
		html += "<br><a href='?_src_=holder;[HrefToken()];viewgcfailure_worldscan=[REF(src)]' style='background:#333;color:#FF8800;padding:4px 12px;border:1px solid #555;border-radius:4px;text-decoration:none;font-family:Courier New'>"
		html += "Запустить полное сканирование мира (10-60 сек)</a><br>"

	// TESTING-only extended sections
	#ifdef TESTING
	if (length(full_var_dump))
		html += "<details><summary><b>Полный дамп переменных ([length(full_var_dump)])</b></summary>"
		html += "<div class='gc_failure'>"
		for (var/line in full_var_dump)
			html += "[html_encode(line)]<br>"
		html += "</div></details>"

	if (length(signal_handler_details))
		html += "<details><summary><b>Обработчики сигналов ([length(signal_handler_details)])</b></summary>"
		html += "<div class='gc_failure'>"
		for (var/line in signal_handler_details)
			html += "[html_encode(line)]<br>"
		html += "</div></details>"

	if (length(component_details))
		html += "<details><summary><b>Детали компонентов ([length(component_details)])</b></summary>"
		html += "<div class='gc_failure'>"
		for (var/line in component_details)
			html += "[html_encode(line)]<br>"
		html += "</div></details>"

	if (length(timer_details))
		html += "<details><summary><b>Детали таймеров ([length(timer_details)])</b></summary>"
		html += "<div class='gc_failure'>"
		for (var/line in timer_details)
			html += "[html_encode(line)]<br>"
		html += "</div></details>"
	#endif

	// VV link to the object if it still exists
	if (datum_ref)
		var/datum/D = locate(datum_ref)
		if (D && D.type == text2path(type_path))
			html += "<br><b>Объект</b>: <a href='?_src_=vars;[HrefToken()];Vars=[datum_ref]'>VV</a>"
		else
			html += "<br><b>Объект</b>: больше не существует ([ref_id])"

	browse_to(user, html)
