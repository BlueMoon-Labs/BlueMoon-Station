/obj/item/stack/medical
	name = "medical pack"
	singular_name = "medical pack"
	icon = 'icons/obj/stack_objects.dmi'
	amount = 12
	max_amount = 12
	w_class = WEIGHT_CLASS_TINY
	full_w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	resistance_flags = FLAMMABLE
	max_integrity = 40
	novariants = FALSE
	item_flags = NOBLUDGEON
	var/self_delay = 50
	var/other_delay = 0
	var/repeating = FALSE
	/// How much brute we heal per application
	var/heal_brute
	/// How much burn we heal per application
	var/heal_burn
	/// How much we reduce bleeding per application on cut wounds
	var/stop_bleeding
	/// How much sanitization to apply to burns on application
	var/sanitization
	/// How much we add to flesh_healing for burn wounds on application
	var/flesh_regeneration
	var/heal_dead = FALSE //can we heal dead body
	var/heal_dead_multiplier = 1 // The effectiveness of treating the dead

/obj/item/stack/medical/attack(mob/living/M, mob/user)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(try_heal), M, user)

/obj/item/stack/medical/proc/try_heal(mob/living/M, mob/user, silent = FALSE)
	if(!M.can_inject(user, TRUE) || INTERACTING_WITH(user, M))
		return
	if(M == user)
		if(!silent)
			user.visible_message("<span class='notice'>[user] начинает наносить \the [src] на себя...</span>", "<span class='notice'>Вы начали наносить \the [src] на себя...</span>")
		if(!do_mob(user, M, self_delay, extra_checks=CALLBACK(M, TYPE_PROC_REF(/mob/living, can_inject), user, TRUE)))
			return
	else if(other_delay)
		if(!silent)
			user.visible_message("<span class='notice'>[user] начинает наносить \the [src] на [M].</span>", "<span class='notice'>Вы начали наносить \the [src] на [M]...</span>")
		if(!do_mob(user, M, other_delay, extra_checks=CALLBACK(M, TYPE_PROC_REF(/mob/living, can_inject), user, TRUE)))
			return

	if(heal(M, user))
		log_combat(user, M, "healed", src.name)
		use(1)
		if(repeating && amount > 0)
			try_heal(M, user, TRUE)


/obj/item/stack/medical/proc/heal(mob/living/M, mob/user)
	return

/obj/item/stack/medical/proc/heal_carbon(mob/living/carbon/C, mob/user, brute, burn)
	var/obj/item/bodypart/affecting = C.get_bodypart(check_zone(user.zone_selected))
	if(!affecting) //Missing limb?
		to_chat(user, "<span class='warning'>У [C] отсутствует \a [ru_parse_zone(user.zone_selected)]!</span>")
		return
	if(affecting.is_organic_limb(FALSE)) //Limb must be organic to be healed - RR
		if(affecting.brute_dam && brute || affecting.burn_dam && burn)
			user.visible_message("<span class='green'>[user] наносит \the [src] на [ru_kogo_zone(affecting.name)] [C].</span>", "<span class='green'>Вы наносите \the [src] на [ru_kogo_zone(affecting.name)] [C].</span>")
			if(affecting.heal_damage(brute, burn))
				C.update_damage_overlays()
			return TRUE
		to_chat(user, "<span class='notice'>[ru_kogo_zone(user.zone_selected)] [C] нельзя вылечить при помощи \the [src].</span>")
		return
	to_chat(user, "<span class='notice'>\The [src] не сработает для механической конечности!</span>")

/obj/item/stack/medical/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "pouch")

/obj/item/stack/medical/bruise_pack
	name = "bruise pack"
	singular_name = "bruise pack"
	desc = "Терапевтическая упаковка геля и повязок для работы с травмами от тупых предметов."
	icon_state = "brutepack"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	heal_brute = 40
	self_delay = 40
	other_delay = 20
	grind_results = list(/datum/reagent/medicine/styptic_powder = 10)

/obj/item/stack/medical/bruise_pack/one
	amount = 1

