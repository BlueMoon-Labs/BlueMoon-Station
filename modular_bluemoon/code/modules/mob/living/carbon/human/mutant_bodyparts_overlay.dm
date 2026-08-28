GLOBAL_LIST_INIT(mutant_overlays_cache, list())

#define MUTANT_OVERLAY_CACHE_MAX 1024
#define MUTANT_OVERLAY_CACHE_EVICT (MUTANT_OVERLAY_CACHE_MAX / 4)

//overlay_params ключи
#define OVERLAYS_LAYER_NAME_KEY_INDEX 1
#define OVERLAYS_EFFECT_DATUM_INDEX 3

#define SNOUT_APPEARANCE "snout"
#define TAIL_APPEARANCE "tail"
#define EARS_APPEARANCE "ears"
#define INSECT_WINGS_APPEARANCE "insect_wings"
#define DECO_WINGS_APPEARANCE "deco_wings"
#define TAUR_APPEARANCE "taur"
#define INSECT_FLUFF_APPEARANCE "insect_fluff"
#define HORNS_APPEARANCE "horns"
#define HAIR_APPEARANCE "hair"

#define PENIS_APPEARANCE "penis"
#define TESTICLES_APPEARANCE "testicles"
#define VAGINA_APPEARANCE "vagina"
#define BREASTS_APPEARANCE "breasts"
#define BUTT_APPEARANCE "butt"
#define BELLY_APPEARANCE "belly"

GLOBAL_LIST_INIT(mutant_overlay_layers, list(
	SNOUT_APPEARANCE,
	TAIL_APPEARANCE,
	EARS_APPEARANCE,
	INSECT_WINGS_APPEARANCE,
	INSECT_FLUFF_APPEARANCE,
	TAUR_APPEARANCE,
	HORNS_APPEARANCE,
	HAIR_APPEARANCE,
))

GLOBAL_LIST_INIT(mutant_overlay_genital_layers, list(
	BREASTS_APPEARANCE,
	VAGINA_APPEARANCE,
	TESTICLES_APPEARANCE,
	PENIS_APPEARANCE,
	BUTT_APPEARANCE,
	BELLY_APPEARANCE,
))

//К сожалению, некоторые части тела не просвечивают через одежду, даже если они видны по is_not_visible
//приходится искусственно выявлять их и повышать layer вручную.
GLOBAL_LIST_INIT(mutant_overlay_layer_bumps, list(
	BREASTS_APPEARANCE = 100,
	VAGINA_APPEARANCE = 100,
	TESTICLES_APPEARANCE = 100,
	PENIS_APPEARANCE = 100,
	BUTT_APPEARANCE = 100,
	BELLY_APPEARANCE = 100,
	SNOUT_APPEARANCE = 40,
))

//-----MARK: M_APPERANCE
/mutable_appearance
	var/color_tone
	var/datum/overlay_effect/used_effect_datum

//Этот прок важен для пересоздания точно такого же оверлея
//Он сохраняет наложенный эффект,цвет и т.д.
/mutable_appearance/proc/copy_special_MA_params(layer, effect_datum)
	var/list/params = list()
	params += isnull(layer) ? src.name : layer
	params += isnull(effect_datum) ? used_effect_datum : effect_datum
	return params

//-----MARK: CACHE
/mob/living/carbon/human/proc/clear_old_cache_if_it_need()
	if(GLOB.mutant_overlays_cache.len > MUTANT_OVERLAY_CACHE_MAX)
		GLOB.mutant_overlays_cache.Cut(1, MUTANT_OVERLAY_CACHE_EVICT + 1)

/mob/living/carbon/human/proc/generate_accessory_cache_key(mutable_appearance/accessory_overlay, datum/overlay_effect/effect_datum)
	return "[accessory_overlay?.icon][accessory_overlay?.icon_state][effect_datum?.name][effect_datum?.color]"

/mob/living/carbon/human/proc/get_overlay_from_cache(key)
	return GLOB.mutant_overlays_cache[key]

/mob/living/carbon/human/proc/write_overlay_icon_in_GLOB_cache(icon/overlayed_icon, cache_key)
	GLOB.mutant_overlays_cache[cache_key] = overlayed_icon
	clear_old_cache_if_it_need()

//---MARK: HUMAN PROCS
/mob/living/carbon/human
	var/list/mutant_part_appearances = list() //Хранит списки по ключам слоя. tail = list(tail_FRONT, tail_ADJ). Содержимое это mutable_apperance
	var/list/layers_for_apply_effect = list()

//По сути, просто берёт иконку, красит её в цвет, в половину меняет прозрачность и накладывает эффект через блэнд.
//Правит иконку на месте, поэтому кормить его можно только свежесозданной.
/mob/living/carbon/human/proc/get_overlayed_icon(icon/A, datum/overlay_effect/effect_datum)
	var/icon/flat_icon = A
	if(effect_datum.need_use_color)
		flat_icon.ColorTone(effect_datum.color)
	if(effect_datum.icon) //Может накладывать любой эффект по форме спрайта
		var/icon/alpha_mask = effect_datum.pre_build_icon
		var/icon/M = new(alpha_mask)
		flat_icon.Blend(M, ICON_ADD)
	return flat_icon

