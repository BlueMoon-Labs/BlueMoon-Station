/mob/living/Login()
	..()
	//Mind updates
	sync_mind()
//ambition start
	if(mind.memory || mind.antag_datums)
		// window = FALSE обязателен: с окном show_memory открывает browse()-попап и
		// возвращает пустую строку, то есть обёртка to_chat слала в чат голый <i></i>,
		// а попап тянул за собой setup_onclose с десятком winexists на каждого игрока.
		// Текст в чат ветка без окна печатает сама.
		mind.show_memory(src, window = FALSE)
//ambition end

	//Round specific stuff
	if(SSticker.mode)
		switch(SSticker.mode.name)
			if("sandbox")
				CanBuild()

	update_damage_hud()
	update_health_hud()

	var/turf/T = get_turf(src)
	if (isturf(T))
		update_z(T.z)

	if(ranged_ability)
		ranged_ability.add_ranged_ability(src, "<span class='notice'>You currently have <b>[ranged_ability]</b> active!</span>")

	var/datum/antagonist/changeling/changeling = mind.has_antag_datum(/datum/antagonist/changeling)
	if(changeling)
		changeling.regain_powers()

	if((vore_flags & VORE_INIT) && !(vore_flags & VOREPREF_INIT)) //Vore's been initialized, voreprefs haven't. If this triggers then that means that voreprefs failed to load due to the client being missing.
		copy_from_prefs_vr()

	set_ssd_indicator(FALSE) //SKYRAT CHANGE - ssd indicator
