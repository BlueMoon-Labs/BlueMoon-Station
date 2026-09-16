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
/// single-channel white emissive convention (KEEP_TOGETHER|TILE_BOUND|PIXEL_SCALE). This is the
/// mechanism that the rest of this codebase uses to render body-part glow against the lighting mask.
/// IMPORTANT: layer is preserved from source by default (not FLOAT_LAYER) so that clothing
/// (higher layers, e.g. uniform -32) correctly blocks body glow (lower layers, e.g. markings -41)
/// via the emissive-plane layer ordering. FLOAT_LAYER would break this ordering and let glow
/// shine through clothes and other mobs.
/proc/emissive_copy(image/source, layer = null)
	var/mutable_appearance/emissive = new /mutable_appearance(source)
	emissive.layer = isnull(layer) ? source.layer : layer
	emissive.plane = EMISSIVE_PLANE
	emissive.color = GLOB.emissive_color
	emissive.blend_mode = BLEND_DEFAULT
	emissive.appearance_flags = (emissive.appearance_flags & ~KEEP_APART) | KEEP_TOGETHER | TILE_BOUND | PIXEL_SCALE
	// Emissive copies must not carry nested game-plane overlays as-is: they would render
	// with wrong colors on the emissive plane. The source icon_state itself is pixel-accurate.
	emissive.overlays.Cut()
	return emissive

/// Builds an emissive BLOCKER copy of a source appearance on the [EMISSIVE_PLANE].
/// The blocker uses the same icon/state/layer/pixels as the source, so opaque pixels
/// of clothing/body correctly occlude glow underneath (markings, mutant parts) and
/// glow of mobs standing behind (front mob blocks back mob where sprites overlap).
/proc/emissive_blocker_copy(image/source, layer = null)
	var/mutable_appearance/blocker = new /mutable_appearance(source)
	blocker.layer = isnull(layer) ? source.layer : layer
	blocker.plane = EMISSIVE_PLANE
	blocker.color = GLOB.em_block_color
	blocker.blend_mode = BLEND_DEFAULT
	blocker.appearance_flags = (blocker.appearance_flags & ~KEEP_APART) | KEEP_TOGETHER | TILE_BOUND | PIXEL_SCALE
	blocker.overlays.Cut()
	return blocker
