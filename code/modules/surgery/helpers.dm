/proc/attempt_initiate_surgery(obj/item/I, mob/living/M, mob/user)
	if(!istype(M))
		return

	var/mob/living/carbon/C
	var/obj/item/bodypart/affecting
	var/selected_zone = user.zone_selected

	if(iscarbon(M))
		C = M
		affecting = C.get_bodypart(check_zone(selected_zone))

	var/datum/surgery/current_surgery

	for(var/datum/surgery/S in M.surgeries)
		if(S.location == selected_zone)
			current_surgery = S

	if(!current_surgery)
		var/list/all_surgeries = GLOB.surgeries_list.Copy()
		var/list/available_surgeries = list()

		for(var/datum/surgery/S in all_surgeries)
			if(!S.possible_locs.Find(selected_zone))
				continue
			if(affecting)
				if(!S.requires_bodypart)
					continue
				if(S.requires_bodypart_type) //ugly but it'll do.
					switch(S.requires_bodypart_type)
						if(BODYPART_ORGANIC)
							if(!affecting.is_organic_limb(FALSE))
								continue
						if(BODYPART_ROBOTIC)
							if(!affecting.is_robotic_limb())
								continue
						if(BODYPART_HYBRID)
							if(!affecting.is_organic_limb() || !affecting.is_robotic_limb())
								continue
				if(S.requires_real_bodypart && affecting.is_pseudopart)
					continue
			else if(C && S.requires_bodypart) //mob with no limb in surgery zone when we need a limb
				continue
			if(S.lying_required && !(M.lying))
				continue
			if(!S.can_start(user, M, I))
				continue
			for(var/path in S.target_mobtypes)
				if(istype(M, path))
					available_surgeries[S.name] = S
					break

		if(!available_surgeries.len)
			return
		// BLUEMOON ADD START
		var/P
		if(user?.client?.prefs?.surgical_disable_radial)
			P = tgui_input_list(user, "Выберите операцию", "Хирургия", available_surgeries)
		else
			// Sorted operations to healing and improving
			var/static/list/options = list(
			"Лечение" = list("icon" = 'modular_citadel/icons/mob/citadel_refs/borg HUDs.dmi', "state" = "medihound"),
			"Остальное" = list("icon" = 'modular_citadel/icons/mob/citadel_refs/borg HUDs.dmi', "state" = "science")
			)

			var/list/choices = list()
			for(var/text in options)
				var/info = options[text]
				var/mutable_appearance/app = new /mutable_appearance()
				app.icon = info["icon"]
				app.icon_state = info["state"]
				app.name = text
				choices[text] = app

			P = show_radial_menu(user, get_turf(M), choices, require_near = TRUE, radius = 20)
			if(!P)
				return TRUE // cancel = don't try to attack

			// get mutable_appearance for available_surgeries
			choices = list()
			var/list/order = list() // names
			var/list/prios = list() // priorities
			for(var/S_name in available_surgeries)
				var/datum/surgery/S = available_surgeries[S_name]
				if((P == "Лечение") != S.is_healing) // for understanding: if(P == "Лечение" && !S.is_healing || P != "Лечение" && S.is_healing)
					continue
				var/mutable_appearance/app = new /mutable_appearance()
				app.icon = S.icon
				app.icon_state = S.icon_state
				app.name = S.name
				choices[S_name] = app

				// prioritization of lists
				var/p = S.radial_priority
				var/i = 1
				while (i <= prios.len && prios[i] <= p)
					i++
				prios.Insert(i, p)
				order.Insert(i, S_name)

			// reassembling list
			var/list/sorted = list()
			for (var/i = 1 to order.len)
				var/key = order[i]
				sorted[key] = choices[key]
			choices = sorted

			var/radial_radius = 27 + min(max(choices.len - 5, 0), 3) * 3 // 6 = 30, 7 = 33, 8+ = 36

			P = show_radial_menu(user, M, choices, require_near = TRUE, radius = radial_radius, tooltips = TRUE)

		if(!P)
			return TRUE // cancel = don't try to attack
		// BLUEMOON ADD END

		if(user && user.Adjacent(M) && (I in user))
			var/datum/surgery/S = available_surgeries[P]

			for(var/datum/surgery/other in M.surgeries)
				if(other.location == S.location)
					return //during the input() another surgery was started at the same location.

			//we check that the surgery is still doable after the input() wait.
			if(C)
				affecting = C.get_bodypart(check_zone(selected_zone))
			if(affecting)
				if(!S.requires_bodypart)
					return
				if(S.requires_bodypart_type) //*scream
					switch(S.requires_bodypart_type)
						if(BODYPART_ORGANIC)
							if(!affecting.is_organic_limb(FALSE))
								return
						if(BODYPART_ROBOTIC)
							if(!affecting.is_robotic_limb())
								return
						if(BODYPART_HYBRID)
							if(!affecting.is_organic_limb() || !affecting.is_robotic_limb())
								return
			else if(C && S.requires_bodypart)
				return
			if(S.lying_required && !(M.lying))
				return
			if(!S.can_start(user, M, I))
				return

			if(S.ignore_clothes || get_location_accessible(M, selected_zone))
				var/datum/surgery/procedure = new S.type(M, selected_zone, affecting)
				user.visible_message("[user] drapes [I] over [M]'s [parse_zone(selected_zone)] to prepare for surgery.", \
					"<span class='notice'>You drape [I] over [M]'s [parse_zone(selected_zone)] to prepare for \an [procedure.name].</span>")
				// BLUEMOON ADD START
				if(M.AmountSleeping() > 60)
					M.SetSleeping(60) //пациент не может уснуть через кнопку во вкладке
				if(!HAS_TRAIT(M, CAN_BE_OPERATED_WITHOUT_PAIN) && !isbloodfledge(M))
					if(procedure.special_surgery_traits.len) // подсказка хирургу при начале процедуры
						if(OPERATION_NEED_FULL_ANESTHETIC in procedure.special_surgery_traits)
							to_chat(user, span_danger("Эта операция требует, чтобы пациент был без сознания для снижения риска провала. Обезболивающее поможет смягчить эффект."))
						if(OPERATION_MUST_BE_PERFORMED_AWAKE in procedure.special_surgery_traits)
							to_chat(user, span_boldwarning("Эта операция требует, чтобы пациент обязательно находился в сознании для снижения шанса провала. Также, рекомендуется обезболивающее."))
					else
						to_chat(user, span_notice("Для этой операции достаточно дать пациенту обезболивающее. Например, распылить сильный алкоголь, морфий или дать \"мазь шахтёра\"."))
				else
					to_chat(user, span_notice("Этой расе не обязательно находиться без сознания или принимать обезболивающее для операции."))
				if(M.mob_weight > MOB_WEIGHT_HEAVY)
					to_chat(user, span_notice("Огромный вес пациент позволяет относительно удобно оперировать его без операционного стола или иных приспособлений. Они НЕ повысят шанс операции."))
				// BLUEMOON ADD END

				log_combat(user, M, "operated on", null, "(OPERATION TYPE: [procedure.name]) (TARGET AREA: [selected_zone])")
			else
				M.balloon_alert(user, "Одежда мешает!")

	else if(!current_surgery.step_in_progress)
		attempt_cancel_surgery(current_surgery, I, M, user)

	return TRUE