/obj/item/stack/medical/bruise_pack/heal(mob/living/M, mob/user)
	var/efficiency = 1
	if(M.stat == DEAD)
		if(!heal_dead)
			to_chat(user, "<span class='warning'>[M] мертв[M.ru_a()]! Вы не можете [M.ru_emu()] помочь.</span>")
			return
		efficiency = heal_dead_multiplier
	if(isanimal(M))
		var/mob/living/simple_animal/critter = M
		if (!(critter.healable))
			to_chat(user, "<span class='notice'> Вы не можете применить \the [src] на [M]!</span>")
			return FALSE
		else if (critter.health == critter.maxHealth)
			to_chat(user, "<span class='notice'> [M] полностью здоров[M.ru_a()].</span>")
			return FALSE
		user.visible_message("<span class='green'>[user] наносит \the [src] на [M].</span>", "<span class='green'>Вы наносите \the [src] на [M].</span>")
		if(AmBloodsucker(M))
			return
		M.heal_bodypart_damage((heal_brute/2)*efficiency)
		return TRUE
	if(iscarbon(M))
		return heal_carbon(M, user, heal_brute*efficiency, heal_burn*efficiency)
	to_chat(user, "<span class='warning'>Вы не можете вылечить [M] при помощи \the [src]!</span>")
	to_chat(user, "<span class='notice'>Вы неможете вылечить [M] при помощи \the [src]!</span>")

/obj/item/stack/medical/bruise_pack/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is bludgeoning себя with [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (BRUTELOSS)

/obj/item/stack/medical/gauze
	name = "medical gauze"
	desc = "Моток эластичной ткани, идеальной для стабилизации любых видов ранений, от порезов до ожогов и переломов костей."
	gender = PLURAL
	singular_name = "medical gauze"
	icon_state = "gauze"
	heal_brute = 5
	self_delay = 50
	other_delay = 20
	amount = 15
	max_amount = 15
	absorption_rate = 0.25
	absorption_capacity = 5
	splint_factor = 0.35
	custom_price = PRICE_REALLY_CHEAP
	grind_results = list(/datum/reagent/cellulose = 2)

// gauze is only relevant for wounds, which are handled in the wounds themselves
/obj/item/stack/medical/gauze/try_heal(mob/living/M, mob/user, silent)
	var/obj/item/bodypart/limb = M.get_bodypart(check_zone(user.zone_selected))
	if(!limb)
		to_chat(user, "<span class='notice'>Нечего перевязывать!</span>")
		return
	if(!LAZYLEN(limb.wounds))
		to_chat(user, "<span class='notice'>[user==M ? "Ваша [limb.ru_name]" : "[limb.ru_name_capital] персонажа [M]"] не требует перевязки!</span>")
		return

	var/gauzeable_wound = FALSE
	for(var/i in limb.wounds)
		var/datum/wound/woundies = i
		if(woundies.wound_flags & ACCEPTS_GAUZE)
			gauzeable_wound = TRUE
			break
	if(!gauzeable_wound)
		to_chat(user, "<span class='notice'>[user==M ? "Ваша [limb.ru_name]" : "[limb.ru_name_capital] персонажа [M]"] не требует перевязки!</span>")
		return

	if(limb.current_gauze && (limb.current_gauze.absorption_capacity * 0.8 > absorption_capacity)) // ignore if our new wrap is < 20% better than the current one, so someone doesn't bandage it 5 times in a row
		to_chat(user, "<span class='warning'>Повязка, что наложена на [user==M ? "вашей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа[M]"], пока ещё хорошем состоянии!</span>")
		return

	user.visible_message("<span class='warning'>[user] пытается перевязать рану на [limb.ru_name_v] персонажа [M] с помощью [src]...</span>", "<span class='warning'>Вы пытаетесь перевязать раны на [user == M ? "вашей [limb.ru_name_v]" : "[limb.ru_name_v] персонажа [M]"] с помощью [src]...</span>")

	if(!do_after(user, (user == M ? self_delay : other_delay), target=M))
		return

	user.visible_message("<span class='green'>[user] наносит [src] на конечность персонажа [M]</span>", "<span class='green'>Вы пытаетесь перевязать раны на [user == M ? "своей конечности" : "конечности персонажа [M]"].</span>")
	limb.apply_gauze(src)

/obj/item/stack/medical/gauze/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WIRECUTTER || I.get_sharpness())
		if(get_amount() < 2)
			to_chat(user, "<span class='warning'>Вам необходимо как минимум две марлевых повязки!</span>")
			return
		new /obj/item/stack/sheet/cloth(user.drop_location())
		user.visible_message("[user] разрезает [src] на части с помощью [I].", \
					 "<span class='notice'>Вы разрезаете [src] на части с помощью [I].</span>", \
					 "<span class='italics'>Вы слышите звук разрезания ткани.</span>")
		use(2)
	else if(I.is_drainable() && I.reagents.has_reagent(/datum/reagent/space_cleaner/sterilizine))
		if(!I.reagents.has_reagent(/datum/reagent/space_cleaner/sterilizine, 5))
			to_chat(user, "<span class='warning'>Не хватает стерилизина в [I], чтобы обработать [src]!</span>")
			return
		user.visible_message("<span class='notice'>[user] обрабатывает [src] с помощью содержимого [I].</span>", "<span class='notice'>Вы выливаете содержимое [I] на [src], обрабатывая это.</span>")
		I.reagents.remove_reagent(/datum/reagent/space_cleaner/sterilizine, 5)
		new /obj/item/stack/medical/gauze/adv/one(user.drop_location())
		use(1)
	else
		return ..()

