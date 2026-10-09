
/datum/element/ambidextria_attack
	element_flags = ELEMENT_DETACH | ELEMENT_BESPOKE
	id_arg_index = 2
	// С предметами какого типа, будет производиться двойная атака
	var/list/attack_with_type

/datum/element/ambidextria_attack/Attach(obj/item/target, list/_attack_with_type)
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE
	. = ..()
	if(_attack_with_type)
		if(islist(_attack_with_type) && _attack_with_type.len)
			attack_with_type = _attack_with_type.Copy()
		else
			attack_with_type = list(_attack_with_type)
	if(!attack_with_type)
		attack_with_type = list(target.type)
	RegisterSignal(target, COMSIG_ITEM_ATTACK, PROC_REF(attack))
	RegisterSignal(target, COMSIG_ITEM_ATTACK_OBJ, PROC_REF(attack_obj))

/datum/element/ambidextria_attack/Detach(obj/item/source)
	. = ..()
	UnregisterSignal(source, list(COMSIG_ITEM_ATTACK, COMSIG_ITEM_ATTACK_OBJ))

/datum/element/ambidextria_attack/proc/get_second_blade(obj/item/blade, mob/living/user)
	var/obj/item/second_blade = user.get_inactive_held_item()
	// Если это сигнал от предмета во второй руке или не подходит по типу = игнорируем
	if(blade == second_blade || !is_type_in_list(second_blade, attack_with_type))
		return
	return second_blade

/datum/element/ambidextria_attack/proc/attack(obj/item/source, mob/living/M, mob/living/user, damage_multiplier)
	SIGNAL_HANDLER
	var/obj/item/second_blade = get_second_blade(source, user)
	if(!second_blade)
		return
	addtimer(CALLBACK(src, PROC_REF(second_attack), second_blade, M, user, damage_multiplier), 0.2 SECONDS)

/datum/element/ambidextria_attack/proc/attack_obj(obj/item/source, obj/O, mob/living/user)
	SIGNAL_HANDLER
	var/obj/item/second_blade = get_second_blade(source, user)
	if(!second_blade)
		return
	addtimer(CALLBACK(src, PROC_REF(second_attack_obj), second_blade, O, user), 0.2 SECONDS)

/datum/element/ambidextria_attack/proc/second_attack(obj/item/second_blade, mob/living/target, mob/living/user, damage_multiplier)
	if(QDELETED(second_blade) || QDELETED(target) || QDELETED(user))
		return
	second_blade.attack(target, user, NONE, damage_multiplier)

/datum/element/ambidextria_attack/proc/second_attack_obj(obj/item/second_blade, obj/target, mob/living/user)
	if(QDELETED(second_blade) || QDELETED(target) || QDELETED(user))
		return
	second_blade.attack_obj(target, user)
