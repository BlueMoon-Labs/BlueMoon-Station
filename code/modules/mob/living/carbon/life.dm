/mob/living/carbon/BiologicalLife(delta_time, times_fired)
	//Reagent processing needs to come before breathing, to prevent edge cases.
	handle_organs(delta_time, times_fired)
	. = ..()		// if . is false, we are dead.
	if(stat == DEAD)
		stop_sound_channel(CHANNEL_HEARTBEAT)
		handle_death()
		rot()
		. = FALSE
	if(!.)
		return
	handle_blood(delta_time, times_fired)
	// handle_blood *could* kill us.
	// we should probably have a better system for if we need to check for death or something in the future hmw
	if(stat != DEAD)
		var/bprv = handle_bodyparts()
		if(bprv & BODYPART_LIFE_UPDATE_HEALTH)
			updatehealth()
	update_stamina()
	doSprintBufferRegen()

	if(stat != DEAD)
		handle_brain_damage()

	if(stat != DEAD)
		handle_liver(delta_time, times_fired)

	if(stat != DEAD)
		handle_corruption()


/mob/living/carbon/PhysicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	if(damageoverlaytemp)
		damageoverlaytemp = 0
		update_damage_hud()

//Procs called while dead
/mob/living/carbon/proc/handle_death()
	if(reagents) // BLUEMOON EDIT - sanity check
		for(var/datum/reagent/R in reagents.reagent_list)
			if(R.chemical_flags & REAGENT_DEAD_PROCESS && !is_reagent_processing_invalid(R, src))
				R.on_mob_dead(src)

///////////////
// BREATHING //
///////////////

//Start of a breath chain, calls breathe()
/mob/living/carbon/handle_breathing(times_fired)
	var/next_breath = 4
	var/obj/item/organ/lungs/L = getorganslot(ORGAN_SLOT_LUNGS)
	var/obj/item/organ/heart/H = getorganslot(ORGAN_SLOT_HEART)
	if(L)
		if(L.damage > L.high_threshold)
			next_breath--
	if(H)
		if(H.damage > H.high_threshold)
			next_breath--

	if((times_fired % next_breath) == 0 || failed_last_breath)
		breathe() //Breathe per 4 ticks if healthy, down to 2 if our lungs or heart are damaged, unless suffocating
		if(failed_last_breath)
			//SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "suffocation", /datum/mood_event/suffocation)

			// HYPER CHANGE
			if(!HAS_TRAIT(src, TRAIT_CHOKE_SLUT))
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "suffocation", /datum/mood_event/suffocation)
			// HYPER CHANGE END

		else
			SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "suffocation")
	else
		if(istype(loc, /obj/))
			var/obj/location_as_object = loc
			location_as_object.handle_internal_lifeform(src,0)

//Second link in a breath chain, calls check_breath()
/mob/living/carbon/proc/breathe()
	var/obj/item/organ/lungs = getorganslot(ORGAN_SLOT_LUNGS)
	if(reagents?.has_reagent(/datum/reagent/toxin/lexorin))
		return
	if(istype(loc, /obj/machinery/atmospherics/components/unary/cryo_cell))
		return
	if(istype(loc, /obj/item/dogborg/sleeper))
		return
	if(ismob(loc))
		return
	if(isbelly(loc))
		return

	var/datum/gas_mixture/environment
	if(loc)
		environment = loc.return_air()

	var/datum/gas_mixture/breath

	if(!getorganslot(ORGAN_SLOT_BREATHING_TUBE))
		if(health <= HEALTH_THRESHOLD_FULLCRIT || (pulledby && pulledby.grab_state >= GRAB_KILL) || HAS_TRAIT(src, TRAIT_MAGIC_CHOKE) || (lungs && lungs.organ_flags & ORGAN_FAILING))
			losebreath++  //You can't breath at all when in critical or when being choked, so you're going to miss a breath

		else if(health <= crit_threshold)
			losebreath += 0.25 //You're having trouble breathing in soft crit, so you'll miss a breath one in four times

	//Suffocate
	if(losebreath >= 1) //You've missed a breath, take oxy damage
		losebreath--
		if(prob(10))
			emote("gasp")
		if(istype(loc, /obj/))
			var/obj/loc_as_obj = loc
			loc_as_obj.handle_internal_lifeform(src,0)
	else
		//Breathe from internal
		breath = get_breath_from_internal(BREATH_VOLUME)

		if(isnull(breath)) //in case of 0 pressure internals

			if(isobj(loc)) //Breathe from loc as object
				var/obj/loc_as_obj = loc
				breath = loc_as_obj.handle_internal_lifeform(src, BREATH_VOLUME)

			else if(isturf(loc)) //Breathe from loc as turf
				var/breath_ratio = 0
				if(environment)
					breath_ratio = BREATH_VOLUME/environment.return_volume()

				breath = loc.remove_air_ratio(breath_ratio)
		else //Breathe from loc as obj again
			if(istype(loc, /obj/))
				var/obj/loc_as_obj = loc
				loc_as_obj.handle_internal_lifeform(src,0)

	if(breath)
		breath.set_volume(BREATH_VOLUME)
	check_breath(breath)

	// Always return breath to environment and qdel to prevent gas mixture leak - each breath creates a new mixture via remove_air_ratio
	if(breath)
		if(loc)
			loc.assume_air(breath)
		qdel(breath)
		air_update_turf()

