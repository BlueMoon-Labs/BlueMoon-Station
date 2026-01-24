/datum/design/board/self_actualization_device
	name = "Machine Design (Self-Actualization Device)"
	desc = "The circuit board for a Self-Actualization Device by Cinco: A Family Company."
	id = "self_actualization_device"
	build_path = /obj/item/circuitboard/machine/self_actualization_device
	category = list("Medical Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/obj/item/circuitboard/machine/self_actualization_device
	name = "Self-Actualization Device (Machine Board)"
	build_path = /obj/machinery/self_actualization_device
	req_components = list(/obj/item/stock_parts/micro_laser = 5)

/obj/machinery/self_actualization_device
	name = "Self-Actualization Device"
	desc = "С помощью современных нейросканеров и косметической хирургии на синтплоти корпорация Veymed \
	совместно с отделом кадров Nanotrasen (и не только) представляет вам Устройство Самоактуализации! \n\
	Когда-нибудь оживляли пациента, а он подавал на вас в суд за халатность, потому что его голова оказалась пришита не к тому телу? \n\
	Просто засуньте его в УСА и включите! Его хмурый взгляд перевернётся вверх тормашками, когда устройство воссоздаст \
	его идеальное «я» благодаря чудесам технологии сканирования мозга! \n\
	Всего через несколько мгновений его выплюнет обратно уже в идеальном облике — готового продолжить свой день без каких-либо судебных претензий!"
	icon = 'modular_splurt/icons/obj/machinery/self_actualization_device.dmi'
	icon_state = "sad_open"
	circuit = /obj/item/circuitboard/machine/self_actualization_device
	state_open = TRUE
	density = FALSE
	use_power = IDLE_POWER_USE
	active_power_usage = 500
	idle_power_usage = 10
	vocal_speed = 5
	vocal_pitch = 0.6
	vocal_pitch_range = 0.3
	/// Is someone being processed inside of the machine?
	var/processing = FALSE
	/// How long does it take to break out of the machine?
	var/breakout_time = 10 SECONDS
	/// How long does the machine take to work?
	var/processing_time = 1 MINUTES
	/// The interval that advertisements are said by the machine's speaker.
	var/next_fact = 20 SECONDS
	/// A list containing advertisements that the machine says while working.
	var/static/list/advertisements = list(\
	"Спасибо, что воспользовались Устройством Самоактуализации от компании Veymed — вы всегда этого хотели.", \
	"Устройство Самоактуализации не должно использоваться пожилыми людьми без непосредственного присмотра взрослых. Компания Cinco не несет ответственности за любые травмы, полученные при использовании устройства самоактуализации без присмотра.", \
	"Пожалуйста, очищайте Устройство Самоактуализации каждые пятнадцать минут! Запрещено использовать неочищенным, в противном случае, компания не несет ответственности, за побочные эффекты, например беременность.", \
	"Перед использованием Устройства Самоактуализации снимите все металлические предметы, иначе выражение «железный человек» станет слишком буквальным!" , \
	"Устройство Самоактуализации не предназначено для романтического использования вдвоём. Даже если очень хочется.", \
	"Перед началом сеанса убедитесь, что у вас нет «дополнительных» органов. Устройство Самоактуализации может решить, что они лишние.", \
	"Компания Veymed напоминает: любые новые органы, выросшие после пятого сеанса, считаются исключительно вашим личным достижением.", \
	"Не вставляйте в Устройство Самоактуализации ничего, что компания не поставляла официально. Особенно если это вибрирует.", \
	"Пользователям, склонным к чрезмерному энтузиазму, следует удерживаться от попыток «достичь взаимности» с устройством. Оно вас не оценит.", \
	"Устройство Самоактуализации не предназначено для личных экспериментов анатомического или интимного характера. Даже если выглядит, будто справится." \
	)
	allow_oversized_characters = TRUE

/obj/machinery/self_actualization_device/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/machinery/self_actualization_device/close_machine(mob/user)
	..()
	playsound(src, 'sound/machines/click.ogg', 50)
	icon_state = "sad_closed"
	if(!occupant)
		return FALSE
	if(!ishuman(occupant) || !check_for_normalizer(occupant)) // BLUEMOON EDIT - normalizer check added
		occupant.forceMove(drop_location())
		set_occupant(null)
		return FALSE
	to_chat(occupant, span_notice("Вы устраиваетесь в [src]."))
	update_appearance()

/obj/machinery/self_actualization_device/examine(mob/user)
	. = ..()
	. += span_notice("Статус-дисплей сообщает: \n\
					- Время процедуры: [DisplayTimeText(processing_time)]")
	var/static/init_processing_time
	if(isnull(init_processing_time))
		init_processing_time = initial(processing_time)
	if(init_processing_time > processing_time)
		. += span_notice("- Машина работает на [span_nicegreen("[100-(processing_time/init_processing_time*100)]%")] быстрее.")
	. += span_notice("Alt-Click для <b>включения</b> машины с пациентом внутри.")

/obj/machinery/self_actualization_device/open_machine(mob/user)
	playsound(src, 'sound/machines/click.ogg', 50)
	icon_state = "sad_open"
	use_power = IDLE_POWER_USE
	..()

/obj/machinery/self_actualization_device/RefreshParts()
	processing_time = initial(processing_time)

	var/parts_rating = 0
	var/i = 0
	for(var/obj/item/stock_parts/L in component_parts)
		parts_rating += L.rating
		++i
	// Average rating of all details
	var/rating = round_down(parts_rating / i)
	var/const/speed_up_per_rating = 20 // T4 = 60% speed up
	var/speed_up_ratio = max(ceil((rating-1) * speed_up_per_rating),0)/100
	processing_time -= processing_time*speed_up_ratio
	processing_time = max(round(processing_time), 1 SECONDS)

/obj/machinery/self_actualization_device/AltClick(mob/user)
	. = ..()
	if(!powered() || !occupant || state_open || processing)
		return FALSE
	to_chat(user, "Вы запускаете процедуру Актуализации.")
	addtimer(CALLBACK(src, PROC_REF(eject_new_you)), processing_time, TIMER_OVERRIDE|TIMER_UNIQUE)
	if(occupant)
		if(!processing)
			icon_state = "sad_on"
		else
			icon_state = "sad_off"
	processing = TRUE
	use_power = ACTIVE_POWER_USE
	next_fact = 0 // Больше рекламы
	update_appearance()

/obj/machinery/self_actualization_device/interact(mob/user)
	if(state_open)
		close_machine()
		return

	if(!processing)
		open_machine()
		return

// SPLURT ADD - if a character is wearing a normalizer, he cannot get inside/complete the procedure (otherwise it leads to errors with setting the size)
/obj/machinery/self_actualization_device/proc/check_for_normalizer(mob/target)
	if(target.GetComponent(/datum/component/size_normalized))
		visible_message(span_warning("[src] издаёт короткий сигнал, отказывая пользователю с устройствами нормализации!"))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50)
		return FALSE // prohibition
	return TRUE // permission