/obj/item/stack/medical/gauze/suicide_act(mob/living/user)
	user.visible_message("<span class='suicide'>[user] пытается обвязать \the [src] вокруг [user.ru_ego()] шеи! Похоже, [user.ru_who()] не совсем понимает, как пользоваться медикаментами!</span>")
	return OXYLOSS

/obj/item/stack/medical/gauze/one
	amount = 1

/obj/item/stack/medical/gauze/improvised
	name = "improvised gauze"
	singular_name = "improvised gauze"
	heal_brute = 0
	desc = "Моток грубо обрезанной ткани от чего-то делавшего хорошую работу в стабилизации ран. Делает это не так хорошо, чем полноценная повязка."
	self_delay = 60
	other_delay = 30
	absorption_rate = 0.15
	absorption_capacity = 4
	splint_factor = 0.15

/obj/item/stack/medical/gauze/adv
	name = "sterilized medical gauze"
	singular_name = "sterilized medical gauze"
	desc = "Моток эластичной стерилизованной ткани. Экстремально эффективна для остановки кровотечений и стабилизации ожогов."
	heal_brute = 7
	self_delay = 45
	other_delay = 15
	absorption_rate = 0.5
	absorption_capacity = 12
	splint_factor = 0.5

/obj/item/stack/medical/gauze/adv/one
	amount = 1

/obj/item/stack/medical/gauze/cyborg
	custom_materials = null
	is_cyborg = TRUE
	source = /datum/robot_energy_storage/medical
	cost = 250

/obj/item/stack/medical/suture
	name = "suture"
	desc = "Стандартная стерилизованная нить для закрытия порезов, рваных ран и остановок кровотечения."
	gender = PLURAL
	singular_name = "suture"
	icon_state = "suture"
	self_delay = 30
	other_delay = 10
	amount = 15
	max_amount = 15
	repeating = TRUE
	heal_brute = 13
	stop_bleeding = 0.6
	grind_results = list(/datum/reagent/medicine/spaceacillin = 2)

/obj/item/stack/medical/suture/emergency
	name = "emergency suture"
	desc = "Моток дешёвой нити, не очень хорошей для латания ран, но неплохо подходящей против кровотечений."
	heal_brute = 10
	amount = 5
	max_amount = 5

/obj/item/stack/medical/suture/one
	amount = 1

/obj/item/stack/medical/suture/five
	amount = 5

/obj/item/stack/medical/suture/medicated
	name = "medicated suture"
	icon_state = "suture_purp"
	desc = "Нить, смоченная в лекарствах, помогающих в заживлении самых тяжёлых рваных ран."
	heal_brute = 20
	stop_bleeding = 1
	grind_results = list(/datum/reagent/medicine/polypyr = 2)
	heal_dead = TRUE
	heal_dead_multiplier = 0.65

/obj/item/stack/medical/suture/medicated/one
	amount = 1

/obj/item/stack/medical/suture/one
	amount = 1

