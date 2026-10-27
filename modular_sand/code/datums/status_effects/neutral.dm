/datum/status_effect/dripping_cum
	id = "dripping_cum"
	status_type = STATUS_EFFECT_REFRESH
	duration = -1
	tick_interval = 5 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/dripping_cum
	var/datum/reagents/contents
	var/list/blood_DNA
	var/cum_in_anus = 0
	var/cum_in_vagina = 0
	var/anus_can_leak
	var/vagina_can_leak

/datum/status_effect/dripping_cum/on_creation(mob/living/carbon/human/new_owner, datum/reagents/add_or_merge, list/blood_DNA, obj/item/organ/genital/hole)
	. = ..()
	if(QDELETED(src) || !.)
		return
	if(!istype(new_owner) || !(istype(add_or_merge) && add_or_merge.total_volume > 0))
		qdel(src)
		return
	var/datum/reagent/consumable/semen/S = add_or_merge.has_reagent(/datum/reagent/consumable/semen)
	if(!S) // !! снять ограничения на тип семени, когда будут существовать настоящие капли различных жидкостей для пола
		qdel(src)
		return
	if(isnull(contents))
		contents = new(300, NO_REACT)
	if(istype(hole, /obj/item/organ/genital/anus))
		cum_in_anus += S.volume
	if(istype(hole, /obj/item/organ/genital/vagina))
		cum_in_vagina += S.volume
	add_or_merge.trans_id_to(contents, S.type, S.volume)
	if(blood_DNA)
		LAZYINITLIST(src.blood_DNA)
		src.blood_DNA |= blood_DNA

/datum/status_effect/dripping_cum/on_remove(mob/living/carbon/human/owner)
	qdel(contents)
	blood_DNA = null
	. = ..()

/datum/status_effect/dripping_cum/refresh(effect, datum/reagents/add_or_merge, list/blood_DNA, obj/item/organ/genital/hole)
	if(!(istype(add_or_merge) && add_or_merge.total_volume > 0))
		return
	var/datum/reagent/consumable/semen/S = add_or_merge.has_reagent(/datum/reagent/consumable/semen)
	if(!S) // !! снять ограничения на тип семени, когда будут существовать настоящие капли различных жидкостей для пола
		return
	if(istype(hole, /obj/item/organ/genital/anus))
		cum_in_anus += S.volume
	if(istype(hole, /obj/item/organ/genital/vagina))
		cum_in_vagina += S.volume
	add_or_merge.trans_id_to(contents, S.type, S.volume)
	if(blood_DNA)
		LAZYINITLIST(src.blood_DNA)
		src.blood_DNA |= blood_DNA

/datum/status_effect/dripping_cum/tick()
	if(contents.total_volume <= 0 || (cum_in_anus + cum_in_vagina <= 0))
		qdel(src)
		return
	if(!owner.alerts["dripping_cum"])
		var/atom/movable/screen/alert/status_effect/A = owner.throw_alert(id, alert_type)
		A.attached_effect = src
		linked_alert = A
	if(!can_drip())
		return
	var/turf/location = get_turf(owner)
	contents.reaction(location, volume_modifier = (1/contents.total_volume), show_message = FALSE)
	contents.remove_any()
	for(var/obj/effect/decal/cleanable/c in location)
		if(is_type_in_list(c, list(/obj/effect/decal/cleanable/semen, /obj/effect/decal/cleanable/semendrip)))
			c.transfer_blood_dna(blood_DNA)
	if(cum_in_anus > 0 && anus_can_leak)
		cum_in_anus--
		if(cum_in_anus < 0) // в любой момент из ниоткуда могут возникнуть очень странные дробные
			cum_in_vagina += cum_in_anus
			cum_in_anus = 0
	else if(cum_in_vagina > 0 && vagina_can_leak)
		cum_in_vagina--
		if(cum_in_vagina < 0)
			cum_in_anus += cum_in_vagina
			cum_in_vagina = 0

/datum/status_effect/dripping_cum/proc/can_drip()
	var/mob/living/carbon/human/human_owner = owner
	var/obj/item/clothing/under/clothes = human_owner.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	var/obj/item/organ/genital/anus/A = human_owner.getorganslot(ORGAN_SLOT_ANUS)
	var/obj/item/organ/genital/vagina/V = human_owner.getorganslot(ORGAN_SLOT_VAGINA)
	// This is completely recyclable.
	if(clothes)
		var/valid = FALSE
		if(is_type_in_typecache(clothes.type, GLOB.skirt_peekable))
			valid = TRUE
		else if(!CHECK_BITFIELD(clothes.body_parts_covered, GROIN))
			valid = TRUE
		if(!valid)
			return FALSE
	var/obj/item/clothing/suit/outer_clothing = human_owner.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(outer_clothing && CHECK_MULTIPLE_BITFIELDS(outer_clothing.body_parts_covered, CHEST | GROIN | LEGS | FEET))
		return FALSE
	var/obj/item/clothing/underwear/briefs/underwear = human_owner.get_item_by_slot(ITEM_SLOT_UNDERWEAR)
	if(underwear && CHECK_BITFIELD(underwear.body_parts_covered, GROIN))
		return FALSE
	if(human_owner.stat == DEAD)
		return FALSE
	if(human_owner.bodytemperature < TCRYO)
		return FALSE
	if(A && !((locate(/obj/item/buttplug) in A.contents) || (locate(/obj/item/dildo) in A.contents) || A.is_knotted))
		anus_can_leak = TRUE
	else
		anus_can_leak = FALSE
	if(V && !((locate(/obj/item/buttplug) in V.contents) || (locate(/obj/item/dildo) in V.contents) || V.is_knotted))
		vagina_can_leak = TRUE
	else
		vagina_can_leak = FALSE
	if(!(((cum_in_anus > 0) && anus_can_leak) || ((cum_in_vagina > 0) && vagina_can_leak)))
		return FALSE
	return TRUE

/atom/movable/screen/alert/status_effect/dripping_cum
	name = "Dripping Cum"
	desc = "Your last affairs left you dripping someone's seed."
	icon = 'modular_sand/icons/hud/screen_alert.dmi'
	icon_state = "dripping_cum"

/atom/movable/screen/alert/status_effect/dripping_cum/MouseEntered(location, control, params)
	desc = initial(desc)
	var/datum/status_effect/dripping_cum/DC = attached_effect
	if(DC)
		var/total_cum = DC.cum_in_anus + DC.cum_in_vagina
		desc += "<br>You feel like there is about [round(total_cum, 0.1)] units inside you. Or even more..."
		if(!DC.can_drip())
			desc += "<br>It seems you're not dripping anymore — maybe you're covered up?"
	else
		desc += "<br>Something seems wrong... you feel empty."
	..()

