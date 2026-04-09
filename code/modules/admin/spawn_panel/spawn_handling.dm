/datum/spawnpanel/proc/spawn_atom(list/spawn_params, mob/user)
	if(!check_rights_for(user.client, R_SPAWN))
		return

	var/path = text2path(spawn_params["type"])
	if(!path)
		to_chat(user, span_warning("SpawnPanel: invalid typepath '[spawn_params["type"]]'"))
		return
	if(!ispath(path, /obj) && !ispath(path, /turf) && !ispath(path, /mob))
		to_chat(user, span_warning("SpawnPanel: path must be /obj, /turf, or /mob."))
		return

	var/amount = clamp(spawn_params["amount"] || 1, 1, ADMIN_SPAWN_CAP)
	var/obj_name = spawn_params["atom_name"] ? sanitize(spawn_params["atom_name"]) : null
	var/obj_dir = text2num(spawn_params["atom_dir"])
	if(obj_dir && !(obj_dir in list(1, 2, 4, 8, 5, 6, 9, 10)))
		obj_dir = null

	var/where = spawn_params["where"] || WHERE_FLOOR_BELOW_MOB
	var/offset_type = spawn_params["offset_type"] || OFFSET_RELATIVE
	var/offset_x = text2num(spawn_params["offsetX"]) || 0
	var/offset_y = text2num(spawn_params["offsetY"]) || 0
	var/offset_z = text2num(spawn_params["offsetZ"]) || 0

	var/turf/target = null
	var/mob/target_mob = null
	var/obj/structure/closet/supplypod/centcompod/pod = null
	var/area/pod_storage_area = null

	if(where == WHERE_FLOOR_BELOW_MOB)
		var/turf/user_turf = get_turf(user)
		if(offset_type == OFFSET_ABSOLUTE)
			target = locate(offset_x, offset_y, offset_z)
		else
			target = locate(user_turf.x + offset_x, user_turf.y + offset_y, user_turf.z + offset_z)
		if(!target)
			target = user_turf

	else if(where == WHERE_TELEPORT_BELOW_MOB)
		target = get_turf(user)

	else if(where == WHERE_SUPPLY_BELOW_MOB)
		var/turf/user_turf2 = get_turf(user)
		if(offset_type == OFFSET_ABSOLUTE)
			target = locate(offset_x, offset_y, offset_z)
		else
			target = locate(user_turf2.x + offset_x, user_turf2.y + offset_y, user_turf2.z + offset_z)
		if(!target)
			target = user_turf2
		pod_storage_area = locate(/area/centcom/supplypod/podStorage) in GLOB.sortedAreas
		pod = new /obj/structure/closet/supplypod/centcompod(pod_storage_area ? pick(get_area_turfs(pod_storage_area)) : null)

	else if(where == WHERE_MOB_HAND)
		if(!iscarbon(user) && !iscyborg(user))
			to_chat(user, span_warning("SpawnPanel: Can only spawn in hand as a carbon or cyborg."))
			return
		target = get_turf(user)

	else if(where == WHERE_MARKED_OBJECT)
		var/datum/marked = user.client.holder?.marked_datum
		if(!marked || !isatom(marked))
			to_chat(user, span_warning("SpawnPanel: No valid marked atom."))
			return
		target = get_turf(marked)

	else if(where == WHERE_IN_MARKED_OBJECT)
		var/datum/marked2 = user.client.holder?.marked_datum
		if(!marked2 || !isatom(marked2))
			to_chat(user, span_warning("SpawnPanel: No valid marked atom."))
			return
		target = marked2

	else if(where == WHERE_TARGETED_LOCATION)
		var/turf/click_turf = spawn_params["targetTurf"]
		if(!click_turf)
			to_chat(user, span_warning("SpawnPanel: No targeted location set."))
			return
		target = click_turf

	else if(where == WHERE_TARGETED_LOCATION_POD)
		var/turf/click_turf2 = spawn_params["targetTurf"]
		if(!click_turf2)
			to_chat(user, span_warning("SpawnPanel: No targeted location set."))
			return
		target = click_turf2
		pod_storage_area = locate(/area/centcom/supplypod/podStorage) in GLOB.sortedAreas
		pod = new /obj/structure/closet/supplypod/centcompod(pod_storage_area ? pick(get_area_turfs(pod_storage_area)) : null)

	else if(where == WHERE_TARGETED_MOB_HAND)
		var/mob/hand_target = spawn_params["targetMob"]
		if(!hand_target || (!iscarbon(hand_target) && !iscyborg(hand_target)))
			to_chat(user, span_warning("SpawnPanel: No valid targeted mob."))
			return
		target_mob = hand_target
		target = get_turf(hand_target)

	if(!target)
		target = get_turf(user)

	for(var/i in 1 to amount)
		if(ispath(path, /turf))
			var/turf/T = get_turf(target)
			if(T)
				var/turf/N = T.ChangeTurf(path)
				if(N && obj_name)
					N.name = obj_name
		else
			var/atom/movable/O
			if(pod)
				O = new path(pod)
			else
				O = new path(target)
			if(!QDELETED(O))
				O.flags_1 |= ADMIN_SPAWNED_1
				if(obj_dir)
					O.setDir(obj_dir)
				if(obj_name)
					O.name = obj_name
					if(ismob(O))
						var/mob/M = O
						M.real_name = obj_name
				if(where == WHERE_MOB_HAND && isliving(user) && isitem(O))
					var/mob/living/L = user
					var/obj/item/I = O
					L.put_in_hands(I)
				else if(where == WHERE_TARGETED_MOB_HAND && target_mob && isliving(target_mob) && isitem(O))
					var/mob/living/LT = target_mob
					var/obj/item/IT = O
					LT.put_in_hands(IT)
				else if(where == WHERE_TELEPORT_BELOW_MOB)
					do_teleport(O, get_turf(user), channel = TELEPORT_CHANNEL_FREE, no_effects = TRUE)
					do_sparks(5, FALSE, get_turf(O))

	if(pod)
		new /obj/effect/pod_landingzone(get_turf(target), pod)

	if(amount == 1)
		log_admin("[key_name(user)] created a [path] at [AREACOORD(user)]")
	else
		log_admin("[key_name(user)] created [amount]x [path] at [AREACOORD(user)]")