/proc/attempt_cancel_surgery(datum/surgery/S, obj/item/I, mob/living/M, mob/user)
	var/selected_zone = user.zone_selected
	if(S.status == 1)
		M.surgeries -= S
		user.visible_message("[user] removes [I] from [M]'s [parse_zone(selected_zone)].", \
			"<span class='notice'>You remove [I] from [M]'s [parse_zone(selected_zone)].</span>")
		qdel(S)
	else if(S.can_cancel)
		var/required_tool_type = TOOL_CAUTERY
		var/obj/item/close_tool = user.get_inactive_held_item()
		var/is_robotic = (S.requires_bodypart_type == BODYPART_ROBOTIC || S.requires_bodypart_type == BODYPART_HYBRID)
		if(is_robotic)
			required_tool_type = TOOL_SCREWDRIVER
		if(iscyborg(user))
			close_tool = locate(/obj/item/cautery) in user.held_items
			if(!close_tool)
				to_chat(user, "<span class='warning'>You need to equip a cautery in an inactive slot to stop [M]'s surgery!</span>")
				return
		else if(!close_tool || close_tool.tool_behaviour != required_tool_type)
			to_chat(user, "<span class='warning'>You need to hold a [is_robotic ? "screwdriver" : "cautery"] in your inactive hand to stop [M]'s surgery!</span>")
			return
		M.surgeries -= S
		user.visible_message("<span class='notice'>[user] closes [M]'s [parse_zone(selected_zone)] with [close_tool] and removes [I].</span>", \
			"<span class='notice'>You close [M]'s [parse_zone(selected_zone)] with [close_tool] and remove [I].</span>")
		qdel(S)

