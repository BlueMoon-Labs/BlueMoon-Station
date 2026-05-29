/datum/round_event_control/wizard_dice
	name = "Wizard Dice"
	typepath = /datum/round_event/wizard_dice
	category = EVENT_CATEGORY_WIZARD
	description = "Spawns the same Die of Fate as lavaland/colossus loot — full 1–20 table (dust on 1, wizard on 20, etc.)."
	min_players = 30
	max_occurrences = 1
	weight = 10
	earliest_start = 60 MINUTES

/datum/round_event/wizard_dice
	announce_chance = 100
	announce_when = 30
	end_when = 300
	var/obj/item/dice/d20/fate/created_dice

/datum/round_event/wizard_dice/setup()
	created_dice = new /obj/item/dice/d20/fate(get_safe_lucky_player_turf())
	RegisterSignal(created_dice, COMSIG_PARENT_QDELETING, PROC_REF(on_dice_destroy))

/datum/round_event/wizard_dice/start()
	announce_to_ghosts(created_dice)

/datum/round_event/wizard_dice/announce(fake)
	priority_announce("В этом районе обнаружен магический двадцатигранный артефакт. Пожалуйста, воздержитесь от взаимодействия с артефактами Магической Федерации — это грубое нарушение Космического Закона, пункт 404.", "Эксперт-маголог предупреждает")

/datum/round_event/wizard_dice/kill()
	if(created_dice && !QDELETED(created_dice))
		UnregisterSignal(created_dice, COMSIG_PARENT_QDELETING)
	. = ..()
	if(created_dice && !QDELETED(created_dice))
		qdel(created_dice)
	created_dice = null

/datum/round_event/wizard_dice/proc/on_dice_destroy()
	SIGNAL_HANDLER
	processing = FALSE
	kill()
