#ifdef MEMORY_PROFILER

SUBSYSTEM_DEF(memory_profiler)
	name = "Memory Profiler"
	init_order = INIT_ORDER_MEMORY_PROFILER
	wait = 1 MINUTES
	flags = SS_NO_TICK_CHECK | SS_BACKGROUND
	runlevels = RUNLEVELS_DEFAULT | RUNLEVEL_LOBBY
	var/fetch_cost = 0
	var/write_cost = 0
	/// Parsed latest snapshot
	var/list/latest_snapshot
	/// Raw latest stats string
	var/latest_raw
	/// History of parsed snapshots, newest first
	var/list/snapshot_history
	/// Timestamps for each snapshot (world.time)
	var/list/snapshot_timestamps
	/// Named baselines: name -> list("snapshot" = parsed, "time" = world.time)
	var/list/baselines
	/// Which baseline name to compare against in UI (per-client would be nice but keeping it simple)
	var/active_baseline = "Init"

/datum/controller/subsystem/memory_profiler/stat_entry(msg)
	msg += "F:[round(fetch_cost,1)]ms"
	msg += "|W:[round(write_cost,1)]ms"
	msg += "|Snaps:[length(snapshot_history)]"
	msg += "|BL:[length(baselines)]"
	return msg

/datum/controller/subsystem/memory_profiler/Initialize()
	snapshot_history = list()
	snapshot_timestamps = list()
	baselines = list()
	TakeSnapshot()
	SaveBaseline("Init")
	if(CONFIG_GET(flag/auto_profile))
		DumpFile()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/memory_profiler/fire()
	TakeSnapshot()
	if(CONFIG_GET(flag/auto_profile))
		DumpFile()

/datum/controller/subsystem/memory_profiler/Shutdown()
	TakeSnapshot()
	if(CONFIG_GET(flag/auto_profile))
		DumpFile()
	return ..()

/datum/controller/subsystem/memory_profiler/proc/TakeSnapshot()
	if(!snapshot_history)
		snapshot_history = list()
		snapshot_timestamps = list()
	if(!baselines)
		baselines = list()
	var/timer = TICK_USAGE_REAL
	var/raw = memorystats_get()
	fetch_cost = MC_AVERAGE(fetch_cost, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))
	if(!raw)
		return
	latest_raw = raw
	latest_snapshot = parse_memorystats(raw)
	if(!latest_snapshot)
		return
	snapshot_history.Insert(1, list(latest_snapshot))
	snapshot_timestamps.Insert(1, world.time)
	if(length(snapshot_history) > MEMORYSTATS_MAX_SNAPSHOTS)
		snapshot_history.len = MEMORYSTATS_MAX_SNAPSHOTS
		snapshot_timestamps.len = MEMORYSTATS_MAX_SNAPSHOTS

/datum/controller/subsystem/memory_profiler/proc/SaveBaseline(name)
	if(!latest_snapshot)
		return FALSE
	if(length(baselines) >= MEMORYSTATS_MAX_BASELINES && !baselines[name])
		return FALSE
	baselines[name] = list("snapshot" = latest_snapshot, "time" = world.time)
	active_baseline = name
	return TRUE

/datum/controller/subsystem/memory_profiler/proc/DeleteBaseline(name)
	if(name == "Init")
		return FALSE
	baselines -= name
	if(active_baseline == name)
		active_baseline = baselines[1] // fall back to first
	return TRUE

/datum/controller/subsystem/memory_profiler/proc/GetActiveBaseline()
	if(!length(baselines) || !active_baseline || !baselines[active_baseline])
		return null
	var/list/bl = baselines[active_baseline]
	return bl["snapshot"]

/datum/controller/subsystem/memory_profiler/proc/GetActiveBaselineTime()
	if(!length(baselines) || !active_baseline || !baselines[active_baseline])
		return 0
	var/list/bl = baselines[active_baseline]
	return bl["time"]

/datum/controller/subsystem/memory_profiler/proc/DumpFile()
	if(!latest_raw)
		return
	var/json_file = file("[GLOB.log_directory]/[MEMORYSTATS_FILENAME]")
	if(fexists(json_file))
		fdel(json_file)
	var/timer = TICK_USAGE_REAL
	WRITE_FILE(json_file, latest_raw)
	write_cost = MC_AVERAGE(write_cost, TICK_DELTA_TO_MS(TICK_USAGE_REAL - timer))

// ========== Parsing ==========

