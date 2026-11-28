/// This should match the interface of /client wherever necessary.
/datum/client_interface
	/// Player preferences datum for the client
	var/datum/preferences/prefs

	/// The view of the client, similar to /client/var/view.
	var/view = "15x15"

	var/datum/admins/holder
	var/datum/mentors/mentor_datum
	/// Последний ввод, как /client/var/last_activity.
	var/last_activity = 0

/datum/client_interface/New()
	. = ..()
	last_activity = world.time

/datum/client_interface/proc/is_afk(duration = CONFIG_GET(number/inactivity_period))
	var/inactivity = world.time - last_activity
	return inactivity > duration ? inactivity : FALSE
