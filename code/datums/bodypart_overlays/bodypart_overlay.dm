// BLUEMOON PORT START - Bodypart overflow subsystem (ported from NovaSector)
// This is a self-contained, minimal port of the /datum/bodypart_overlay framework,
// reduced to what augment (cybernetic implant) overlays need. The full NovaSector
// system also covers mutant parts / markings / emotes, which BlueMoon handles
// through its own overlays_standing[] system, so those subtypes are NOT ported.
//
// WHY THIS EXISTS:
//   Implants like the Reviver, neural receiver, jetpack, etc. have sprites in
//   bodypart_overlay_augmentations.dmi that should render ON the character's body
//   (not just on the item object itself). This datum wraps those sprites so they
//   can be attached to an /obj/item/bodypart and drawn by get_limb_icon().
//
// Layer postfixes used as keys in the `layers` assoc list (mirrors NovaSector)
#define EXTERNAL_FRONT "FRONT"
#define EXTERNAL_ADJACENT "ADJ"
#define EXTERNAL_BEHIND "BEHIND"
// No position modifier to apply to the overlay
#define NO_MODIFY "do not modify"
// Height-offset location applied by owner.apply_height() (not used in this build,
// NovaSector uses this for tall/short characters). Kept for port parity.
#define ENTIRE_BODY "full body"
// The color tone applied to any overlay drawn on a husked body (obscures skin detail)
#define HUSK_COLOR_TONE rgb(96, 88, 80)

// How an overlay behaves when the owner is a husk
#define HUSK_OVERLAY_NONE 0
#define HUSK_OVERLAY_GRAYSCALE 1
#define HUSK_OVERLAY_NORMAL 2

/// Abstract parent. Each instance represents one visual layer drawn on a bodypart.
/// An /obj/item/bodypart holds a list of these in its `bodypart_overlays` var.
/datum/bodypart_overlay
	/// Assoc list [layer postfix string] -> [positive layer number]. The postfix is
	/// passed to the child get_image() as `layer_index`, and the layer is negated
	/// before being passed as `layer_real` (bodypart overlays use negative draw layers).
	VAR_PROTECTED/list/layers
	/// Whether this overlay casts an emissive shadow (blocker) on the emissive plane.
	var/blocks_emissive = EMISSIVE_BLOCK_UNIQUE
	/// Whether the overlay should be drawn on husked owners (see HUSK_OVERLAY_*)
	var/draw_on_husks = HUSK_OVERLAY_NONE
	/// How the overlay offset is modified. Reserved for future use (kept for port parity).
	var/offset_location = NO_MODIFY

/datum/bodypart_overlay/New()
	. = ..()
	set_layers(layers)

/datum/bodypart_overlay/proc/set_layer(layer_postfix, layer_number)
	layers = layers ? layers.Copy() : list()
	layers[layer_postfix] = layer_number

/datum/bodypart_overlay/proc/set_layers(list/layer_list)
	if(!length(layer_list))
		return
	layers = layer_list.Copy()

/datum/bodypart_overlay/proc/clear_layer(layer_postfix)
	var/list/existing_layers = layers.Copy()
	existing_layers -= layer_postfix
	if(!length(existing_layers))
		layers = null
		return
	layers = existing_layers

/// Returns every mutable appearance this overlay contributes to the limb at every layer.
/datum/bodypart_overlay/proc/get_all_overlays(obj/item/bodypart/limb)
	var/list/overlays = list()
	for(var/overlay_postfix in layers)
		var/overlay_layer = layers[overlay_postfix]
		overlays += get_overlay(limb, overlay_postfix, -overlay_layer)
	return overlays

/// Builds the list of images for one layer of this overlay.
/// layer_index = the string postfix (e.g. "ADJ"), layer_real = the negated draw layer.
/datum/bodypart_overlay/proc/get_overlay(obj/item/bodypart/limb, layer_index, layer_real)
	var/image/main_image = get_image(limb, layer_index, layer_real)
	if(limb && limb.species_id == "husk" && draw_on_husks != HUSK_OVERLAY_NORMAL)
		main_image = huskify_image(main_image, limb)
	else
		color_image(main_image, limb, layer_index)
	var/list/created_overlays = list(main_image)
	// Emissive blockers prevent the glow of other overlays punching through this one.
	if(blocks_emissive != EMISSIVE_BLOCK_NONE && !isnull(limb))
		created_overlays += emissive_blocker(main_image.icon, main_image.icon_state, limb, layer = main_image.layer, alpha = main_image.alpha)
	return created_overlays

