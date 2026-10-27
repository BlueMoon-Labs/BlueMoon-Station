/datum/species/ipc/hk
	/// Горят ли глаза на последней отрисовке тела: перерисовка только при смене.
	var/eyes_drawn = FALSE
	var/eyes_blinked_off = FALSE
	/// Бронеплиты HK-47: видны на корпусе, кроме времени маскировки.
	var/armor_plates = FALSE
	var/eye_blink_ticks = 0
	/// Глаза темнеют, пока ЭМИ держит шасси.
	var/emp_blackout = FALSE
	var/eyes_reprogrammed = FALSE
	var/recolor_on_reprogram = TRUE

/// Эмиссив виден, только пока виден сам турф: в полной темноте дальше see_in_dark глаза выдаёт этот свет.
/// Белый и слабый: цветной оверлейный свет перекрашивает шасси умножением.
/obj/effect/dummy/lighting_obj/moblight/hk_eyes
	name = "HK eye glow"
	light_power = 0.1

/datum/species/ipc/hk/handle_body(mob/living/carbon/human/droid, block_recursive_calls = FALSE)
	. = ..()
	var/list/extras = hk_eye_overlays(droid)
	eyes_drawn = length(extras) > 0
	var/obj/effect/dummy/lighting_obj/moblight/hk_eyes/glow = locate() in droid
	glow?.set_light_on(eyes_drawn)
	if(armor_plates && !HAS_TRAIT(droid, TRAIT_HK47_DISGUISED))
		extras += mutable_appearance('modular_bluemoon/icons/mob/human/hk_droid_plates.dmi', "hk_plates", -BODY_ADJ_UPPER_LAYER)
	if(!length(extras))
		return
	var/list/standing = droid.overlays_standing[BODY_LAYER]
	droid.remove_overlay(BODY_LAYER)
	droid.overlays_standing[BODY_LAYER] = (standing || list()) + extras
	droid.apply_overlay(BODY_LAYER)

/datum/species/ipc/hk/spec_life(mob/living/carbon/human/droid)
	. = ..()
	if(droid.InCritical())
		if(++eye_blink_ticks >= HK_EYE_BLINK_TICKS)
			eye_blink_ticks = 0
			eyes_blinked_off = !eyes_blinked_off
	else
		eye_blink_ticks = 0
		eyes_blinked_off = FALSE
	refresh_eyes(droid)

/datum/species/ipc/hk/spec_death(gibbed, mob/living/carbon/human/droid)
	. = ..()
	if(!gibbed)
		refresh_eyes(droid)

/datum/species/ipc/hk/proc/refresh_eyes(mob/living/carbon/human/droid)
	if(eyes_lit(droid) != eyes_drawn)
		droid.update_body()

/datum/species/ipc/hk/proc/eyes_lit(mob/living/carbon/human/droid)
	if(!hk_model || eyes_blinked_off || droid.stat == DEAD || HAS_TRAIT(droid, TRAIT_HUSK))
		return FALSE
	if(emp_blackout && droid.IsParalyzed())
		return FALSE
	if(!droid.getorganslot(ORGAN_SLOT_EYES) || !droid.get_bodypart(BODY_ZONE_HEAD))
		return FALSE
	return TRUE

/datum/species/ipc/hk/proc/hk_eye_overlays(mob/living/carbon/human/droid)
	. = list()
	if(!eyes_lit(droid))
		return
	var/mutable_appearance/eyes = mutable_appearance(override_bp_icon, "[hk_model]_eyes", -BODY_LAYER)
	eyes.category = "HEAD"
	if(eyes_reprogrammed)
		eyes.color = HK_REPROGRAMMED_EYE_MATRIX
	. += eyes
	. += emissive_copy(eyes, offset_spokesman = droid)
