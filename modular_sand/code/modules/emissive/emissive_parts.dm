/proc/emissives_allowed(datum/dna/dna)
	return dna && dna.features?["allow_emissives"]

GLOBAL_LIST_INIT(emissive_parts_list, list(
	"eyes",
	"penis", "testicles", "vagina", "breasts", "butt", "anus", "belly",
	"horns", "ears", "tail", "snout", "wings", "frills", "spines", "caps",
	"moth_antennae"
))

/proc/has_emissive_part(list/features, part)
	if(!features?["allow_emissives"])
		return FALSE
	return emissive_part_enabled(features, part)

/proc/emissive_part_enabled(list/features, part)
	var/list/parts = features?["emissive_parts"]
	return islist(parts) && (part in parts)

/proc/toggle_emissive_part(list/features, part)
	if(!features || !(part in GLOB.emissive_parts_list))
		return FALSE
	if(!islist(features["emissive_parts"]))
		features["emissive_parts"] = list()
	var/list/parts = features["emissive_parts"]
	if(part in parts)
		parts -= part
	else
		parts += part
		features["allow_emissives"] = TRUE
	return (part in parts)

/proc/emissive_copy(mutable_appearance/source, layer = EMISSIVE_BLOCKER_LAYER + 0.5)
	var/mutable_appearance/emissive = new /mutable_appearance(source)
	emissive.layer = layer
	emissive.plane = EMISSIVE_PLANE
	emissive.color = GLOB.emissive_color
	emissive.appearance_flags = KEEP_TOGETHER|TILE_BOUND|PIXEL_SCALE
	return emissive

GLOBAL_LIST_EMPTY(marking_emissive_icon_cache)

/proc/make_marking_emissive_icon(icon/source_icon, source_state)
	var/cache_key = "[source_icon]-[source_state]"
	if(GLOB.marking_emissive_icon_cache[cache_key])
		return GLOB.marking_emissive_icon_cache[cache_key]
	var/icon/result = new(source_icon, source_state)
	GLOB.marking_emissive_icon_cache[cache_key] = result
	return result
