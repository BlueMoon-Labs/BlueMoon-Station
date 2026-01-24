//Cloning revival method.
//The pod handles the actual cloning while the computer manages the clone profiles

//Potential replacement for genetics revives or something I dunno (?)

#define CLONE_INITIAL_DAMAGE     150    //Clones in clonepods start with 150 cloneloss damage and 150 brainloss damage, thats just logical
#define MINIMUM_HEAL_LEVEL 20

#define SPEAK(message) radio.talk_into(src, message, radio_channel)

/obj/machinery/clonepod
	name = "cloning pod"
	desc = "Капсула с электронно-контролируемым замком для выращивания тканей органической природы."
	density = TRUE
	icon = 'icons/obj/machines/cloning.dmi'
	icon_state = "pod_0"
	req_access = list(ACCESS_CLONING) //FOR PREMATURE UNLOCKING.
	verb_say = "states"
	circuit = /obj/item/circuitboard/machine/clonepod

	var/heal_level //The clone is released once its health reaches this level.
	var/obj/machinery/computer/cloning/connected = null //So we remember the connected clone machine.
	var/mess = FALSE //Need to clean out it if it's full of exploded clone.
	var/attempting = FALSE //One clone attempt at a time thanks
	var/speed_coeff
	var/efficiency

	var/datum/mind/clonemind
	var/get_clone_mind = CLONEPOD_GET_MIND
	var/grab_ghost_when = CLONER_MATURE_CLONE

	var/internal_radio = TRUE
	var/obj/item/radio/radio
	var/radio_key = /obj/item/encryptionkey/headset_med
	var/radio_channel = RADIO_CHANNEL_MEDICAL

	var/obj/effect/countdown/clonepod/countdown

	var/list/unattached_flesh
	var/flesh_number = 0
	var/datum/bank_account/current_insurance
	fair_market_price = 5 // He nodded, because he knew I was right. Then he swiped his credit card to pay me for arresting him.
	payment_department = ACCOUNT_MED

/obj/machinery/clonepod/Initialize(mapload)
	. = ..()

	countdown = new(src)

	if(internal_radio)
		radio = new(src)
		radio.keyslot = new radio_key
		radio.subspace_transmission = TRUE
		radio.canhear_range = 0
		radio.recalculateChannels()

	update_icon()

/obj/machinery/clonepod/Destroy()
	go_out()
	QDEL_NULL(radio)
	QDEL_NULL(countdown)
	if(connected)
		connected.DetachCloner(src)
	QDEL_LIST(unattached_flesh)
	. = ..()

/obj/machinery/clonepod/RefreshParts()
	speed_coeff = 0
	efficiency = 0
	for(var/obj/item/stock_parts/scanning_module/S in component_parts)
		efficiency += S.rating
	for(var/obj/item/stock_parts/manipulator/P in component_parts)
		speed_coeff += (P.rating / 2)
	speed_coeff = max(1, speed_coeff)
	heal_level = clamp((efficiency * 10) + 10, MINIMUM_HEAL_LEVEL, 100)

//Clonepod

/obj/machinery/clonepod/examine(mob/user)
	. = ..()
	var/mob/living/mob_occupant = occupant
	. += span_notice("<i>Связующее</i> устройство может быть <i>отсканировано</i> мультитулом.</span>")
	if(mess)
		. += "Наполнено кровю и потрохами. Вы покляться можете, что оно двинулось..."
	if(in_range(user, src) || isobserver(user))
		. += span_notice("Статус-дисплей сообщает: \n\
		- Скорость клонирования: <b>[speed_coeff*50]%</b> \n\
		- Ожидаемые клеточные травмы: <b>[100-heal_level]%</b>.")
		if(efficiency > 5)
			to_chat(user, span_notice("Капсула улучшена и поддерживает автообработку."))
	if(is_operational() && mob_occupant)
		if(mob_occupant.stat != DEAD)
			. += "Текущий цикл клонирования завершён на [round(get_completion())]%"

/obj/machinery/clonepod/return_air()
	// We want to simulate the clone not being in contact with
	// the atmosphere, so we'll put them in a constant pressure
	// nitrogen. They don't need to breathe while cloning anyway.
	var/static/datum/gas_mixture/immutable/cloner/GM //global so that there's only one instance made for all cloning pods
	if(!GM)
		GM = new
	return GM

