//predominantly negative traits

/datum/quirk/blooddeficiency
	name = "Острое Малокровие"
	desc = "Ваше тело не производит достаточно крови для поддержания себя."
	value = -2
	gain_text = "<span class='danger'>Вы чувствуете, как ваши силы угасают.</span>"
	lose_text = "<span class='notice'>Былые силы возвращаются.</span>"
	antag_removal_text = "Ваша антагонистическая натура избавила вас от малокровия."
	medical_record_text = "Пациент нуждается в регулярном восстановлении крови по причине малокровия."

/datum/quirk/blooddeficiency/add()
	RegisterSignal(quirk_holder, COMSIG_SPECIES_GAIN, PROC_REF(update_mail))

	var/mob/living/carbon/human/human_holder = quirk_holder
	update_mail(new_species = human_holder.dna.species)

/datum/quirk/blooddeficiency/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	if(NOBLOOD in H.dna.species.species_traits) //can't lose blood if your species doesn't have any
		return
	else
		quirk_holder.blood_volume -= 0.2

/datum/quirk/blooddeficiency/proc/update_mail(datum/source, datum/species/new_species, datum/species/old_species)
	SIGNAL_HANDLER

	mail_goodies.Cut()

	if(isnull(new_species.exotic_blood)) // && isnull(new_species.exotic_bloodtype)) // We don't really support your blood yet :(
		if(NOBLOOD in new_species.inherent_traits)
			return

		mail_goodies += /obj/item/reagent_containers/blood/OMinus
		return

	for(var/obj/item/reagent_containers/blood/blood_bag as anything in typesof(/obj/item/reagent_containers/blood))
		var/right_blood_type = !isnull(new_species.exotic_bloodtype) && initial(blood_bag.blood_type) == new_species.exotic_bloodtype
//		var/right_blood_reagent = !isnull(new_species.exotic_blood) && initial(blood_bag.unique_blood) == new_species.exotic_blood
		if(right_blood_type) // || right_blood_reagent)
			mail_goodies += blood_bag

/datum/quirk/depression
	name = "Депрессия"
	desc = "Иногда вы просто ненавидите жизнь."
	mob_trait = TRAIT_DEPRESSION
	value = -1
	gain_text = "<span class='danger'>У вас начинается депрессия.</span>"
	medical_record_text = "У пациента наблюдаются серьёзные перепады настроения, вызывающие острые периоды депрессии."
	lose_text = "<span class='notice'>У вас больше нет депрессии.</span>" //if only it were that easy!
	mood_quirk = TRUE
	processing_quirk = TRUE

/datum/quirk/depression/on_process()
	if(prob(0.05))
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "depression", /datum/mood_event/depression)

/datum/quirk/family_heirloom
	name = "Семейная реликвия"
	desc = "Вы владелец реликвии, передающейся из поколения в поколение. Её нужно беречь!"
	value = -1
	mood_quirk = TRUE
	flavor_quirk = TRUE
	medical_record_text = "Пациент демонстрирует неестественную привязанность к семейной реликвии."
	var/obj/item/heirloom
	var/where
	var/loadout_heirloom = FALSE // BLUEMOON EDIT - выбор вещей из лодаута как family heirloom
	processing_quirk = TRUE

GLOBAL_LIST_EMPTY(family_heirlooms)

/datum/quirk/family_heirloom/on_spawn()
	// Define holder and type
	var/mob/living/carbon/human/human_holder = quirk_holder
	var/obj/item/heirloom_type
	// BLUEMOON EDIT START - выбор вещей из лодаута как family heirloom
	if(human_holder && istype(human_holder) && human_holder.mind && !isnull(human_holder.mind.assigned_heirloom))
		heirloom = human_holder.mind.assigned_heirloom
		if(heirloom && istype(heirloom))
			loadout_heirloom = TRUE
	if(!loadout_heirloom)
		// The quirk holder's species - we have a 50% chance, if we have a species with a set heirloom, to choose a species heirloom.
		var/datum/species/holder_species = human_holder.dna?.species
		if(holder_species && LAZYLEN(holder_species.family_heirlooms) && prob(50))
			heirloom_type = pick(holder_species.family_heirlooms)
		else
			// Our quirk holder's job
			var/datum/job/holder_job = SSjob.GetJob(human_holder.last_mind?.assigned_role)
			if(holder_job && LAZYLEN(holder_job.family_heirlooms))
				heirloom_type = pick(holder_job.family_heirlooms)

		// If we didn't find an heirloom somehow, throw them a generic one
		if(!heirloom_type)
			heirloom_type = pick(/obj/item/toy/cards/deck, /obj/item/lighter, /obj/item/dice/d20)
		// Create the heirloom item
		heirloom = new heirloom_type(get_turf(quirk_holder))
		heirloom.item_flags |= FAMILY_HEIRLOOM
		// Determine and assign item location
		var/list/slots = list(
			"В левом кармане" = ITEM_SLOT_LPOCKET,
			"В правом кармане" = ITEM_SLOT_RPOCKET,
			"В рюкзаке" = ITEM_SLOT_BACKPACK
		)
		where = human_holder.equip_in_one_of_slots(heirloom, slots, FALSE) || "под ногами"
	// BLUEMOON EDIT END
	// Add to global list
	GLOB.family_heirlooms += heirloom

