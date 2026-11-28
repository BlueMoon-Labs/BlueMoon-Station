#define HERETIC_EMERGENCE_FILTER "heretic_emergence"
#define HERETIC_EMERGENCE_FILTER_PRIORITY 9
#define HERETIC_EMERGENCE_GLOW_FILTER "heretic_emergence_glow"
#define HERETIC_EMERGENCE_GLOW_PRIORITY 10
#define HERETIC_EMERGENCE_GLOW_ALPHA "99"
#define HERETIC_EMERGENCE_GLOW_MIN 1
#define HERETIC_EMERGENCE_GLOW_MAX 3
#define HERETIC_EMERGENCE_PULSE (0.6 SECONDS)
#define HERETIC_EMERGENCE_HIT_FEEDBACK (0.5 SECONDS)

/datum/status_effect/heretic_ascended
	id = "heretic_ascended"
	duration = -1
	tick_interval = 2 SECONDS
	alert_type = null
	examine_text = "<span class='warning'>SUBJECTPRONOUN держится неестественно стойко: дубинки, станы и снотворное почти не действуют, свалить можно только изматыванием группой и стрельбой в упор. Когда спадёт завеса явления, светошумовые гранаты снова сбивают с ног, а разбить клинок и скрыться SUBJECTPRONOUN уже не может.</span>"
	var/added_max_health = 0
	var/last_damage_time = 0
	var/reentry = FALSE
	/// Идёт явление: оглушения не действуют, урон ослаблен сильнее обычного.
	var/emerging = FALSE

/datum/status_effect/heretic_ascended/on_apply()
	. = ..()
	for(var/trait in list(TRAIT_HERETIC_ASCENDED, TRAIT_NOSOFTCRIT, TRAIT_TASED_RESISTANCE, TRAIT_IGNOREDAMAGESLOWDOWN, TRAIT_NOBREATH, TRAIT_RESISTCOLD, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE))
		ADD_TRAIT(owner, trait, REF(src))
	added_max_health = max(0, HERETIC_ASCENDED_MAX_HEALTH - owner.maxHealth)
	owner.setMaxHealth(owner.maxHealth + added_max_health)
	owner.updatehealth()
	refresh_damage_mod()
	if(ishuman(owner))
		var/mob/living/carbon/human/human = owner
		human.physiology.heretic_stamina_mod *= HERETIC_ASCENDED_STAMINA_MOD
	RegisterSignal(owner, COMSIG_LIVING_STATUS_STUN, PROC_REF(shorten_stun))
	RegisterSignal(owner, COMSIG_LIVING_STATUS_KNOCKDOWN, PROC_REF(shorten_knockdown))
	RegisterSignal(owner, COMSIG_LIVING_STATUS_PARALYZE, PROC_REF(shorten_paralyze))
	RegisterSignal(owner, COMSIG_LIVING_STATUS_IMMOBILIZE, PROC_REF(shorten_immobilize))
	RegisterSignal(owner, COMSIG_LIVING_STATUS_UNCONSCIOUS, PROC_REF(shorten_unconscious))
	RegisterSignal(owner, COMSIG_LIVING_STATUS_SLEEP, PROC_REF(block_sleep))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damaged))

/datum/status_effect/heretic_ascended/on_remove()
	owner.remove_status_effect(/datum/status_effect/heretic_emergence)
	UnregisterSignal(owner, list(COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_STATUS_KNOCKDOWN, COMSIG_LIVING_STATUS_PARALYZE, COMSIG_LIVING_STATUS_IMMOBILIZE, COMSIG_LIVING_STATUS_UNCONSCIOUS, COMSIG_LIVING_STATUS_SLEEP, COMSIG_MOB_APPLY_DAMAGE))
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
	if(owner.stat == DEAD)
		return
	if(iscarbon(owner) && owner.blood_volume && owner.blood_volume < BLOOD_VOLUME_NORMAL)
		owner.blood_volume = min(BLOOD_VOLUME_NORMAL, owner.blood_volume + HERETIC_ASCENDED_BLOOD_REGEN)
	if(world.time - last_damage_time < HERETIC_ASCENDED_REGEN_DELAY)
		return
	owner.heal_overall_damage(HERETIC_ASCENDED_REGEN, HERETIC_ASCENDED_REGEN, only_organic = FALSE)