/obj/machinery/clonepod/proc/get_completion()
	. = FALSE
	var/mob/living/mob_occupant = occupant
	if(mob_occupant)
		. = (100 * ((mob_occupant.health + 100) / (heal_level + 100)))

/obj/machinery/clonepod/attack_ai(mob/user)
	return examine(user)

//Start growing a human clone in the pod!
/obj/machinery/clonepod/proc/growclone(ckey, clonename, ui, mutation_index, mindref, blood_type, datum/species/mrace, list/features, factions, list/quirks, datum/bank_account/insurance, list/traumas)
	if(panel_open)
		return FALSE
	if(mess || attempting)
		return FALSE
	if(get_clone_mind == CLONEPOD_GET_MIND)
		clonemind = locate(mindref) in SSticker.minds
		if(!istype(clonemind))	//not a mind
			return FALSE
		if(!QDELETED(clonemind.current))
			if(clonemind.current.stat != DEAD)	//mind is associated with a non-dead body
				return FALSE
			if(clonemind.current.suiciding) // Mind is associated with a body that is suiciding.
				return FALSE
			if(AmBloodsucker(clonemind.current)) //If the mind is a bloodsucker
				return FALSE
		if(clonemind.active)	//somebody is using that mind
			if( ckey(clonemind.key)!=ckey )
				return FALSE
		else
			// get_ghost() will fail if they're unable to reenter their body
			var/mob/dead/observer/G = clonemind.get_ghost()
			if(!G)
				return FALSE
			if(G.suiciding) // The ghost came from a body that is suiciding.
				return FALSE
		if(clonemind.damnation_type) //Can't clone the damned.
			INVOKE_ASYNC(src, PROC_REF(horrifyingsound))
			mess = TRUE
			update_icon()
			return FALSE
	current_insurance = insurance
	attempting = TRUE //One at a time!!
	countdown.start()

	var/mob/living/carbon/human/H = new /mob/living/carbon/human(src)

	H.hardset_dna(ui, mutation_index, H.real_name, blood_type, mrace, features)

	H.easy_randmut(NEGATIVE+MINOR_NEGATIVE) //100% bad mutation. Can be cured with mutadone.

	H.silent = 20 //Prevents an extreme edge case where clones could speak if they said something at exactly the right moment.
	occupant = H

	if(!clonename)	//to prevent null names
		clonename = "clone ([rand(1,999)])"
	H.real_name = clonename

	//Get the clone body ready
	maim_clone(H)
	ADD_TRAIT(H, TRAIT_MUTATION_STASIS, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_STABLEHEART, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_STABLELIVER, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_EMOTEMUTE, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_MUTE, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_NOBREATH, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_NOCRITDAMAGE, CLONING_POD_TRAIT)
	H.Unconscious(80)

	if(clonemind)
		clonemind.transfer_to(H)

	else if(get_clone_mind == CLONEPOD_POLL_MIND)
		poll_for_mind(H, clonename)

	if(grab_ghost_when == CLONER_FRESH_CLONE)
		H.grab_ghost()
		to_chat(H, "<span class='notice'><b>Сознание медленно подкрадывается к вам с регенерацией вашего тела.</b><br><i>Так вот как ощущается клонирование?</i></span>")

	if(grab_ghost_when == CLONER_MATURE_CLONE)
		H.ghostize(TRUE)	//Only does anything if they were still in their old body and not already a ghost
		to_chat(H.get_ghost(TRUE), "<span class='notice'>Ваше тело начинает регенерировать в капсуле клонирования. Вы придёте в сознание как только это завершится.</span>")

	if(H)
		H.faction |= factions

		for(var/V in quirks)
			var/datum/quirk/Q = new V(H)
			Q.on_clone(quirks[V])

		for(var/t in traumas)
			var/datum/brain_trauma/BT = t
			var/datum/brain_trauma/cloned_trauma = BT.on_clone()
			if(cloned_trauma)
				H.gain_trauma(cloned_trauma, BT.resilience)

		H.set_cloned_appearance()
		H.give_genitals(TRUE)

		H.suiciding = FALSE
	attempting = FALSE
	return TRUE

/obj/machinery/clonepod/proc/poll_for_mind(mob/living/carbon/human/H, clonename)
	set waitfor = FALSE
	var/list/candidates = pollCandidatesForMob("Хотите ли взять роль дефективного клона [clonename]? (Не занимайтесь ERP без разрешения оригинала)", null, null, null, 100, H, POLL_IGNORE_CLONE)
	if(LAZYLEN(candidates))
		var/mob/C = pick(candidates)
		H.key = C.key

