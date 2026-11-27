/obj/item/organ/synthetic_radio
	name = "synthetic radio module"
	desc = "Модуль встроенной радиосистемы с панелью для ключей шифрования в голове синтетика."
	icon_state = "brain_implant"
	slot = ORGAN_SLOT_SYNTH_RADIO
	zone = BODY_ZONE_HEAD
	status = ORGAN_ROBOTIC
	organ_flags = ORGAN_SYNTHETIC
	w_class = WEIGHT_CLASS_TINY
	decay_factor = 0.02

	var/obj/item/radio/internal/synthetic/radio
	var/emp_damage = 0

/obj/item/organ/synthetic_radio/on_life(seconds, times_fired)
	var/was_emped = !!(organ_flags & ORGAN_SYNTHETIC_EMP)
	var/before = damage
	. = ..()
	if(was_emped)
		emp_damage += damage - before

/obj/item/organ/synthetic_radio/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(!. || !owner || !ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	radio = new /obj/item/radio/internal/synthetic(H)
	radio.organ = src
	H.synth_radio = radio
	if((H.ears || H.ears_extra) && H.dna?.species)
		H.dna.species.migrate_synth_headset_keys(H)
	radio.recalculateChannels()

/obj/item/organ/synthetic_radio/Remove(special = FALSE)
	var/mob/living/carbon/human/H = owner
	if(ishuman(H) && H.synth_radio == radio)
		if(radio)
			for(var/obj/item/encryptionkey/K in radio.keyslots)
				K.forceMove(get_turf(H))
			radio.keyslots = null
		H.synth_radio = null
		H.synth_head_panel_open = FALSE
	QDEL_NULL(radio)
	. = ..()

/obj/item/organ/synthetic_radio/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF || !owner)
		return
	var/before = damage
	applyOrganDamage(0.25 * severity)
	emp_damage += damage - before
	if(prob(30))
		organ_flags |= ORGAN_SYNTHETIC_EMP
	if(radio)
		radio.start_jamming()
		radio.recalculateChannels()
	to_chat(owner, span_warning("Встроенная радиосистема повреждена ЭМИ!"))

/obj/item/organ/synthetic_radio/clear_emp_damage()
	if(QDELETED(src))
		return
	if(emp_damage)
		applyOrganDamage(-emp_damage)
		emp_damage = 0
	if(damage < maxHealth)
		organ_flags &= ~ORGAN_FAILING
	..()
