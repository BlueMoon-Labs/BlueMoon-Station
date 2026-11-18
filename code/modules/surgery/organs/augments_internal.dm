#define ANTI_STUN_SET_AMOUNT 40

/obj/item/organ/cyberimp
	name = "cybernetic implant"
	desc = "A state-of-the-art implant that improves a baseline's functionality."
	status = ORGAN_ROBOTIC
	organ_flags = ORGAN_SYNTHETIC
	var/implant_color = "#FFFFFF"
	var/implant_overlay
	///Makes the implant invisible to health analyzers and medical HUDs.
	var/syndicate_implant = FALSE
	/// Icon of the bodypart overlay we're going to be applying to our owner (on their body)
	var/aug_icon = 'icons/mob/human/species/misc/bodypart_overlay_augmentations.dmi'
	/// Icon state of the bodypart overlay we're going to be applying to our owner (on their body)
	var/aug_overlay = null
	/// Does the implant also have an emissive (glowing) overlay rendered on the body? Uses the "[aug_overlay]_e" icon state.
	var/emissive_overlay = FALSE
	/// Bodypart overlay datum we apply to the limb we're implanted into. Managed by on_bodypart_insert/remove.
	var/datum/bodypart_overlay/augment/bodypart_aug = null

/obj/item/organ/cyberimp/Initialize(mapload)
	. = ..()
	create_bodypart_aug()

/// Lazily (re)creates the bodypart_overlay if the implant needs one. Safe to call multiple times.
/obj/item/organ/cyberimp/proc/create_bodypart_aug()
	if(!aug_overlay)
		return
	if(QDELETED(bodypart_aug))
		if(!isnull(bodypart_aug))
			QDEL_NULL(bodypart_aug)
		bodypart_aug = new(src)

/obj/item/organ/cyberimp/Destroy()
	. = ..()
	QDEL_NULL(bodypart_aug) // Do this after Remove() has done its thing, otherwise on_bodypart_remove() will not properly remove the overlay

/obj/item/organ/cyberimp/New(var/mob/M = null)
	// bodypart may need to exist before the New-based Insert() runs, so create it up-front
	create_bodypart_aug()
	if(iscarbon(M))
		src.Insert(M)
	if(implant_overlay)
		var/mutable_appearance/overlay = mutable_appearance(icon, implant_overlay)
		overlay.color = implant_color
		add_overlay(overlay)
	return ..()

/// Returns the icon_state used for this implant's bodypart overlay (on the body).
/obj/item/organ/cyberimp/proc/get_overlay_state(image_layer, obj/item/bodypart/limb)
	return aug_overlay

/// Which bodypart zones this implant draws its overlay on. Most implants touch a single limb.
/obj/item/organ/cyberimp/proc/get_bodypart_zones()
	return list(check_zone(zone))

/// Builds the list of images to draw for this implant on the owner's body.
/// Delegates to the bodypart_overlay/augment datum via get_overlay().
/obj/item/organ/cyberimp/proc/get_overlay(image_layer, obj/item/bodypart/limb)
	. = list()
	var/overlay_state = get_overlay_state(image_layer, limb)
	. += image(icon = aug_icon, icon_state = overlay_state, layer = image_layer)
	if (emissive_overlay)
		. += emissive_appearance(aug_icon, "[overlay_state]_e", layer = image_layer, offset_spokesman = limb?.owner || limb)

/// Called when this implant is inserted into a specific bodypart. Applies the augment overlay to the body.
/obj/item/organ/cyberimp/proc/on_bodypart_insert(obj/item/bodypart/limb)
	if(!limb)
		return
	if (bodypart_aug)
		limb.add_bodypart_overlay(bodypart_aug)

/// Called when this implant is removed from a specific bodypart. Removes the augment overlay from the body.
/obj/item/organ/cyberimp/proc/on_bodypart_remove(obj/item/bodypart/limb)
	if(limb && bodypart_aug) // конечность может быть уже удалена (гиб)
		limb.remove_bodypart_overlay(bodypart_aug)