//Grow clones to maturity then kick them out.  FREELOADERS
/obj/machinery/clonepod/process()
	var/mob/living/mob_occupant = occupant

	if(!is_operational()) //Autoeject if power is lost
		if(mob_occupant)
			go_out()
			mob_occupant.copy_from_prefs_vr()
			connected_message("Клон извлечён: потеряна энергия.")

	else if(mob_occupant && (mob_occupant.loc == src))
		if(SSeconomy.full_ancap)
			if(!current_insurance)
				go_out()
				connected_message("Клон извлечён: нет банковского аккаунта.")
				if(internal_radio)
					SPEAK("Клонирование субъекта [mob_occupant.real_name] было отменено ввиду отсутствия банковского аккаунта для взымания оплаты.")
			else if(!current_insurance.adjust_money(-fair_market_price))
				go_out()
				connected_message("CКлон извлечён: недостаточно средств.")
				if(internal_radio)
					SPEAK("Клонирование субъекта [mob_occupant.real_name] было заранее отменено ввиду отсутствия средств для оплаты.")
			else
				var/datum/bank_account/D = SSeconomy.get_dep_account(payment_department)
				if(D)
					D.adjust_money(fair_market_price)
		if(mob_occupant && (mob_occupant.stat == DEAD) || (mob_occupant.suiciding) || mob_occupant.hellbound)  //Autoeject corpses and suiciding dudes.			connected_message("Clone Rejected: Deceased.")
			if(internal_radio)
				SPEAK("Клонирование было \
					отменено ввиду невосстановимого отказа тканей.")
			go_out()
			mob_occupant.copy_from_prefs_vr()

		else if(mob_occupant && mob_occupant.cloneloss > (100 - heal_level))
			mob_occupant.Unconscious(80)
			var/dmg_mult = CONFIG_GET(number/damage_multiplier)
			 //Slowly get that clone healed and finished.
			mob_occupant.adjustCloneLoss(-((speed_coeff / 2) * dmg_mult))
			var/progress = CLONE_INITIAL_DAMAGE - mob_occupant.getCloneLoss()
			// To avoid the default cloner making incomplete clones
			progress += (100 - MINIMUM_HEAL_LEVEL)
			var/milestone = CLONE_INITIAL_DAMAGE / flesh_number
			var/installed = flesh_number - unattached_flesh.len

			if((progress / milestone) >= installed)
				// attach some flesh
				var/obj/item/I = pick_n_take(unattached_flesh)
				if(isorgan(I))
					var/obj/item/organ/O = I
					O.organ_flags &= ~ORGAN_FROZEN
					O.Insert(mob_occupant)
				else if(isbodypart(I))
					var/obj/item/bodypart/BP = I
					BP.attach_limb(mob_occupant)

			use_power(7500) //This might need tweaking.

		else if((mob_occupant && mob_occupant.cloneloss <= (100 - heal_level)))
			connected_message("Процесс клонирования завершён.")
			if(internal_radio)
				SPEAK("Цикл клонирования завершён.")

			// If the cloner is upgraded to debugging high levels, sometimes
			// organs and limbs can be missing.
			for(var/i in unattached_flesh)
				if(isorgan(i))
					var/obj/item/organ/O = i
					O.organ_flags &= ~ORGAN_FROZEN
					O.Insert(mob_occupant)
				else if(isbodypart(i))
					var/obj/item/bodypart/BP = i
					BP.attach_limb(mob_occupant)

			go_out()
			mob_occupant.copy_from_prefs_vr()

	else if (!mob_occupant || mob_occupant.loc != src)
		occupant = null
		use_power(200)

	update_icon()