/obj/item/stack/medical/suture/heal(mob/living/M, mob/user)
	. = ..()
	var/efficiency = 1
	if(M.stat == DEAD)
		if(!heal_dead)
			to_chat(user, "<span class='warning'>[M] мертв[M.ru_a()]! Вы не можете [M.ru_emu()] помочь.</span>")
			return
		efficiency = heal_dead_multiplier
	if(iscarbon(M))
		return heal_carbon(M, user, heal_brute*efficiency, 0*efficiency)
	if(isanimal(M))
		var/mob/living/simple_animal/critter = M
		if (!(critter.healable))
			to_chat(user, "<span class='warning'>Вы не можете вылечить [M] при помощи \the [src]!</span>")
			return FALSE
		else if (critter.health == critter.maxHealth)
			to_chat(user, "<span class='notice'>[M] полностью здоров[M.ru_a()].</span>")
			return FALSE
		user.visible_message("<span class='green'>[user] зашивает раны [M] с помощью \the [src].</span>", "<span class='green'>Вы зашиваете раны [M] с помощью \the [src]</span>")
		M.heal_bodypart_damage(heal_brute*efficiency)
		return TRUE
	to_chat(user, "<span class='warning'>Вы не можете вылечить [M] при помощи \the [src]!</span>")

/obj/item/stack/medical/ointment
	name = "ointment"
	desc = "Стандартная мазь от ожогов, вполне эфффективная против ожогов второй степени при бинтовании, впрочем, также стабилизирует и более серьёзные ожоги. Не прям хороша для полного заживления ожогов."
	gender = PLURAL
	singular_name = "ointment"
	icon_state = "ointment"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount = 12
	max_amount = 12
	self_delay = 40
	other_delay = 20

	heal_burn = 10
	flesh_regeneration = 2.5
	sanitization = 0.4
	grind_results = list(/datum/reagent/medicine/kelotane = 10)

/obj/item/stack/medical/ointment/heal(mob/living/M, mob/user)
	var/efficiency = 1
	if(M.stat == DEAD)
		if(!heal_dead)
			to_chat(user, "<span class='warning'>Вы не можете вылечить [M] при помощи \the [src]!</span>")
			return
		efficiency = heal_dead_multiplier
	if(iscarbon(M))
		return heal_carbon(M, user, heal_brute*efficiency, heal_burn*efficiency)
	to_chat(user, "<span class='warning'>Вы не можете вылечить [M] при помощи \the [src]!</span>")

/obj/item/stack/medical/ointment/suicide_act(mob/living/user)
	user.visible_message("<span class='suicide'>[user] выдавливает \the [src] в свой рот! Он[user.ru_a()] вообще знает, что оно ядовито?!</span>")
	return TOXLOSS

/obj/item/stack/medical/mesh
	name = "regenerative mesh"
	desc = "Бактерицидная сетка для оборачивания ожогов."
	gender = PLURAL
	singular_name = "regenerative mesh"
	icon_state = "regen_mesh"
	self_delay = 30
	other_delay = 10
	amount = 15
	max_amount = 15
	heal_burn = 13
	repeating = TRUE
	sanitization = 0.75
	flesh_regeneration = 3
	var/is_open = TRUE ///This var determines if the sterile packaging of the mesh has been opened.
	grind_results = list(/datum/reagent/medicine/spaceacillin = 2)

/obj/item/stack/medical/mesh/one
	amount = 1

/obj/item/stack/medical/mesh/five
	amount = 5

/obj/item/stack/medical/mesh/advanced
	name = "advanced regenerative mesh"
	desc = "Продвинутая стека со смесью экстракта алоэ и стрелизирующих агентов, для работы с ожогами."
	gender = PLURAL
	singular_name = "advanced regenerative mesh"
	icon_state = "aloe_mesh"
	heal_burn = 20
	sanitization = 1.25
	flesh_regeneration = 5
	grind_results = list(/datum/reagent/consumable/aloejuice = 1)
	heal_dead = TRUE
	heal_dead_multiplier = 0.65

/obj/item/stack/medical/mesh/advanced/one
	amount = 1

/obj/item/stack/medical/mesh/Initialize(mapload)
	. = ..()
	if(amount == max_amount)	 //only seal full mesh packs
		is_open = FALSE
		update_icon()

/obj/item/stack/medical/mesh/advanced/update_icon_state()
	if(!is_open)
		icon_state = "aloe_mesh_closed"
	else
		return ..()