/// Forces the owner's body part overlays to rebuild (e.g. when a dynamic overlay state changes).
/obj/item/organ/cyberimp/proc/refresh_bodypart_overlays(mob/living/carbon/target = owner)
	if (target && ishuman(target))
		var/mob/living/carbon/human/H = target
		H.update_body_parts(TRUE, FALSE)

/obj/item/organ/cyberimp/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(. && owner)
		for(var/limb_zone in get_bodypart_zones())
			on_bodypart_insert(owner.get_bodypart(limb_zone))
		refresh_bodypart_overlays()

/obj/item/organ/cyberimp/Remove(special = FALSE)
	var/mob/living/carbon/prev_owner = owner
	var/list/prev_limbs = list()
	if(prev_owner)
		for(var/limb_zone in get_bodypart_zones())
			prev_limbs += prev_owner.get_bodypart(limb_zone)
	. = ..()
	for(var/obj/item/bodypart/limb in prev_limbs)
		on_bodypart_remove(limb)
	refresh_bodypart_overlays(prev_owner)

// В отличие от органов, имланты будут работать, только пока их можно активировать
/obj/item/organ/cyberimp/on_life(seconds, times_fired)
	return activate_allowed(silent = TRUE) && ..()

//[[[[BRAIN]]]]

/obj/item/organ/cyberimp/brain
	name = "cybernetic brain implant"
	desc = "Injectors of extra sub-routines for the brain."
	icon_state = "brain_implant"
	implant_overlay = "brain_implant_overlay"
	zone = BODY_ZONE_HEAD
	w_class = WEIGHT_CLASS_TINY

/obj/item/organ/cyberimp/brain/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	var/stun_amount = 2*severity
	owner.Stun(stun_amount)
	to_chat(owner, "<span class='warning'>Your body seizes up!</span>")

/obj/item/organ/cyberimp/brain/anti_drop
	name = "Anti-Drop implant"
	desc = "This cybernetic brain implant will allow you to force your hand muscles to contract, preventing item dropping. Twitch ear to toggle."
	var/active = 0
	var/list/stored_items = list()
	implant_color = "#DE7E00"
	slot = ORGAN_SLOT_BRAIN_ANTIDROP
	actions_types = list(/datum/action/item_action/organ_action/toggle)

/obj/item/organ/cyberimp/brain/anti_drop/ui_action_click()
	active = !active
	if(active)
		for(var/obj/item/I in owner.held_items)
			stored_items += I

		var/list/L = owner.get_empty_held_indexes()
		if(LAZYLEN(L) == owner.held_items.len)
			to_chat(owner, "<span class='notice'>You are not holding any items, your hands relax...</span>")
			active = 0
			stored_items = list()
		else
			for(var/obj/item/I in stored_items)
				to_chat(owner, "<span class='notice'>Your [owner.get_held_index_name(owner.get_held_index_of_item(I))]'s grip tightens.</span>")
				ADD_TRAIT(I, TRAIT_NODROP, ANTI_DROP_IMPLANT_TRAIT)

	else
		release_items()
		to_chat(owner, "<span class='notice'>Your hands relax...</span>")

/obj/item/organ/cyberimp/brain/anti_drop/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	var/range = severity/10
	var/atom/A
	if(active)
		release_items()
	for(var/obj/item/I in stored_items)
		A = pick(oview(range))
		I.throw_at(A, range, 2)
		to_chat(owner, "<span class='warning'>Your [owner.get_held_index_name(owner.get_held_index_of_item(I))] spasms and throws the [I.name]!</span>")
	stored_items = list()

/obj/item/organ/cyberimp/brain/anti_drop/proc/release_items()
	for(var/obj/item/I in stored_items)
		REMOVE_TRAIT(I, TRAIT_NODROP, ANTI_DROP_IMPLANT_TRAIT)
	stored_items = list()