/mob/living/carbon/proc/has_smoke_protection()
	if(HAS_TRAIT(src, TRAIT_NOBREATH))
		return TRUE
	return FALSE


//Third link in a breath chain, calls handle_breath_temperature()
/mob/living/carbon/proc/check_breath(datum/gas_mixture/breath)
	if((status_flags & GODMODE))
		return

	var/obj/item/organ/lungs = getorganslot(ORGAN_SLOT_LUNGS)
	if(!lungs)
		adjustOxyLoss(2)

	//CRIT
	if(!breath || (breath.total_moles() == 0) || !lungs)
		if(reagents?.has_reagent(/datum/reagent/medicine/epinephrine) && lungs)
			return
		adjustOxyLoss(1)

		failed_last_breath = 1
		throw_alert("not_enough_oxy", /atom/movable/screen/alert/not_enough_oxy)
		return FALSE

	var/safe_oxy_min = 16
	var/safe_oxy_max = 50
	var/safe_co2_max = 10
	var/safe_tox_max = 0.05
	var/SA_para_min = 1
	var/SA_sleep_min = 5
	var/oxygen_used = 0
	var/moles = breath.total_moles()
	var/breath_pressure = (moles*R_IDEAL_GAS_EQUATION*breath.return_temperature())/BREATH_VOLUME
	var/O2_partialpressure = ((breath.get_moles(GAS_O2)/moles)*breath_pressure) + (((breath.get_moles(GAS_PLUOXIUM)*8)/moles)*breath_pressure)
	var/Toxins_partialpressure = (breath.get_moles(GAS_PLASMA)/moles)*breath_pressure
	var/CO2_partialpressure = (breath.get_moles(GAS_CO2)/moles)*breath_pressure


	//OXYGEN
	if(O2_partialpressure > safe_oxy_max) // Too much Oxygen - blatant CO2 effect copy/pasta
		if(!o2overloadtime)
			o2overloadtime = world.time
		else if(world.time - o2overloadtime > 120)
			Dizzy(10)	// better than a minute of you're fucked KO, but certainly a wake up call. Honk.
			adjustOxyLoss(3)
			if(world.time - o2overloadtime > 300)
				adjustOxyLoss(8)
		if(prob(20))
			emote("cough")
		throw_alert("too_much_oxy", /atom/movable/screen/alert/too_much_oxy)
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "suffocation", /datum/mood_event/suffocation)

	if(O2_partialpressure < safe_oxy_min) //Not enough oxygen
		if(prob(20))
			emote("gasp")
		if(O2_partialpressure > 0)
			var/ratio = 1 - O2_partialpressure/safe_oxy_min
			adjustOxyLoss(min(5*ratio, 3))
			failed_last_breath = 1
			oxygen_used = breath.get_moles(GAS_O2)*ratio
		else
			adjustOxyLoss(3)
			failed_last_breath = 1
		throw_alert("not_enough_oxy", /atom/movable/screen/alert/not_enough_oxy)
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "suffocation", /datum/mood_event/suffocation)

	else //Enough oxygen
		failed_last_breath = 0
		o2overloadtime = 0 //reset our counter for this too
		if(health >= crit_threshold)
			adjustOxyLoss(-5)
		oxygen_used = breath.get_moles(GAS_O2)
		clear_alert("not_enough_oxy")
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "suffocation")

	breath.adjust_moles(GAS_O2, -oxygen_used)
	breath.adjust_moles(GAS_CO2, oxygen_used)

	//CARBON DIOXIDE
	if(CO2_partialpressure > safe_co2_max)
		if(!co2overloadtime)
			co2overloadtime = world.time
		else if(world.time - co2overloadtime > 120)
			Unconscious(60)
			adjustOxyLoss(3)
			if(world.time - co2overloadtime > 300)
				adjustOxyLoss(8)
		if(prob(20))
			emote("cough")

	else
		co2overloadtime = 0

	//TOXINS/PLASMA
	if(Toxins_partialpressure > safe_tox_max)
		var/ratio = (breath.get_moles(GAS_PLASMA)/safe_tox_max) * 10
		adjustToxLoss(clamp(ratio, MIN_TOXIC_GAS_DAMAGE, MAX_TOXIC_GAS_DAMAGE))
		throw_alert("too_much_tox", /atom/movable/screen/alert/too_much_tox)
	else
		clear_alert("too_much_tox")

	//NITROUS OXIDE
	if(breath.get_moles(GAS_NITROUS))
		var/SA_partialpressure = (breath.get_moles(GAS_NITROUS)/breath.total_moles())*breath_pressure
		if(SA_partialpressure > SA_para_min)
			Unconscious(60)
			if(SA_partialpressure > SA_sleep_min)
				Sleeping(max(AmountSleeping() + 60, 400)) // BLUEMOON EDIT, WAS H.Sleeping(max(H.AmountSleeping() + 40, 400)) - сервак лагает и под анестезией просыпаются
		else if(SA_partialpressure > 0.01)
			if(prob(20))
				emote(pick("giggle","laugh"))
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "chemical_euphoria", /datum/mood_event/chemical_euphoria)
	else
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "chemical_euphoria")

	//BZ (Facepunch port of their Agent B)
	if(breath.get_moles(GAS_BZ))
		var/bz_partialpressure = (breath.get_moles(GAS_BZ)/breath.total_moles())*breath_pressure
		if(bz_partialpressure > 1)
			hallucination += 10
		else if(bz_partialpressure > 0.01)
			hallucination += 5

	//TRITIUM
	if(breath.get_moles(GAS_TRITIUM))
		var/tritium_partialpressure = (breath.get_moles(GAS_TRITIUM)/breath.total_moles())*breath_pressure
		radiation += tritium_partialpressure/10

	//NITRYL
	if(breath.get_moles(GAS_NITRYL))
		var/nitryl_partialpressure = (breath.get_moles(GAS_NITRYL)/breath.total_moles())*breath_pressure
		adjustFireLoss(nitryl_partialpressure/4)

	//MIASMA
	if(breath.get_moles(GAS_MIASMA))
		var/miasma_partialpressure = (breath.get_moles(GAS_MIASMA)/breath.total_moles())*breath_pressure
		if(miasma_partialpressure > MINIMUM_MOLES_DELTA_TO_MOVE)

			if(prob(0.05 * miasma_partialpressure))
				var/datum/disease/advance/miasma_disease = new /datum/disease/advance/random(TRUE, 2,3)
				miasma_disease.name = "Unknown"
				ForceContractDisease(miasma_disease, TRUE, TRUE)

			//Miasma side effects
			switch(miasma_partialpressure)
				if(1 to 5)
					// At lower pp, give out a little warning
					SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "smell")
					if(prob(5))
						to_chat(src, "<span class='notice'>There is an unpleasant smell in the air.</span>")
				if(5 to 20)
					//At somewhat higher pp, warning becomes more obvious
					if(prob(15))
						to_chat(src, "<span class='warning'>You smell something horribly decayed inside this room.</span>")
						SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "smell", /datum/mood_event/disgust/bad_smell)
				if(15 to 30)
					//Small chance to vomit. By now, people have internals on anyway
					if(prob(5))
						to_chat(src, "<span class='warning'>The stench of rotting carcasses is unbearable!</span>")
						SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "smell", /datum/mood_event/disgust/nauseating_stench)
						vomit()
				if(30 to INFINITY)
					//Higher chance to vomit. Let the horror start
					if(prob(25))
						to_chat(src, "<span class='warning'>The stench of rotting carcasses is unbearable!</span>")
						SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "smell", /datum/mood_event/disgust/nauseating_stench)
						vomit()
				else
					SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "smell")


	//Clear all moods if no miasma at all
	else
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "smell")

	//BREATH TEMPERATURE
	handle_breath_temperature(breath)

	return TRUE

