/// Removes request files left behind if the server stopped during a loadout crypto operation.
SUBSYSTEM_DEF(loadout_crypto_cleanup)
	name = "Loadout crypto cleanup"
	flags = SS_NO_FIRE

/datum/controller/subsystem/loadout_crypto_cleanup/Initialize(timeofday)
	var/list/leftovers = flist("tmp/")
	if(leftovers)
		var/static/regex/loadout_crypto_file = regex("^[LOADOUT_CRYPTO_TMP_FILENAME]_\[a-f0-9]{[LOADOUT_CRYPTO_REQUEST_ID_HEX_LENGTH]}\\.json(?:\\.out(?:\\.err)?)?$")
		for(var/filename in leftovers)
			if(loadout_crypto_file.Find(filename))
				fdel("tmp/[filename]")
	return ..()
