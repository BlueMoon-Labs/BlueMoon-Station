GLOBAL_LIST_INIT(mutant_overlays_cache, list())

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
)


//-----MUTABLE_APPERANCE-----

//Я не знаю, как иначе передавать эффекты, не сохраняя их. Поэтому создал переменные
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

//---HUMAN PROCS---

/mob/living/carbon/human
	var/list/mutant_part_appearances = list() //Хранит списки по ключам слоя. tail = list(tail_FRONT, tail_ADJ). Содержимое это mutable_apperance
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

/mob/living/carbon/human/proc/apply_overlay_on_bodypart(layer, color, effect_datum)
	if(!(layer in layers_for_apply_effect))
		layers_for_apply_effect[layer] = list(layer, color, effect_datum)

/**
 * Потолок кэша готовых иконок оверлея и сколько вытесняется при переполнении.
 *
 * Прежние 30 записей с вытеснением половины были меньше, чем нужно ОДНОМУ носителю: ключ
 * состоит из иконки, стейта, имени эффекта и цвета, а слоёв у мутантных частей до
 * пятнадцати - хвост, морда, уши, крылья, тавр, рога, волосы плюс генитали. Двое в МОДах
 * уже гоняли кэш по кругу, и попадания не было практически никогда.
 */
#define MUTANT_OVERLAY_CACHE_MAX 1024
/// Четверть кэша, самые старые.
#define MUTANT_OVERLAY_CACHE_EVICT (MUTANT_OVERLAY_CACHE_MAX / 4)

/mob/living/carbon/human/proc/clear_old_cache_if_it_need()
	if(GLOB.mutant_overlays_cache.len > MUTANT_OVERLAY_CACHE_MAX)
		GLOB.mutant_overlays_cache.Cut(1, MUTANT_OVERLAY_CACHE_EVICT + 1)

/mob/living/carbon/human/proc/get_overlay_from_cache(key)
	return GLOB.mutant_overlays_cache[key]

/mob/living/carbon/human/proc/generate_accessory_cache_key(mutable_appearance/accessory_overlay, datum/overlay_effect/effect_datum)
	return "[accessory_overlay?.icon][accessory_overlay?.icon_state][effect_datum?.name][effect_datum?.color]"

/**
 * Собирает оверлей мутантной части с наложенным эффектом, переиспользуя готовую иконку.
 *
 * КЭШИРУЕТСЯ ИКОНКА, А НЕ ОВЕРЛЕЙ. Раньше в кэш клался готовый /mutable_appearance, а
 * читался он в переменную типа /icon и подставлялся в `icon = ...` нового оверлея. Попадание
 * поэтому не просто не экономило работу - оно записывало в поле icon датум оверлея вместо
 * иконки, и клиент на этом месте рисовал что придётся. Ровно так на проде и выглядели
 * "случайные спрайты на людях", пропавшие шляпы и чужие текстуры крови (28.08.2026).
 *
 * Промах при этом стоил дорого и был почти всегда (кэш на 30 записей при пятнадцати слоях
 * на одного носителя): icon() на каждый вызов - это НОВАЯ рантайм-иконка со ВСЕМИ
 * направлениями и кадрами стейта, а рантайм-иконка, попавшая в appearance, уезжает
 * отдельным ресурсом КАЖДОМУ видящему клиенту и живёт у него до конца сессии. Прок зовётся
 * из handle_mutant_bodyparts - самого дорогого по self прока в профиле раунда, - то есть на
 * каждой перерисовке носителя МОДа, для каждого его мутантного слоя.
 *
 * Исходная иконка теперь создаётся ТОЛЬКО при промахе: на попадании она не нужна вовсе.
 */