/datum/quirk/family_heirloom/post_add()
	// BLUEMOON EDIT START - выбор вещей из лодаута как family heirloom
	if(!loadout_heirloom)
		if(where == "В рюкзаке")
			var/mob/living/carbon/human/H = quirk_holder
			SEND_SIGNAL(H.back, COMSIG_TRY_STORAGE_SHOW, H)

		to_chat(quirk_holder, "<span class='boldnotice'>[where] находится [heirloom.name], передающаяся из поколения в поколение. Береги её!</span>")
		var/list/family_name = splittext(quirk_holder.real_name, " ")
		heirloom.name = "\improper [family_name[family_name.len]] family [heirloom.name]"
	else
		to_chat(quirk_holder, "<span class='boldnotice'>Ты прихватил с собой свою любимую вещь, [heirloom.name]. Береги её!</span>")
	// BLUEMOON EDIT END

/datum/quirk/family_heirloom/on_process()
	// Ignore for dead holder
	if(quirk_holder.stat == DEAD)
		return

	// When held: Positive mood
	if(heirloom && (heirloom in quirk_holder.GetAllContents()))
		SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "family_heirloom_missing")
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "family_heirloom", /datum/mood_event/family_heirloom)

	// When not held: Negative mood
	else
		SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "family_heirloom")
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "family_heirloom_missing", /datum/mood_event/family_heirloom_missing)

/datum/quirk/item_quirk/family_heirloom/remove()
	// Clear mood events when removing this quirk
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "family_heirloom")
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "family_heirloom_missing")

/datum/quirk/family_heirloom/clone_data()
	return heirloom

/datum/quirk/family_heirloom/on_clone(data)
	heirloom = data

/datum/quirk/heavy_sleeper
	name = "Крепко спящий"
	desc = "Вы спите как убитый! Ваш сон длится чуть дольше."
	value = -1
	mob_trait = TRAIT_HEAVY_SLEEPER
	flavor_quirk = TRUE
	gain_text = "<span class='danger'>Вы чувствуете сонливость.</span>"
	lose_text = "<span class='notice'>Вы снова чувствуете себя бодрым!.</span>"
	medical_record_text = "Пациент показал аномальные результаты во время исследования сна - его гораздо сложнее разбудить."

/datum/quirk/brainproblems
	name = "Опухоль головного мозга"
	desc = "В вашей голове есть маленький друг, который медленно разрушает мозг. Следует прихватить с собой маннитол!"
	value = -3
	gain_text = "<span class='danger'>Вы чувствуете, как ваши извилины разглаживаются.</span>"
	lose_text = "<span class='notice'>Извилины снова появляются на вашем мозгу.</span>"
	medical_record_text = "У пациента опухоль, которая постепенно разрушает его мозг."
	processing_quirk = TRUE

/datum/quirk/brainproblems/on_process()
	quirk_holder.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.2)

/datum/quirk/nearsighted //t. errorage
	name = "Близорукость"
	desc = "У вас близорукость; вы прибываете на станцию с очками."
	name = "Близорукость"
	desc = "У вас близорукость; вы прибываете на станцию с очками."
	value = -1
	gain_text = "<span class='danger'>Объекты вдали вас расплываются.</span>"
	lose_text = "<span class='notice'>Ваше зрение приходит в норму.</span>"
	medical_record_text = "Для того, чтобы нивелировать эффект близорукости, пациенту требуются очки."

/datum/quirk/nearsighted/add()
	quirk_holder.become_nearsighted(ROUNDSTART_TRAIT)

/datum/quirk/nearsighted/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/glasses/regular/glasses = new(get_turf(H))
	if(!H.equip_to_slot_if_possible(glasses, ITEM_SLOT_EYES))
		H.put_in_hands(glasses)