//Fourth and final link in a breath chain
/mob/living/carbon/proc/handle_breath_temperature(datum/gas_mixture/breath)
	return

/mob/living/carbon/proc/get_breath_from_internal(volume_needed)
	var/obj/item/clothing/check
	var/internals = FALSE

	if(!HAS_TRAIT(src, TRAIT_NO_INTERNALS))
		for(check in GET_INTERNAL_SLOTS(src))
			if((check.clothing_flags & ALLOWINTERNALS))
				internals = TRUE
	if(internal)
		if(internal.loc != src && !istype(internal.loc, /obj/structure/table/optable)) // BLUEMOON ADD - добавлено проверка на хирургический стол, чтобы можно было пользоваться баллоном из него
			internal = null
		else if (!internals && !getorganslot(ORGAN_SLOT_BREATHING_TUBE))
			internal = null
		else
			. = internal.remove_air_volume(volume_needed)
			if(!.)
				return FALSE //to differentiate between no internals and active, but empty internals

// Make corpses rot, emitting miasma
/mob/living/carbon/proc/rot()
	// Properly stored corpses shouldn't create miasma
	if(istype(loc, /obj/structure/closet/crate/coffin)|| istype(loc, /obj/structure/closet/body_bag) || istype(loc, /obj/structure/bodycontainer))
		return

	// No decay if formaldehyde/preservahyde in corpse or when the corpse is charred
	if(reagents?.has_reagent(/datum/reagent/toxin/formaldehyde, 1) || HAS_TRAIT(src, TRAIT_HUSK) || reagents?.has_reagent(/datum/reagent/preservahyde, 1))
		return

	// Also no decay if corpse chilled or not organic/undead
	if((bodytemperature <= T0C-10) || !(mob_biotypes & (MOB_ORGANIC|MOB_UNDEAD)))
		return

	// Wait a bit before decaying
	if(world.time - timeofdeath < 600)
		return

	var/deceasedturf = get_turf(src)

	// Closed turfs don't have any air in them, so no gas building up
	if(!istype(deceasedturf,/turf/open))
		return

	var/turf/open/miasma_turf = deceasedturf

	var/datum/gas_mixture/stank = new

	stank.set_moles(GAS_MIASMA,0.25)

	stank.set_temperature(BODYTEMP_NORMAL)

	miasma_turf.assume_air(stank)
	qdel(stank)

	miasma_turf.air_update_turf()

/mob/living/carbon/proc/handle_blood(delta_time, times_fired)
	return

