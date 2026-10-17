/datum/mind
	/// Последнее убийство игрока, совершённое антагом: открывает его для охоты HK-47 и служит первым следом.
	var/hk47_kill_time
	var/hk47_kill_area
	var/hk47_hunted = FALSE

GLOBAL_DATUM_INIT(hk47_kill_ledger, /datum/hk47_kill_ledger, new)

/// Весь раунд отмечает антагов, убивших члена экипажа: охота HK-47 приходит и после таких убийств.
/datum/hk47_kill_ledger

/mob/living
	/// ckey и world.time последнего удара или выстрела по мобу, для журнала убийств HK-47.
	var/hk47_attacker_ckey
	var/hk47_attack_time

/// Кто бил или стрелял в моба последним, если это было не раньше HK47_HIT_MEMORY назад.
/proc/hk47_recent_attacker(mob/living/victim)
	if(isnull(victim?.hk47_attack_time) || world.time - victim.hk47_attack_time > HK47_HIT_MEMORY)
		return null
	return victim.hk47_attacker_ckey

/datum/hk47_kill_ledger/proc/listen()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death))
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_spawn))

/datum/hk47_kill_ledger/proc/on_job_spawn(datum/source, datum/job/job, mob/living/spawned, client/player_client)
	SIGNAL_HANDLER
	watch(spawned)

/// Тело экипажа под учётом ударов и выстрелов; учёт уходит за разумом в новые тела.
/datum/hk47_kill_ledger/proc/watch(mob/living/body)
	if(!isliving(body))
		return
	RegisterSignal(body, COMSIG_LIVING_ATTACKER_SET, PROC_REF(on_attacked), override = TRUE)
	RegisterSignal(body, COMSIG_LIVING_HIT_BY_PROJECTILE, PROC_REF(on_shot), override = TRUE)
	RegisterSignal(body, COMSIG_MOB_ON_NEW_MIND, PROC_REF(on_new_mind), override = TRUE)
	if(body.mind)
		RegisterSignal(body.mind, COMSIG_MIND_TRANSFER, PROC_REF(on_mind_transfer), override = TRUE)

/datum/hk47_kill_ledger/proc/on_new_mind(mob/living/source)
	SIGNAL_HANDLER
	if(source.mind)
		RegisterSignal(source.mind, COMSIG_MIND_TRANSFER, PROC_REF(on_mind_transfer), override = TRUE)

/datum/hk47_kill_ledger/proc/on_mind_transfer(datum/mind/source, mob/new_character, mob/old_character)
	SIGNAL_HANDLER
	watch(new_character)

/datum/hk47_kill_ledger/proc/on_attacked(mob/living/source, mob/attacker)
	SIGNAL_HANDLER
	note_attack(source, attacker)

/datum/hk47_kill_ledger/proc/on_shot(mob/living/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	note_attack(source, projectile.firer)

/datum/hk47_kill_ledger/proc/note_attack(mob/living/victim, mob/attacker)
	if(!ismob(attacker) || attacker == victim || !attacker.ckey)
		return
	victim.hk47_attacker_ckey = attacker.ckey
	victim.hk47_attack_time = world.time

/datum/hk47_kill_ledger/proc/on_mob_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	var/killer_ckey = hk47_recent_attacker(died)
	if(!died.mind || !killer_ckey || killer_ckey == died.ckey)
		return
	var/datum/mind/killer = hk47_mind_by_ckey(killer_ckey)
	if(!killer || killer == died.mind || !hk47_is_antag_mind(killer))
		return
	killer.hk47_kill_time = world.time
	killer.hk47_kill_area = get_area_name(died, TRUE)

/datum/controller/subsystem/ticker/Initialize(timeofday)
	. = ..()
	GLOB.hk47_kill_ledger.listen()
