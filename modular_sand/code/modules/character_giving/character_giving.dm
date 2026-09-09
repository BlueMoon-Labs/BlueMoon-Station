#define REDEMPTION_CODE_GENERATION_ATTEMPTS 5

GLOBAL_LIST_INIT(character_offers, list())

/datum/character_offer_instance
	var/owner_ckey
	var/savefile/character_savefile
	var/redemption_code

/datum/character_offer_instance/New(owner_ckey, character_savefile)
	. = ..()
	if(!owner_ckey || !character_savefile)
		qdel(src)
		return
	src.owner_ckey = owner_ckey
	src.character_savefile = character_savefile

	// 5 digit number, no fucking way some idiot is guessing this
	var/attempts = 0
	while(!redemption_code || LAZYFIND(GLOB.character_offers, redemption_code))
		if(attempts >= REDEMPTION_CODE_GENERATION_ATTEMPTS)
			qdel(src)
			return
		redemption_code = "[random_nukecode()]"
		attempts++

	LAZYSET(GLOB.character_offers, redemption_code, src)

/datum/character_offer_instance/Destroy(force, ...)
	// Префы могут быть не из GLOB.preferences_datums (снос датума префов зовёт нас сам).
	var/datum/preferences/to_remove = LAZYACCESS(GLOB.preferences_datums, owner_ckey)
	if(to_remove)
		to_remove.offer = null
	LAZYREMOVE(GLOB.character_offers, redemption_code)
	owner_ckey = null
	character_savefile = null
	redemption_code = null
	return ..()

/datum/character_offer_instance/proc/on_quit()
	qdel(src)

#undef REDEMPTION_CODE_GENERATION_ATTEMPTS
