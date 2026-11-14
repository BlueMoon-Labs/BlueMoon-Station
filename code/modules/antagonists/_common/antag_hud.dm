/datum/atom_hud/antag
	hud_icons = list(ANTAG_HUD)
	var/self_visible = TRUE
	/// Слабые ссылки на разумы, у которых этот худ записан в antag_hud_states
	var/list/datum/weakref/member_minds

/datum/atom_hud/antag/hidden
	self_visible = FALSE

/datum/atom_hud/antag/New()
	// Своя категория значка у каждого антаг-худа: у культиста-революционера два значка, и каждую команду видит своя
	var/static/antag_hud_serial = 0
	hud_icons = list("[ANTAG_HUD]_[++antag_hud_serial]")
	return ..()

/datum/atom_hud/antag/Destroy()
	for(var/mob/member as anything in hudatoms.Copy())
		leave_hud(member)
	for(var/datum/weakref/mind_ref as anything in member_minds?.Copy())
		var/datum/mind/mind = mind_ref.resolve()
		if(mind)
			forget_mind(mind)
	member_minds = null
	return ..()

/datum/atom_hud/antag/proc/join_hud(mob/M)
	//sees_hud should be set to 0 if the mob does not get to see it's own hud type.
	if(!istype(M))
		CRASH("join_hud(): [M] ([M?.type]) is not a mob!")
	var/datum/mind/mind = M.mind
	if(!mind)
		CRASH("join_hud(): [M] ([M.type]) has no mind!")
	if(!(M in hudatoms))
		var/category = hud_icons[1]
		if(!M.hud_list)
			M.hud_list = list()
		if(!M.hud_list[category])
			var/image/holder = image('icons/mob/hud.dmi', M, "")
			holder.appearance_flags = RESET_COLOR|RESET_TRANSFORM
			M.hud_list[category] = holder
		add_to_hud(M)
		if(self_visible)
			add_hud_to(M)
	if(!mind.antag_hud_states)
		mind.antag_hud_states = list()
	if(!(src in mind.antag_hud_states))
		mind.antag_hud_states[src] = null
	LAZYOR(member_minds, WEAKREF(mind))
	mind.antag_hud = src
	mind.antag_hud_icon_state = mind.antag_hud_states[src]

/datum/atom_hud/antag/proc/leave_hud(mob/M)
	if(!M)
		return
	if(!istype(M))
		CRASH("leave_hud(): [M] ([M.type]) is not a mob!")
	remove_from_hud(M)
	remove_hud_from(M)
	var/category = hud_icons[1]
	var/image/holder = M.hud_list?[category]
	if(holder)
		holder.loc = null
		M.hud_list -= category
	if(M.mind)
		forget_mind(M.mind)

/datum/atom_hud/antag/proc/forget_mind(datum/mind/mind)
	LAZYREMOVE(member_minds, mind.weak_reference)
	if(mind.antag_hud_states)
		mind.antag_hud_states -= src
		if(!length(mind.antag_hud_states))
			mind.antag_hud_states = null
	if(mind.antag_hud == src)
		mind.antag_hud = null
		mind.antag_hud_icon_state = null


//GAME_MODE PROCS
/// Ставит значок антаг-худа hud; без hud - последнего худа, в который вступил разум
/proc/set_antag_hud(mob/M, new_icon_state, datum/atom_hud/antag/hud)
	if(!M)
		return
	if(!istype(M))
		CRASH("set_antag_hud(): [M] ([M.type]) is not a mob!")
	var/datum/mind/mind = M.mind
	if(!hud)
		// Значок снимает leave_hud; пустой без худа после него стёр бы значок другой роли
		if(!new_icon_state)
			return
		hud = mind?.antag_hud
	if(!hud)
		return
	var/image/holder = M.hud_list?[hud.hud_icons[1]]
	if(holder)
		holder.icon_state = new_icon_state
	if(mind && (hud in mind.antag_hud_states))
		mind.antag_hud_states[hud] = new_icon_state
		if(mind.antag_hud == hud)
			mind.antag_hud_icon_state = new_icon_state


//MIND PROCS
//these are called by mind.transfer_to()
/datum/mind/proc/transfer_antag_huds(datum/atom_hud/antag/newhud, mob/old_body)
	var/list/kept_huds = antag_hud_states?.Copy()
	leave_all_antag_huds()
	for(var/datum/atom_hud/antag/hud as anything in kept_huds)
		if(QDELETED(hud))
			continue
		if(old_body && old_body != current && (!old_body.mind || old_body.mind == src))
			hud.leave_hud(old_body)
		hud.join_hud(current)
		set_antag_hud(current, kept_huds[hud], hud)
	if(newhud && (newhud in antag_hud_states))
		antag_hud = newhud
		antag_hud_icon_state = antag_hud_states[newhud]

/datum/mind/proc/leave_all_antag_huds()
	for(var/datum/atom_hud/antag/hud in GLOB.all_huds)
		// Моб состоит в антаг-худе в двух ролях: носитель значка (hudatoms, через
		// add_to_hud) и зритель (hudusers, через add_hud_to). join_hud даёт вторую роль
		// только при self_visible, а девять из десяти антаг-худов - hidden: предатель,
		// ниндзя, генокрад, абдуктор, sintouched, soulless, брат, еретик, гангстер.
		// Проверка одного лишь hudusers их не находила, и при переносе разума значок
		// оставался висеть на прежнем теле до конца смены
		if(hud.hudusers[current] || (current in hud.hudatoms))
			hud.leave_hud(current)
	for(var/datum/atom_hud/antag/hud as anything in antag_hud_states?.Copy())
		hud.forget_mind(src)
	antag_hud = null
	antag_hud_icon_state = null
