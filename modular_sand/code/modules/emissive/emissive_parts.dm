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

/// Слои, оверлеи которых зеркалятся на эмиссивный план как блокеры. Только то, что реально
/// закрывает свечение снизу (волосы, головные уборы, одежда поверх тела) и встречается
/// почти на каждом персонаже. Список короткий намеренно: каждая зеркальная иконка — это
/// дополнительные пиксели в bound_icon персонажа, а полное зеркалирование всех оверлеев
/// (как было в откаченном коммите 2ddd290) упиралось в лимит клиента и давало ERROR-спрайт.
GLOBAL_LIST_INIT(emissive_blocked_layers, list(
	HAIR_LAYER, HEAD_LAYER, FACEMASK_LAYER, GLASSES_LAYER, NECK_LAYER,
	UNIFORM_LAYER, DRESS_LAYER, SHIRT_LAYER, SHOES_LAYER
))

/// Builds a white emissive copy of a source appearance on the [EMISSIVE_PLANE], using BlueMoon's
/// single-channel white emissive convention (KEEP_TOGETHER|TILE_BOUND|PIXEL_SCALE). This is the
/// mechanism that the rest of this codebase uses to render body-part glow against the lighting mask.
/// The copy keeps the source layer by default: on the emissive plane the drawing order has to match
/// the game plane, otherwise a blocking item cannot punch the alpha out of the glow below it.
/// Nested overlays are dropped because they are not on the emissive plane and would add pixels.
/proc/emissive_copy(mutable_appearance/source, layer = null)
	var/mutable_appearance/emissive = new /mutable_appearance(source)
	emissive.layer = layer != null ? layer : source.layer
	emissive.overlays = null
	emissive.plane = EMISSIVE_PLANE
	emissive.color = GLOB.emissive_color
	emissive.appearance_flags = (emissive.appearance_flags & ~KEEP_APART) | KEEP_TOGETHER | TILE_BOUND | PIXEL_SCALE
	return emissive

/// Blocker counterpart of [proc/emissive_copy]: the same icon on the same layer, painted in the
/// blocking color so it erases the glow drawn below it on the emissive plane. Callers must place
/// the blocker in front of the glow it protects (see `/mob/living/carbon/apply_overlay`).
/proc/emissive_blocker_copy(image/source)
	if(!source?.icon || !source.icon_state)
		return null
	var/mutable_appearance/blocker = new /mutable_appearance(source)
	blocker.overlays = null
	blocker.plane = EMISSIVE_PLANE
	blocker.color = GLOB.em_block_color
	blocker.appearance_flags = (blocker.appearance_flags & ~KEEP_APART) | KEEP_TOGETHER | TILE_BOUND | PIXEL_SCALE
	return blocker
