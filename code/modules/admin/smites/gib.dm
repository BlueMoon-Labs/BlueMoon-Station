/datum/smite/gib
	name = "Gib"

/datum/smite/gib/effect(client/user, mob/living/target)
	. = ..()
	sleep(6 SECONDS)
	if(QDELETED(target))
		return
	target.psydo_nyte()
	target.playsound_local(target, 'modular_bluemoon/sound/misc/psydong.ogg', 100, FALSE)
	sleep(2 SECONDS)
	if(QDELETED(target))
		return
	target.psydo_nyte()
	target.playsound_local(target, 'modular_bluemoon/sound/misc/psydong.ogg', 100, FALSE)
	sleep(1.5 SECONDS)
	if(QDELETED(target))
		return
	target.psydo_nyte()
	target.playsound_local(target, 'modular_bluemoon/sound/misc/psydong.ogg', 100, FALSE)
	sleep(1 SECONDS)
	if(QDELETED(target))
		return
	target.gib(FALSE)
