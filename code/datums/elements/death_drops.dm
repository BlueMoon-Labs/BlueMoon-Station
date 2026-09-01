//Порт tgstation@14140a6355d, адаптация: id_arg_index вместо argument_hash_start_idx;
//убран спец-кейс /obj/effect/mob_spawn/corpse (нет донорского API create()/set_*_loss)
//и list_clear_nulls (без корпсов create_loot всегда возвращает объект).
/**
 * ## Элемент death_drops
 *
 * Декларативный лут при смерти вместо оверрайдов death()/drop_loot().
 * ELEMENT_BESPOKE по списку тайпов: list(тайп = количество) или просто list(тайпы).
 * В отличие от базового simple_animal.loot умеет счётчики, разброс по пикселям
 * и подавление лута при гибе (no_gib_drops).
 */
/datum/element/death_drops
	element_flags = ELEMENT_BESPOKE
	id_arg_index = 2
	/// Что дропает цель при смерти: список тайпов, опционально ассоциативный (тайп = количество)
	var/list/loot
	/// Не дропать лут при гибе?
	var/no_gib_drops

/datum/element/death_drops/Attach(datum/target, list/loot, no_gib_drops = FALSE)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE
	if(!loot)
		stack_trace("[type] добавлен на [target] БЕЗ ЛУТА.")
	src.loot = loot
	src.no_gib_drops = no_gib_drops
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/element/death_drops/Detach(datum/source, ...)
	. = ..()
	UnregisterSignal(source, COMSIG_LIVING_DEATH)

/// Обработчик смерти цели
/datum/element/death_drops/proc/on_death(mob/living/target, gibbed)
	SIGNAL_HANDLER
	if(no_gib_drops && gibbed)
		return

	var/list/spawn_loot
	if(islist(loot))
		spawn_loot = loot.Copy()
	else
		spawn_loot = list(loot)

	var/atom/loot_loc = target.drop_location()
	if(SEND_SIGNAL(target, COMSIG_LIVING_DROP_LOOT, spawn_loot, gibbed) & COMPONENT_NO_LOOT_DROP)
		return

	var/list/all_loot = list()
	for(var/thing_to_spawn in spawn_loot)
		for(var/i in 1 to (spawn_loot[thing_to_spawn] || 1))
			all_loot += create_loot(thing_to_spawn, loot_loc, target, gibbed, spread_px = spawn_loot.len * 3)

	SEND_SIGNAL(target, COMSIG_LIVING_DROPPED_LOOT, all_loot, gibbed)

/// Спавнит одну единицу лута с лёгким пиксельным разбросом
/datum/element/death_drops/proc/create_loot(typepath, atom/loot_loc, mob/living/dead, gibbed, spread_px = 4)
	var/atom/movable/drop = new typepath(loot_loc)
	if(isitem(drop) && spread_px)
		var/obj/item/dropped_item = drop
		var/clamped_px = clamp(spread_px, 0, 16)
		dropped_item.pixel_x = rand(-clamped_px, clamped_px)
		dropped_item.pixel_y = rand(-clamped_px, clamped_px)
	return drop
