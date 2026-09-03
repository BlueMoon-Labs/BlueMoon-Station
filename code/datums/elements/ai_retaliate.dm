//Порт tgstation@14140a6355d, адаптация: без TRAIT_SUBTREE_REQUIRED_OPERATIONAL_DATUM
//(инфраструктуры обязательных сабтри у basic-мобов в кодбазе нет); ключ
//BB_BASIC_MOB_RETALIATE_LIST уже определён в ai_blackboard.dm.
/**
 * ## Элемент ai_retaliate
 *
 * Вешается на моба с ai_controller и складывает всех, кто его ударил,
 * в blackboard-реестр обидчиков (BB_BASIC_MOB_RETALIATE_LIST: атакующий = world.time).
 * Что делать с этой информацией - решает сам контроллер.
 * Задел для мирных/немигрированных мобов; у hostile-мобов своя память обид.
 */
/datum/element/ai_retaliate

/datum/element/ai_retaliate/Attach(datum/target)
	. = ..()
	if(!ismob(target))
		return ELEMENT_INCOMPATIBLE
	target.AddElement(/datum/element/relay_attackers)
	RegisterSignal(target, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))

/datum/element/ai_retaliate/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_ATOM_WAS_ATTACKED)

/// Записываем атакующего в blackboard-список обидчиков
/datum/element/ai_retaliate/proc/on_attacked(mob/victim, atom/attacker)
	SIGNAL_HANDLER
	if(victim == attacker)
		return
	victim.ai_controller?.set_blackboard_key_assoc_lazylist(BB_BASIC_MOB_RETALIATE_LIST, attacker, world.time)