/obj/item/organ/cyberimp/brain/anti_drop/deactivate(removing)
	. = ..()
	if(active)
		ui_action_click()

/obj/item/organ/cyberimp/brain/anti_drop/sec_level
	name = "Corporate Anti-Drop implant"
	implant_color = "#ab6509"
	active_security_level = ANTI_DROP_SEC_LEVEL

/obj/item/organ/cyberimp/brain/anti_stun
	name = "CNS Rebooter implant"
	desc = "This implant will automatically give you back control over your central nervous system, reducing downtime when stunned."
	implant_color = "#FFFF00"
	slot = ORGAN_SLOT_BRAIN_ANTISTUN

/obj/item/organ/cyberimp/brain/anti_stun/on_life()
	. = ..()
	if(!. || crit_fail)
		return
	owner.adjustStaminaLoss(-3.5, FALSE) //Citadel edit, makes it more useful in Stamina based combat
	owner.HealAllImmobilityUpTo(ANTI_STUN_SET_AMOUNT)

/obj/item/organ/cyberimp/brain/anti_stun/emp_act(severity)
	. = ..()
	if(crit_fail || (organ_flags & ORGAN_FAILING) || . & EMP_PROTECT_SELF)
		return
	crit_fail = TRUE
	organ_flags |= ORGAN_FAILING
	addtimer(CALLBACK(src, PROC_REF(reboot)), 0.9 * severity)

/obj/item/organ/cyberimp/brain/anti_stun/proc/reboot()
	crit_fail = FALSE
	organ_flags &= ~ORGAN_FAILING

/obj/item/organ/cyberimp/brain/anti_stun/sec_level
	name = "Corporate CNS Rebooter implant"
	implant_color = "#c0c000"
	active_security_level = CNS_REBOOTER_SEC_LEVEL

/obj/item/organ/cyberimp/brain/robot_radshielding
	name = "ECC System Guard implant"
	desc = "This implant can counteract the effects of harmful radiation in robots, effectively increasing their radiation tolerance significantly."
	implant_color = "#0066ff"
	slot = ORGAN_SLOT_BRAIN_ROBOT_RADSHIELDING
	var/active = FALSE

/obj/item/organ/cyberimp/brain/robot_radshielding/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(!HAS_TRAIT(owner, TRAIT_ROBOTIC_ORGANISM))
		return //Why did you even get yourself implanted this if you aren't a robot?
	owner.adjustToxLoss(severity / 10, toxins_type = TOX_SYSCORRUPT)
	to_chat(owner, span_warning("<b>ECC-имплантат</b> внезапно начинает вести себя очень нестабильно, нарушая работу вашей системы."))

/obj/item/organ/cyberimp/brain/robot_radshielding/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	code_activate()

/obj/item/organ/cyberimp/brain/robot_radshielding/code_activate()
	. = ..()
	if(active)
		return
	ADD_TRAIT(owner, TRAIT_ROBOT_RADSHIELDING, ROBOT_RADSHIELDING_IMPLANT_TRAIT) //Organics can get this, but it does literally nothing for them except cause more pain if EMPd, so uh, good on you?
	to_chat(owner, span_nicegreen("<b>ECC-имплантат</b> активируется, обеспечивая защиту от радиации."))
	active = !active

/obj/item/organ/cyberimp/brain/robot_radshielding/deactivate(removing)
	. = ..()
	if(!active)
		return
	REMOVE_TRAIT(owner, TRAIT_ROBOT_RADSHIELDING, ROBOT_RADSHIELDING_IMPLANT_TRAIT)
	if(!removing)
		to_chat(owner, span_warning("<b>ECC-имплантат</b> отключаяется, вы больше не защищены от радиации."))
	active = !active

