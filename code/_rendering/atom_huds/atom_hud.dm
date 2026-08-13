/* HUD DATUMS */

GLOBAL_LIST_EMPTY(all_huds)

//GLOBAL HUD LIST
GLOBAL_LIST_INIT(huds, alist(
	DATA_HUD_SECURITY_BASIC = new/datum/atom_hud/data/human/security/basic(),
	DATA_HUD_SECURITY_ADVANCED = new/datum/atom_hud/data/human/security/advanced(),
	DATA_HUD_MEDICAL_BASIC = new/datum/atom_hud/data/human/medical/basic(),
	DATA_HUD_MEDICAL_ADVANCED = new/datum/atom_hud/data/human/medical/advanced(),
	DATA_HUD_DIAGNOSTIC_BASIC = new/datum/atom_hud/data/diagnostic/basic(),
	DATA_HUD_DIAGNOSTIC_ADVANCED = new/datum/atom_hud/data/diagnostic/advanced(),
	DATA_HUD_ABDUCTOR = new/datum/atom_hud/abductor(),
	DATA_HUD_SENTIENT_DISEASE = new/datum/atom_hud/sentient_disease(),
	DATA_HUD_AI_DETECT = new/datum/atom_hud/ai_detector(),
	ANTAG_HUD_CULT = new/datum/atom_hud/antag(),
	ANTAG_HUD_REV = new/datum/atom_hud/antag(),
	ANTAG_HUD_OPS = new/datum/atom_hud/antag(),
	ANTAG_HUD_WIZ = new/datum/atom_hud/antag(),
	ANTAG_HUD_SHADOW = new/datum/atom_hud/antag(),
	ANTAG_HUD_TRAITOR = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_NINJA = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_CHANGELING = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_ABDUCTOR = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_DEVIL = new/datum/atom_hud/antag(),
	ANTAG_HUD_SINTOUCHED = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_SOULLESS = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_CLOCKWORK = new/datum/atom_hud/antag(),
	ANTAG_HUD_BROTHER = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_BLOODSUCKER = new/datum/atom_hud/antag/bloodsucker(),
	ANTAG_HUD_FUGITIVE = new/datum/atom_hud/antag(),
	ANTAG_HUD_HERETIC = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_SPACECOP = new/datum/atom_hud/antag(),
	ANTAG_HUD_GANGSTER = new/datum/atom_hud/antag/hidden(),
	ANTAG_HUD_SLAVER = new/datum/atom_hud/antag(),
	DATA_HUD_ANTAGTARGET = new/datum/atom_hud/data/human/antagtarget(),
	ANTAG_HUD_ZOMBIE = new/datum/atom_hud/antag(),
	))

/datum/atom_hud
	var/list/atom/hudatoms = list() //list of all atoms which display this hud
	var/list/hudusers = list() //list with all mobs who can see the hud
	var/list/hud_icons = list() //these will be the indexes for the atom's hud_list

	var/list/next_time_allowed = list() //mobs associated with the next time this hud can be added to them
	var/list/queued_to_see = list() //mobs that have triggered the cooldown and are queued to see the hud, but do not yet

/datum/atom_hud/New()
	GLOB.all_huds += src

/datum/atom_hud/Destroy()
	for(var/v in hudusers)
		remove_hud_from(v)
	for(var/v in hudatoms)
		remove_from_hud(v)
	GLOB.all_huds -= src
	return ..()

/datum/atom_hud/proc/remove_hud_from(mob/M, absolute = FALSE)
	if(!M || !hudusers[M])
		return
	if(absolute || !--hudusers[M])
		if(!(M in hudatoms)) // сигнал общий на обе роли - снимаем только когда обе кончились
			UnregisterSignal(M, COMSIG_PARENT_QDELETING)
		hudusers -= M
		if(next_time_allowed[M])
			next_time_allowed -= M
		if(queued_to_see[M])
			queued_to_see -= M
		else
			for(var/atom/A in hudatoms)
				remove_from_single_hud(M, A)

/datum/atom_hud/proc/remove_from_hud(atom/A)
	if(!A)
		return FALSE
	for(var/mob/M in hudusers)
		remove_from_single_hud(M, A)
	hudatoms -= A
	if(!hudusers[A]) // сигнал общий на обе роли - снимаем только когда обе кончились
		UnregisterSignal(A, COMSIG_PARENT_QDELETING)
	return TRUE

/datum/atom_hud/proc/remove_from_single_hud(mob/M, atom/A) //unsafe, no sanity apart from client
	if(!M || !M.client || !A || !A.hud_list)
		return
	for(var/i in hud_icons)
		M.client.images -= A.hud_list[i]

/datum/atom_hud/proc/add_hud_to(mob/M)
	if(!M)
		return
	if(!hudusers[M])
		hudusers[M] = 1
		RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(unregister_mob), override = TRUE)
		if(next_time_allowed[M] > world.time)
			if(!queued_to_see[M])
				addtimer(CALLBACK(src, PROC_REF(show_hud_images_after_cooldown), M), next_time_allowed[M] - world.time)
				queued_to_see[M] = TRUE
		else
			next_time_allowed[M] = world.time + ADD_HUD_TO_COOLDOWN
			push_all_atoms_to_user(M)
	else
		hudusers[M]++

