/datum/component/heretic_craft
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Базовое знание пути, владеющее объектом.
	var/datum/weakref/owner_ref
	var/clue
	var/mutable_appearance/marking
	var/craft_id

/datum/component/heretic_craft/Initialize(datum/eldritch_knowledge/owner, craft_id, clue, mutable_appearance/marking)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	// Дубль при COMPONENT_DUPE_UNIQUE создаётся и сразу удаляется, поэтому он не трогает объект и знание.
	if(parent.GetComponent(/datum/component/heretic_craft))
		return
	owner_ref = WEAKREF(owner)
	src.craft_id = craft_id
	src.clue = clue
	src.marking = marking
	var/atom/crafted = parent
	if(marking)
		crafted.add_overlay(marking)
	heretic_craft_placed_fx(crafted, owner)
	RegisterSignal(crafted, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(crafted, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))

/datum/component/heretic_craft/Destroy(force, silent)
	var/atom/crafted = parent
	if(crafted && marking)
		crafted.cut_overlay(marking)
	marking = null
	var/datum/eldritch_knowledge/owner = owner_ref?.resolve()
	owner_ref = null
	. = ..()
	// Знание узнаёт о снятии после отцепления: удаление объекта в ответ не вызовет этот Destroy повторно.
	if(crafted)
		owner?.on_craft_removed(crafted, craft_id)

/datum/component/heretic_craft/proc/on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/owner = owner_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(owner && heretic?.get_knowledge(owner.type) == owner)
		examine_list += span_eldritch("Ваше ремесло: [owner.name]. Экипаж при осмотре видит: [clue]")
		return
	if(clue)
		examine_list += span_warning(clue)

/datum/component/heretic_craft/proc/on_attackby(atom/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return
	user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и чужое ремесло на нём рассеивается."), span_notice("Вы касаетесь [source] нулевым жезлом, и чужое ремесло рассеивается."))
	log_game("[key_name(user)] снимает ремесло еретика [craft_id] с [source] ([source.type]) нулевым жезлом в [AREACOORD(source)].")
	heretic_craft_dispel_fx(source, owner_ref?.resolve())
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/// crafted может быть уже в qdel: удалять его владельцу можно только при !QDELETED(crafted).
/datum/eldritch_knowledge/proc/on_craft_removed(atom/crafted, craft_id)
	SHOULD_NOT_SLEEP(TRUE)
	return

/proc/heretic_craft_on(atom/target, craft_id)
	var/datum/component/heretic_craft/craft = target?.GetComponent(/datum/component/heretic_craft)
	return craft?.craft_id == craft_id ? craft : null

#define HERETIC_CAPTURE_SHARED "shared"

/// Поверженность, общая для захватов: сон и добровольный отдых сами по себе не в счёт.
/proc/heretic_capture_downed(mob/living/victim)
	return victim.IsKnockdown() || (victim.resting && victim.knocked_to_floor) || (victim.combat_flags & COMBAT_FLAG_HARD_STAMCRIT)

/// Причина, по которой еретик не может начать захват цели, или null; ignore_shared пропускает общую передышку.
/proc/heretic_capture_block_reason(mob/living/user, mob/living/victim, capture_id, ignore_shared = FALSE)
	if(!istype(victim) || QDELETED(victim))
		return "Захватывать некого."
	if(victim.stat == DEAD)
		return "Захват удерживает только живых."
	var/containment = heretic_containment_reason(user)
	if(containment)
		return containment
	if(victim == user)
		return "Себя не захватить."
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		return "Мансус не держит своих: еретика и его созданий захватить нельзя."
	// Психозащита заряды здесь не тратит и держала бы вечно, поэтому от захватов тела она не спасает.
	if(!heretic_can_affect(user, victim, chargecost = 0, tinfoil = FALSE))
		return "Цель защищена от магии."
	var/shared_until = 0
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		if(immunity.duration <= world.time)
			continue
		if(immunity.capture_id == capture_id)
			return "Цель ещё приходит в себя после прошлого захвата: осталось [heretic_capture_seconds_left(immunity.duration)] с."
		if(immunity.capture_id == HERETIC_CAPTURE_SHARED)
			shared_until = immunity.duration
	if(shared_until && !ignore_shared)
		return "Цель только что вышла из другого захвата: осталось [heretic_capture_seconds_left(shared_until)] с."
	return null

/proc/heretic_capture_seconds_left(ends_at, now = world.time)
	// В float32 (world.time + 60 с) - world.time бывает 600.00006: round() снимает шум до округления вверх.
	return max(1, CEILING(round(ends_at - now, 1) / (1 SECONDS), 1))

/// Невосприимчивость к этому захвату и общая передышка от всех; hold_after сдвигает обе на время, пока цель не очнулась; held_for - сколько захват реально держал: несостоявшийся не даёт ничего, короткий - меньше.
/proc/heretic_capture_release(mob/living/victim, capture_id, hold_after = 0, held_for = INFINITY)
	if(!istype(victim) || QDELETED(victim) || held_for <= 0)
		return null
	var/immunity = min(HERETIC_CAPTURE_IMMUNITY, max(HERETIC_CAPTURE_MIN_IMMUNITY, held_for * HERETIC_CAPTURE_IMMUNITY_PER_HOLD))
	. = heretic_capture_extend_immunity(victim, capture_id, immunity + hold_after)
	if(held_for >= HERETIC_CAPTURE_SHAKE_TIME)
		heretic_capture_extend_immunity(victim, HERETIC_CAPTURE_SHARED, HERETIC_CAPTURE_SHARED_IMMUNITY + hold_after)

/// Захват сорвался на телеграфе, ещё не схватив: перезарядка его заклинания возвращается.
/proc/heretic_refund_capture(mob/living/user, spell_type, reason)
	for(var/obj/effect/proc_holder/spell/spell as anything in user?.mind?.spell_list)
		if(istype(spell, spell_type))
			spell.heretic_revert_cast(user, "[reason] Перезарядка возвращена.")
			return TRUE
	to_chat(user, span_warning(reason))
	return FALSE

/// Сколько держал захват с момента started_at; 0 - не начинался.
/proc/heretic_capture_held_for(started_at)
	return started_at ? max(world.time - started_at, 1) : 0

/proc/heretic_capture_extend_immunity(mob/living/victim, capture_id, time)
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		if(immunity.capture_id == capture_id)
			immunity.duration = max(immunity.duration, world.time + time)
			return immunity
	return victim.apply_status_effect(/datum/status_effect/heretic_capture_immunity, capture_id, time)

/// Пока захват держит цель, «Помощь» не укорачивает удержание: цель можно только растолкать за HERETIC_CAPTURE_SHAKE_TIME.
/proc/heretic_capture_hold(mob/living/victim, source)
	if(!istype(victim) || QDELETED(victim))
		return
	var/already_held = HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD)
	ADD_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD, source)
	if(!already_held)
		victim.AddElement(/datum/element/heretic_capture_shake)
		heretic_capture_hold_fx(victim, source)