/mob/living/carbon/proc/handle_bodyparts(seconds, times_fired)
	for(var/I in bodyparts)
		var/obj/item/bodypart/BP = I
		if(BP.needs_processing)
			. |= BP.on_life(seconds, times_fired)

/mob/living/carbon/proc/handle_organs(seconds, times_fired)
	if(stat != DEAD)
		for(var/V in internal_organs)
			var/obj/item/organ/O = V
			if(O)
				O.on_life(seconds, times_fired)
	else if(!QDELETED(src))
		if(reagents?.has_reagent(/datum/reagent/toxin/formaldehyde, 1) || reagents?.has_reagent(/datum/reagent/preservahyde, 1)) // No organ decay if the body contains formaldehyde. Or preservahyde.
			return
		for(var/V in internal_organs)
			var/obj/item/organ/O = V
			if(O)
				O.on_death(seconds, times_fired) //Needed so organs decay while inside the body.

/mob/living/carbon/handle_diseases()
	for(var/thing in diseases)
		var/datum/disease/D = thing
		if(prob(D.infectivity))
			D.spread()

		if(stat != DEAD || D.process_dead)
			D.stage_act()

/mob/living/carbon/handle_wounds()
	for(var/thing in all_wounds)
		var/datum/wound/W = thing
		if(W.processes) // meh
			W.handle_process()