/mob/living/carbon/human/proc/use_effect_by_params(mutable_appearance/accessory_overlay, list/overlay_params)
	var/datum/overlay_effect/effect_datum = overlay_params[OVERLAYS_EFFECT_DATUM_INDEX]
	var/layer_name = overlay_params[OVERLAYS_LAYER_NAME_KEY_INDEX]
	var/cache_list_key = generate_accessory_cache_key(accessory_overlay, effect_datum)
	var/icon/template = get_overlay_from_cache(cache_list_key)

	if(!template)
		template = fcopy_rsc(get_overlayed_icon(icon(accessory_overlay.icon, accessory_overlay.icon_state), effect_datum))
		write_overlay_icon_in_GLOB_cache(template, cache_list_key)

	var/MA_layer = accessory_overlay.layer
	var/layer_bump = GLOB.mutant_overlay_layer_bumps[layer_name]
	if(layer_bump)
		MA_layer += layer_bump

	var/mutable_appearance/overlay_MA = mutable_appearance(icon = template, layer = MA_layer, plane = accessory_overlay.plane, alpha = LIGHTING_PLANE_ALPHA_VISIBLE, appearance_flags = accessory_overlay.appearance_flags, color = effect_datum.color, pixel_x = accessory_overlay.pixel_x, pixel_y = accessory_overlay.pixel_y, blend_mode=BLEND_OVERLAY)
	overlay_MA.name = "[layer_name]_[accessory_overlay.icon_state]"

	var/target_index = (layer_name in GLOB.mutant_overlay_genital_layers) ? GENITAL_EFFECT_LAYER : BODYPART_EFFECT_LAYER
	return add_new_overlay_effect_in_standing(target_index, overlay_MA)

//MARK: Обновление и применение
/datum/species/proc/update_overlay_by_key(key, mob/living/carbon/human/H, mutable_appearance/accessory_overlay)
	if(!H.layers_for_apply_effect[key])
		return FALSE
	var/overlay_params = H.layers_for_apply_effect[key]
	accessory_overlay = H.use_effect_by_params(accessory_overlay, overlay_params)

//Обновляем только те проходы, которых коснулась правка. null = оба.
/mob/living/carbon/human/proc/update_overlayed_parts(list/changed_layers)
	if(!changed_layers || has_common_layer(changed_layers, GLOB.mutant_overlay_layers))
		update_mutant_bodyparts()
	if(!changed_layers || has_common_layer(changed_layers, GLOB.mutant_overlay_genital_layers))
		update_genitals()

/mob/living/carbon/human/proc/has_common_layer(list/changed_layers, list/target_layers)
	for(var/layer in changed_layers)
		if(layer in target_layers)
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/apply_bodypart_overlays(list/layers, update = TRUE, datum/overlay_effect/effect_datum)
	var/list/target_layers = layers ? layers : (GLOB.mutant_overlay_layers + GLOB.mutant_overlay_genital_layers)
	var/datum/overlay_effect/target_datum = effect_datum ? effect_datum : new /datum/overlay_effect/mod_effect
	for(var/layer in target_layers)
		apply_overlay_on_bodypart(layer, color, target_datum)
	if(update)
		update_overlayed_parts(target_layers)

/mob/living/carbon/human/proc/apply_overlay_on_bodypart(layer, color, effect_datum)
	if(!(layer in layers_for_apply_effect))
		layers_for_apply_effect[layer] = list(layer, color, effect_datum)

/mob/living/carbon/human/proc/add_new_overlay_effect_in_standing(new_item_index, mutable_appearance/additional_appearance)
	if(!overlays_standing[new_item_index])
		overlays_standing[new_item_index] = list()
	overlays_standing[new_item_index] += additional_appearance
	return additional_appearance

//MARK: Очистка
/mob/living/carbon/human/proc/clear_bodypart_overlays(update = TRUE, key)
	var/list/changed_layers
	if(isnull(key))
		layers_for_apply_effect = list()
	else
		if(!(key in layers_for_apply_effect))
			return FALSE
		layers_for_apply_effect -= key
		changed_layers = list(key)
	if(update)
		update_overlayed_parts(changed_layers)
	return TRUE

/mob/living/carbon/human/proc/remove_overlay_by_bodypart_key(key, need_update_body)
	return clear_bodypart_overlays(need_update_body, key)

#undef MUTANT_OVERLAY_CACHE_MAX
#undef MUTANT_OVERLAY_CACHE_EVICT
#undef OVERLAYS_LAYER_NAME_KEY_INDEX
#undef OVERLAYS_EFFECT_DATUM_INDEX