/// Parses memorystats raw output into assoc list: category -> list(entry_name = list("size" = "...", "count" = "..."))
/proc/parse_memorystats(raw_text)
	var/list/result = list()
	var/current_category
	for(var/line in splittext(raw_text, "\n"))
		line = trim(line)
		if(!length(line) || line == "Server mem usage:")
			continue
		if(findtext(line, ":") == length(line))
			current_category = copytext(line, 1, length(line))
			result[current_category] = list()
			continue
		if(!current_category)
			continue
		var/colon_pos = findtext(line, ": ")
		if(!colon_pos)
			continue
		var/entry_name = copytext(line, 1, colon_pos)
		var/rest = copytext(line, colon_pos + 2)
		var/paren_pos = findtext(rest, "(")
		var/size_text = ""
		var/count_text = ""
		if(paren_pos)
			size_text = trim(copytext(rest, 1, paren_pos))
			count_text = copytext(rest, paren_pos + 1, length(rest))
		else
			size_text = trim(rest)
		var/list/entries = result[current_category]
		entries[entry_name] = list("size" = size_text, "count" = count_text)
	return result

/// Gets numeric count from a snapshot entry
/proc/get_snapshot_count(list/snapshot, category, entry_name)
	if(!snapshot?[category])
		return null
	var/list/entries = snapshot[category]
	if(!entries[entry_name])
		return null
	var/list/data = entries[entry_name]
	return text2num(data["count"])

/// Formats world.time ticks to "Xм Yс"
/proc/format_time_short(time_val)
	var/minutes = round(time_val / 600)
	var/seconds = round((time_val % 600) / 10)
	if(minutes > 0)
		return "[minutes]м [seconds]с"
	return "[seconds]с"

// ========== HTML Generation ==========

