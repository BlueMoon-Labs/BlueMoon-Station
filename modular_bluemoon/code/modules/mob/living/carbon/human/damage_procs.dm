#define LAST_HURT_STAMINA_HIT 10

/mob/living/carbon/human/adjustOxyLoss(amount, updating_health, forced)
	. = ..()
	if(!.)
		return
	if(!has_dna())
		return
	if(HAS_TRAIT(src, TRAIT_CHOKE_SLUT))
		if(amount <= 0)
			return
		if(stat >= DEAD)
			return
		if(HAS_TRAIT(src, TRAIT_NOBREATH))
			return
		if(stat == CONSCIOUS)
			// Oxy damage is not impressive, usually doesn't even exceeds 5. By default we need 300 lust to cum, futhermore lust constantly decreases.
			// So we add fat multiplier to make it noticeable.
			handle_post_sex(amount*5)
		else // proc/handle_post_sex() won't work here if mob is not CONSCIOUS
			add_lust(amount*5)
			if(get_lust() >= get_climax_threshold()) // BLUEMOON EDIT
				mob_climax(forced_climax=TRUE, cause="choke_slut")

// Версия carbon.dm не зовёт ..(), поэтому след урона ставится у человека: все его версии зовут ..().
/mob/living/carbon/human/updatehealth()
	var/health_before = health
	var/stamina_before = staminaloss
	. = ..()
	if(health < health_before || staminaloss - stamina_before >= LAST_HURT_STAMINA_HIT)
		last_hurt_at = world.time

#undef LAST_HURT_STAMINA_HIT
