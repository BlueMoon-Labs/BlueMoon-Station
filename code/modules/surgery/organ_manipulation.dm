#define TYPE_INSERT "insert"
#define TYPE_EXTRACT "extract"
#define TYPE_HEAL "heal"

/datum/surgery/organ_manipulation
	name = "Organ manipulation"
	desc = "Хирургическая процедура, выполняемая для имплантации, извлечения или лечения внутренних органов пациента."
	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ORGANIC
	requires_real_bodypart = 1
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/saw,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/incise,
		/datum/surgery_step/manipulate_organs,
		//there should be bone fixing
		/datum/surgery_step/close
		)
	special_surgery_traits = list(OPERATION_NEED_FULL_ANESTHETIC) // BLUEMOON ADD - операция требует, чтобы пациент находился без сознания
	icon_state = "hemostat"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_STATIC

/datum/surgery/organ_manipulation/soft
	possible_locs = list(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/incise,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/close
		)

/datum/surgery/organ_manipulation/alien
	name = "Alien organ manipulation"
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	target_mobtypes = list(/mob/living/carbon/alien/humanoid)
	steps = list(
		/datum/surgery_step/saw,
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/saw,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/close
		)

/datum/surgery/organ_manipulation/mechanic
	name = "Prosthesis organ manipulation"
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ROBOTIC
	steps = list(
		/datum/surgery_step/mechanic_open,
		/datum/surgery_step/open_hatch,
		/datum/surgery_step/mechanic_unwrench,
		/datum/surgery_step/prepare_electronics,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/mechanic_wrench,
		/datum/surgery_step/mechanic_close
		)