/datum/quirk/nyctophobia
	name = "Никтофобия"
	desc = "Вы боитесь тьмы и осторожничаете, пребывая в ней."
	value = -1
	flavor_quirk = TRUE
	medical_record_text = "Пациент боится темноты."

/datum/quirk/nyctophobia/add()
	RegisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED, PROC_REF(on_holder_moved))

/datum/quirk/nyctophobia/remove()
	UnregisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED)
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "nyctophobia")

/// Called when the quirk holder moves. Updates the quirk holder's mood.
/datum/quirk/nyctophobia/proc/on_holder_moved(mob/living/source, atom/old_loc, dir, forced)
	if(quirk_holder.stat != CONSCIOUS || quirk_holder.IsSleeping() || quirk_holder.IsUnconscious())
		return

	var/mob/living/carbon/human/human_holder = quirk_holder

	if(human_holder.dna?.species.id in list(SPECIES_SHADOW, SPECIES_NIGHTMARE))
		return

	if((human_holder.sight & SEE_TURFS) == SEE_TURFS)
		return

	var/turf/holder_turf = get_turf(quirk_holder)

	var/lums = holder_turf.get_lumcount()

	if(lums > 0.2)
		SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "nyctophobia")
		return

	if(quirk_holder.m_intent == MOVE_INTENT_RUN)
		to_chat(quirk_holder, span_warning("Не торопись... ты в кромешной тьме..."))
		quirk_holder.toggle_move_intent()
	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "nyctophobia", /datum/mood_event/nyctophobia)

/datum/quirk/lightless
	name = "Светочувствительность"
	desc = "Яркий свет вызывает у вас раздражение. Глаза начинают слезиться, кожа чешется под действием ионизирующего излучения, а волосы становятся сухими и непослушными. Возможно, это болезнь. Если бы только Nanotrasen учитывали ваши потребности..."
	value = -1
	gain_text = "<span class='danger'>Яркий свет раздражает вас.</span>"
	lose_text = "<span class='notice'>Вы не боитесь не бояться света.</span>"
	medical_record_text = "Несмотря на предупреждения, пациент отказывается включать свет, что приводит к падению с лестницы прямо в подвал."

/datum/quirk/lightless/add()
	RegisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED, PROC_REF(on_holder_moved))

/datum/quirk/lightless/remove()
	UnregisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED)
	SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "brightlight")

/datum/quirk/lightless/proc/on_holder_moved(mob/living/source, atom/old_loc, dir, forced)
	if(quirk_holder.stat != CONSCIOUS || quirk_holder.IsSleeping() || quirk_holder.IsUnconscious())
		return

	var/mob/living/carbon/human/human_holder = quirk_holder

	if(human_holder.dna?.species.id in list(SPECIES_SHADOW, SPECIES_NIGHTMARE))
		return

	if((human_holder.sight & SEE_TURFS) == SEE_TURFS)
		return

	var/turf/holder_turf = get_turf(quirk_holder)

	var/lums = holder_turf.get_lumcount()

	if(lums < 0.8)
		SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "brightlight")
		return

	SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "brightlight", /datum/mood_event/brightlight)


/datum/quirk/lightless/on_process()
	var/turf/T = get_turf(quirk_holder)
	var/lums = T.get_lumcount()
	if(lums >= 0.8)
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "brightlight", /datum/mood_event/brightlight)
	else
		SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "brightlight")

/datum/quirk/nonviolent
	name = "Пацифист"
	desc = "Насилие противно вам настолько, что вы не можете никому навредить."
	value = -2
	mob_trait = TRAIT_PACIFISM
	gain_text = "<span class='danger'>Вы отвергаете саму мысль о возможном насилии!</span>"
	lose_text = "<span class='notice'>Вам кажется, что вы снова можете постоять за себя.</span>"
	medical_record_text = "Пациент крайне миролюбивый и не может заставить себя сделать кому-то больно."
	antag_removal_text = "Ваша антагонистическая натура привела к отказу от пацифизма."

/datum/quirk/paraplegic
	name = "Парализованный"
	desc = "Ваши ноги не работают. Ничто и никогда не исправит это. Подумайте о хорошем — о бесплатной инвалидной коляске!"
	value = -4
	mob_trait = TRAIT_PARA
	human_only = TRUE
	gain_text = null // Handled by trauma.
	lose_text = null
	medical_record_text = "У пациента неизлечимое нарушение опорно-двигательных функций нижних конечностей."
	on_spawn_immediate = FALSE