/obj/item/organ/cyberimp/brain/sandevistan
	name = "Sandevistan"
	desc = "A neural cybernetic implant that temporarily overclocks the user's nervous system, granting a massive burst of speed and reaction time."
	icon_state = "qian-ti_sandevistan"
	implant_overlay = "brain_implant_overlay"
	zone = BODY_ZONE_HEAD
	w_class = WEIGHT_CLASS_TINY
	slot = ORGAN_SLOT_BRAIN_SANDEVISTAN
	implant_color = "#00FFFF"
	actions_types = list(/datum/action/item_action/organ_action/use/sandevistan)
	var/active = FALSE
	var/duration = 10 SECONDS
	var/cooldown = 15 SECONDS
	var/movespeed_mod = /datum/movespeed_modifier/sandevistan
	var/movespeed_mod_weak = /datum/movespeed_modifier/sandevistan/weak
	/// The movespeed modifier that is currently applied.
	var/active_movespeed_mod
	var/next_use = 0
	/// Счётчик активаций для перегруза
	var/overload_count = 0
	/// Через сколько накопленный перегруз сбрасывается, пока имплант установлен.
	var/overload_reset_interval = 2 MINUTES
	/// ID таймера периодического сброса перегруза.
	var/overload_reset_timer
	/// Timer id for the afterimage trail.
	var/afterimage_timer
	/// Last turf an afterimage was spawned on.
	var/turf/last_afterimage_turf
	/// Цвет контура персонажа во время действия.
	var/outline_color = "#00FFFF"
	/// Цвет следа в воздухе; null - след повторяет внешность персонажа без окраски.
	var/trail_color
	/// Интервал спавна следа в децисекундах (меньше = плотнее след).
	var/afterimage_interval = 0.2
	/// Шанс в процентах уклониться от любого проджектайла, пока имплант активен.
	var/projectile_dodge_chance = 45
	/// Во сколько раз ускоряются времязатратные действия владельца (4 = в четыре раза быстрее).
	var/action_speed_mult = SANDEVISTAN_ACTION_SPEED_MULT
	/// Полупрозрачность владельца и его следов во время действия.
	var/sandevistan_alpha = 160
	/// Пули владельца, замороженные на время действия импланта.
	var/list/frozen_projectiles
	/// Следы в воздухе, которые живут до конца действия импланта.
	var/list/active_afterimages
	/// Отложенные удары ближнего боя: наносят урон разом после окончания действия.
	var/list/deferred_attacks
	/// Исходная альфа владельца до активации.
	var/owner_old_alpha
	/// Исходный цвет владельца до активации.
	var/owner_old_color
	/// Исходный модификатор задержки действий владельца до активации.
	var/owner_old_action_cooldown_mod
	/// Звук включения и работы импланта (длится почти весь эффект). Обычная и корпоративная версии.
	var/start_sound = 'sound/effects/sandevistan/sandevistan_start_and_go_1.ogg'
	/// Звук окончания действия импланта.
	var/end_sound = 'sound/effects/sandevistan/sandevistan_ends.ogg'

/datum/action/item_action/organ_action/use/sandevistan
	name = "Activate Sandevistan"

/datum/action/item_action/organ_action/use/sandevistan/Trigger()
	. = ..()
	if(!.)
		return
	var/obj/item/organ/cyberimp/brain/sandevistan/S = target
	if(!istype(S))
		return
	S.activate_sandevistan()

