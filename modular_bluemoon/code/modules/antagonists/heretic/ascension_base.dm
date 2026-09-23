/datum/status_effect/heretic_ascended
	id = "heretic_ascended"
	duration = -1
	tick_interval = 2 SECONDS
	alert_type = null
	examine_text = "<span class='warning'>SUBJECTPRONOUN держится неестественно стойко: дубинки и станы почти не действуют, свалить можно только изматыванием группой и стрельбой в упор. Светошумовые гранаты всё ещё сбивают с ног.</span>"
	var/added_max_health = 0
	var/last_damage_time = 0
	var/reentry = FALSE

/datum/status_effect/heretic_ascended/on_apply()
	. = ..()
	for(var/trait in list(TRAIT_HERETIC_ASCENDED, TRAIT_NOSOFTCRIT, TRAIT_TASED_RESISTANCE, TRAIT_IGNOREDAMAGESLOWDOWN, TRAIT_NOBREATH, TRAIT_RESISTCOLD, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE))
		ADD_TRAIT(owner, trait, REF(src))
	added_max_health = max(0, HERETIC_ASCENDED_MAX_HEALTH - owner.maxHealth)
	owner.setMaxHealth(owner.maxHealth + added_max_health)
	owner.updatehealth()
	if(ishuman(owner))
		var/mob/living/carbon/human/human = owner
		human.physiology.heretic_ascension_mod = HERETIC_ASCENDED_DAMAGE_MOD
		human.physiology.heretic_stamina_mod *= HERETIC_ASCENDED_STAMINA_MOD
	RegisterSignal(owner, COMSIG_LIVING_STATUS_STUN, PROC_REF(shorten_stun))
	RegisterSignal(owner, COMSIG_LIVING_STATUS_KNOCKDOWN, PROC_REF(shorten_knockdown))
	RegisterSignal(owner, COMSIG_LIVING_STATUS_PARALYZE, PROC_REF(shorten_paralyze))
	RegisterSignal(owner, COMSIG_LIVING_STATUS_IMMOBILIZE, PROC_REF(shorten_immobilize))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damaged))

/datum/status_effect/heretic_ascended/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_STATUS_KNOCKDOWN, COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_IMMOBILIZE, COMSIG_MOB_APPLY_DAMAGE))
	var/mob/living/carbon/human/human = owner
	if(ishuman(owner) && human.physiology)
		human.physiology.heretic_stamina_mod /= HERETIC_ASCENDED_STAMINA_MOD
		human.physiology.heretic_ascension_mod = 1
	// Снимаем только свою прибавку; предел, выставленный заново, ниже прежнего не опускаем.
	var/base_max_health = HERETIC_ASCENDED_MAX_HEALTH - added_max_health
	owner.setMaxHealth(max(owner.maxHealth - added_max_health, min(owner.maxHealth, base_max_health)))
	added_max_health = 0
	owner.updatehealth()
	REMOVE_TRAITS_IN(owner, REF(src))
	return ..()

/datum/status_effect/heretic_ascended/tick()
	if(owner.stat == DEAD || world.time - last_damage_time < HERETIC_ASCENDED_REGEN_DELAY)
		return
	owner.heal_overall_damage(HERETIC_ASCENDED_REGEN, HERETIC_ASCENDED_REGEN, only_organic = FALSE)

/datum/status_effect/heretic_ascended/proc/on_damaged(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage > 0 && (damagetype == BRUTE || damagetype == BURN))
		last_damage_time = world.time

// Stun() человека применяет stun_mod ещё до сигнала, поэтому повторный Stun() учёл бы его дважды.
/datum/status_effect/heretic_ascended/proc/shorten_stun(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	reentry = TRUE
	owner.SetStun(max(owner.AmountStun(), amount * HERETIC_ASCENDED_STUN_MOD), updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/datum/status_effect/heretic_ascended/proc/shorten_knockdown(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	reentry = TRUE
	owner.Knockdown(amount * HERETIC_ASCENDED_STUN_MOD, updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/datum/status_effect/heretic_ascended/proc/shorten_paralyze(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	reentry = TRUE
	owner.Paralyze(amount * HERETIC_ASCENDED_STUN_MOD, updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/datum/status_effect/heretic_ascended/proc/shorten_immobilize(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	reentry = TRUE
	owner.Immobilize(amount * HERETIC_ASCENDED_STUN_MOD, updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/// Разворачивает чужой снаряд, летящий в source, назад веером; allowed_flags ограничивает типы снарядов.
/proc/heretic_try_deflect(mob/living/source, real_attack, atom/object, attack_type, chance, list/allowed_flags)
	if(!real_attack || !(attack_type & ATTACK_TYPE_PROJECTILE) || !istype(object, /obj/item/projectile) || source.stat == DEAD)
		return null
	var/obj/item/projectile/projectile = object
	if(projectile.firer == source || (allowed_flags && !(projectile.flag in allowed_flags)) || !prob(chance))
		return null
	source.handle_projectile_attack_redirection(projectile, REDIRECT_METHOD_DEFLECT, silent = TRUE)
	return projectile
