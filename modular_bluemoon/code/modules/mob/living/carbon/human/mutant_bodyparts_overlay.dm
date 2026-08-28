GLOBAL_LIST_INIT(mutant_overlays_cache, list())
#define MUTANT_OVERLAY_CACHE_MAX 1024
#define MUTANT_OVERLAY_CACHE_EVICT (MUTANT_OVERLAY_CACHE_MAX / 4)

//overlay_params ключи
#define OVERLAYS_LAYER_NAME_KEY_INDEX 1
#define OVERLAYS_EFFECT_DATUM_INDEX 3

#define EXTRA_LAYER_MODIFICATOR 40

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

#define OVERLAY_LAYERS list( \
	SNOUT_APPEARANCE, \
	TAIL_APPEARANCE, \
	EARS_APPEARANCE, \
	INSECT_WINGS_APPEARANCE, \
	INSECT_FLUFF_APPEARANCE, \
	TAUR_APPEARANCE, \
	HORNS_APPEARANCE, \
	HAIR_APPEARANCE, \
)

#define OVERLAY_GENITAL_LIST list( \
	BREASTS_APPEARANCE, \
	VAGINA_APPEARANCE, \
	TESTICLES_APPEARANCE, \
	PENIS_APPEARANCE, \
	BREASTS_APPEARANCE, \
	BUTT_APPEARANCE, \
	BELLY_APPEARANCE, \
	SNOUT_APPEARANCE, \
)

//К сожалению, некоторые части тела не просвечивают через одежду, даже если они видны по is_not_visible
//приходится искусственно выявлять их и повышать layer вручную.
#define NEED_EXTRA_LAYER_MODIFICATOR list(\
	BREASTS_APPEARANCE = 100, \
	VAGINA_APPEARANCE = 100, \
	TESTICLES_APPEARANCE = 100, \
	PENIS_APPEARANCE = 100, \
	BREASTS_APPEARANCE = 100, \
	BUTT_APPEARANCE = 100, \
	BELLY_APPEARANCE = 100, \
	SNOUT_APPEARANCE = 40, \
)

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

/mob/living/carbon/human/proc/write_overlay_MA_in_GLOB_cache(mutable_appearance/MA, cache_key)
	GLOB.mutant_overlays_cache[cache_key] = MA
	clear_old_cache_if_it_need()

//---MARK: HUMAN PROCS
/mob/living/carbon/human
	var/list/layers_for_apply_effect = list()

//По сути, просто берёт иконку, красит её в цвет, в половину меняет прозрачность и накладывает эффект через блэнд.
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
	var/icon/template = get_overlayed_icon(icon(accessory_overlay.icon, accessory_overlay.icon_state), effect_datum)
	var/mutable_appearance/cached_MA = get_overlay_from_cache(cache_list_key)
	var/mutable_appearance/overlay_MA

	var/MA_layer = accessory_overlay.layer
	if(layer_name in NEED_EXTRA_LAYER_MODIFICATOR)
		MA_layer += NEED_EXTRA_LAYER_MODIFICATOR[layer_name]

	overlay_MA = cached_MA ? cached_MA : mutable_appearance(icon = template, layer = MA_layer, plane = accessory_overlay.plane, alpha = LIGHTING_PLANE_ALPHA_VISIBLE, appearance_flags = accessory_overlay.appearance_flags, color = effect_datum.color, pixel_x = accessory_overlay.pixel_x, pixel_y = accessory_overlay.pixel_y, blend_mode=BLEND_OVERLAY)
	var/target_layer = (layer_name in OVERLAY_GENITAL_LIST) ? GENITAL_EFFECT_LAYER : BODYPART_EFFECT_LAYER

	return add_new_overlay_effect_in_standing(target_layer, overlay_MA, cache_list_key)

//MARK: Обновление и применение
/datum/species/proc/update_overlay_by_key(key, mob/living/carbon/human/H, mutable_appearance/accessory_overlay)
	if(!H.layers_for_apply_effect[key])
		return FALSE
	var/overlay_params = H.layers_for_apply_effect[key]
	accessory_overlay = H.use_effect_by_params(accessory_overlay, overlay_params)

/mob/living/carbon/human/proc/update_overlayed_parts(force_update)
	if(check_for_update(OVERLAY_LAYERS) || force_update)
		update_mutant_bodyparts()
	if(check_for_update(OVERLAY_GENITAL_LIST) || force_update)
		update_genitals()

/mob/living/carbon/human/proc/apply_bodypart_overlays(list/layers, update = TRUE, datum/overlay_effect/effect_datum)
	var/list/target_layers = layers ? layers : (OVERLAY_LAYERS + OVERLAY_GENITAL_LIST)
	var/datum/overlay_effect/target_datum = effect_datum ? effect_datum : new /datum/overlay_effect/mod_effect
	for(var/layer in target_layers)
		apply_overlay_on_bodypart(layer, color, target_datum)
	if(update)
		update_overlayed_parts()

/mob/living/carbon/human/proc/apply_overlay_on_bodypart(layer, color, effect_datum)
	if(!(layer in layers_for_apply_effect))
		layers_for_apply_effect[layer] = list(layer, color, effect_datum)

/mob/living/carbon/human/proc/add_new_overlay_effect_in_standing(new_item_index, mutable_appearance/additional_appearance, cache_list_key)
	if(!overlays_standing[new_item_index])
		overlays_standing[new_item_index] = list()
	overlays_standing[new_item_index] += additional_appearance

	write_overlay_MA_in_GLOB_cache(additional_appearance, cache_list_key)
	return additional_appearance

//MARK: Очистка
/mob/living/carbon/human/proc/clear_bodypart_overlays(update = TRUE, key)
	var/force_update = FALSE
	if(!key)
		layers_for_apply_effect = list()
		force_update = TRUE
	if(key in layers_for_apply_effect)
		layers_for_apply_effect -= key
	if(update)
		update_overlayed_parts(force_update)

/mob/living/carbon/human/proc/remove_overlay_by_bodypart_key(key, need_update_body)
	clear_bodypart_overlays(FALSE, key)
	return need_update_body ? update_overlayed_parts() : TRUE

//MARK: Дополнительные проверки
//Нужно проверять, есть ли целевые слои в тех, которые реально использовались.
// Если что-то не было изменено, то зачем это обновлять?
/mob/living/carbon/human/proc/check_for_update(target_layers_to_compare)
	for(var/layer in layers_for_apply_effect)
		if(layer in target_layers_to_compare)
			return TRUE

#undef MUTANT_OVERLAY_CACHE_MAX
#undef MUTANT_OVERLAY_CACHE_EVICT