// SPLURT ADD END

/obj/machinery/self_actualization_device/process(delta_time)
	if(!processing)
		return
	if(!powered() || !occupant || !iscarbon(occupant))
		open_machine()
		return

	next_fact -= delta_time SECONDS
	if(next_fact <= 0)
		next_fact = initial(next_fact)
		say(pick(advertisements))
		playsound(loc, 'sound/machines/chime.ogg', 30, FALSE)

/// Ejects the occupant as either their preference character, or as a monke based on emag status.
/obj/machinery/self_actualization_device/proc/eject_new_you()
	if(state_open || !occupant || !powered())
		return
	processing = FALSE
	use_power = IDLE_POWER_USE

	if(!ishuman(occupant) || !check_for_normalizer(occupant)) // BLUEMOON EDIT - added || !check_for_normalizer(occupant)
		return FALSE

	var/mob/living/carbon/human/patient = occupant
	var/original_name = patient.dna.real_name

	//Organ damage saving code.
	var/heart_damage = check_organ(patient, /obj/item/organ/heart)
	var/liver_damage = check_organ(patient, /obj/item/organ/liver)
	var/lung_damage = check_organ(patient, /obj/item/organ/lungs)
	var/stomach_damage = check_organ(patient, /obj/item/organ/stomach)
	var/brain_damage = check_organ(patient, /obj/item/organ/brain)
	var/eye_damage = check_organ(patient, /obj/item/organ/eyes)
	var/ear_damage = check_organ(patient, /obj/item/organ/ears)

	var/list/trauma_list = list()
	if(patient.get_traumas())
		for(var/datum/brain_trauma/trauma as anything in patient.get_traumas())
			trauma_list += trauma

	var/brute_damage = patient.getBruteLoss()
	var/burn_damage = patient.getFireLoss()

	patient.client?.prefs?.copy_to(patient)
	patient.dna.update_dna_identity()
	log_game("[key_name(patient)] used a Self-Actualization Device at [loc_name(src)].")

	if(patient.dna.real_name != original_name)
		message_admins("[key_name_admin(patient)] has used the Self-Actualization Device, and changed the name of their character. \
		Original Name: [original_name], New Name: [patient.dna.real_name]. \
		This may be a false positive from changing from a humanized monkey into a character, so be careful.")

	// Apply organ damage
	patient.setOrganLoss(ORGAN_SLOT_HEART, heart_damage)
	patient.setOrganLoss(ORGAN_SLOT_LIVER, liver_damage)
	patient.setOrganLoss(ORGAN_SLOT_LUNGS, lung_damage)
	patient.setOrganLoss(ORGAN_SLOT_STOMACH, stomach_damage)
	// Head organ damage.
	patient.setOrganLoss(ORGAN_SLOT_EYES, eye_damage)
	patient.setOrganLoss(ORGAN_SLOT_EARS, ear_damage)
	patient.setOrganLoss(ORGAN_SLOT_BRAIN, brain_damage)

	//Re-Applies Trauma
	var/obj/item/organ/brain/patient_brain = patient.getorgan(/obj/item/organ/brain)

	if(length(trauma_list))
		patient_brain.traumas = trauma_list

	//Re-Applies Damage
	patient.getBruteLoss(brute_damage)
	patient.getFireLoss(burn_damage)

	if(SSquirks?.check_blacklist_conflicts(patient.client?.prefs?.all_quirks))
		patient.client.prefs.all_quirks.Cut()
		patient.client.prefs.save_character()
		log_admin("All quirks for [key_name(patient)] were reset due to quirk selection blacklist (via Self-Actualization Device).")

	SSquirks.AssignQuirks(patient, patient.client, TRUE, TRUE, null, FALSE, patient)
	SSlanguage.AssignLanguage(patient, patient.client)
	if(iscuratorjob(patient))
		patient.grant_all_languages(source = LANGUAGE_CURATOR)
		patient.remove_blocked_language(GLOB.all_languages, source=LANGUAGE_ALL)

	open_machine()
	playsound(src, 'sound/machines/microwave/microwave-end.ogg', 100, FALSE)

/// Checks the damage on the inputed organ and stores it.
/obj/machinery/self_actualization_device/proc/check_organ(mob/living/carbon/human/patient, obj/item/organ/organ_to_check)
	var/obj/item/organ/organ_to_track = patient.getorgan(organ_to_check)

	// If the organ is missing, the organ damage is automatically set to 100.
	if(!organ_to_track)
		return 100 //If the organ is missing, return max damage.

	return organ_to_track.damage

/obj/machinery/self_actualization_device/screwdriver_act(mob/living/user, obj/item/used_item)
	. = TRUE
	if(..())
		return

	if(occupant)
		balloon_alert(user, "Внутри пациент!")
		return

	if(default_deconstruction_screwdriver(user, icon_state, icon_state, used_item))
		update_appearance()
		return

	return FALSE

/obj/machinery/self_actualization_device/crowbar_act(mob/living/user, obj/item/used_item)
	if(occupant)
		balloon_alert(user, "Внутри пациент!")
		return

	if(default_deconstruction_crowbar(used_item))
		return TRUE
