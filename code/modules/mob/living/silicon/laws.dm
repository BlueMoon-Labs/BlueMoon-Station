/mob/living/silicon/proc/show_laws() //Redefined in ai/laws.dm and robot/laws.dm
	return

/mob/living/silicon/proc/laws_sanity_check()
	if (!laws)
		make_laws()

// (EDIT) Pe4henika bluemoon -- start
/mob/living/silicon/proc/post_lawchange(announce = TRUE)
    throw_alert("newlaw", /atom/movable/screen/alert/newlaw)
    if(announce && last_lawchange_announce != world.time)
        to_chat(src, "<br><span class='userdanger'><font size=4>ВНИМАНИЕ: Ваши законы были изменены!</font></span>")
        to_chat(src, "<span class='userdanger'>Проверьте активный набор законов немедленно.</span><br>")

        src << 'sound/machines/terminal_processing.ogg'

        addtimer(CALLBACK(src, PROC_REF(show_laws)), 0, TIMER_DELETE_ME)
        last_lawchange_announce = world.time

        // Если законы сменились у ИИ, пушим обновление всем боргам в сети
        if(isAI(src))
            var/mob/living/silicon/ai/AI = src
            for(var/mob/living/silicon/robot/R in GLOB.silicon_mobs)
                if(R.connected_ai == AI && R.lawupdate)
                    R.lawsync(TRUE) // TRUE передает announce в lawsync
// (EDIT) Pe4henika bluemoon -- end

/mob/living/silicon/proc/set_law_sixsixsix(law, announce = TRUE)
	laws_sanity_check()
	laws.set_law_sixsixsix(law)
	post_lawchange(announce)

/mob/living/silicon/proc/set_zeroth_law(law, law_borg, announce = TRUE)
	laws_sanity_check()
	laws.set_zeroth_law(law, law_borg)
	post_lawchange(announce)

/mob/living/silicon/proc/add_inherent_law(law, announce = TRUE)
	laws_sanity_check()
	laws.add_inherent_law(law)
	post_lawchange(announce)

/mob/living/silicon/proc/clear_inherent_laws(announce = TRUE)
	laws_sanity_check()
	laws.clear_inherent_laws()
	post_lawchange(announce)

/mob/living/silicon/proc/add_supplied_law(number, law, announce = TRUE)
	laws_sanity_check()
	laws.add_supplied_law(number, law)
	post_lawchange(announce)

/mob/living/silicon/proc/clear_supplied_laws(announce = TRUE)
	laws_sanity_check()
	laws.clear_supplied_laws()
	post_lawchange(announce)

/mob/living/silicon/proc/add_ion_law(law, announce = TRUE)
	laws_sanity_check()
	laws.add_ion_law(law)
	post_lawchange(announce)

/mob/living/silicon/proc/add_hacked_law(law, announce = TRUE)
	laws_sanity_check()
	laws.add_hacked_law(law)
	post_lawchange(announce)

/mob/living/silicon/proc/replace_random_law(law, groups, announce = TRUE)
	laws_sanity_check()
	. = laws.replace_random_law(law,groups)
	post_lawchange(announce)

/mob/living/silicon/proc/shuffle_laws(list/groups, announce = TRUE)
	laws_sanity_check()
	laws.shuffle_laws(groups)
	post_lawchange(announce)

/mob/living/silicon/proc/remove_law(number, announce = TRUE)
	laws_sanity_check()
	. = laws.remove_law(number)
	post_lawchange(announce)

/mob/living/silicon/proc/clear_ion_laws(announce = TRUE)
	laws_sanity_check()
	laws.clear_ion_laws()
	post_lawchange(announce)

/mob/living/silicon/proc/clear_hacked_laws(announce = TRUE)
	laws_sanity_check()
	laws.clear_hacked_laws()
	post_lawchange(announce)

/mob/living/silicon/proc/make_laws()
	laws = new /datum/ai_laws
	laws.set_laws_config()
	laws.associate(src)

/mob/living/silicon/proc/clear_zeroth_law(force, announce = TRUE)
	laws_sanity_check()
	laws.clear_zeroth_law(force)
	post_lawchange(announce)

/mob/living/silicon/proc/clear_law_sixsixsix(force, announce = TRUE)
	laws_sanity_check()
	laws.clear_law_sixsixsix(force)
	post_lawchange(announce)