//Let's unlock this early I guess.  Might be too early, needs tweaking.
/obj/machinery/clonepod/attackby(obj/item/W, mob/user, params)
	if(!(occupant || mess))
		if(default_deconstruction_screwdriver(user, "[icon_state]_maintenance", "[initial(icon_state)]",W))
			return

	if(default_deconstruction_crowbar(W))
		return

	if(W.tool_behaviour == TOOL_MULTITOOL)
		if(istype(W.buffer, /obj/machinery/computer/cloning))
			if(get_area(W.buffer) != get_area(src))
				to_chat(user, "<font color = #666633>-% Нельзя соединить машинерию между зонами питания. Буфер очищен %-</font color>")
				W.buffer = null
				return
			to_chat(user, "<font color = #666633>-% Успешно соединено [W.buffer] с [src] %-</font color>")
			var/obj/machinery/computer/cloning/comp = W.buffer
			if(connected)
				connected.DetachCloner(src)
			comp.AttachCloner(src)
		else
			W.buffer = src
			to_chat(user, "<font color = #666633>-% Успешно сохранено [REF(W.buffer)] [W.buffer] в буфер обмена %-</font color>")
		return

	var/mob/living/mob_occupant = occupant
	if(W.GetID())
		if(!check_access(W))
			to_chat(user, "<span class='danger'>В доступе отказано.</span>")
			return
		if(!(mob_occupant || mess))
			to_chat(user, "<span class='danger'>Ошибка: капсула не имеет пациента.</span>")
			return
		else
			connected_message("Emergency Ejection")
			SPEAK("Экстренное извлечение текущего клона. Выживание не гарантируется.")
			to_chat(user, "<span class='notice'>Вы вынудили экстренное извлечение. </span>")
			go_out()
			mob_occupant.copy_from_prefs_vr()
	else
		return ..()

/obj/machinery/clonepod/emag_act(mob/user)
	. = ..()
	if(!occupant)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	to_chat(user, "<span class='warning'>Вы испортили генетические процессы компиляции.</span>")
	malfunction()
	return TRUE

//Put messages in the connected computer's temp var for display.
/obj/machinery/clonepod/proc/connected_message(message)
	if ((isnull(connected)) || (!istype(connected, /obj/machinery/computer/cloning)))
		return FALSE
	if (!message)
		return FALSE

	connected.cloning_message = message
	connected.updateUsrDialog()
	return TRUE

/obj/machinery/clonepod/proc/go_out()
	countdown.stop()
	var/mob/living/mob_occupant = occupant
	var/turf/T = get_turf(src)

	if(mess) //Clean that mess and dump those gibs!
		for(var/obj/fl in unattached_flesh)
			fl.forceMove(T)
			if(istype(fl, /obj/item/organ))
				var/obj/item/organ/O = fl
				O.organ_flags &= ~ORGAN_FROZEN
		unattached_flesh.Cut()
		mess = FALSE
		if(mob_occupant)
			mob_occupant.spawn_gibs()
		audible_message("<span class='italics'>Вы слышите шлепок.</span>")
		update_icon()
		return

	if(!mob_occupant)
		return
	current_insurance = null
	REMOVE_TRAIT(mob_occupant, TRAIT_STABLEHEART, CLONING_POD_TRAIT)
	REMOVE_TRAIT(mob_occupant, TRAIT_MUTATION_STASIS, CLONING_POD_TRAIT)
	REMOVE_TRAIT(mob_occupant, TRAIT_STABLELIVER, CLONING_POD_TRAIT)
	REMOVE_TRAIT(mob_occupant, TRAIT_EMOTEMUTE, CLONING_POD_TRAIT)
	REMOVE_TRAIT(mob_occupant, TRAIT_MUTE, CLONING_POD_TRAIT)
	REMOVE_TRAIT(mob_occupant, TRAIT_NOCRITDAMAGE, CLONING_POD_TRAIT)
	REMOVE_TRAIT(mob_occupant, TRAIT_NOBREATH, CLONING_POD_TRAIT)

	if(grab_ghost_when == CLONER_MATURE_CLONE)
		mob_occupant.grab_ghost()
		to_chat(occupant, "<span class='notice'><b>Появляется яркая вспышка!</b><br><i>Вы ощущаетесь новым существом.</i></span>")
		mob_occupant.flash_act()

	var/list/policies = CONFIG_GET(keyed_list/policy)
	var/policy = policies[POLICYCONFIG_ON_CLONE]
	if(policy)
		to_chat(occupant, policy)
	occupant.log_message("revived using cloning.", LOG_GAME)
	mob_occupant.adjustOrganLoss(ORGAN_SLOT_BRAIN, mob_occupant.getCloneLoss())

	occupant.forceMove(T)
	update_icon()
	mob_occupant.domutcheck(1) //Waiting until they're out before possible monkeyizing. The 1 argument forces powers to manifest.
	for(var/fl in unattached_flesh)
		qdel(fl)
	unattached_flesh.Cut()

	occupant = null