/datum/status_effect/heretic_ascended/proc/refresh_damage_mod()
	var/mob/living/carbon/human/human = owner
	if(ishuman(human) && human.physiology)
		human.physiology.heretic_ascension_mod = HERETIC_ASCENDED_DAMAGE_MOD * (emerging ? HERETIC_ASCENDED_EMERGENCE_DAMAGE_MOD : 1)

/datum/status_effect/heretic_ascended/proc/on_damaged(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage > 0 && (damagetype == BRUTE || damagetype == BURN))
		last_damage_time = world.time

// Stun() человека применяет stun_mod ещё до сигнала, поэтому повторный Stun() учёл бы его дважды.
/datum/status_effect/heretic_ascended/proc/shorten_stun(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	if(emerging)
		return COMPONENT_NO_STUN
	reentry = TRUE
	owner.SetStun(max(owner.AmountStun(), amount * HERETIC_ASCENDED_STUN_MOD), updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/datum/status_effect/heretic_ascended/proc/shorten_knockdown(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	if(emerging)
		return COMPONENT_NO_STUN
	reentry = TRUE
	owner.Knockdown(amount * HERETIC_ASCENDED_STUN_MOD, updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/datum/status_effect/heretic_ascended/proc/shorten_paralyze(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	if(emerging)
		return COMPONENT_NO_STUN
	reentry = TRUE
	owner.Paralyze(amount * HERETIC_ASCENDED_STUN_MOD, updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/datum/status_effect/heretic_ascended/proc/shorten_immobilize(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	if(emerging)
		return COMPONENT_NO_STUN
	reentry = TRUE
	owner.Immobilize(amount * HERETIC_ASCENDED_STUN_MOD, updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

/datum/status_effect/heretic_ascended/proc/shorten_unconscious(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(reentry || amount <= 0)
		return NONE
	if(emerging)
		return COMPONENT_NO_STUN
	reentry = TRUE
	owner.Unconscious(amount * HERETIC_ASCENDED_STUN_MOD, updating, ignore_canstun)
	reentry = FALSE
	return COMPONENT_NO_STUN

// Снотворное повторяет Sleeping() каждый тик, поэтому укороченный сон всё равно держал бы вознесённого лёжа.
/datum/status_effect/heretic_ascended/proc/block_sleep(datum/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	return amount > 0 ? COMPONENT_NO_STUN : NONE

/// Явление: первые секунды вознёсшегося. Видимая завеса, оглушения не действуют, урон слабее; потом обычная уязвимость.
/datum/status_effect/heretic_emergence
	id = "heretic_emergence"
	duration = HERETIC_ASCENDED_EMERGENCE_TIME
	tick_interval = -1
	alert_type = null
	on_remove_on_mob_delete = TRUE
	examine_text = "<span class='warning'>Тело окутывает дрожащая завеса явления: пули, лазеры и удары её почти не пробивают, оглушения не действуют. Завеса вот-вот спадёт - тогда и бейте.</span>"
	var/ink = COLOR_WHITE
	var/datum/heretic_path/veil_path
	var/obj/effect/abstract/heretic_particle_holder/motes
	/// on_remove зовётся и после отказа on_apply: снимать можно только наложенное.
	var/applied = FALSE
	COOLDOWN_DECLARE(hit_feedback)

/datum/status_effect/heretic_emergence/on_apply()
	. = ..()
	var/datum/status_effect/heretic_ascended/ascended = owner.has_status_effect(/datum/status_effect/heretic_ascended)
	if(!ascended || owner.stat == DEAD)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(owner)
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic?.selected_path]
	ink = path?.book_ink || COLOR_WHITE
	veil_path = path
	applied = TRUE
	ascended.emerging = TRUE
	ascended.refresh_damage_mod()
	var/mob/living/carbon/human/human = owner
	if(ishuman(human))
		human.physiology.heretic_stamina_mod *= HERETIC_ASCENDED_EMERGENCE_DAMAGE_MOD
	owner.SetAllImmobility(0)
	owner.SetUnconscious(0)
	// Тонкий контур и дрожащее свечение под телом: ни то, ни другое не заливает просветы между руками и ногами.
	if(!path || path.emergence_filters)
		owner.add_filter(HERETIC_EMERGENCE_FILTER, HERETIC_EMERGENCE_FILTER_PRIORITY, outline_filter(size = 1, color = ink))
		owner.add_filter(HERETIC_EMERGENCE_GLOW_FILTER, HERETIC_EMERGENCE_GLOW_PRIORITY, drop_shadow_filter(x = 0, y = 0, size = HERETIC_EMERGENCE_GLOW_MIN, color = "[ink][HERETIC_EMERGENCE_GLOW_ALPHA]"))
		animate(owner.get_filter(HERETIC_EMERGENCE_GLOW_FILTER), size = HERETIC_EMERGENCE_GLOW_MAX, time = HERETIC_EMERGENCE_PULSE, loop = -1, easing = SINE_EASING)
		animate(size = HERETIC_EMERGENCE_GLOW_MIN, time = HERETIC_EMERGENCE_PULSE, easing = SINE_EASING)
	motes = heretic_vfx_attach_particles(owner, path?.vfx_particles, behind = TRUE)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_hit))
	owner.visible_message(span_danger("Вокруг [owner] смыкается дрожащая завеса: пули и удары её почти не пробивают, пока она держится!"), span_eldritch("Завеса явления укрывает вас на [DisplayTimeText(HERETIC_ASCENDED_EMERGENCE_TIME)]: оглушения не действуют, урон ослаблен. Потом вы снова уязвимы."))
	playsound(owner, 'modular_bluemoon/sound/heretic/common/emergence_on.ogg', 70, TRUE)
	log_game("[key_name(owner)] входит в явление вознесения на [DisplayTimeText(HERETIC_ASCENDED_EMERGENCE_TIME)] в [AREACOORD(owner)].")

/datum/status_effect/heretic_emergence/on_remove()
	if(!applied)
		return ..()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE)
	var/datum/status_effect/heretic_ascended/ascended = owner.has_status_effect(/datum/status_effect/heretic_ascended)
	if(ascended)
		ascended.emerging = FALSE
		ascended.refresh_damage_mod()
	var/mob/living/carbon/human/human = owner
	if(ishuman(human) && human.physiology)
		human.physiology.heretic_stamina_mod /= HERETIC_ASCENDED_EMERGENCE_DAMAGE_MOD
	owner.remove_filter(list(HERETIC_EMERGENCE_FILTER, HERETIC_EMERGENCE_GLOW_FILTER))
	heretic_vfx_release_particles(owner, motes)
	motes = null
	if(owner.stat != DEAD && !QDELETED(owner))
		owner.visible_message(span_danger("Завеса вокруг [owner] рассеивается: теперь [owner] снова можно ранить!"), span_warning("Завеса явления спала: вы снова уязвимы."))
		playsound(owner, 'modular_bluemoon/sound/heretic/common/emergence_off.ogg', 60, TRUE)
		if(veil_path?.wave_type)
			new veil_path.wave_type(get_turf(owner))
		else
			heretic_vfx_shockwave(owner, ink, 2, 0.6 SECONDS)
	log_game("[key_name(owner)] выходит из явления вознесения в [AREACOORD(owner)].")
	return ..()

/datum/status_effect/heretic_emergence/proc/on_hit(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage <= 0 || !COOLDOWN_FINISHED(src, hit_feedback))
		return
	COOLDOWN_START(src, hit_feedback, HERETIC_EMERGENCE_HIT_FEEDBACK)
	heretic_vfx_pulse(owner, ink, 4, 0.3 SECONDS)
	playsound(owner, HERETIC_EMERGENCE_HIT_SFX, 25, TRUE, SILENCED_SOUND_EXTRARANGE)

/// Разворачивает чужой снаряд, летящий в source, назад веером; allowed_flags ограничивает типы снарядов.
/proc/heretic_try_deflect(mob/living/source, real_attack, atom/object, attack_type, chance, list/allowed_flags)
	if(!real_attack || !(attack_type & ATTACK_TYPE_PROJECTILE) || !istype(object, /obj/item/projectile) || source.stat == DEAD)
		return null
	var/obj/item/projectile/projectile = object
	if(projectile.firer == source || (allowed_flags && !(projectile.flag in allowed_flags)) || !prob(chance))
		return null
	source.handle_projectile_attack_redirection(projectile, REDIRECT_METHOD_DEFLECT, silent = TRUE)
	return projectile

#undef HERETIC_EMERGENCE_FILTER
#undef HERETIC_EMERGENCE_FILTER_PRIORITY
#undef HERETIC_EMERGENCE_GLOW_FILTER
#undef HERETIC_EMERGENCE_GLOW_PRIORITY
#undef HERETIC_EMERGENCE_GLOW_ALPHA
#undef HERETIC_EMERGENCE_GLOW_MIN
#undef HERETIC_EMERGENCE_GLOW_MAX
#undef HERETIC_EMERGENCE_PULSE
#undef HERETIC_EMERGENCE_HIT_FEEDBACK