/mob/living/carbon/handle_mutations_and_radiation()
	if(dna && dna.temporary_mutations.len)
		for(var/mut in dna.temporary_mutations)
			if(dna.temporary_mutations[mut] < world.time)
				if(mut == UI_CHANGED)
					if(dna.previous["UI"])
						dna.uni_identity = merge_text(dna.uni_identity,dna.previous["UI"])
						updateappearance(mutations_overlay_update=1)
						dna.previous.Remove("UI")
					dna.temporary_mutations.Remove(mut)
					continue
				if(mut == UE_CHANGED)
					if(dna.previous["name"])
						real_name = dna.previous["name"]
						name = real_name
						dna.previous.Remove("name")
					if(dna.previous["UE"])
						dna.unique_enzymes = dna.previous["UE"]
						dna.previous.Remove("UE")
					if(dna.previous["blood_type"])
						dna.blood_type = dna.previous["blood_type"]
						dna.previous.Remove("blood_type")
					dna.temporary_mutations.Remove(mut)
					continue
		for(var/datum/mutation/human/HM in dna.mutations)
			if(HM && HM.timed)
				dna.remove_mutation(HM.type)

	radiation -= min(radiation, RAD_LOSS_PER_TICK)
	if(radiation > RAD_MOB_SAFE)
		if(!HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
			adjustToxLoss(log(radiation-RAD_MOB_SAFE)*RAD_TOX_COEFFICIENT)
		else
			var/rad_threshold = HAS_TRAIT(src, TRAIT_ROBOT_RADSHIELDING) ? RAD_UPGRADED_ROBOT_SAFE : RAD_DEFAULT_ROBOT_SAFE
			if(radiation > rad_threshold)
				adjustToxLoss(log(radiation-rad_threshold)*RAD_TOX_COEFFICIENT, toxins_type = TOX_SYSCORRUPT) //Robots are less resistant to rads, unless upgraded in which case they are fine at higher levels than organics.

/mob/living/carbon/handle_stomach()
	set waitfor = 0
	for(var/mob/living/M in stomach_contents)
		if(M.loc != src)
			stomach_contents.Remove(M)
			continue
		if(iscarbon(M) && stat != DEAD)
			if(M.stat == DEAD)
				M.death(1)
				stomach_contents.Remove(M)
				qdel(M)
				continue
			if(SSmobs.times_fired%3==1)
				if(!(M.status_flags & GODMODE))
					M.adjustBruteLoss(5)
				adjust_nutrition(10)


/*
Alcohol Poisoning Chart
Note that all higher effects of alcohol poisoning will inherit effects for smaller amounts (i.e. light poisoning inherts from slight poisoning)
In addition, severe effects won't always trigger unless the drink is poisonously strong
All effects don't start immediately, but rather get worse over time; the rate is affected by the imbiber's alcohol tolerance

0: Non-alcoholic
1-10: Barely classifiable as alcohol - occassional slurring
11-20: Slight alcohol content - slurring
21-30: Below average - imbiber begins to look slightly drunk
31-40: Just below average - no unique effects
41-50: Average - mild disorientation, imbiber begins to look drunk
51-60: Just above average - disorientation, vomiting, imbiber begins to look heavily drunk
61-70: Above average - small chance of blurry vision, imbiber begins to look smashed
71-80: High alcohol content - blurry vision, imbiber completely shitfaced
81-90: Extremely high alcohol content - light brain damage, passing out
91-100: Dangerously toxic - swift death
*/
#define BALLMER_POINTS 5
GLOBAL_LIST_INIT(ballmer_good_msg, list("Эй, народ, а что, если мы заменим обычную проводку на блюспейсовую и тогда мыши не смогут перегрызть электросети?",
										"Послушайте. А что если, в теории, мы бы смогли управлять порядком исследований с наших КПК?",
										"Не знаю, как насчёт вас, но ID и КПК по отдельности - это чертовски неудобно. Может нам, стоит объеденить их в чип и вживить его в руку? Тогда, их перестанут так легко красть...",
										"Почему мы просто не превратим каждую пару обуви в галоши? У нас же есть технологии!",
										"Мы можем связать СИЛО с нашими протолатами, так почему бы нам не связать его и с автолатами?",
										"Если мы можем делать лучшие бомбы с помощью нагретой плазмы, кислорода и трития, то почему в станционных ядерных бомбах до сих пор используется плутоний?",
										"Мы должны перенести весь наш NT-софт на модульные консоли и выкинуть компьютеры. Они гораздо лучше настраиваются, поддерживают кросс-платформенное использование и позволяют использовать безумное количество многозадачности.",
										"Подождите, если мы используем больше манипуляторов в чем-то, то это печатается дешевле, верно? А если мы просто сделаем новый тип принтера с 12 манипуляторами внутри, чтобы печатать вещи очень дешево?"
										))
GLOBAL_LIST_INIT(ballmer_windows_me_msg, list("Йоу, а что, если мы поставим в каждый КПК автоматически включаемый веб-сервер с паролями администраторов по умолчанию?",
											"Итак, вы знаете, как мы отделяем нашу кодовую базу от мастер-ветки, которая запускается на наших потребительских устройствах? Что, если мы объединим их и отменим разделение между кодовой базой и сервером?",
											"Чувак, радикальная идея: мехи H.O.N.K, но без бананиума...",
											"Просто идеальная идея. Установить мусорные трубы по всей станции и использовать их для перемещения.",
											"Что, если мы будем использовать язык, написанный на салфетке и созданный за одну неделю, для всех наших серверов?",
											"Что, если мы возьмем шкафчик, случайный мусор и сделаем из него экзокостюм? Разве это не было бы супер круто и все такое?",
											"Окей, послушай меня, что если мы начнём делать незаконные вещи законными, чтобы охрана перестала нас донимать за их наличие?",
											"У меня есть безумная идея, ребята. Что если вместо обезьян для испытаний, мы будем использовать только горилл?",
											"Воу, ладно, а что если мы возьмём чуток ядер слаймов и смешаем их в другого слайма? Было бы круто посмотреть, что получится.",
											"Мы НАНОтрейзен, и нам нужно разблокировать НАНОчасти. Что в этом предложении не так?"
											))

//this updates all special effects: stun, sleeping, knockdown, druggy, stuttering, etc..
/mob/living/carbon/handle_status_effects()
	..()
	if(staminaloss > 0 && !HAS_TRAIT(src, TRAIT_NO_STAMINA_REGENERATION))
		adjustStaminaLoss((!CHECK_MOBILITY(src, MOBILITY_STAND) ? ((combat_flags & COMBAT_FLAG_HARD_STAMCRIT) ? STAM_RECOVERY_STAM_CRIT : STAM_RECOVERY_RESTING) : STAM_RECOVERY_NORMAL))

	if(!(combat_flags & COMBAT_FLAG_HARD_STAMCRIT) && incomingstammult != 1)
		incomingstammult = max(0.01, incomingstammult)
		incomingstammult = min(1, incomingstammult*2)

	var/restingpwr = 1 + 4 * !CHECK_MOBILITY(src, MOBILITY_STAND)

	//Dizziness
	if(dizziness)
		var/client/C = client
		var/pixel_x_diff = 0
		var/pixel_y_diff = 0
		var/temp
		var/saved_dizz = dizziness
		if(C)
			var/oldsrc = src
			var/amplitude = dizziness*(sin(dizziness * world.time) + 1) // This shit is annoying at high strength
			src = null
			spawn(0)
				if(C)
					temp = amplitude * sin(saved_dizz * world.time)
					pixel_x_diff += temp
					C.pixel_x += temp
					temp = amplitude * cos(saved_dizz * world.time)
					pixel_y_diff += temp
					C.pixel_y += temp
					sleep(3)
					if(C)
						temp = amplitude * sin(saved_dizz * world.time)
						pixel_x_diff += temp
						C.pixel_x += temp
						temp = amplitude * cos(saved_dizz * world.time)
						pixel_y_diff += temp
						C.pixel_y += temp
					sleep(3)
					if(C)
						C.pixel_x -= pixel_x_diff
						C.pixel_y -= pixel_y_diff
			src = oldsrc
		dizziness = max(dizziness - restingpwr, 0)

	if(drowsyness)
		drowsyness = max(drowsyness - restingpwr, 0)
		blur_eyes(2)
		if(prob(5))
			AdjustSleeping(20)
			Unconscious(100)

	//Jitteriness
	if(jitteriness)
		do_jitter_animation(jitteriness)
		jitteriness = max(jitteriness - restingpwr, 0)
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "jittery", /datum/mood_event/jittery)
	else
		SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "jittery")

	if(druggy)
		adjust_drugginess(-1)

	if(silent)
		silent = max(silent-1, 0)

	if(hallucination)
		handle_hallucinations()

	if(drunkenness && !isrobotic(src))
		drunkenness *= 0.96 // Опьянение для органиков
		if(drunkenness >= 6)
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "drunk", /datum/mood_event/drunk)
			if(prob(25))
				slurring += 2
			jitteriness = max(jitteriness - 3, 0)
			// throw_alert("drunk", /atom/movable/screen/alert/drunk)
			if(HAS_TRAIT(src, TRAIT_DRUNK_HEALING))
				adjustBruteLoss(-0.12, FALSE)
				adjustFireLoss(-0.06, FALSE)
			sound_environment_override = SOUND_ENVIRONMENT_PSYCHOTIC
		else
			SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "drunk")
			clear_alert("drunk")
			sound_environment_override = SOUND_ENVIRONMENT_NONE
			drunkenness = max(drunkenness - 0.2, 0)

		if(mind && (mind.assigned_role == "Scientist" || mind.assigned_role == "Research Director"))
			if(SSresearch.science_tech)
				if(drunkenness >= 12.9 && drunkenness <= 13.8)
					drunkenness = round(drunkenness, 0.01)
					var/ballmer_percent = 0
					if(drunkenness == 13.35) // why run math if I dont have to
						ballmer_percent = 1
					else
						ballmer_percent = (-abs(drunkenness - 13.35) / 0.9) + 1
					if(prob(5))
						say(pick(GLOB.ballmer_good_msg), forced = "ballmer")
					SSresearch.science_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = BALLMER_POINTS * ballmer_percent))
				if(drunkenness > 26) // by this point you're into windows ME territory
					if(prob(5))
						SSresearch.science_tech.remove_point_list(list(TECHWEB_POINT_TYPE_GENERIC = BALLMER_POINTS))
						say(pick(GLOB.ballmer_windows_me_msg), forced = "ballmer")

		if(drunkenness >= 41)
			if(prob(25))
				confused += 2
			Dizzy(10)
			if(HAS_TRAIT(src, TRAIT_DRUNK_HEALING)) // effects stack with lower tiers
				adjustBruteLoss(-0.3, FALSE)
				adjustFireLoss(-0.15, FALSE)

		if(drunkenness >= 51)
			if(prob(5))
				confused += 10
				vomit()
			Dizzy(25)

		if(drunkenness >= 61)
			if(prob(50))
				blur_eyes(5)
			if(HAS_TRAIT(src, TRAIT_DRUNK_HEALING))
				adjustBruteLoss(-0.4, FALSE)
				adjustFireLoss(-0.2, FALSE)

		if(drunkenness >= 71)
			blur_eyes(5)

		if(drunkenness >= 81)
			adjustToxLoss(0.2)
			if(prob(5) && !stat)
				to_chat(src, "<span class='warning'>Maybe you should lie down for a bit...</span>")

		if(drunkenness >= 91)
			adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.4, 60)
			if(prob(20) && !stat)
				if(SSshuttle.emergency.mode == SHUTTLE_DOCKED && is_station_level(z)) //QoL mainly
					to_chat(src, "<span class='warning'>You're so tired... but you can't miss that shuttle...</span>")
				else
					to_chat(src, "<span class='warning'>Just a quick nap...</span>")
					Sleeping(900)

		if(drunkenness >= 101)
			adjustToxLoss(4) //Let's be honest you shouldn't be alive by now
		else
			SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "drunk")

	// BLUEMOON ADD START - опьянение для синтетиков
	else if (drunkenness)
		drunkenness *= 0.96
		if(drunkenness >= 6)
			SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "drunk", /datum/mood_event/drunk_synth)
			if(prob(25))
				slurring += 2
			jitteriness = max(jitteriness - 3, 0)
			if(HAS_TRAIT(src, TRAIT_DRUNK_HEALING))
				if(prob(2.5))
					to_chat(src, "<span class='synth'>Вы фиксируете лёгкое уменьшение повреждений вашего корпуса под действием употреблённой жидкости...</span>")
				adjustBruteLoss(-0.12, FALSE)
				adjustFireLoss(-0.06, FALSE)
			sound_environment_override = SOUND_ENVIRONMENT_PSYCHOTIC
		else
			SEND_SIGNAL(src, COMSIG_CLEAR_MOOD_EVENT, "drunk")
			clear_alert("drunk")
			sound_environment_override = SOUND_ENVIRONMENT_NONE
			drunkenness = max(drunkenness - 0.2, 0)

		if(mind?.assigned_role == "Scientist" || mind?.assigned_role == "Research Director")
			if (prob(3))
				to_chat(src, "<span class='synth'>Вы ощущаете разгон своих аналитических процессоров...</span>")
			if(SSresearch.science_tech)
				if(drunkenness >= 12.9 && drunkenness <= 13.8)
					drunkenness = round(drunkenness, 0.01)
					var/ballmer_percent = 0
					if(drunkenness == 13.35)
						ballmer_percent = 1
					else
						ballmer_percent = (-abs(drunkenness - 13.35) / 0.9) + 1
					if(prob(5))
						say(pick(GLOB.ballmer_good_msg), forced = "ballmer")
					SSresearch.science_tech.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = BALLMER_POINTS * ballmer_percent))
				if(drunkenness > 26)
					if(prob(5))
						SSresearch.science_tech.remove_point_list(list(TECHWEB_POINT_TYPE_GENERIC = BALLMER_POINTS))
						say(pick(GLOB.ballmer_windows_me_msg), forced = "ballmer")

		if(mind?.assigned_role == "Roboticist" && prob(3))
			to_chat(src, "<span class='synth'>Ваши манипуляторы подрагивают, а в вашем позитронном мозге роятся невероятные идеи о превосходстве синтетической расы... Нужно построить больше роботов!</span>")

		if(drunkenness >= 41)
			Dizzy(5)
			if(prob(5))
				emote(
					pick("ping", "beep", "buzz", "buzz2")
				)
			if(prob(10))
				do_fake_sparks(2, TRUE, src)
			if(prob(15))
				jitteriness += 3
			if(HAS_TRAIT(src, TRAIT_DRUNK_HEALING))
				if(prob(5))
					to_chat(src, "<span class='synth'>Перегрузка системы, вызванная выпитой жидкостью, ещё сильнее ускоряет процессы саморемонта...</span>")
				adjustBruteLoss(-0.3, FALSE)
				adjustFireLoss(-0.15, FALSE)

		if(drunkenness >= 51)
			if(prob(5))
				to_chat(src, "<span class='warning'>Зафиксирована перегрузка сенсоров!</span>")
				blur_eyes(10)
			if(HAS_TRAIT(src, TRAIT_DRUNK_HEALING))
				adjustBruteLoss(-0.4, FALSE)
				adjustFireLoss(-0.2, FALSE)
			if (prob(25))
				slurring += 5
			if(prob(5))
				to_chat(src, "<span class='warning'>Вы испускаете сноп искр, теряя заряд!</span>")
				do_sparks(4, TRUE, src)
				adjust_nutrition(-40)

		if(drunkenness >= 81)
			if (prob(5))
				to_chat(src, "<span class='warning'>Употреблённая жидкость вызывает критические ошибки в вашей системе...</span>")
			adjustToxLoss(1, TRUE, FALSE, TOX_SYSCORRUPT)
			if(prob(5) && !stat)
				to_chat(src, "<span class='userdanger'>ОШИБ%!№...</span>")
				emote("malf")
				drowsyness += 2
				Dizzy(10)
				AdjustUnconscious(60)

		if(drunkenness >= 91)
			if (prob(5))
				to_chat(src, "<span class='warning'>Вы фиксируете каскадные повреждения своего позитронного мозга!</span>")
			adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.8, 60)
			adjustToxLoss(1.2, TRUE, FALSE, TOX_SYSCORRUPT)
			if(prob(20) && !stat)
				if(SSshuttle.emergency.mode == SHUTTLE_DOCKED && is_station_level(z))
					if(prob(10))
						to_chat(src, "<span class='warning'>Ваша система фиксирует прибытие шаттла и переходит в режим овердрайва, чтобы не отключиться от перегрузки синтанолом...</span>")
				else
					playsound(src, 'modular_splurt/sound/misc/connection_terminated.ogg', 40, FALSE)
					emote("me", EMOTE_VISIBLE, "с громким щелчком выключается, падая на пол!")
					to_chat(src, "<span class='userdanger'>Обновление операционной системы, пожалуйста, ожи%@#$$!</span>")
					AdjustUnconscious(900)
					if(isipcperson(src))
						dna.features["ipc_screen"] = "BSOD"
						update_body()
	// BLUEMOON ADD END