/datum/surgery/organ_manipulation/mechanic/soft
	possible_locs = list(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	steps = list(
		/datum/surgery_step/mechanic_open,
		/datum/surgery_step/open_hatch,
		/datum/surgery_step/prepare_electronics,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/mechanic_close
		)

/datum/surgery_step/manipulate_organs
	time = 64
	name = "Манипулировать с Органами"
	repeatable = 1
	implements = list(/obj/item/organ = 100, /obj/item/organ_storage = 100)
	stop_implements = TRUE
	preop_sound = 'sound/surgery/organ2.ogg'
	success_sound = 'sound/surgery/organ1.ogg'
	var/list/implements_extract = list(TOOL_HEMOSTAT = 100, TOOL_CROWBAR = 55)
	var/list/implements_heal = list(/obj/item/stack/medical/mesh = 100, /obj/item/stack/medical/ointment = 75, /obj/item/stack/medical/suture = 65, /obj/item/stack/medical/bone_gel = 35, /obj/item/stack/medical/gauze = 15)
	//organs that we can treat
	var/list/heal_allowed_organs = list(/obj/item/organ/heart, /obj/item/organ/lungs,/obj/item/organ/ears, /obj/item/organ/stomach, /obj/item/organ/tongue, /obj/item/organ/liver)
	var/current_type
	var/obj/item/organ/I = null

/datum/surgery_step/manipulate_organs/New()
	..()
	implements = implements + implements_extract + implements_heal

/datum/surgery_step/manipulate_organs/initiate(mob/user, mob/living/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail)
	. = ..()
	if(. && istype(tool, /obj/item/stack))
		var/obj/item/stack/T = tool
		T.use(1)

/datum/surgery_step/manipulate_organs/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	I = null
	current_type = null
	if(istype(tool, /obj/item/organ_storage))
		preop_sound = initial(preop_sound)
		success_sound = initial(success_sound)
		if(!tool.contents.len)
			to_chat(user, span_notice("Внутри [tool] ничего нет."))
			return -1
		I = tool.contents[1]
		if(!isorgan(I))
			to_chat(user, span_notice("Вы не можете поместить [I] в [parse_zone(target_zone)] [target]!"))
			return -1
		tool = I
	if(isorgan(tool))
		current_type = TYPE_INSERT
		preop_sound = 'sound/surgery/hemostat1.ogg'
		success_sound = 'sound/surgery/organ2.ogg'
		I = tool
		if(target_zone != I.zone || target.getorganslot(I.slot))
			to_chat(user, span_notice("[I] не поместиться в [parse_zone(target_zone)] [target]!"))
			return -1
		var/obj/item/organ/meatslab = tool
		if(!meatslab.useable)
			to_chat(user, span_warning("[I] слишком поврежден, вы не можете его использовать!"))
			return -1
		display_results(user, target, span_notice("Вы начинаете пересаживать [tool] в [parse_zone(target_zone)] [target]..."),
			"[user] начинает пересадку [tool] в [parse_zone(target_zone)] [target].",
			"[user] начинает что-то запихивать в [parse_zone(target_zone)] [target].")

	else
		if(implement_type in implements_extract)
			current_type = TYPE_EXTRACT
		else if(implement_type in implements_heal)
			current_type = TYPE_HEAL

		if(current_type)
			var/list/organs = target.getorganszone(target_zone)
			if(!organs.len)
				to_chat(user, span_warning("Внутри [parse_zone(target_zone)] [target] нет органов!"))
				return -1
			else
				for(var/obj/item/organ/O in organs)
					organs -= O
					if(current_type == TYPE_HEAL)
						var/allowed_organ = FALSE
						for(var/path in heal_allowed_organs)
							if(istype(O, path) && O.status == ORGAN_ORGANIC)
								allowed_organ = TRUE
								break
						if(!allowed_organ)
							continue
					O.on_find(user)
					organs[O.name] = O

				I = show_radial_menu(user, target, organs, require_near = TRUE, tooltips = TRUE)
				if(I && user && target && user.Adjacent(target) && user.get_active_held_item() == tool)
					I = organs[I]
					if(!I)
						return -1
					if(current_type == TYPE_HEAL)
						if(I.organ_flags & ORGAN_FAILING)
							to_chat(user, span_warning("Некроз проник слишком глубоко в ткани органа, нет надежды на восстановление..."))
							return -1
						if(!I.damage)
							to_chat(user, span_notice("Орган цел и не требует восстановления."))
							return -1
					if(current_type == TYPE_EXTRACT)
						display_results(user, target, span_notice("Вы начинаете извлекать [I] из [parse_zone(target_zone)] [target]..."),
							"[user] начинает извлекать [I] из [parse_zone(target_zone)] [target].",
							"[user] начинает извлекать что-то из [parse_zone(target_zone)] [target].")
					else
						display_results(user, target, span_notice("Вы пытаетесь исцелить [I], нанося [tool] на повреждения..."),
							"[user] начинает наносить [tool], пытаясь исцелить [I] [target].",
							"[user] начинает что-то делать внутри [parse_zone(target_zone)] [target].")
				else
					return -1

/datum/surgery_step/manipulate_organs/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	switch(current_type)
		if(TYPE_INSERT)
			if(istype(tool, /obj/item/organ_storage))
				I = tool.contents[1]
				tool.icon_state = initial(tool.icon_state)
				tool.desc = initial(tool.desc)
				tool.cut_overlays()
				tool = I
			else
				I = tool
			user.temporarilyRemoveItemFromInventory(I, TRUE)
			I.Insert(target)
			display_results(user, target, span_notice("Вы трансплантируете [tool] в [parse_zone(target_zone)] [target]."),
				"[user] трансплантирует [tool] в [parse_zone(target_zone)] [target]!",
				"[user] трансплантирует что-то в [parse_zone(target_zone)] [target]!")
		if(TYPE_EXTRACT)
			if(I && I.owner == target)
				display_results(user, target, span_notice("Вы успешно извлекаете [I] из [parse_zone(target_zone)] [target]."),
					"[user] успешно извлекает [I] из [parse_zone(target_zone)] [target]!",
					"[user] успешно извлекает что-то из [parse_zone(target_zone)] [target]!")
				log_combat(user, target, "surgically removed [I.name] from", addition="INTENT: [uppertext(user.a_intent)]")
				I.Remove()
				user.put_in_hands(I)
			else
				display_results(user, target, span_notice("Вы ничего не можете извлечь из [parse_zone(target_zone)] [target]!"),
					"[user] кажется, ничего не может извлечь из [parse_zone(target_zone)] [target]!",
					"[user] кажется, ничего не может извлечь из [parse_zone(target_zone)] [target]!")
		if(TYPE_HEAL)
			if(I && I.owner == target)
				display_results(user, target, span_notice("Вы успешно исцелили [target] [I]."),
					"[user] успешно закончил лечение [target] [I]!",
					"[user] закончил что-то делать внутри [target]!")
				I.setOrganDamage(0)
			else
				display_results(user, target, span_warning("Вам ничего не удалось исцелить в [parse_zone(target_zone)] [target]!"),
					"[user] кажется ничего не смог сделать внутри [parse_zone(target_zone)] [target]!",
					"[user] кажется ничего не смог сделать внутри [parse_zone(target_zone)] [target]")

	return TRUE

#undef TYPE_INSERT
#undef TYPE_EXTRACT
#undef TYPE_HEAL