/obj/item/organ/cyberimp/brain/sandevistan/proc/activate_sandevistan()
	if(!owner)
		return
	// У корпоративной версии активация доступна только с красного кода.
	if(!activate_allowed(user = owner))
		return
	if(active)
		to_chat(owner, span_warning("Sandevistan is already active."))
		return
	if(world.time < next_use)
		var/timeleft = round((next_use - world.time) / 10)
		to_chat(owner, span_warning("Sandevistan recharging. [timeleft] seconds remaining."))
		return
	if(owner.stat == DEAD)
		return

	var/first_use = (overload_count == 0)
	overload_count++
	active = TRUE
	next_use = world.time + cooldown
	to_chat(owner, span_notice("Your vision sharpens as time seems to slow around you."))
	owner.playsound_local(owner, start_sound, 50, FALSE)
	// Все активации дают сниженную скорость (как раньше первая); различается только длительность.
	active_movespeed_mod = movespeed_mod_weak
	owner.add_movespeed_modifier(movespeed_mod_weak)
	ADD_TRAIT(owner, TRAIT_NO_STAMINA_DAMAGE, REF(src))
	ADD_TRAIT(owner, TRAIT_SANDEVISTAN_ACTIVE, REF(src))
	// Времязатратные действия ускорены: перезарядки КД в 4 раза, do_after/do_mob почти мгновенные.
	owner.add_actionspeed_modifier(/datum/actionspeed_modifier/sandevistan)
	owner_old_action_cooldown_mod = owner.action_cooldown_mod
	owner.action_cooldown_mod /= action_speed_mult
	// Владелец становится неотличимым от своего следа: та же альфа и тот же цвет.
	owner_old_alpha = owner.alpha
	owner_old_color = owner.color
	owner.alpha = sandevistan_alpha
	if(trail_color)
		owner.color = trail_color
	frozen_projectiles = null
	active_afterimages = null
	deferred_attacks = null
	if(istype(src, /obj/item/organ/cyberimp/brain/sandevistan/military))
		if(overload_count > 2)
			apply_overload_effects()
	else if(overload_count >= 2)
		apply_overload_effects()
	last_afterimage_turf = null
	afterimage_timer = addtimer(CALLBACK(src, PROC_REF(spawn_afterimage)), afterimage_interval, TIMER_LOOP|TIMER_STOPPABLE)
	// Первая активация короче на 0.25 с, вторая — длиннее на 0.25 с.
	var/use_duration = duration
	if(first_use)
		use_duration -= 0.25 SECONDS
	else if(overload_count == 2)
		use_duration += 0.25 SECONDS
	addtimer(CALLBACK(src, PROC_REF(deactivate_sandevistan)), use_duration)

/obj/item/organ/cyberimp/brain/sandevistan/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(!. || !owner)
		return
	overload_reset_timer = addtimer(CALLBACK(src, PROC_REF(reset_overload)), overload_reset_interval, TIMER_LOOP|TIMER_STOPPABLE)
	RegisterSignal(owner, COMSIG_MOD_PROJECTILE_FIRE, PROC_REF(on_projectile_fired))

/obj/item/organ/cyberimp/brain/sandevistan/Remove(special = FALSE)
	if(owner)
		UnregisterSignal(owner, COMSIG_MOD_PROJECTILE_FIRE)
	if(overload_reset_timer)
		deltimer(overload_reset_timer)
		overload_reset_timer = null
	return ..()

/// Находит активный сандевистан у владельца; используется точками входа в ядре игры.
/proc/get_active_sandevistan(mob/living/user)
	if(!iscarbon(user))
		return null
	var/obj/item/organ/cyberimp/brain/sandevistan/S = user.getorganslot(ORGAN_SLOT_BRAIN_SANDEVISTAN)
	if(istype(S) && S.active)
		return S
	return null

/// Отложенная атака ближнего боя, которая наносит урон после окончания сандевистана.
/datum/sandevistan_deferred_attack
	var/obj/item/weapon
	var/datum/species/species
	var/mob/living/user
	var/mob/living/target
	var/datum/martial_art/style
	var/attackchain_flags
	var/damage_multiplier = 1

/// Откладывает удар оружием: урон нанесётся в конце действия импланта.
/obj/item/organ/cyberimp/brain/sandevistan/proc/queue_item_attack(obj/item/weapon, mob/living/target, mob/living/user, attackchain_flags, damage_multiplier)
	if(!active || QDELETED(weapon) || QDELETED(target) || QDELETED(user))
		return FALSE
	var/datum/sandevistan_deferred_attack/attack = new()
	attack.weapon = weapon
	attack.target = target
	attack.user = user
	attack.attackchain_flags = attackchain_flags
	attack.damage_multiplier = damage_multiplier
	LAZYADD(deferred_attacks, attack)
	return TRUE