/obj/machinery/clonepod/proc/malfunction()
	var/mob/living/mob_occupant = occupant
	if(mob_occupant)
		connected_message("Критическая ошибка!")
		SPEAK("Критическая ошибка! Пожалуйста, сообщите технику Thinktronic Systems, ввиду возможного случая вашей гарантии.")
		mess = TRUE
		maim_clone(mob_occupant)	//Remove every bit that's grown back so far to drop later, also destroys bits that haven't grown yet
		update_icon()
		if(mob_occupant.mind != clonemind)
			clonemind.transfer_to(mob_occupant)
		mob_occupant.grab_ghost() // We really just want to make you suffer.
		flash_color(mob_occupant, flash_color="#960000", flash_time=100)
		to_chat(mob_occupant, "<span class='warning'><b>Агония полыхает в сознании, пока ваше тело рвёт на части.</b><br><i>Так вот, каково умирать? Именно так.</i></span>")
		playsound(src.loc, 'sound/machines/warning-buzzer.ogg', 50, 0)
		SEND_SOUND(mob_occupant, sound('sound/hallucinations/veryfar_noise.ogg',0,1,50))
		QDEL_IN(mob_occupant, 40)

/obj/machinery/clonepod/relaymove(mob/user)
	container_resist(user)

/obj/machinery/clonepod/container_resist(mob/living/user)
	if(user.stat == CONSCIOUS)
		go_out()

/obj/machinery/clonepod/emp_act(severity)
	. = ..()
	if (!(. & EMP_PROTECT_SELF))
		var/mob/living/mob_occupant = occupant
		if(mob_occupant && prob((25+severity/1.34)/efficiency))
			connected_message(Gibberish("ЭМИ-спровоцированное случайное извлечение", 0))
			SPEAK(Gibberish("Воздействие электромагнитного возмущения спровоцировало извлечение, ОШИБКА: Ивана Иванова, преждевременно." ,0))
			mob_occupant.copy_from_prefs_vr()
			go_out()

/obj/machinery/clonepod/ex_act(severity, target, origin)
	..()
	if(!QDELETED(src))
		go_out()

/obj/machinery/clonepod/handle_atom_del(atom/A)
	if(A == occupant)
		occupant = null
		countdown.stop()

/obj/machinery/clonepod/proc/horrifyingsound()
	for(var/i in 1 to 5)
		playsound(loc,pick('sound/hallucinations/growl1.ogg','sound/hallucinations/growl2.ogg','sound/hallucinations/growl3.ogg'), 100, rand(0.95,1.05))
		sleep(1)
	sleep(10)
	playsound(loc,'sound/hallucinations/wail.ogg',100,1)

/obj/machinery/clonepod/deconstruct(disassembled = TRUE)
	if(occupant)
		go_out()
	..()

/obj/machinery/clonepod/proc/maim_clone(mob/living/carbon/human/H)
	if(!unattached_flesh)
		unattached_flesh = list()
	else
		for(var/fl in unattached_flesh)
			qdel(fl)
		unattached_flesh.Cut()

	H.setCloneLoss(CLONE_INITIAL_DAMAGE)     //Yeah, clones start with very low health, not with random, because why would they start with random health
	// In addition to being cellularly damaged, they also have no limbs or internal organs.
	// Applying brainloss is done when the clone leaves the pod, so application of traumas can happen.
	// based on the level of damage sustained.

	if(!HAS_TRAIT(H, TRAIT_NODISMEMBER))
		var/static/list/zones = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
		for(var/zone in zones)
			var/obj/item/bodypart/BP = H.get_bodypart(zone)
			if(BP)
				BP.drop_limb()
				BP.forceMove(src)
				unattached_flesh += BP

	for(var/o in H.internal_organs)
		var/obj/item/organ/organ = o
		if(!istype(organ) || (organ.organ_flags & ORGAN_VITAL))
			continue
		organ.organ_flags |= ORGAN_FROZEN
		organ.Remove(TRUE)
		organ.forceMove(src)
		unattached_flesh += organ

	flesh_number = unattached_flesh.len

/obj/machinery/clonepod/update_icon_state()
	if(mess)
		icon_state = "pod_g"
	else if(occupant)
		icon_state = "pod_1"
	else
		icon_state = "pod_0"

	if(panel_open)
		icon_state = "pod_0_maintenance"