/// Applies the husk color tone to the overlay for husked owners.
/datum/bodypart_overlay/proc/huskify_image(image/main_image, obj/item/bodypart/limb)
	var/icon/husk_icon = new(main_image.icon)
	husk_icon.ColorTone(HUSK_COLOR_TONE)
	main_image.icon = husk_icon
	if(limb)
		if(limb.mutation_color)
			main_image.color = limb.mutation_color
		else if(limb.species_color)
			main_image.color = limb.species_color
	return main_image

/// Overridden by subtypes to return the actual main image for a layer.
/datum/bodypart_overlay/proc/get_image(obj/item/bodypart/limb, layer_index, layer_real)
	CRASH("Get image needs to be overridden")

/// Overridden by subtypes to tint the overlay (e.g. skin / species colors).
/datum/bodypart_overlay/proc/color_image(image/overlay, obj/item/bodypart/limb, layer_index)
	return

/datum/bodypart_overlay/proc/added_to_limb(obj/item/bodypart/limb)
	return

/datum/bodypart_overlay/proc/removed_from_limb(obj/item/bodypart/limb)
	return

/// Rebuilds the overlay's appearance from its source (organ, feature, etc).
/datum/bodypart_overlay/proc/set_appearance()
	CRASH("Update appearance needs to be overridden")

/datum/bodypart_overlay/proc/can_draw_on_bodypart(obj/item/bodypart/bodypart_owner, mob/living/carbon/owner)
	SHOULD_CALL_PARENT(TRUE)
	return bodypart_owner.species_id != "husk" || draw_on_husks != HUSK_OVERLAY_NONE

/// Returns extra data appended to the mob's icon render key so the limb icon cache
/// is correctly invalidated when this overlay's appearance changes.
/datum/bodypart_overlay/proc/icon_render_key(obj/item/bodypart/limb)
	return list()

// ============================================================================
// AUGMENT OVERLAY
// ============================================================================
// Renders a cybernetic implant's sprite (from bodypart_overlay_augmentations.dmi)
// onto a specific bodypart. Does NOT have its own icon/icon_state - it delegates
// all image generation to the owning /obj/item/organ/cyberimp via its get_overlay()
// proc. The implant owns the aug_icon / aug_overlay / emissive_overlay vars.
/datum/bodypart_overlay/augment
	layers = list(EXTERNAL_ADJACENT = BODY_ADJ_LAYER)
	draw_on_husks = HUSK_OVERLAY_NORMAL
	offset_location = ENTIRE_BODY
	/// The cybernetic implant this overlay renders for.
	var/obj/item/organ/cyberimp/implant

/datum/bodypart_overlay/augment/New(obj/item/organ/cyberimp/implant)
	. = ..()
	src.implant = implant

/datum/bodypart_overlay/augment/Destroy(force)
	implant = null
	return ..()

/datum/bodypart_overlay/augment/icon_render_key(obj/item/bodypart/limb)
	. = ..()
	. += implant.get_overlay_state()

/datum/bodypart_overlay/augment/get_overlay(obj/item/bodypart/limb, layer_index, layer_real)
	// Delegate image creation to the implant, which knows its exact icon/state.
	var/list/imageset = implant.get_overlay(layer_real, limb)
	if(!limb || implant.blocks_emissive == EMISSIVE_BLOCK_NONE)
		return imageset

	// Add an emissive blocker for each generated image so this implant's glow
	// doesn't punch through other overlaid sprites on the same limb.
	var/list/all_images = list()
	for(var/image/overlay as anything in imageset)
		all_images += overlay
		all_images += emissive_blocker(overlay.icon, overlay.icon_state, limb, layer = overlay.layer, alpha = overlay.alpha)

	return all_images

// BLUEMOON PORT END - bodypart overlay augment system
