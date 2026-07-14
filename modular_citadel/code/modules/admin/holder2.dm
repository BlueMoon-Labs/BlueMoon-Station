/datum/admins
		var/following = null

/datum/admins/associate(client/C)
	..()
	if(istype(C))
		C.mentor_datum_set(TRUE)

/datum/admins/disassociate()
	if(owner)
		if(owner.mentor_datum)
			owner.become_inactive_mentor()
		owner.mentor_datum_set()
	..()