/obj/machinery/clonepod/update_overlays()
	. = ..()
	if(mess)
		var/mutable_appearance/gib1 = mutable_appearance(CRYOMOBS, "gibup")
		var/mutable_appearance/gib2 = mutable_appearance(CRYOMOBS, "gibdown")
		gib1.pixel_y = 27 + round(sin(world.time) * 3)
		gib1.pixel_x = round(sin(world.time * 3))
		gib2.pixel_y = 27 + round(cos(world.time) * 3)
		gib2.pixel_x = round(cos(world.time * 3))
		. += gib2
		. += gib1
	else if(occupant)
		var/mutable_appearance/occupant_overlay
		var/completion = (flesh_number - unattached_flesh.len) / flesh_number

		if(unattached_flesh.len <= 0)
			occupant_overlay = mutable_appearance(occupant.icon, occupant.icon_state)
			occupant_overlay.copy_overlays(occupant)
			. += "cover-on"
		else
			occupant_overlay = mutable_appearance(CRYOMOBS, "clone_meat")
			var/matrix/tform = matrix()
			tform.Scale(completion)
			tform.Turn(cos(world.time * 2) * 3)
			occupant_overlay.transform = tform
			occupant_overlay.appearance_flags = NONE

		occupant_overlay.dir = SOUTH
		occupant_overlay.pixel_y = 27 + round(sin(world.time) * 3)
		occupant_overlay.pixel_x = round(sin(world.time * 3))

		. += occupant_overlay
		. += "cover-on"
	. += "panel"

//Experimental cloner; clones a body regardless of the owner's status, letting a ghost control it instead
/obj/machinery/clonepod/experimental
	name = "experimental cloning pod"
	desc = "Древняя капсула клонирования. Выглядит как ранний прототип экспериментальных клонерок, что были на объектах Nanotrasen Stations."
	icon = 'icons/obj/machines/cloning.dmi'
	icon_state = "pod_0"
	req_access = null
	circuit = /obj/item/circuitboard/machine/clonepod/experimental
	internal_radio = FALSE
	get_clone_mind = CLONEPOD_POLL_MIND

/*
 *	Manual -- A big ol' manual.
 */

/obj/item/paper/guides/jobs/medical/cloning
	name = "paper - 'H-87 Cloning Apparatus Manual"
	default_raw_text = {"<h4>Getting Started</h4>
	Congratulations, your station has purchased the H-87 industrial cloning device!<br>
	Using the H-87 is almost as simple as brain surgery! Simply insert the target humanoid into the scanning chamber and select the scan option to create a new profile!<br>
	<b>That's all there is to it!</b><br>
	<i>Notice, cloning system cannot scan inorganic life or small primates.  Scan may fail if subject has suffered extreme brain damage.</i><br>
	<p>Clone profiles may be viewed through the profiles menu. Scanning implants a complementary HEALTH MONITOR IMPLANT into the subject, which may be viewed from each profile.
	Profile Deletion has been restricted to \[Station Head\] level access.</p>
	<h4>Cloning from a profile</h4>
	Cloning is as simple as pressing the CLONE option at the bottom of the desired profile.<br>
	Per your company's EMPLOYEE PRIVACY RIGHTS agreement, the H-87 has been blocked from cloning crewmembers while they are still alive.<br>
	<br>
	<p>The provided CLONEPOD SYSTEM will produce the desired clone.  Standard clone maturation times (With SPEEDCLONE technology) are roughly 90 seconds.
	The cloning pod may be unlocked early with any \[Medical Researcher\] ID after initial maturation is complete.</p><br>
	<i>Please note that resulting clones may have a small DEVELOPMENTAL DEFECT as a result of genetic drift.</i><br>
	<h4>Profile Management</h4>
	<p>The H-87 (as well as your station's standard genetics machine) can accept STANDARD DATA DISKETTES.
	These diskettes are used to transfer genetic information between machines and profiles.
	A load/save dialog will become available in each profile if a disk is inserted.</p><br>
	<i>A good diskette is a great way to counter aforementioned genetic drift!</i><br>
	<br>
	<font size=1>This technology produced under license from Thinktronic Systems, LTD.</font>"}

#undef CLONE_INITIAL_DAMAGE
#undef SPEAK
#undef MINIMUM_HEAL_LEVEL