/proc/get_location_modifier(mob/M)
	var/turf/T = get_turf(M)
	if(locate(/obj/structure/table/optable, T))
		return TRUE
	else if(locate(/obj/structure/table, T))
		return 0.8
	else if(locate(/obj/structure/bed, T))
		return 0.7
	else
		return 0.5


/proc/get_location_accessible(mob/M, location)
	var/covered_locations = 0	//based on body_parts_covered
	var/face_covered = 0	//based on flags_inv
	var/eyesmouth_covered = 0	//based on flags_cover
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		for(var/obj/item/clothing/I in list(C.back, C.wear_mask, C.head))
			covered_locations |= I.body_parts_covered
			face_covered |= I.flags_inv
			eyesmouth_covered |= I.flags_cover
		if(ishuman(C))
			var/mob/living/carbon/human/H = C
			for(var/obj/item/I in list(H.wear_suit, H.w_uniform, H.w_underwear, H.w_socks, H.w_shirt, H.shoes, H.belt, H.gloves, H.wrists, H.glasses, H.ears, H.ears_extra)) //skyrat edit
				covered_locations |= I.body_parts_covered
				face_covered |= I.flags_inv
				eyesmouth_covered |= I.flags_cover

	switch(location)
		if(BODY_ZONE_HEAD)
			if(covered_locations & HEAD)
				return FALSE
		if(BODY_ZONE_PRECISE_EYES)
			if(covered_locations & HEAD || face_covered & HIDEEYES || eyesmouth_covered & GLASSESCOVERSEYES)
				return FALSE
		if(BODY_ZONE_PRECISE_MOUTH)
			if(covered_locations & HEAD || face_covered & HIDEFACE || eyesmouth_covered & MASKCOVERSMOUTH || eyesmouth_covered & HEADCOVERSMOUTH)
				return FALSE
		if(BODY_ZONE_CHEST)
			if(covered_locations & CHEST)
				return FALSE
		if(BODY_ZONE_PRECISE_GROIN)
			if(covered_locations & GROIN)
				return FALSE
		if(BODY_ZONE_L_ARM)
			if(covered_locations & ARM_LEFT)
				return FALSE
		if(BODY_ZONE_R_ARM)
			if(covered_locations & ARM_RIGHT)
				return FALSE
		if(BODY_ZONE_L_LEG)
			if(covered_locations & LEG_LEFT)
				return FALSE
		if(BODY_ZONE_R_LEG)
			if(covered_locations & LEG_RIGHT)
				return FALSE
		if(BODY_ZONE_PRECISE_L_HAND)
			if(covered_locations & HAND_LEFT)
				return FALSE
		if(BODY_ZONE_PRECISE_R_HAND)
			if(covered_locations & HAND_RIGHT)
				return FALSE
		if(BODY_ZONE_PRECISE_L_FOOT)
			if(covered_locations & FOOT_LEFT)
				return FALSE
		if(BODY_ZONE_PRECISE_R_FOOT)
			if(covered_locations & FOOT_RIGHT)
				return FALSE

	return TRUE