/// Откладывает безоружный удар: в конце повторяем саму процедуру урона.
/obj/item/organ/cyberimp/brain/sandevistan/proc/queue_unarmed_attack(datum/species/species, mob/living/user, mob/living/target, datum/martial_art/style, attackchain_flags)
	if(!active || QDELETED(species) || QDELETED(user) || QDELETED(target))
		return FALSE
	var/datum/sandevistan_deferred_attack/attack = new()
	attack.species = species
	attack.user = user
	attack.target = target
	attack.style = style
	attack.attackchain_flags = attackchain_flags
	LAZYADD(deferred_attacks, attack)
	return TRUE

/// Все накопленные удары разом наносят урон, когда действие импланта закончилось.
/obj/item/organ/cyberimp/brain/sandevistan/proc/release_deferred_attacks()
	if(!deferred_attacks)
		return
	var/list/attacks = deferred_attacks
	deferred_attacks = null
	for(var/datum/sandevistan_deferred_attack/attack as anything in attacks)
		if(QDELETED(attack) || QDELETED(attack.user) || QDELETED(attack.target))
			continue
		if(attack.weapon)
			if(!QDELETED(attack.weapon))
				attack.weapon.attack(attack.target, attack.user, attack.attackchain_flags, attack.damage_multiplier)
		else if(attack.species && !QDELETED(attack.species))
			attack.species.harm(attack.user, attack.target, attack.style, attack.attackchain_flags)
		qdel(attack)

