//Порт tgstation@14140a6355d, адаптация под сигналы BlueMoon: COMSIG_PARENT_ATTACKBY
//(пре-атака, аналога COMSIG_ATOM_AFTER_ATTACKEDBY нет; отсеиваем NOBLUDGEON и force=0),
//COMSIG_MOB_ATTACK_HAND с интентами вместо combat_mode/modifiers (INTENT_HARM = урон,
//INTENT_DISARM = толчок), COMSIG_ATOM_BULLET_ACT вместо PROJECTILE_PREHIT (гард по
//nodamage и firer), COMSIG_ATOM_HITBY с thrownthing.thrower (нет get_thrower());
//хуки алиенов, мехов и басик-мобов убраны - таких сигналов в кодбазе нет.
/**
 * ## Элемент relay_attackers
 *
 * Слушает ворох сигналов вида "кто-то меня атаковал" и сводит их в единый
 * COMSIG_ATOM_WAS_ATTACKED с атакующим, флагами атаки и направлением.
 * Потребителям достаточно подписаться на один сигнал вместо десятка.
 */
/datum/element/relay_attackers

/datum/element/relay_attackers/Attach(datum/target)
	. = ..()
	if(!HAS_TRAIT(target, TRAIT_RELAYING_ATTACKER)) // элемент навешивают из многих мест - не дублируем подписки
		RegisterSignal(target, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
		RegisterSignal(target, COMSIG_MOB_ATTACK_HAND, PROC_REF(on_attack_hand))
		RegisterSignal(target, COMSIG_ATOM_ATTACK_PAW, PROC_REF(on_attack_paw))
		RegisterSignal(target, COMSIG_ATOM_ATTACK_ANIMAL, PROC_REF(on_attack_animal))
		RegisterSignal(target, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_bullet_act))
		RegisterSignal(target, COMSIG_ATOM_HITBY, PROC_REF(on_hitby))
		RegisterSignal(target, COMSIG_ATOM_HULK_ATTACK, PROC_REF(on_attack_hulk))
	ADD_TRAIT(target, TRAIT_RELAYING_ATTACKER, REF(src))

/datum/element/relay_attackers/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, list(
		COMSIG_PARENT_ATTACKBY,
		COMSIG_MOB_ATTACK_HAND,
		COMSIG_ATOM_ATTACK_PAW,
		COMSIG_ATOM_ATTACK_ANIMAL,
		COMSIG_ATOM_BULLET_ACT,
		COMSIG_ATOM_HITBY,
		COMSIG_ATOM_HULK_ATTACK,
	))
	REMOVE_TRAIT(source, TRAIT_RELAYING_ATTACKER, REF(src))

/// Замах предметом: сигнал летит до атаки, поэтому отсеиваем заведомо небоевые предметы
/datum/element/relay_attackers/proc/on_attackby(atom/target, obj/item/weapon, mob/attacker, params)
	SIGNAL_HANDLER
	if(!weapon.force || (weapon.item_flags & NOBLUDGEON))
		return
	relay_attacker(target, attacker, weapon.damtype == STAMINA ? ATTACKER_STAMINA_ATTACK : ATTACKER_DAMAGING_ATTACK, get_dir(target, attacker))

/// Голые руки: харм-интент бьёт, дизарм толкает, остальное атакой не считаем
/datum/element/relay_attackers/proc/on_attack_hand(mob/target, mob/living/attacker, act_intent)
	SIGNAL_HANDLER
	switch(act_intent)
		if(INTENT_HARM)
			relay_attacker(target, attacker, ATTACKER_DAMAGING_ATTACK, get_dir(target, attacker))
		if(INTENT_DISARM)
			relay_attacker(target, attacker, ATTACKER_SHOVING, get_dir(target, attacker))

/// Лапы обезьян: бьют только в харм-интенте
/datum/element/relay_attackers/proc/on_attack_paw(atom/target, mob/living/attacker)
	SIGNAL_HANDLER
	if(attacker.a_intent != INTENT_HARM)
		return
	relay_attacker(target, attacker, ATTACKER_DAMAGING_ATTACK, get_dir(target, attacker))

/// Атака simple_animal: считается, если у зверя вообще есть урон
/datum/element/relay_attackers/proc/on_attack_animal(atom/target, mob/living/simple_animal/attacker)
	SIGNAL_HANDLER
	if(attacker.melee_damage_upper <= 0)
		return
	relay_attacker(target, attacker, ATTACKER_DAMAGING_ATTACK, get_dir(target, attacker))

/// Даже если попадание чем-то заблокировано - в нас всё равно стреляли
/datum/element/relay_attackers/proc/on_bullet_act(atom/target, obj/item/projectile/hit_projectile)
	SIGNAL_HANDLER
	if(hit_projectile.nodamage || hit_projectile.damage <= 0)
		return
	if(!ismob(hit_projectile.firer))
		return
	relay_attacker(target, hit_projectile.firer, ATTACK_RANGED | (hit_projectile.damage_type == STAMINA ? ATTACKER_STAMINA_ATTACK : ATTACKER_DAMAGING_ATTACK), get_dir(target, hit_projectile))

/// Даже если бросок пойман/заблокирован - в нас всё равно кинули
/datum/element/relay_attackers/proc/on_hitby(atom/target, atom/movable/hit_atom, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(!isitem(hit_atom))
		return
	var/obj/item/hit_item = hit_atom
	if(!hit_item.throwforce)
		return
	var/mob/thrown_by = throwingdatum?.thrower
	if(!istype(thrown_by))
		return
	relay_attacker(target, thrown_by, ATTACK_RANGED | (hit_item.damtype == STAMINA ? ATTACKER_STAMINA_ATTACK : ATTACKER_DAMAGING_ATTACK), get_dir(target, hit_atom))

/// Кулак халка
/datum/element/relay_attackers/proc/on_attack_hulk(atom/target, mob/attacker)
	SIGNAL_HANDLER
	relay_attacker(target, attacker, ATTACKER_DAMAGING_ATTACK, get_dir(target, attacker))

/// Единая точка: рассылаем, кто нас только что атаковал (обычно моб)
/datum/element/relay_attackers/proc/relay_attacker(atom/victim, atom/attacker, attack_flags, direction)
	SEND_SIGNAL(victim, COMSIG_ATOM_WAS_ATTACKED, attacker, attack_flags, direction)
