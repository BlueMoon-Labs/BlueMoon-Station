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
	ANTAG_HUD_GANGSTER = new/datum/atom_hud/antag/gangster(),
	ANTAG_HUD_SLAVER = new/datum/atom_hud/antag(),
	DATA_HUD_ANTAGTARGET = new/datum/atom_hud/data/human/antagtarget(),
	ANTAG_HUD_ZOMBIE = new/datum/atom_hud/antag(),
	))

/// Группы z худов, кэш по номеру уровня (см. get_hud_z_group)
GLOBAL_LIST_EMPTY(hud_z_groups)

/**
 * Группа z для атом-худов: значки видны только зрителям той же группы. Группа - нижний уровень
 * стека, связанного по вертикали, поэтому переход по лестнице группу не меняет. 0 - nullspace.
 */
/proc/get_hud_z_group(z)
	if(!z)
		return 0
	var/list/groups = GLOB.hud_z_groups
	if(length(groups) >= z && groups[z])
		return groups[z]
	var/group = min(get_multiz_accessible_levels(z))
	// До инициализации маппинга связи уровней ещё не прочитаны
	if(SSmapping.initialized)
		if(length(groups) < z)
			groups.len = z
		groups[z] = group
	return group

/datum/atom_hud
	var/list/atom/movable/hudatoms = list() //list of all atoms which display this hud
	var/list/hudusers = list() //list with all mobs who can see the hud
	var/list/hud_icons = list() //these will be the indexes for the atom's hud_list

	var/list/next_time_allowed = list() //mobs associated with the next time this hud can be added to them
	var/list/queued_to_see = list() //mobs that have triggered the cooldown and are queued to see the hud, but do not yet

/datum/atom_hud/New()
	GLOB.all_huds += src

/datum/atom_hud/Destroy()
	// По копиям: remove_hud_from()/remove_from_hud() вырезают элемент из того же списка, по
	// которому идёт for-in, и обход перескакивает через соседа - половина подписчиков ушла бы
	// в мир с чужими картинками в client.images.
	for(var/v in hudusers.Copy())
		remove_hud_from(v, TRUE)
	for(var/v in hudatoms.Copy())
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
		else if(viewer_has_images(M))
			// Значки атомов, ушедших из группы зрителя, остаются у него до снятия худа - собираем все группы
			var/list/images_to_remove = list()
			collect_hud_images_for(M, images_to_remove, check_visibility = FALSE, z_group = HUD_Z_GROUP_ANY)
			remove_hud_images(M, images_to_remove)

/// Картинки худа живут в client.images: у моба без клиента снимать нечего.
/datum/atom_hud/proc/viewer_has_images(mob/viewer)
	return !!viewer.client

/datum/atom_hud/proc/remove_hud_images(mob/viewer, list/images_to_remove)
	if(viewer?.client && length(images_to_remove))
		viewer.client.images -= images_to_remove

/datum/atom_hud/proc/remove_from_hud(atom/movable/A)
	if(!A)
		return FALSE
	for(var/mob/M in hudusers)
		remove_from_single_hud(M, A)
	hudatoms -= A
	LAZYREMOVE(A.hud_memberships, src)
	if(!hudusers[A]) // сигнал общий на обе роли - снимаем только когда обе кончились
		UnregisterSignal(A, COMSIG_PARENT_QDELETING)
	return TRUE

/datum/atom_hud/proc/remove_from_single_hud(mob/M, atom/movable/A, list/hud_icon_keys = hud_icons) //unsafe, no sanity apart from client
	if(!M || !M.client || !A || !A.hud_list)
		return
	// Симметрично add_to_single_hud: один `-=` на весь набор иконок вместо
	// отдельного вычитания на каждую. У диагностического худа иконок 11, и каждое
	// вычитание - это проход по client.images, который у госта с тремя продвинутыми
	// худами исчисляется тысячами изображений.
	var/client/their_client = M.client
	var/list/atom_hud_list = A.hud_list
	var/list/local_hud_icons = hud_icon_keys
	if(length(local_hud_icons) == 1)
		var/hud_image = atom_hud_list[local_hud_icons[1]]
		if(hud_image)
			their_client.images -= hud_image
		return
	var/list/to_remove
	for(var/i in local_hud_icons)
		var/hud_image = atom_hud_list[i]
		if(!hud_image)
			continue
		LAZYADD(to_remove, hud_image)
	if(to_remove)
		their_client.images -= to_remove

/datum/atom_hud/proc/add_hud_to(mob/M)
	if(!M)
		return
	if(!hudusers[M])
		if(!GLOB.hud_view_group_watcher)
			GLOB.hud_view_group_watcher = new
		// Прочие худы моба переезжают на его текущую группу до того, как этот наберёт по ней значки
		M.refresh_hud_view_group()
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

/datum/atom_hud/proc/add_to_hud(atom/movable/A)
	if(!A)
		return FALSE
	hudatoms |= A
	LAZYOR(A.hud_memberships, src)
	// override: атом может уже быть зарегистрирован как huduser этим же худом.
	RegisterSignal(A, COMSIG_PARENT_QDELETING, PROC_REF(unregister_mob), override = TRUE)
	show_atom_to_its_z_group(A)
	return TRUE