/proc/heretic_capture_unhold(mob/living/victim, source)
	if(QDELETED(victim))
		return
	REMOVE_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD, source)
	if(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD))
		victim.RemoveElement(/datum/element/heretic_capture_shake)
		heretic_capture_unhold_fx(victim)

/datum/element/heretic_capture_shake
	element_flags = ELEMENT_DETACH

/datum/element/heretic_capture_shake/Attach(datum/target)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_CARBON_PRE_MISC_HELP, PROC_REF(on_help))

/datum/element/heretic_capture_shake/Detach(datum/source, ...)
	UnregisterSignal(source, COMSIG_CARBON_PRE_MISC_HELP)
	return ..()

/datum/element/heretic_capture_shake/proc/on_help(mob/living/source, mob/living/helper)
	SIGNAL_HANDLER
	if(!HAS_TRAIT(source, TRAIT_HERETIC_CAPTURE_HOLD) || !isliving(helper) || helper == source)
		return NONE
	if(!IS_HERETIC(helper) && !IS_HERETIC_MONSTER(helper))
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_capture_shake), helper, source)
	if(source.IsSleeping() || source.IsUnconscious() || source.IsParalyzed() || source.IsKnockdown() || source.IsStun() || source.IsImmobilized())
		return COMPONENT_BLOCK_MISC_HELP
	return NONE

/proc/heretic_capture_shake(mob/living/helper, mob/living/victim)
	if(LAZYFIND(helper.do_afters, victim))
		return FALSE
	helper.visible_message(span_warning("[helper] изо всех сил трясёт [victim], пытаясь растолкать."), span_notice("Вы трясёте [victim]. Не отходите [DisplayTimeText(HERETIC_CAPTURE_SHAKE_TIME)]: если вас ударят, попытка сорвётся."))
	var/datum/heretic_capture_shake/attempt = new(helper, victim)
	. = do_after(helper, HERETIC_CAPTURE_SHAKE_TIME, victim, extra_checks = CALLBACK(attempt, TYPE_PROC_REF(/datum/heretic_capture_shake, holds)))
	qdel(attempt)
	if(!. || !HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD))
		return FALSE
	helper.visible_message(span_notice("[helper] растолкал [victim], и чужая хватка разжимается."))
	log_game("[key_name(helper)] расталкивает [key_name(victim)] из захвата еретика в [AREACOORD(victim)].")
	heretic_capture_shaken_fx(helper, victim)
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, helper)
	return TRUE

/// Попытку растолкать срывает удар по расталкивающему от другого существа, но не его собственные раны.
/datum/heretic_capture_shake
	var/mob/living/helper
	var/mob/living/victim
	var/struck = FALSE

/datum/heretic_capture_shake/New(mob/living/helper, mob/living/victim)
	src.helper = helper
	src.victim = victim
	RegisterSignal(helper, COMSIG_LIVING_ATTACKER_SET, PROC_REF(on_attacked))
	RegisterSignal(helper, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_bullet))
	RegisterSignal(helper, COMSIG_ATOM_HITBY, PROC_REF(on_hitby))