/obj/item/stack/medical/mesh/update_icon_state()
	if(!is_open)
		icon_state = "regen_mesh_closed"
	else
		return ..()

/obj/item/stack/medical/mesh/heal(mob/living/M, mob/user)
	. = ..()
	var/efficiency = 1
	if(M.stat == DEAD)
		if(!heal_dead)
			to_chat(user, "<span class='warning'>[M] мертв[M.ru_a()]! Вы не можете [M.ru_emu()] помочь.</span>")
			return
		efficiency = heal_dead_multiplier
	if(iscarbon(M))
		return heal_carbon(M, user, heal_brute*efficiency, heal_burn*efficiency)
	to_chat(user, "<span class='warning'>Вы не можете вылечить [M] при помощи \the [src]!</span>")


/obj/item/stack/medical/mesh/try_heal(mob/living/M, mob/user, silent = FALSE)
	if(!is_open)
		to_chat(user, "<span class='warning'>Вам нужно для начала раскрыть [src].</span>")
		return
	. = ..()

/obj/item/stack/medical/mesh/AltClick(mob/living/user)
	if(!is_open)
		to_chat(user, "<span class='warning'>Вам нужно для начала раскрыть [src].</span>")
		return
	. = ..()

/obj/item/stack/medical/mesh/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!is_open && (user.get_inactive_held_item() == src))
		to_chat(user, "<span class='warning'>Вам нужно для начала раскрыть [src].</span>")
		return
	. = ..()

/obj/item/stack/medical/mesh/attack_self(mob/user)
	if(!is_open)
		is_open = TRUE
		to_chat(user, "<span class='notice'>Вы раскрыли упакопку стерильной сетки.</span>")
		update_icon()
		playsound(src, 'sound/items/poster_ripped.ogg', 20, TRUE)
		return
	. = ..()

/obj/item/stack/medical/bone_gel
	name = "bone gel"
	singular_name = "bone gel"
	desc = "Сильнодействующий медицинский гель, при правильном применении на повреждённую кость провоцирует интенсивную реакцию сращивания костных тканей. Может быть применён напрямую, как и хирургическая лента, напрямую на кость в крайнем случае, что, впрочем, очень вредно пациенту и не рекомендуется."

	icon = 'icons/obj/surgery.dmi'
	icon_state = "bone-gel"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'

	amount = 4
	self_delay = 20
	grind_results = list(/datum/reagent/medicine/bicaridine = 10)
	novariants = TRUE

/obj/item/stack/medical/bone_gel/attack(mob/living/M, mob/user)
	to_chat(user, "<span class='warning'>Костный гель может быть применён только на раздробленные конечности в [span_red("агрессивном")] хвате!</span>")
	return

