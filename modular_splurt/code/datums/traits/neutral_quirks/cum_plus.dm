/datum/quirk/cum_plus
	name = "Сверхпродуктивные Гениталии"
	desc = "Ваши гениталии производят и вмещают больше, чем обычно."
	value = 0
	flavor_quirk = TRUE
	gain_text = span_notice("Вы чувствуете давление в паху.")
	lose_text = span_notice("Вы чувствуете, как ваш пах стал легче.")
	medical_record_text = "Гениталии пациента демонстрируют высокую продуктивность."
	var/obj/item/organ/genital/testicles/modified_organ

/datum/quirk/cum_plus/add()
	RegisterSignal(quirk_holder, COMSIG_MOB_ORGAN_ADD, PROC_REF(sync_organ_bonus))
	RegisterSignal(quirk_holder, COMSIG_MOB_ORGAN_REMOVE, PROC_REF(sync_organ_bonus))
	sync_organ_bonus()

/datum/quirk/cum_plus/remove()
	UnregisterSignal(quirk_holder, list(COMSIG_MOB_ORGAN_ADD, COMSIG_MOB_ORGAN_REMOVE))
	if(!QDELETED(modified_organ))
		modified_organ.update_fluid_reserve()
		modified_organ.fluid_mult -= 0.5
		modified_organ.fluid_max_volume /= 1.75
		modified_organ.stored_fluid = min(modified_organ.stored_fluid, modified_organ.fluid_max_volume)
	modified_organ = null

/datum/quirk/cum_plus/proc/sync_organ_bonus(datum/source)
	SIGNAL_HANDLER
	var/mob/living/carbon/M = quirk_holder
	if(!M)
		return
	var/obj/item/organ/genital/testicles/current = M.getorganslot(ORGAN_SLOT_TESTICLES)
	if(current == modified_organ)
		return
	if(!QDELETED(modified_organ))
		modified_organ.update_fluid_reserve()
		modified_organ.fluid_mult -= 0.5
		modified_organ.fluid_max_volume /= 1.75
		modified_organ.stored_fluid = min(modified_organ.stored_fluid, modified_organ.fluid_max_volume)
	modified_organ = current
	if(!QDELETED(current))
		current.update_fluid_reserve()
		current.fluid_mult += 0.5
		current.fluid_max_volume *= 1.75
