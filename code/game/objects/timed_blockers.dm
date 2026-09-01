#define FOG_DISSIPATE_TIME_MAX 60 MINUTES
/// Сколько времени остаётся у связанного щита после того, как гост-роль заняли.
#define SHIELD_FADE_ON_CLAIM_TIME 3 MINUTES

/obj/structure/shield
	name = "Heavy Shield"
	desc = "Густой, плотный, энергетический щит. Обычно, таких хватает на галактический час."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-red"
	density = FALSE
	anchored = TRUE
	opacity = FALSE//from TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/expire_time // world.time when this shield should dissipate
	var/dissipate_timer_id
	/// Путь антаг-датума (например /datum/antagonist/cult/neutered/ghost_role).
	/// Когда роль занимает игрок с таким антагонизмом, щит начинает быстро истаивать.
	var/antag_type
	/// Сколько времени остаётся щиту после появления гост-роли.
	var/fade_time = SHIELD_FADE_ON_CLAIM_TIME

GLOBAL_LIST_EMPTY(trespass_warns) // to avoid spamming the bandit's chat

/obj/structure/shield/Initialize()
	. = ..()
	expire_time = world.time + FOG_DISSIPATE_TIME_MAX
	dissipate_timer_id = addtimer(CALLBACK(src, PROC_REF(dissipate_fog)), FOG_DISSIPATE_TIME_MAX, TIMER_STOPPABLE)
	if(antag_type)
		RegisterSignal(SSdcs, COMSIG_GHOST_ROLE_CLAIMED, PROC_REF(handle_ghost_role_claimed))

/obj/structure/shield/Destroy()
	if(dissipate_timer_id)
		deltimer(dissipate_timer_id)
		dissipate_timer_id = null
	UnregisterSignal(SSdcs, COMSIG_GHOST_ROLE_CLAIMED)
	return ..()

/obj/structure/shield/proc/dissipate_fog()
	qdel(src)

/obj/structure/shield/proc/accelerate_dissipation(new_remaining)
	if(QDELETED(src))
		return
	if(new_remaining <= 0)
		dissipate_fog()
		return
	if((expire_time - world.time) <= new_remaining)
		return
	expire_time = world.time + new_remaining
	if(dissipate_timer_id)
		deltimer(dissipate_timer_id)
	dissipate_timer_id = addtimer(CALLBACK(src, PROC_REF(dissipate_fog)), new_remaining, TIMER_STOPPABLE)
	visible_message(span_warning("[src] мерцает и начинает быстро истаивать..."))

/obj/structure/shield/proc/handle_ghost_role_claimed(datum/source, mob/living/spawned)
	SIGNAL_HANDLER
	if(QDELETED(spawned) || !spawned.mind || !LAZYLEN(spawned.mind.antag_datums))
		return
	for(var/datum/antagonist/A in spawned.mind.antag_datums)
		if(istype(A, antag_type))
			accelerate_dissipation(fade_time)
			return

/datum/atom_hud/alternate_appearance/shield/mobShouldSee(mob/M)
	return TRUE

/obj/structure/shield/proc/describe_time()
	var/timedesc = "...хм, ну даже не знаю"
	var/remaining = expire_time - world.time
	switch(remaining)
		if(0 to 1 MINUTES)
			timedesc = "на грани полного исчезновения"
		if(1 to 5 MINUTES)
			timedesc = "пропадающим"
		if(5 MINUTES to 15 MINUTES)
			timedesc = "почти что пропадающим"
		if(15 MINUTES to 30 MINUTES)
			timedesc = "достаточно рабочим"
		if(30 MINUTES to FOG_DISSIPATE_TIME_MAX)
			timedesc = "более чем рабочим"
	return timedesc

/obj/structure/shield/examine(mob/user)
	. = ..()
	. += span_info("В данный момент, энергетический щит смотрится [span_notice(describe_time())]. | Вторжение через энергетические щиты взведёт ракеты типа КОСМОС-КОСМОС ближайшего фрегата в активное состояние")

/obj/structure/shield/CanPass(atom/movable/AM)
	if(AM in GLOB.trespass_warns)
		return FALSE
	if(isliving(AM))
		var/mob/living/M = AM
		to_chat(M, span_warning("Я не могу пройти через щит.") + span_info("\n\
							В данный момент, щит смотрится [span_notice(describe_time())]."))
		GLOB.trespass_warns += M
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(clear_trespass_warning), M), 40 SECONDS)
		return FALSE

/proc/clear_trespass_warning(mob/target)
	if(target)
		GLOB.trespass_warns -= target

/obj/structure/shield/yellow
	icon_state = "shield-yellow"

/obj/structure/shield/golden
	icon_state = "shield-golden"

/obj/structure/shield/grey
	icon_state = "shield-grey"

/obj/structure/shield/blue
	icon_state = "shield-old"

// ---------- Щиты, связанные с гост-ролями ----------
// Реагируют на занятие конкретной роли: как только игрок заспавнился с указанным
// антагонизмом, все такие щиты на карте начинают истаивать за fade_time.

/obj/structure/shield/bloodward
	name = "Blood Shield"
	desc = "Густой, плотный, энергетический щит алого оттенка. Плетения Кровавого Геометра без присмотра живых культистов быстро тают."
	icon_state = "shield-red"
	antag_type = /datum/antagonist/cult/neutered/ghost_role

/obj/structure/shield/clockward
	name = "Clock Shield"
	desc = "Густой, плотный, энергетический щит золотистого оттенка. Шестерни Всемогущего Двигателя без присмотра слуг быстро останавливаются."
	icon_state = "shield-yellow"
	antag_type = /datum/antagonist/clockcult/neutered/ghost_role

/datum/antagonist/cult/neutered/ghost_role
	name = "Cultist Remnant"

/datum/antagonist/clockcult/neutered/ghost_role
	name = "Clock Cultist Remnant"
