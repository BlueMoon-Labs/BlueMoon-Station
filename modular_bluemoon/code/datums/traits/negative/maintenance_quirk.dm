/datum/quirk/high_quality_maintenance
	name = BLUEMOON_TRAIT_NAME_COMPLEX_MAINTENANCE
	desc = "ТОЛЬКО ДЛЯ СИНТЕТИКОВ! Ваше тело слишком сложно устроено, чтобы его мог оперировать кто угодно, кроме роботехника, РД (или антагонистов/гост-ролей)."
	gain_text = span_warning("Эти новые протезы такие классные... И дорогие! И сложные в обслуживании... И дорогие!")
	lose_text = span_notice("??")
	value = -4
	mob_trait = TRAIT_BLUEMOON_COMPLEX_MAINTENANCE
	on_spawn_immediate = FALSE // иначе on_spawn из-за потенциального удаления квирка ломается

/datum/quirk/high_quality_maintenance/on_spawn()
	. = ..()
	if(!HAS_TRAIT(quirk_holder, TRAIT_ROBOTIC_ORGANISM)) // только персонажи-синтетики могут пользоваться этим квирком
		to_chat(quirk_holder, span_warning("Все квирки были сброшены, т.к. квирк [src] не подходит виду персонажа."))
		var/list/user_quirks = quirk_holder.roundstart_quirks
		user_quirks -= src
		for(var/datum/quirk/Q as anything in user_quirks)
			qdel(Q)
		qdel(src)

/datum/job/roboticist/New()
	var/list/extra_mind_traits = list(TRAIT_QUALIFIED_ROBOTIC_MAINTER)
	LAZYADD(mind_traits, extra_mind_traits)
	. = ..()

/datum/job/rd/New()
	var/list/extra_mind_traits = list(TRAIT_QUALIFIED_ROBOTIC_MAINTER)
	LAZYADD(mind_traits, extra_mind_traits)
	. = ..()