/mob/living/carbon/human/proc/use_effect_by_params(mutable_appearance/accessory_overlay, list/overlay_params)
	var/datum/overlay_effect/effect_datum = overlay_params[3]
	var/layer = overlay_params[1]
	var/cache_list_key = generate_accessory_cache_key(accessory_overlay, effect_datum)
	var/icon/template = get_overlay_from_cache(cache_list_key)

	if(!template)
		// Под стражем: промах кэша строит рантайм-иконку со всеми направлениями и кадрами,
		// а отказ /icon/New() обрывает всю перерисовку носителя молча и до /world/Error не
		// доходит. Пустышка в кэш НЕ пишется - иначе слой пропал бы до конца раунда.
		try
			// get_overlayed_icon() правит иконку НА МЕСТЕ (ColorTone и Blend мутируют
			// приёмник), поэтому кормить его можно только свежесозданной копией.
			//
			// fcopy_rsc, как у соседних кэшей (clothing.dm, atoms.dm, species.dm): в кэше
			// должен лежать неизменяемый слепок, который переиспользуется, а не рантайм-иконка,
			// которую нечем защитить от правки на месте следующим вызовом.
			template = fcopy_rsc(get_overlayed_icon(icon(accessory_overlay.icon, accessory_overlay.icon_state), effect_datum))
			GLOB.mutant_overlays_cache[cache_list_key] = template
			clear_old_cache_if_it_need()
		catch(var/exception/icon_error)
			template = note_icon_alloc_failure("оверлей мутантной части [accessory_overlay.icon_state] с эффектом [effect_datum?.name]", icon_error)

	var/mutable_appearance/overlay_MA = mutable_appearance(icon = template, layer = accessory_overlay.layer, plane = accessory_overlay.plane, alpha = LIGHTING_PLANE_ALPHA_VISIBLE, appearance_flags = accessory_overlay.appearance_flags, color = effect_datum.color, pixel_x = accessory_overlay.pixel_x, pixel_y = accessory_overlay.pixel_y, blend_mode=BLEND_OVERLAY)
	overlay_MA.name = "[layer]_[accessory_overlay.icon_state]"

	var/target_layer = (layer in OVERLAY_GENITAL_LIST) ? GENITAL_EFFECT_LAYER : BODYPART_EFFECT_LAYER
	if(!overlays_standing[target_layer])
		overlays_standing[target_layer] = list()
	overlays_standing[target_layer] += overlay_MA
	return overlay_MA

/mob/living/carbon/human/proc/apply_bodypart_overlays(list/layers, update = TRUE, datum/overlay_effect/effect_datum)
	var/list/target_layers = layers ? layers : (OVERLAY_LAYERS + OVERLAY_GENITAL_LIST)
	var/datum/overlay_effect/target_datum = effect_datum ? effect_datum : new /datum/overlay_effect/mod_effect
	for(var/layer in target_layers)
		apply_overlay_on_bodypart(layer, color, target_datum)
	if(update)
		update_mutant_bodyparts()

/mob/living/carbon/human/proc/clear_bodypart_overlays(update = TRUE)
	layers_for_apply_effect = list()
	if(update)
		update_mutant_bodyparts()

/mob/living/carbon/human/proc/remove_overlay_by_bodypart_key(key, need_update_body)
	if(key in layers_for_apply_effect)
		layers_for_apply_effect -= key
		if(need_update_body)
			update_mutant_bodyparts()
		return TRUE
	return FALSE

/datum/species/proc/update_overlay_by_key(key, mob/living/carbon/human/H, mutable_appearance/accessory_overlay)

	if(!H.layers_for_apply_effect[key])
		return FALSE

	var/overlay_params = H.layers_for_apply_effect[key]
	accessory_overlay = H.use_effect_by_params(accessory_overlay, overlay_params)

/datum/species/proc/save_part_appearance(mob/living/carbon/human/H, mutant_part_string, accessory_overlay)
	if(!H.mutant_part_appearances[mutant_part_string])
		H.mutant_part_appearances[mutant_part_string] = list()
	H.mutant_part_appearances[mutant_part_string] += accessory_overlay

/mob/living/carbon/human/proc/get_appearance_by_layer(layer)
	return mutant_part_appearances[layer]

#undef MUTANT_OVERLAY_CACHE_MAX
#undef MUTANT_OVERLAY_CACHE_EVICT
