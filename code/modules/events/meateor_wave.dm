/datum/round_event_control/meteor_wave/meaty
	name = "Meteor Wave: Meaty"
	typepath = /datum/round_event/meteor_wave/meaty
	weight = 2
	max_occurrences = 1
	description = "A meteor wave made of meat."
	category = EVENT_CATEGORY_SPACE

/datum/round_event/meteor_wave/meaty
	wave_name = "meaty"

/datum/round_event/meteor_wave/meaty/announce(fake)
	if(!fake)
		notify_market()
	priority_announce("\"Митиоры\" были обнаружены на пути столкновения со станцией.", "Тащи Швабру!", "meteors", has_important_message = TRUE)