/datum/heretic_capture_shake/Destroy()
	helper = null
	victim = null
	return ..()

/datum/heretic_capture_shake/proc/on_attacked(datum/source, mob/attacker)
	SIGNAL_HANDLER
	if(attacker && attacker != helper)
		struck = TRUE

/datum/heretic_capture_shake/proc/on_bullet(datum/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	if(projectile?.firer && projectile.firer != helper && !projectile.nodamage)
		struck = TRUE

/datum/heretic_capture_shake/proc/on_hitby(datum/source, atom/movable/hitting_atom, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(throwingdatum?.thrower && throwingdatum.thrower != helper)
		struck = TRUE

/datum/heretic_capture_shake/proc/holds()
	return !struck && !QDELETED(victim) && HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD)

/mob/living
	/// Захваты, при которых цель тянет и пристёгивает только держащий: источник -> weakref держащего.
	var/list/heretic_pull_owners

/// Цель захвата тянет и пристёгивает только его владелец: чужая хватка рвётся сразу, цель отстёгивается.
/proc/heretic_capture_lock_pull(mob/living/victim, mob/living/owner, source)
	if(!istype(victim) || QDELETED(victim))
		return
	LAZYSET(victim.heretic_pull_owners, source, WEAKREF(owner))
	if(victim.pulledby && victim.pulledby != owner)
		victim.pulledby.stop_pulling()
	victim.buckled?.unbuckle_mob(victim, TRUE)

/proc/heretic_capture_unlock_pull(mob/living/victim, source)
	if(QDELETED(victim))
		return
	LAZYREMOVE(victim.heretic_pull_owners, source)

/proc/heretic_capture_pull_refusal(mob/living/victim, mob/user)
	if(!LAZYLEN(victim?.heretic_pull_owners))
		return null
	for(var/source in victim.heretic_pull_owners)
		var/datum/weakref/owner_ref = victim.heretic_pull_owners[source]
		if(owner_ref?.resolve() == user)
			return null
	return "[victim] в чужом захвате: сдвинуть не получается."

/mob/living/can_be_pulled(user, grab_state, force)
	. = ..()
	if(!.)
		return
	var/refusal = heretic_capture_pull_refusal(src, user)
	if(!refusal)
		return
	if(ismob(user))
		to_chat(user, span_warning(refusal))
	return FALSE

/mob/living/can_buckle_others(mob/living/target, atom/buckle_to)
	. = ..()
	if(!. || !istype(target))
		return
	var/refusal = heretic_capture_pull_refusal(target, src)
	if(!refusal)
		return
	to_chat(src, span_warning(refusal))
	return FALSE

/// Сон или беспамятство, которым закончился захват: держится как захват, пока цель не очнётся.
/datum/status_effect/heretic_capture_knockout
	id = "heretic_capture_knockout"
	tick_interval = 1 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_MULTIPLE
	var/capture_id
	var/datum/weakref/knowledge_ref

/datum/status_effect/heretic_capture_knockout/on_creation(mob/living/new_owner, datum/eldritch_knowledge/knowledge, capture_id, time)
	src.capture_id = capture_id
	knowledge_ref = WEAKREF(knowledge)
	duration = time
	return ..()

/datum/status_effect/heretic_capture_knockout/on_apply()
	. = ..()
	heretic_capture_hold(owner, REF(src))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice_starting))

/datum/status_effect/heretic_capture_knockout/tick()
	if(!owner.IsSleeping() && !owner.IsUnconscious())
		qdel(src)

/datum/status_effect/heretic_capture_knockout/proc/on_shaken(datum/source)
	SIGNAL_HANDLER
	owner.SetSleeping(0)
	owner.SetUnconscious(0)
	qdel(src)

/datum/status_effect/heretic_capture_knockout/proc/on_sacrifice_starting(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_capture_knockout/on_remove()
	UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING))
	heretic_capture_unhold(owner, REF(src))
	return ..()

/proc/heretic_capture_knock_out(mob/living/victim, datum/eldritch_knowledge/knowledge, capture_id, time)
	return victim.apply_status_effect(/datum/status_effect/heretic_capture_knockout, knowledge, capture_id, time)

/datum/eldritch_knowledge/proc/knocked_out_by_capture(mob/living/victim)
	if(!victim?.IsSleeping() && !victim?.IsUnconscious())
		return FALSE
	for(var/datum/status_effect/heretic_capture_knockout/knockout as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_knockout))
		if(knockout.knowledge_ref?.resolve() == src)
			return TRUE
	return FALSE

/datum/status_effect/heretic_capture_immunity
	id = "heretic_capture_immunity"
	duration = HERETIC_CAPTURE_IMMUNITY
	tick_interval = -1
	alert_type = null
	status_type = STATUS_EFFECT_MULTIPLE
	var/capture_id

/datum/status_effect/heretic_capture_immunity/on_creation(mob/living/new_owner, capture_id, time)
	src.capture_id = capture_id
	if(!isnull(time))
		duration = time
	return ..()

#undef HERETIC_CAPTURE_SHARED