/datum/quirk/paraplegic/add()
	var/datum/brain_trauma/severe/paralysis/paraplegic/T = new()
	var/mob/living/carbon/human/H = quirk_holder
	H.gain_trauma(T, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/paraplegic/on_spawn()
	if(quirk_holder.client)
		var/modified_limbs = quirk_holder.client.prefs.modified_limbs
		if(!(modified_limbs[BODY_ZONE_L_LEG] == LOADOUT_LIMB_AMPUTATED && modified_limbs[BODY_ZONE_R_LEG] == LOADOUT_LIMB_AMPUTATED && !isjellyperson(quirk_holder)))
			if(quirk_holder.buckled) // Handle late joins being buckled to arrival shuttle chairs.
				quirk_holder.buckled.unbuckle_mob(quirk_holder)

			var/turf/T = get_turf(quirk_holder)
			var/obj/structure/chair/spawn_chair = locate() in T

			var/obj/vehicle/ridden/wheelchair/wheels = new(T)
			if(spawn_chair) // Makes spawning on the arrivals shuttle more consistent looking
				wheels.setDir(spawn_chair.dir)

			wheels.buckle_mob(quirk_holder)

			// During the spawning process, they may have dropped what they were holding, due to the paralysis
			// So put the things back in their hands.

			for(var/obj/item/I in T)
				if(I.fingerprintslast == quirk_holder.ckey)
					quirk_holder.put_in_hands(I)

/* Квирк нефунцкиональный и не задействован в механе
/datum/quirk/poor_aim
	name = "Ужасный стрелок"
	desc = "Ваши навыки обращения с оружием не позволяют точно прицелиться даже для того, чтобы спасти свою жизнь. Стрельба с двух рук даже не обсуждается."
	value = -1
	mob_trait = TRAIT_POOR_AIM
	flavor_quirk = TRUE
	medical_record_text = "Обе руки пациента подвержены тремору."
*/

/datum/quirk/prosopagnosia
	name = "Прозопагнозия"
	desc = "Расстройство не позволяет вам различать лица, совсем."
	value = -1
	mob_trait = TRAIT_PROSOPAGNOSIA
	medical_record_text = "Пациент страдает от прозопагнозии и не способен различать лица."

/datum/quirk/insanity
	name = "Диссоциативное расстройство"
	desc = "Вы страдаете от тяжелого расстройства и видите яркие галлюцинации. ЛСД подавляет болезнь, к побочному эффекту этого вещества у вас невосприимчивость. <b>Это не даёт разрешение на гриферство.</b>"
	value = -2
	//no mob trait because it's handled uniquely
	gain_text = "<span class='userdanger'>...</span>"
	lose_text = "<span class='notice'>Вы чувствуете себя в гармонии с миром.</span>"
	medical_record_text = "Пациент страдает от острого диссоциативного расстройства и испытывает яркие галлюцинации."
	processing_quirk = TRUE

/datum/quirk/insanity/on_process()
	if(quirk_holder.reagents.has_reagent(/datum/reagent/toxin/mindbreaker))
		quirk_holder.hallucination = 0
		return
	if(prob(2)) //we'll all be mad soon enough
		madness()

/datum/quirk/insanity/proc/madness()
	quirk_holder.hallucination += rand(10, 25)

/datum/quirk/insanity/post_add() //I don't /think/ we'll need this but for newbies who think "roleplay as insane" = "license to kill" it's probably a good thing to have
	if(!quirk_holder.mind || quirk_holder.mind.special_role)
		return
	to_chat(quirk_holder, "<span class='big bold info'>Пожалуйста учтите, что диссоциативное расстройство НЕ даёт права атаковать или вмешиваться в \
	раунд. Вы не антагонист и правила будут к вам применены те же, что и к обычным членам экипажа.</span>")

/datum/mood_event/anxiety_eyecontact
	description = "<span class='warning'>Иногда из-за визуального контакта я нервничаю...</span>\n"
	mood_change = -5
	timeout = 3 MINUTES

/datum/quirk/phobia
	name = "Фобия"
	desc = "Прошлое нанесло вам травму на всю жизнь и продолжает преследовать, когда вы встречаетесь с величайшими из своих страхов."
	flavor_quirk = TRUE
	value = -2 // It can hardstun you. You can be a job that your phobia targets...
	gain_text = "<span class='danger'>Вы начинаете трястись, когда всепоглощающий страх захватывает ваш разум.</span>"
	lose_text = "<span class='notice'>Ваша уверенность сметает страх, что терзал вас долгое время.</span>"
	medical_record_text = "Пациент имеет иррациональный страх к неопределенному стимулу."
	var/datum/brain_trauma/mild/phobia/phobia

/datum/quirk/phobia/post_add()
	var/mob/living/carbon/human/H = quirk_holder
	phobia = new
	H.gain_trauma(phobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/phobia/remove()
	var/mob/living/carbon/human/H = quirk_holder
	H?.cure_trauma_type(phobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/mute
	name = "Немота"
	desc = "Из-за несчастного случая, заболевания или вовсе по собственному желанию вы не можете говорить."
	value = -2 //HALP MAINTS
	mob_trait = TRAIT_MUTE
	gain_text = "<span class='danger'>Вы не можете говорить!</span>"
	lose_text = "<span class='notice'>Вы чувствуете, как сила в голосовых связках растёт.</span>"
	medical_record_text = "Пациент страдает от немоты."
	antag_removal_text = "Ваша антагонистическая натура заставила ваш голос снова проявиться."
	var/datum/brain_trauma/severe/mute/mute

/datum/quirk/mute/add()
	var/mob/living/carbon/human/H = quirk_holder
	mute = new
	H.gain_trauma(mute, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/mute/remove()
	var/mob/living/carbon/human/H = quirk_holder
	H?.cure_trauma_type(mute, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/unstable
	name = "Нестабильный"
	desc = "Душевные раны делают восстановление рассудка после его потери невозможным. Аккуратнее с управлением настроением!"
	value = -2
	mob_trait = TRAIT_UNSTABLE
	gain_text = "<span class='danger'>Слишком многое творится в вашей голове.</span>"
	lose_text = "<span class='notice'>Ваш разум наконец-то успокоился.</span>"
	medical_record_text = "Разум пациента находится в уязвимом состоянии и не может восстановиться после полученных травм."

/datum/quirk/blindness
	name = "Слепота"
	desc = "Вы полностью слепой, ничего это не изменит."
	value = -4
	gain_text = "<span class='danger'>Вы ничего не видите.</span>"
	lose_text = "<span class='notice'>Чудесным образом, к вам возвращается зрение.</span>"
	medical_record_text = "У пациента полная слепота."

/datum/quirk/blindness/add()
	quirk_holder.become_blind(ROUNDSTART_TRAIT)
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine_holder))

/datum/quirk/blindness/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/clothing/glasses/sunglasses/blindfold/white/glasses = new(get_turf(H))
	if(!H.equip_to_slot_if_possible(glasses, ITEM_SLOT_EYES, bypass_equip_delay_self = TRUE)) //if you can't put it on the user's eyes, put it in their hands, otherwise put it on their eyes eyes
		H.put_in_hands(glasses)
	H.regenerate_icons()

/datum/quirk/blindness/remove()
	if(!quirk_holder)
		return
	quirk_holder.cure_blind(ROUNDSTART_TRAIT)
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)

/datum/quirk/blindness/proc/on_examine_holder(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list)
	examine_list += "<span class='warning'>[quirk_holder.ru_ego(TRUE)] глаза мутные и остекленелые...</span>"

/datum/quirk/coldblooded
	name = "Холоднокровие"
	desc = "Ваше тело не генерирует тепло, из-за чего требуется внешняя регуляция."
	value = -2
	medical_record_text = "Пациент эктотермичен."
	mob_trait = TRAIT_COLDBLOODED
	gain_text = "<span class='notice'>Вы чувствуете, как кровь стынет в жилах.</span>"
	lose_text = "<span class='notice'>Вы чувствуете себя теплокровнее.</span>"

/datum/quirk/monophobia
	name = "Монофобия"
	desc = "Вы испытываете стресс, когда не находитесь в компании других, вызывающий реакции от болезненного состояния до инфарктов."
	value = -3 // Might change it to 4.
	gain_text = "<span class='danger'>Вы чувствуете себя одиноко...</span>"
	lose_text = "<span class='notice'>Вы чувствуете, что одному быть не так уж и плохо.</span>"
	medical_record_text = "Пациент приобретает болезненное состояние, если не находится в компании, оно может привести к потенциально смертельным уровням стресса."

/datum/quirk/monophobia/post_add()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	H.gain_trauma(/datum/brain_trauma/severe/monophobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/monophobia/remove()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	H?.cure_trauma_type(/datum/brain_trauma/severe/monophobia, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/no_smell
	name = "Аносмия"
	desc = "Вы не ощущаете запахи! Вы не сможете обнаружать определенные бесцветные газы."
	value = -1
	mob_trait = TRAIT_ANOSMIA
	gain_text = "<span class='notice'>Вы не чувствуете запахов!</span>"
	lose_text = "<span class='notice'>Вы снова чувствуете запахи!</span>"
	medical_record_text = "Пациент страдает от аносмии и не может различать запахи газов и частиц."

/datum/quirk/paper_skin
	name = "Бумажная Кожа"
	desc = "Вы слабы плотью, порезаться становится гораздо легче."
	value = -1
	mob_trait = TRAIT_PAPER_SKIN
	gain_text = "<span class='notice'>Вы чувствуете, что ваша плоть слаба!</span>"
	lose_text = "<span class='notice'>Ваша плоть снова крепка!</span>"
	medical_record_text = "Пациент слаб плотью, по этой причине он гораздо легче приобретает резаные раны."

/datum/quirk/glass_bones
	name = "Хрустальные Кости"
	desc = "Ваши кости гораздо более хрупкие, потому уязвимы к переломам."
	value = -1
	mob_trait = TRAIT_GLASS_BONES
	gain_text = "<span class='notice'>Ваши кости ощущаются слабыми!</span>"
	lose_text = "<span class='notice'>Ваши кости ощущаются более прочными!</span>"
	medical_record_text = "Пациент страдает от хрупкости костей, из-за чего его кости легче ломаются."

/datum/quirk/cursed
	name = "Проклятый"
	desc = "Вас преследует злой рок. У вас выше шансы пострадать от несчастных случаев. Пришла беда — отворяй врата."
	value = -3
	mob_trait = TRAIT_CURSED
	gain_text = span_danger("Вы чувствуете, что сейчас будет плохой день.")
	lose_text = span_notice("Вы чувствуете, что сейчас будет хороший день.")
	medical_record_text = "Пациента преследует невезение."

/datum/quirk/cursed/add(client/client_source)
	quirk_holder.AddComponent(/datum/component/omen/quirk)

/datum/quirk/cursed/remove(client/client_source)
	qdel(quirk_holder.GetComponent(/datum/component/omen/quirk))

/datum/quirk/alcohol_intolerance
	name = "Непереносимость Алкоголя"
	desc = "Вы получаете урон токсинами вместо того, чтобы пьянеть при употреблении алкоголя."
	value = -1
	mob_trait = TRAIT_TOXIC_ALCOHOL
	medical_record_text = "Организм пациента не усваивает этиловый спирт."

/datum/quirk/alcohol_intolerance/add()
	var/mob/living/carbon/human/H = quirk_holder
	var/datum/species/species = H.dna.species
	species.disliked_food |= ALCOHOL

/datum/quirk/alcohol_intolerance/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		var/datum/species/species = H.dna.species
		species.disliked_food &= ~ALCOHOL

/datum/quirk/less_nightmare
	name = "Отпрыск Ночного Кошмара"
	desc = "Вы очень схожи с так называемыми Ночными Кошмарами. Каким бы образом это не получилось, теперь всякое свечение вам опасно."
	value = -4
	mob_trait = TRAIT_LESS_NIGHTMARE
	gain_text = span_notice("Ваше тело становится уязвимым к свету...")
	lose_text = span_notice("Ваше тело более устойчивым, чем раньше.")
	medical_record_text = "Тело пациента уязвимо к свету."

/datum/quirk/less_nightmare/add()
	var/mob/living/carbon/human/C = quirk_holder
	C.AddElement(/datum/element/photosynthesis, 1, 1, 0, 0, 0, 0, SHADOW_SPECIES_LIGHT_THRESHOLD, SHADOW_SPECIES_LIGHT_THRESHOLD)
	give_item(/obj/item/flashlight/flashdark, quirk_holder)
	give_item(/obj/item/clothing/accessory/permit/special/lessnightmareish, quirk_holder)

/datum/quirk/less_nightmare/remove()
	var/mob/living/carbon/human/C = quirk_holder
	// BLUEMOON EDIT START - sanity check
	if(!C)
		return
	// BLUEMOON EDIT END
	C.RemoveElement(/datum/element/photosynthesis, 1, 1, 0, 0, 0, 0, SHADOW_SPECIES_LIGHT_THRESHOLD, SHADOW_SPECIES_LIGHT_THRESHOLD)
