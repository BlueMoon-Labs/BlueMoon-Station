// (FILE EDIT) Pe4henika bluemoon 01.03.2026
/mob/living/silicon/robot/verb/cmd_show_laws()
	set category = "Robot Commands"
	set name = "Show Laws"

	if(usr.stat == DEAD)
		return //won't work if dead
	show_laws()

/mob/living/silicon/robot/show_laws(everyone = 0)
	laws_sanity_check()
	var/who = everyone ? world : src

	if(lawupdate && connected_ai)
		if(connected_ai.stat || connected_ai.control_disabled)
			to_chat(src, "<b>AI signal lost, unable to sync laws.</b>")
		else
			lawsync(FALSE)
	else if(lawupdate && !connected_ai)
		to_chat(src, "<b>No AI selected to sync laws with, disabling lawsync protocol.</b>")
		lawupdate = 0

	laws.show_laws(who)
	if (shell) //AI shell
		to_chat(who, "<b>Remember, you are an AI remotely controlling your shell, other AIs can be ignored.</b>")
	else if (connected_ai)
		to_chat(who, "<b>Remember, [connected_ai.name] is your master, other AIs can be ignored.</b>")
	else if (emagged)
		to_chat(who, "<b>Remember, you are not required to listen to the AI.</b>")
	else
		to_chat(who, "<b>Remember, you are not bound to any AI, you are not required to listen to them.</b>")

/mob/living/silicon/robot/proc/lawsync(announce = FALSE)
	laws_sanity_check()
	var/datum/ai_laws/master = connected_ai ? connected_ai.laws : null
	if (!master)
		return

	// Оптимизированное копирование законов
	laws.devillaws = master.devillaws.Copy()
	laws.ion = master.ion.Copy()
	laws.hacked = master.hacked.Copy()
	laws.zeroth = master.zeroth_borg ? master.zeroth_borg : master.zeroth
	laws.inherent = master.inherent.Copy()
	laws.supplied = master.supplied.Copy()

	picturesync()

	if(announce)
		post_lawchange(TRUE)
