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

/// Builds a white emissive copy of a source appearance on the [EMISSIVE_PLANE], using BlueMoon's
/// single-channel white emissive convention. This is the mechanism that the rest of this codebase
/// uses to render body-part glow against the lighting mask.
///
/// The emissive copy is intentionally confined to the SOURCE part's exact sprite pixels. Body-part
/// glow must only punch a small hole through the darkness via the lighting plane's emissive alpha
/// mask (plane_master "emissives" filter); it must NOT reveal a whole tile/surroundings. The source
/// uses RESET_TRANSFORM and its natural pixel bounds (no TILE_BOUND / PIXEL_SCALE) so the glow stays
/// pixel-accurate instead of expanding across the tile grid, which looked like unintended dark-vision.
/proc/emissive_copy(mutable_appearance/source, layer = FLOAT_LAYER)
	var/mutable_appearance/emissive = new /mutable_appearance(source)
	emissive.layer = layer
	emissive.plane = EMISSIVE_PLANE
	emissive.color = GLOB.emissive_color
	emissive.appearance_flags = (emissive.appearance_flags & ~(TILE_BOUND | PIXEL_SCALE)) | KEEP_TOGETHER | RESET_TRANSFORM
	return emissive