/// Все снаряды, выпущенные владельцем во время действия, замирают до его окончания.
/obj/item/organ/cyberimp/brain/sandevistan/proc/on_projectile_fired(mob/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	if(!active || !projectile)
		return
	projectile.paused = TRUE
	LAZYADD(frozen_projectiles, projectile)

/// Сбрасывает накопленный перегруз, чтобы он не копился всю смену у базовой и корпоративной версий.
/obj/item/organ/cyberimp/brain/sandevistan/proc/reset_overload()
	if(!owner)
		return
	overload_count = 0
	if(ishuman(owner))
		to_chat(owner, span_notice("[src] has cooled down."))

/obj/item/organ/cyberimp/brain/sandevistan/proc/apply_overload_effects()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	if(overload_count == 2 || (istype(src, /obj/item/organ/cyberimp/brain/sandevistan/military) && overload_count == 3))
		to_chat(H, span_warning("Your body starts to strain from the repeated overclocking!"))
		shake_camera(H, 5, 3)
		H.Jitter(15)
		if(!istype(src, /obj/item/organ/cyberimp/brain/sandevistan/military))
			if(H.get_active_held_item())
				H.dropItemToGround(H.get_active_held_item())
			if(H.get_inactive_held_item())
				H.dropItemToGround(H.get_inactive_held_item())
		else
			if(H.get_active_held_item())
				H.dropItemToGround(H.get_active_held_item())
			if(H.get_inactive_held_item())
				H.dropItemToGround(H.get_inactive_held_item())
		for(var/i in 1 to 2)
			var/obj/item/bodypart/chest/C = H.get_bodypart(BODY_ZONE_CHEST)
			if(C)
				C.force_wound_upwards(/datum/wound/pierce/critical)
		H.blood_volume = max(BLOOD_VOLUME_SAFE - 150, H.blood_volume - 150)
	else if(overload_count >= 3 || (istype(src, /obj/item/organ/cyberimp/brain/sandevistan/military) && overload_count >= 4))
		to_chat(H, span_userdanger("Your cybernetic system goes into critical overload!"))
		shake_camera(H, 10, 6)
		H.Jitter(30)
		H.blur_eyes(10)
		H.adjustToxLoss(60)
		H.adjustOrganLoss(ORGAN_SLOT_BRAIN, 40)
		// Множественные кровотечения
		var/list/all_parts = H.bodyparts
		for(var/i in 1 to 4)
			var/obj/item/bodypart/BP = pick(all_parts)
			if(BP)
				BP.force_wound_upwards(/datum/wound/slash/critical)
		H.blood_volume = max(BLOOD_VOLUME_SURVIVE - 200, H.blood_volume - 200)
		// Тяжёлая интоксикация
		H.reagents.add_reagent(/datum/reagent/toxin/cyanide, 15)
		H.reagents.add_reagent(/datum/reagent/toxin/leadacetate, 10)

/obj/item/organ/cyberimp/brain/sandevistan/proc/spawn_afterimage()
	if(!active || !owner)
		return
	var/turf/current_turf = get_turf(owner)
	if(!current_turf || current_turf == last_afterimage_turf)
		return
	last_afterimage_turf = current_turf
	var/obj/effect/temp_visual/sandevistan_afterimage/afterimage = new(current_turf, owner, trail_color, sandevistan_alpha)
	LAZYADD(active_afterimages, afterimage)

/obj/item/organ/cyberimp/brain/sandevistan/proc/deactivate_sandevistan()
	if(!owner || !active)
		return
	active = FALSE
	to_chat(owner, span_warning("The world snaps back into focus as your Sandevistan powers down."))
	owner.playsound_local(owner, end_sound, 50, FALSE)
	owner.remove_movespeed_modifier(active_movespeed_mod || movespeed_mod)
	active_movespeed_mod = null
	REMOVE_TRAIT(owner, TRAIT_NO_STAMINA_DAMAGE, REF(src))
	REMOVE_TRAIT(owner, TRAIT_SANDEVISTAN_ACTIVE, REF(src))
	owner.remove_actionspeed_modifier(/datum/actionspeed_modifier/sandevistan)
	if(!isnull(owner_old_action_cooldown_mod))
		owner.action_cooldown_mod = owner_old_action_cooldown_mod
		owner_old_action_cooldown_mod = null
	if(!isnull(owner_old_alpha))
		owner.alpha = owner_old_alpha
		owner_old_alpha = null
	// color по умолчанию равен null, поэтому проверять isnull здесь нельзя — иначе окраска останется навсегда.
	owner.color = owner_old_color
	owner_old_color = null
	if(afterimage_timer)
		deltimer(afterimage_timer)
		afterimage_timer = null
	last_afterimage_turf = null
	// Замороженные пули продолжают полёт, следы исчезают.
	for(var/obj/item/projectile/projectile in frozen_projectiles)
		if(!QDELETED(projectile))
			projectile.paused = FALSE
	frozen_projectiles = null
	for(var/obj/effect/temp_visual/sandevistan_afterimage/afterimage in active_afterimages)
		qdel(afterimage)
	active_afterimages = null
	// Все удары, сделанные во время действия, наносят урон одновременно с его окончанием.
	release_deferred_attacks()
	var/deadly = FALSE
	if(istype(src, /obj/item/organ/cyberimp/brain/sandevistan/military))
		deadly = (overload_count >= 5) // 4 безопасных + 1 смертельный
	else
		deadly = (overload_count >= 3)
	if(deadly && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.stat < DEAD)
			H.adjustOrganLoss(ORGAN_SLOT_BRAIN, 70)
			H.adjustToxLoss(100)
			H.blood_volume = max(0, H.blood_volume - 300)
			H.visible_message(span_danger("[H] suddenly collapses as their cybernetic system violently shuts down!"), span_userdanger("Your body gives out from the catastrophic overload!"))
			H.Paralyze(10 SECONDS)
			if(H.blood_volume <= BLOOD_VOLUME_SURVIVE)
				H.adjustOxyLoss(50)

/obj/item/organ/cyberimp/brain/sandevistan/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(active)
		deactivate_sandevistan()
	if(prob(50 / severity))
		next_use = world.time + cooldown * 1.5
		to_chat(owner, span_warning("Your Sandevistan glitches wildly from the EMP!"))
		if(istype(src, /obj/item/organ/cyberimp/brain/sandevistan/military))
			overload_count = max(overload_count, 3)
		else
			overload_count = max(overload_count, 2)

/obj/item/organ/cyberimp/brain/sandevistan/deactivate(removing)
	. = ..()
	if(active)
		deactivate_sandevistan()

/obj/effect/temp_visual/sandevistan_afterimage
	name = ""
	/// След живёт до конца действия импланта и удаляется им вручную.
	duration = 600
	alpha = 160
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = MOB_LAYER - 0.02

/obj/effect/temp_visual/sandevistan_afterimage/Initialize(mapload, mob/living/source, trail_color, sustain_alpha = 160)
	. = ..()
	if(!source)
		return
	appearance = source.appearance
	dir = source.dir
	plane = source.plane
	layer = source.layer - 0.02
	alpha = sustain_alpha
	if(trail_color)
		color = trail_color
	// Намеренно без затухания: след стоит на месте, пока имплант активен.

/// Ускорение времязатратных действий: базовый модификатор 1 + (-0.95) даёт сеть 0.05, то есть ~20x (почти мгновенно).
/datum/actionspeed_modifier/sandevistan
	multiplicative_slowdown = -0.95

/obj/item/organ/cyberimp/brain/sandevistan/military
	name = "Cybersun Sandevistan"
	desc = "A military-grade neural overclocking implant. Far more potent than civilian models, with a longer duration at the cost of increased strain."
	icon_state = "militech_sandevistan"
	implant_overlay = "brain_implant_overlay"
	implant_color = "#FF3333"
	syndicate_implant = TRUE
	duration = 15 SECONDS
	cooldown = 15 SECONDS
	movespeed_mod = /datum/movespeed_modifier/sandevistan/military
	movespeed_mod_weak = /datum/movespeed_modifier/sandevistan/military/weak
	// Предательская версия: тёмно-розовый контур и след, след ещё плотнее.
	outline_color = "#C2185B"
	trail_color = "#C2185B"
	afterimage_interval = 0.04
	// Агентская версия использует свой звук включения/работы.
	start_sound = 'sound/effects/sandevistan/sandevistan_start_and_go_2.ogg'
	/// Максимальное количество активаций до перегруза
	var/max_safe_activations = 4

/obj/item/organ/cyberimp/brain/sandevistan/sec_level
	name = "Corporate Sandevistan"
	desc = "A corporate-issued neural overclocking implant, tuned for security use. Offers a balanced burst of speed with a reasonable cooldown."
	icon_state = "qian-ti_sandevistan"
	implant_overlay = "brain_implant_overlay"
	implant_color = "#ab6509"
	active_security_level = SEC_LEVEL_RED
	duration = 10 SECONDS
	cooldown = 15 SECONDS
	movespeed_mod = /datum/movespeed_modifier/sandevistan

//[[[[MOUTH]]]]
/obj/item/organ/cyberimp/mouth
	zone = BODY_ZONE_PRECISE_MOUTH

/obj/item/organ/cyberimp/mouth/breathing_tube
	name = "breathing tube implant"
	desc = "This simple implant adds an internals connector to your back, allowing you to use internals without a mask and protecting you from being choked."
	icon_state = "implant_mask"
	aug_overlay = "breathing_tube"
	slot = ORGAN_SLOT_BREATHING_TUBE
	w_class = WEIGHT_CLASS_TINY

/obj/item/organ/cyberimp/mouth/breathing_tube/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(0.6*severity))
		to_chat(owner, "<span class='warning'>Your breathing tube suddenly closes!</span>")
		owner.losebreath += 8

#undef ANTI_STUN_SET_AMOUNT