//used in human and monkey handle_environment()
/mob/living/carbon/proc/natural_bodytemperature_stabilization()
	if(HAS_TRAIT(src, TRAIT_COLDBLOODED) || HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
		return FALSE //return FALSE as your natural temperature. Species proc handle_environment() will adjust your temperature based on this.

	var/body_temperature_difference = BODYTEMP_NORMAL - bodytemperature
	switch(bodytemperature)
		if(-INFINITY to BODYTEMP_COLD_DAMAGE_LIMIT) //Cold damage limit is 50 below the default, the temperature where you start to feel effects.
			return max((body_temperature_difference * metabolism_efficiency / BODYTEMP_AUTORECOVERY_DIVISOR), BODYTEMP_AUTORECOVERY_MINIMUM)
		if(BODYTEMP_COLD_DAMAGE_LIMIT to BODYTEMP_NORMAL)
			return max(body_temperature_difference * metabolism_efficiency / BODYTEMP_AUTORECOVERY_DIVISOR, min(body_temperature_difference, BODYTEMP_AUTORECOVERY_MINIMUM/4))
		if(BODYTEMP_NORMAL to BODYTEMP_HEAT_DAMAGE_LIMIT) // Heat damage limit is 50 above the default, the temperature where you start to feel effects.
			return min(body_temperature_difference * metabolism_efficiency / BODYTEMP_AUTORECOVERY_DIVISOR, max(body_temperature_difference, -BODYTEMP_AUTORECOVERY_MINIMUM/4))
		if(BODYTEMP_HEAT_DAMAGE_LIMIT to INFINITY)
			return min((body_temperature_difference / BODYTEMP_AUTORECOVERY_DIVISOR), -BODYTEMP_AUTORECOVERY_MINIMUM)	//We're dealing with negative numbers

/mob/living/carbon/proc/get_cooling_efficiency()
	if(!HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
		return TRUE

	var/integration_bonus = min(blood_volume * SYNTH_INTEGRATION_COOLANT_CAP, integrating_blood * SYNTH_INTEGRATION_COOLANT_PENALTY)	//Integration blood somewhat helps, though only at 40% impact and to a cap of 25% of current blood level.
	var/blood_effective_volume = blood_volume + integration_bonus
	var/coolant_efficiency = min(blood_effective_volume / BLOOD_VOLUME_SAFE, 1)	//Low coolant is only a negative, adding more than needed will not help you.
	var/environment_efficiency = get_environment_cooling_efficiency()

	return min(coolant_efficiency * environment_efficiency, SYNTH_MAX_COOLING_EFFICIENCY)


/mob/living/carbon/proc/get_environment_cooling_efficiency()
/* BLUEMOON REMOVAL START - для защиты от космоса, у синтетиков теперь есть portable cooling unit. Скафандры не должны работать
	var/suitlink = check_suitlinking()
	if(suitlink)
		return suitlink //If you are wearing full EVA or lavaland hazard gear (on lavaland), assume it has been made to accomodate your cooling needs.
BLUEMOON REMOVAL END */
	var/datum/gas_mixture/environment = loc.return_air()
	if(!environment)
		return FALSE

	var/pressure = environment.return_pressure()
	var/heat = environment.return_temperature()

	var/heat_efficiency = clamp(1 + ((bodytemperature - heat) * SYNTH_HEAT_EFFICIENCY_COEFF), 0, SYNTH_SINGLE_INFLUENCE_COOLING_EFFECT_CAP)
	var/pressure_efficiency = clamp(pressure / ONE_ATMOSPHERE, 0, SYNTH_SINGLE_INFLUENCE_COOLING_EFFECT_CAP)

	if(HAS_TRAIT(src, TRAIT_LOWPRESSURECOOLING))
		pressure_efficiency = max(pressure_efficiency, 1)	//Space adaptation nulls drawbacks of low-pressure cooling.

	var/total_environment_efficiency = min(heat_efficiency * pressure_efficiency, SYNTH_TOTAL_ENVIRONMENT_EFFECT_CAP)	//At best, you can get 200% total
	return total_environment_efficiency

/mob/living/carbon/proc/check_suitlinking()
	var/suit_item = get_item_by_slot(ITEM_SLOT_OCLOTHING)
	var/head_item = get_item_by_slot(ITEM_SLOT_HEAD)
	var/turf/T = get_turf(src)

	if(istype(head_item, /obj/item/clothing/head/helmet/space) && istype(suit_item, /obj/item/clothing/suit/space))
		return TRUE

	if(istype(head_item, /obj/item/clothing/head/mod) && istype(suit_item, /obj/item/clothing/suit/mod))
		var/obj/item/clothing/suit/mod/modsuit = suit_item
		var/obj/item/mod/control/mod_control = modsuit.mod
		if(mod_control && mod_control.active)
			return TRUE

	if(T && is_mining_level(T.z) && istype(head_item, /obj/item/clothing/head/hooded/explorer) && istype(suit_item, /obj/item/clothing/suit/hooded/explorer))
		return TRUE

	return FALSE

/////////
//LIVER//
/////////

/mob/living/carbon/proc/handle_liver(seconds, times_fired)
	var/obj/item/organ/liver/liver = getorganslot(ORGAN_SLOT_LIVER)
	if((!dna && !liver) || (NOLIVER in dna?.species.species_traits))
		return
	if(!liver || liver.organ_flags & ORGAN_FAILING)
		liver_failure(seconds, times_fired)

/mob/living/carbon/proc/liver_failure(seconds, times_fired)
	if(reagents)
		reagents.end_metabolization(src, keep_liverless = TRUE) //Stops trait-based effects on reagents, to prevent permanent buffs
		reagents.metabolize(src, seconds, times_fired, can_overdose=FALSE, liverless = TRUE)
	if(HAS_TRAIT(src, TRAIT_STABLELIVER))
		return
	adjustToxLoss(4, TRUE,  TRUE)
	if(prob(15))
		to_chat(src, "<span class='danger'>You feel a stabbing pain in your abdomen!</span>")


////////////////
//BRAIN DAMAGE//
////////////////

/mob/living/carbon/proc/handle_brain_damage()
	for(var/T in get_traumas())
		var/datum/brain_trauma/BT = T
		BT.on_life()

/////////////////////////////////////
//MONKEYS WITH TOO MUCH CHOLOESTROL//
/////////////////////////////////////

/mob/living/carbon/proc/can_heartattack()
	if(!needs_heart())
		return FALSE
	var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
	if(!heart || (heart.organ_flags & ORGAN_SYNTHETIC))
		return FALSE
	return TRUE

/mob/living/carbon/proc/needs_heart()
	if(HAS_TRAIT(src, TRAIT_STABLEHEART))
		return FALSE
	if(dna && dna.species && (NOBLOOD in dna.species.species_traits)) //not all carbons have species!
		return FALSE
	return TRUE

/mob/living/carbon/proc/undergoing_cardiac_arrest()
	var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
	if(istype(heart) && heart.beating)
		return FALSE
	else if(!needs_heart())
		return FALSE
	return TRUE

/mob/living/carbon/proc/set_heartattack(status)
	if(!can_heartattack())
		return FALSE

	var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
	if(!istype(heart))
		return

	if(status)
		heart.Stop()
	else
		heart.Restart()
