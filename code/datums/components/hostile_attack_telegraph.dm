/**
 * Даёт сильным hostile-мобам читаемое окно перед мили-ударом.
 * Адаптация tg basic_mob_attack_telegraph под BlueMoon simple_animal API.
 */
/datum/component/hostile_attack_telegraph
	var/telegraph_duration
	var/mutable_appearance/target_overlay
	var/atom/current_target
	var/replaying_attack = FALSE

/datum/component/hostile_attack_telegraph/Initialize(duration = 0.4 SECONDS, telegraph_icon = 'icons/mob/telegraphing/telegraph.dmi', telegraph_state = ATTACK_EFFECT_SMASH)
	if(!istype(parent, /mob/living/simple_animal/hostile))
		return COMPONENT_INCOMPATIBLE
	telegraph_duration = duration
	target_overlay = mutable_appearance(telegraph_icon, telegraph_state)

/datum/component/hostile_attack_telegraph/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_HOSTILE_ATTACKINGTARGET, PROC_REF(on_attack))

/datum/component/hostile_attack_telegraph/UnregisterFromParent()
	forget_target(current_target)
	UnregisterSignal(parent, COMSIG_HOSTILE_ATTACKINGTARGET)
	return ..()

/datum/component/hostile_attack_telegraph/Destroy()
	forget_target(current_target)
	target_overlay = null
	return ..()

/datum/component/hostile_attack_telegraph/proc/on_attack(mob/living/simple_animal/hostile/source, atom/target)
	SIGNAL_HANDLER
	if(source.client || !(isliving(target) || istype(target, /obj/vehicle/sealed/mecha)))
		return
	if(replaying_attack)
		replaying_attack = FALSE
		return
	if(!current_target)
		INVOKE_ASYNC(src, PROC_REF(delayed_attack), source, target)
	return COMPONENT_HOSTILE_NO_ATTACK

/datum/component/hostile_attack_telegraph/proc/delayed_attack(mob/living/simple_animal/hostile/source, atom/target)
	if(QDELETED(source) || QDELETED(target))
		return
	current_target = target
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(forget_target))
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(target_moved))
	RegisterSignal(target, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_target_overlays_update))
	target.update_appearance()
	sleep(telegraph_duration)
	if(QDELETED(source) || QDELETED(target) || current_target != target || source.target != target || !source.Adjacent(target))
		forget_target(target)
		return
	forget_target(target)
	replaying_attack = TRUE
	source.target = target
	source.AttackingTarget()
	//Если сабтип не дошёл до родительского сигнала, не пропускаем следующий удар.
	replaying_attack = FALSE

/datum/component/hostile_attack_telegraph/proc/target_moved(atom/target)
	SIGNAL_HANDLER
	if(!target.Adjacent(parent))
		forget_target(target)

/datum/component/hostile_attack_telegraph/proc/forget_target(atom/target)
	SIGNAL_HANDLER
	if(!target || target != current_target)
		return
	current_target = null
	UnregisterSignal(target, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED, COMSIG_ATOM_UPDATE_OVERLAYS))
	if(!QDELETED(target))
		target.update_appearance()

/datum/component/hostile_attack_telegraph/proc/on_target_overlays_update(atom/target, list/overlays)
	SIGNAL_HANDLER
	if(target == current_target)
		overlays += target_overlay
