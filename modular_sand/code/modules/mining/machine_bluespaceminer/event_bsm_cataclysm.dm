/// Админский ивент (weight = 0, admin_only): запускается только вручную через
/// "Admin.Events -> Trigger Event" и наводит tunguska-класс блюспейс-метеорит на
/// блюспейс-майнер через /proc/bsm_spawn_meteor_at_miner(). Админ может прицелиться
/// в конкретный майнер либо оставить случайную цель.

/proc/bsm_get_all_miners()
	var/list/miners = list()
	var/list/by_zlevel = SSmachines.bluespaceminer_by_zlevel
	if(!islist(by_zlevel))
		return miners
	for(var/z in 1 to length(by_zlevel))
		var/list/z_miners = by_zlevel[z]
		if(!islist(z_miners))
			continue
		for(var/obj/machinery/mineral/bluespace_miner/miner as anything in z_miners)
			if(miner && !QDELETED(miner))
				miners += miner
	return miners

/proc/bsm_pick_random_miner()
	var/list/miners = bsm_get_all_miners()
	if(!length(miners))
		return null
	return pick(miners)

/datum/round_event_control/bsm_cataclysm
	name = "Bluespace Cataclysm Meteor"
	typepath = /datum/round_event/bsm_cataclysm
	category = EVENT_CATEGORY_SPACE
	description = "Крупный привязанный к блюспейсу метеорит пронзает станцию и бьёт по выбранному (или случайному) блюспейс-майнеру."
	weight = 0
	admin_only = TRUE
	max_occurrences = 0
	earliest_start = 0
	min_players = 0
	severity = DIRECTOR_SEVERITY_MAJOR
	admin_setup = list(/datum/event_admin_setup/bsm_cataclysm_target)

/datum/round_event/bsm_cataclysm
	start_when = 1
	end_when = 2
	/// Целевой блюспейс-майнер (выбран админом); null = случайный из реестра.
	var/obj/machinery/mineral/bluespace_miner/target_miner

/datum/round_event/bsm_cataclysm/start()
	var/obj/machinery/mineral/bluespace_miner/target = target_miner
	if(QDELETED(target))
		target = bsm_pick_random_miner()
	if(QDELETED(target))
		message_admins("Bluespace Cataclysm Meteor не нашёл ни одного рабочего блюспейс-майнера и не был запущен.")
		return
	bsm_spawn_meteor_at_miner(target)
	bsm_log_instability(target, "admin event", "admin-forced cataclysm meteor via round event")

/// Админ прицеливается в конкретный блюспейс-майнер; "Случайный майнер" = авто-выбор.
/datum/event_admin_setup/bsm_cataclysm_target
	var/input_text = "Навести блюспейс-метеор на конкретный блюспейс-майнер?"
	/// Цель, выбранная админом; null = случайный майнер.
	var/obj/machinery/mineral/bluespace_miner/chosen_miner

/datum/event_admin_setup/bsm_cataclysm_target/prompt_admins()
	var/list/options = list()
	var/random_option = "Случайный майнер"
	options[random_option] = null
	for(var/obj/machinery/mineral/bluespace_miner/miner as anything in bsm_get_all_miners())
		options["[AREACOORD(miner)]"] = miner
	var/choice = tgui_input_list(usr, input_text, event_control.name, options)
	if(isnull(choice))
		return ADMIN_CANCEL_EVENT
	chosen_miner = options[choice]

/datum/event_admin_setup/bsm_cataclysm_target/apply_to_event(datum/round_event/bsm_cataclysm/event)
	event.target_miner = chosen_miner
	var/target_text = chosen_miner ? "майнер [AREACOORD(chosen_miner)]" : "случайный майнер"
	message_admins("[key_name_admin(usr)] направил блюспейс-метеор на [target_text].")
	log_admin("[key_name(usr)] aimed the bluespace cataclysm meteor at [target_text].")