/// Выдаёт значки атома зрителям его группы z: при входе в худ и при переезде атома на другой уровень
/datum/atom_hud/proc/show_atom_to_its_z_group(atom/movable/A)
	var/atom_group = A.get_hud_z_group_cached()
	for(var/mob/M in hudusers)
		if(!queued_to_see[M] && M.get_hud_view_group_cached() == atom_group)
			add_to_single_hud(M, A)

/// Override to gate which atoms of this hud are visible to which mobs.
/// Returning FALSE skips the atom in BOTH the per-call add_to_single_hud
/// path and the batched collect_hud_images_for path. Default: always show.
/datum/atom_hud/proc/should_show_to(mob/M, atom/movable/A)
	return TRUE

/datum/atom_hud/proc/add_to_single_hud(mob/M, atom/movable/A, list/hud_icon_keys = hud_icons) //unsafe, no sanity apart from client
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
	var/list/local_hud_icons = hud_icon_keys
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

/**
 * Собирает в out значки атомов худа одной группы z.
 * При снятии HUD проверка видимости отключается: ранее показанные иконки тоже надо убрать.
 * z_group: null - группа зрителя M (без M - все атомы), HUD_Z_GROUP_ANY - все группы.
 */
/datum/atom_hud/proc/collect_hud_images_for(mob/M, list/out, check_visibility = TRUE, z_group = null)
	if(!islist(out))
		return
	var/list/local_hud_icons = hud_icons
	if(!length(local_hud_icons))
		return
	if(isnull(z_group))
		z_group = M ? M.get_hud_view_group_cached() : HUD_Z_GROUP_ANY
	for(var/atom/movable/A as anything in hudatoms)
		if(!A)
			continue
		if(z_group != HUD_Z_GROUP_ANY && A.get_hud_z_group_cached() != z_group)
			continue
		if(check_visibility && !should_show_to(M, A))
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

/// Группа z, по которой худы раздают значки атома
/atom/movable/proc/get_hud_z_group_cached()
	if(isnull(hud_z_group))
		var/turf/our_turf = get_turf(src)
		hud_z_group = get_hud_z_group(our_turf?.z)
	return hud_z_group

/// Переезд значка на другой уровень: значки получают зрители новой группы. У зрителей старой
/// они остаются невидимыми до смены группы или снятия худа - снимать их у каждого слишком дорого
/atom/movable/proc/update_hud_z_group(new_z)
	var/new_group = get_hud_z_group(new_z)
	if(new_group == hud_z_group)
		return
	hud_z_group = new_group
	for(var/datum/atom_hud/hud as anything in hud_memberships)
		hud.show_atom_to_its_z_group(src)

/// Группа z, на которую сейчас смотрит клиент моба: при observe и камерах это не уровень самого моба
/mob/proc/current_hud_view_group()
	var/atom/viewpoint = client?.eye || src
	var/turf/view_turf = get_turf(viewpoint)
	return get_hud_z_group(view_turf?.z)

/mob/proc/get_hud_view_group_cached()
	if(isnull(hud_view_group))
		hud_view_group = current_hud_view_group()
	return hud_view_group

/**
 * Переводит значки всех худов моба на группу z, куда сейчас смотрит его клиент.
 * new_z - уровень, на который моб переезжает: forceMove госта зовёт onTransitZ до смены loc.
 */
/mob/proc/refresh_hud_view_group(new_z = null)
	var/new_group
	if(!isnull(new_z) && (!client || client.eye == src))
		new_group = get_hud_z_group(new_z)
	else
		new_group = current_hud_view_group()
	var/old_group = hud_view_group
	if(new_group == old_group)
		return
	hud_view_group = new_group
	if(isnull(old_group) || !client)
		return
	var/list/images_to_remove = list()
	var/list/images_to_add = list()
	for(var/datum/atom_hud/hud as anything in GLOB.all_huds)
		if(!hud.hudusers[src] || hud.queued_to_see[src])
			continue
		hud.collect_hud_images_for(src, images_to_remove, check_visibility = FALSE, z_group = old_group)
		hud.collect_hud_images_for(src, images_to_add, z_group = new_group)
	if(length(images_to_remove))
		client.images -= images_to_remove
	if(length(images_to_add))
		client.images |= images_to_add

/// Раз в секунду сверяет группу z каждого клиента: observe, камеры и abstract_move меняют взгляд без onTransitZ
/datum/hud_view_group_watcher

/datum/hud_view_group_watcher/New()
	START_PROCESSING(SSprocessing, src)

/datum/hud_view_group_watcher/process(seconds_per_tick)
	for(var/client/viewer as anything in GLOB.clients)
		viewer?.mob?.refresh_hud_view_group()

GLOBAL_DATUM(hud_view_group_watcher, /datum/hud_view_group_watcher)

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
	// Без клиента группа не следила за взглядом
	hud_view_group = current_hud_view_group()
	for(var/datum/atom_hud/hud as anything in GLOB.all_huds)
		if(!hud || !hud.hudusers[src])
			continue
		hud.push_all_atoms_to_image_list(src, target_images)

/mob/dead/new_player/reload_huds()
	return