/proc/generate_memorystats_html(list/current, list/previous, datum/admins/holder)
	var/list/html = list()
	html += {"<!DOCTYPE html><html><head><meta charset='utf-8'>
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
body { background: #111; color: #ccc; font-family: Consolas, 'Courier New', monospace; font-size: 12px; padding: 8px; }
.bar { background: #1a1a1a; border: 1px solid #333; padding: 5px 10px; margin-bottom: 6px; display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.bar a { color: #4fc3f7; text-decoration: none; padding: 2px 8px; border: 1px solid #4fc3f7; font-size: 11px; }
.bar a:hover { background: #4fc3f720; }
.bar a.act { background: #4fc3f7; color: #111; }
.bar a.sav { color: #4c4; border-color: #4c4; }
.bar a.sav:hover { background: #4c420; }
.bar a.del { color: #f44; border-color: #f44; font-size: 10px; }
.bar a.del:hover { background: #f4420; }
.bar .sep { color: #333; }
.bar .info { color: #888; font-size: 11px; }
.warn { background: #4a1c1c; border-left: 3px solid #f44; padding: 4px 8px; margin-bottom: 6px; font-size: 11px; color: #f88; }
.warn b { color: #faa; }
table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
th { background: #1a1a1a; color: #888; text-align: left; padding: 4px 8px; font-size: 11px; text-transform: uppercase; border-bottom: 1px solid #333; font-weight: normal; }
td { padding: 3px 8px; border-bottom: 1px solid #1a1a1a; }
tr:hover { background: #1a1a1a; }
.cat { color: #4fc3f7; font-size: 12px; font-weight: bold; padding: 6px 0 3px 0; border-bottom: 1px solid #333; margin-top: 6px; }
.r { text-align: right; }
.up { color: #f44; }
.dn { color: #4c4; }
.zr { color: #444; }
.big { color: #f44; font-weight: bold; }
.row { display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 6px; }
.box { background: #1a1a1a; border: 1px solid #333; padding: 4px 10px; min-width: 90px; }
.box .lb { color: #666; font-size: 10px; text-transform: uppercase; }
.box .vl { color: #eee; font-size: 14px; font-weight: bold; }
.box .vl.bad { color: #f44; }
</style></head><body>"}

	// Toolbar: refresh
	html += "<div class='bar'>"
	html += "<a href='byond://?src=[REF(holder)];[HrefToken()];memorystats_refresh=1'>ОБНОВИТЬ</a>"
	html += "<span class='sep'>|</span>"
	html += "<span class='info'>Снимков: [length(SSmemory_profiler.snapshot_history)] | Fetch: [round(SSmemory_profiler.fetch_cost, 0.1)]мс | Аптайм: [format_time_short(world.time)]</span>"
	html += "</div>"

	// Baselines bar
	html += "<div class='bar'>"
	html += "<span class='info'>Baseline:</span>"
	for(var/bl_name in SSmemory_profiler.baselines)
		var/list/bl_data = SSmemory_profiler.baselines[bl_name]
		var/bl_time = bl_data["time"]
		var/is_active = (bl_name == SSmemory_profiler.active_baseline)
		html += "<a class='[is_active ? "act" : ""]' href='byond://?src=[REF(holder)];[HrefToken()];memorystats_select_bl=[url_encode(bl_name)]'>[bl_name] ([format_time_short(bl_time)])</a>"
		if(bl_name != "Init")
			html += "<a class='del' href='byond://?src=[REF(holder)];[HrefToken()];memorystats_del_bl=[url_encode(bl_name)]'>x</a>"
	html += "<span class='sep'>|</span>"
	html += "<a class='sav' href='byond://?src=[REF(holder)];[HrefToken()];memorystats_save_bl=1'>+ СОХРАНИТЬ</a>"
	html += "</div>"

	if(!current)
		html += "<div class='warn'>Нет данных. Библиотека memorystats не загружена.</div>"
		html += "</body></html>"
		return jointext(html, "")

	var/list/baseline = SSmemory_profiler.GetActiveBaseline()

	// Summary
	html += "<div class='row'>"
	var/total_objects = 0
	var/total_bl_objects = 0
	if(current["objects"])
		var/list/obj_entries = current["objects"]
		for(var/ename in obj_entries)
			var/list/d = obj_entries[ename]
			var/c = text2num(d["count"])
			if(isnum(c))
				total_objects += c
	if(baseline?["objects"])
		var/list/bl_entries = baseline["objects"]
		for(var/ename in bl_entries)
			var/list/d = bl_entries[ename]
			var/c = text2num(d["count"])
			if(isnum(c))
				total_bl_objects += c
	var/obj_growth = total_objects - total_bl_objects
	html += "<div class='box'><div class='lb'>Объектов</div><div class='vl'>[total_objects]</div></div>"
	if(baseline)
		html += "<div class='box'><div class='lb'>vs [SSmemory_profiler.active_baseline]</div><div class='vl [obj_growth > 1000 ? "bad" : ""]'>[obj_growth > 0 ? "+[obj_growth]" : "[obj_growth]"]</div></div>"
	html += "<div class='box'><div class='lb'>CPU</div><div class='vl [world.cpu > 100 ? "bad" : ""]'>[round(world.cpu, 0.1)]%</div></div>"
	html += "<div class='box'><div class='lb'>Tick</div><div class='vl'>[round(world.tick_usage, 0.1)]%</div></div>"
	html += "</div>"

	// Warnings
	var/list/warnings = list()
	if(baseline)
		for(var/category in current)
			var/list/entries = current[category]
			for(var/ename in entries)
				var/cur_c = get_snapshot_count(current, category, ename)
				var/bl_c = get_snapshot_count(baseline, category, ename)
				if(!isnum(cur_c) || !isnum(bl_c) || bl_c == 0)
					continue
				var/growth_pct = ((cur_c - bl_c) / bl_c) * 100
				if(growth_pct > 50 && (cur_c - bl_c) > 100)
					warnings += "<b>[category]/[ename]</b>: [bl_c] → [cur_c] (+[round(growth_pct, 1)]%)"
	if(length(warnings))
		html += "<div class='warn'>Подозрительный рост vs [SSmemory_profiler.active_baseline]:<br>[jointext(warnings, "<br>")]</div>"

	// Tables
	for(var/category in current)
		html += "<div class='cat'>[uppertext(category)]</div>"
		html += "<table><tr><th>Тип</th><th class='r'>Размер</th><th class='r'>Кол-во</th>"
		if(baseline)
			html += "<th class='r'>vs [SSmemory_profiler.active_baseline]</th>"
		if(previous)
			html += "<th class='r'>vs Пред.</th>"
		html += "</tr>"
		var/list/entries = current[category]
		for(var/entry_name in entries)
			var/list/data = entries[entry_name]
			var/cur_count = text2num(data["count"])
			html += "<tr>"
			html += "<td>[entry_name]</td>"
			html += "<td class='r'>[data["size"]]</td>"
			html += "<td class='r'>[data["count"]]</td>"
			if(baseline)
				html += "<td class='r'>[format_delta(cur_count, get_snapshot_count(baseline, category, entry_name))]</td>"
			if(previous)
				html += "<td class='r'>[format_delta(cur_count, get_snapshot_count(previous, category, entry_name))]</td>"
			html += "</tr>"
		html += "</table>"

	html += "</body></html>"
	return jointext(html, "")

/proc/format_delta(cur, prev)
	if(!isnum(cur) || !isnum(prev))
		return "<span class='zr'>—</span>"
	var/diff = cur - prev
	if(diff == 0)
		return "<span class='zr'>±0</span>"
	if(diff > 0)
		var/cls = diff > 500 ? "big" : "up"
		return "<span class='[cls]'>+[diff]</span>"
	return "<span class='dn'>[diff]</span>"

#endif