/// Общий обработчик qdel для обеих ролей (huduser и hudatom).
/// Раньше hudatoms не имели авто-снятия вовсе: remove_from_all_data_huds покрывает
/// только /datum/atom_hud/data, а из antag/abductor/прочих худов удалённый атом
/// не выпадал никогда - худ держал труп до конца раунда.
/datum/atom_hud/proc/unregister_mob(datum/source, force)
	SIGNAL_HANDLER
	if(hudusers[source])
		remove_hud_from(source, TRUE)
	if(source in hudatoms)
		remove_from_hud(source)

/datum/atom_hud/proc/show_hud_images_after_cooldown(M)
	if(queued_to_see[M])
		queued_to_see -= M
		next_time_allowed[M] = world.time + ADD_HUD_TO_COOLDOWN
		push_all_atoms_to_user(M)

/datum/atom_hud/proc/add_to_hud(atom/A)
	if(!A)
		return FALSE
	hudatoms |= A
	// override: атом может уже быть зарегистрирован как huduser этим же худом.
	RegisterSignal(A, COMSIG_PARENT_QDELETING, PROC_REF(unregister_mob), override = TRUE)
	for(var/mob/M in hudusers)
		if(!queued_to_see[M])
			add_to_single_hud(M, A)
	return TRUE

/// Override to gate which atoms of this hud are visible to which mobs.
/// Returning FALSE skips the atom in BOTH the per-call add_to_single_hud
/// path and the batched collect_hud_images_for path. Default: always show.
/datum/atom_hud/proc/should_show_to(mob/M, atom/A)
	return TRUE

/datum/atom_hud/proc/add_to_single_hud(mob/M, atom/A) //unsafe, no sanity apart from client
	if(!M || !A)
		return
	var/client/their_client = M.client
	if(!their_client)
		return
	if(!should_show_to(M, A))
		return
	var/list/atom_hud_list = A.hud_list
	if(!atom_hud_list)
		return
	var/list/local_hud_icons = hud_icons
	if(length(local_hud_icons) == 1)
		var/hud_image = atom_hud_list[local_hud_icons[1]]
		if(hud_image)
			their_client.images |= hud_image
		return
	var/first_hud_image
	var/list/to_add
	for(var/i in local_hud_icons)
		var/hud_image = atom_hud_list[i]
		if(!hud_image)
			continue
		if(!first_hud_image)
			first_hud_image = hud_image
			continue
		if(!to_add)
			to_add = list()
			to_add += first_hud_image
		to_add += hud_image
	if(to_add)
		their_client.images |= to_add
	else if(first_hud_image)
		their_client.images |= first_hud_image

/// Append every image visible to M from this hud's hudatoms into `out`.
/// Used by batched bulk-add paths so we end up with ONE
/// `client.images |= big_list` per flushed batch instead of N individual unions.
/// Duplicates inside `out` are tolerated — the trailing |= dedups them.
/// M may be null; `should_show_to(M, A)` is responsible for any gating
/// that depends on the mob.
/datum/atom_hud/proc/collect_hud_images_for(mob/M, list/out)
	if(!islist(out))
		return
	var/list/local_hud_icons = hud_icons
	if(!length(local_hud_icons))
		return
	for(var/atom/A as anything in hudatoms)
		if(!A)
			continue
		if(!should_show_to(M, A))
			continue
		var/list/atom_hud_list = A.hud_list
		if(!atom_hud_list)
			continue
		for(var/i in local_hud_icons)
			var/hud_image = atom_hud_list[i]
			if(hud_image)
				out += hud_image

/// Build the entire list of images this hud wants to push to M and union it
/// into target_images in a single |= call.
/datum/atom_hud/proc/push_all_atoms_to_image_list(mob/M, list/target_images)
	if(!islist(target_images))
		return
	var/list/collected = list()
	collect_hud_images_for(M, collected)
	if(length(collected))
		target_images |= collected

/// Build the entire list of images this hud wants to push to M and union it
/// into M.client.images in a single |= call. Replaces the per-atom
/// add_to_single_hud loop that used to live in add_hud_to /
/// show_hud_images_after_cooldown. One batched union avoids paying the
/// list-membership cost of |= per atom.
/datum/atom_hud/proc/push_all_atoms_to_user(mob/M)
	if(!M)
		return
	var/client/their_client = M.client
	if(!their_client)
		return
	push_all_atoms_to_image_list(M, their_client.images)

//MOB PROCS
/mob/proc/reload_huds()
	if(!client)
		return
	reload_huds_into(client.images)

/// Re-adds every HUD image visible to this mob into `target_images`, one batched
/// `|=` per hud (collect_hud_images_for → single union, instead of N unions).
///
/// MUST NOT SLEEP. This runs as part of /mob/Login(), and several callers attach a
/// client and then keep working synchronously on the assumption that Login() has
/// already finished — most importantly the ghost-role spawner path
/// /obj/effect/mob_spawn/proc/create(), which does `mob.ckey = ckey` and then
/// immediately reads `src.mind` (only created later in Login() via sync_mind()).
/// A yield in here used to leave freshly-spawned ghost-role bodies with no mind,
/// no "Ghost Role" assignment (so they counted as station crew) and a random
/// appearance, while the spawner never decremented its uses / qdel'd itself.
/mob/proc/reload_huds_into(list/target_images)
	SHOULD_NOT_SLEEP(TRUE)
	if(!islist(target_images))
		return
	for(var/datum/atom_hud/hud as anything in GLOB.all_huds)
		if(!hud || !hud.hudusers[src])
			continue
		hud.push_all_atoms_to_image_list(src, target_images)

/mob/dead/new_player/reload_huds()
	return