/obj/item/stack/medical/bone_gel/suicide_act(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		C.visible_message("<span class='suicide'>[C] выдавливает весь \the [src] внутрь своего рта! Это не правильное применение! Похоже, что [C.ru_who()] пытается совершить суицид!</span>")
		if(do_after(C, 2 SECONDS))
			C.emote("realagony")
			for(var/i in C.bodyparts)
				var/obj/item/bodypart/bone = i
				var/datum/wound/blunt/severe/oof_ouch = new
				oof_ouch.apply_wound(bone)
				var/datum/wound/blunt/critical/oof_OUCH = new
				oof_OUCH.apply_wound(bone)

			for(var/i in C.bodyparts)
				var/obj/item/bodypart/bone = i
				bone.receive_damage(brute=60)
			use(1)
			return (BRUTELOSS)
		else
			C.visible_message("<span class='suicide'>[C] проваливает затею как идиот и всё равно умудряется сдохнуть!</span>")
			return (BRUTELOSS)

/obj/item/stack/medical/bone_gel/cyborg
	custom_materials = null
	is_cyborg = TRUE
	source = /datum/robot_energy_storage/medical
	cost = 250

/obj/item/stack/medical/aloe
	name = "aloe cream"
	desc = "Лечащая паста для открытых ран."

	icon_state = "aloe_paste"
	self_delay = 20
	other_delay = 10
	novariants = TRUE
	amount = 20
	max_amount = 20
	var/heal = 3
	grind_results = list(/datum/reagent/consumable/aloejuice = 1)

/obj/item/stack/medical/aloe/heal(mob/living/M, mob/user)
	. = ..()
	var/efficiency = 1
	if(M.stat == DEAD)
		if(!heal_dead)
			to_chat(user, "<span class='warning'>[M] мертв[M.ru_a()]! Вы не можете [M.ru_emu()] помочь.</span>")
			return FALSE
		efficiency = heal_dead_multiplier
	if(iscarbon(M))
		return heal_carbon(M, user, heal*efficiency, heal*efficiency)
	if(isanimal(M))
		var/mob/living/simple_animal/critter = M
		if (!(critter.healable))
			to_chat(user, "Вы не можете использовать \the [src] на [M]!</span>")
			return FALSE
		else if (critter.health == critter.maxHealth)
			to_chat(user, "<span class='notice'>[M] не требует ухода.</span>")
			return FALSE
		user.visible_message("<span class='green'>[user] намазывает \the [src] на [M].</span>", "<span class='green'>Вы намазываете \the [src] на [M].</span>")
		M.heal_bodypart_damage(heal*efficiency, heal*efficiency)
		return TRUE

	to_chat(user, "<span class='warning'>Вы не можете вылечить [M] при помощи \the [src]!</span>")

/obj/item/stack/medical/nanogel
	name = "nanogel"
	singular_name = "nanogel"
	desc = "Высокотехнологичный гель, при применении на отремонтированную снаружи роботическую конечность - нейтрализует остаточные внутренние повреждения, позволяя дальнейшее обслуживание без хирургии."
	self_delay = 150	//Agonizingly slow if used on self, but, not completely forbidden because antags with robolimbs need a way to handle their thresholds.
	other_delay = 30	//Pretty fast if used on others.
	amount = 12
	max_amount = 12	//Two synths worth of fixing, if every single bodypart of them has internal damage. Usually, probably more like 6-12.
	icon_state = "nanogel"
	var/being_applied = FALSE	//No doafter stacking.

/obj/item/stack/medical/nanogel/one
	amount = 1

/obj/item/stack/medical/nanogel/try_heal(mob/living/M, mob/user, silent = FALSE)
	if(being_applied)
		to_chat(user, "<span class='warning'>Вы уже намазываете [src]!</span>")
		return
	if(!iscarbon(M))
		to_chat(user, "<span class='warning'>Оно не поможет [M]!</span>")
		return
	being_applied = TRUE
	..()
	being_applied = FALSE

/obj/item/stack/medical/nanogel/heal(mob/living/M, mob/user)
	var/mob/living/carbon/C = M	//Only carbons should be able to get here
	if(!C)
		return
	var/obj/item/bodypart/affecting = C.get_bodypart(check_zone(user.zone_selected))
	if(!affecting) //Missing limb?
		to_chat(user, "<span class='warning'>[C] не имеет \a [parse_zone(user.zone_selected)]!</span>")
		return
	if(!affecting.is_robotic_limb())
		to_chat(user, "<span class='warning'>Это не поможет нероботическим конечностям!</span>")
		return
	if(!affecting.threshhold_brute_passed && !affecting.threshhold_burn_passed)
		to_chat(user, "<span class='warning'>Нет нужды намазывать гель на [affecting].</span>")
		return
	if(affecting.threshhold_brute_passed && affecting.brute_dam == affecting.threshhold_passed_mindamage)
		. = TRUE
		affecting.threshhold_brute_passed = FALSE
	if(affecting.threshhold_burn_passed && affecting.burn_dam == affecting.threshhold_passed_mindamage)
		. = TRUE
		affecting.threshhold_burn_passed = FALSE
	if(.)
		user.visible_message("<span class='green'>Наногель вступает в реакцию на теле [C], ремонтируя внутренние повреждения [affecting].</span>", "<span_class='green'>Вы наблюдаете как наногель начинает работу по ремонту внутренних повреждений [affecting]</span>")
		return
	//If it gets here: It failed, lets tell the user why.
	to_chat(user, "<span class='warning'>[src] терпит неудачу в с [affecting] из-за остаточного урона [(affecting.threshhold_burn_passed && affecting.threshhold_burn_passed) ? "травм и ожогов" : "[affecting.threshhold_burn_passed ? "ожогами" : "травмами"]"]! Проведите внешне обслуживание перед применением.</span>")
