
	//The mob should have a gender you want before running this proc. Will run fine without H
/datum/preferences/proc/random_character(gender_override)
	if(gender_override)
		gender = gender_override
	else
		gender = pick(MALE,FEMALE)
	underwear = random_underwear(gender)
	undie_color = random_short_color()
	undershirt = random_undershirt(gender)
	shirt_color = random_short_color()
	socks = random_socks()
	socks_color = random_short_color()
	use_custom_skin_tone = FALSE
	skin_tone = random_skin_tone()
	hair_style = random_hair_style(gender)
	facial_hair_style = random_facial_hair_style(gender)
	hair_color = random_short_color()
	facial_hair_color = random_short_color()
	var/random_eye_color = random_eye_color()
	left_eye_color = random_eye_color
	right_eye_color = random_eye_color
	if(!pref_species)
		var/rando_race = pick(GLOB.roundstart_races)
		pref_species = new rando_race()
	features = random_features(pref_species?.id, gender)
	bark_id = pick(GLOB.bark_random_list)
	bark_pitch = BARK_PITCH_RAND(gender)
	bark_variance = BARK_VARIANCE_RAND
	age = rand(AGE_MIN,AGE_MAX)

/datum/preferences/proc/build_preview_appearance(aroused_preview = FALSE, preview_mode = PREVIEW_PREF_JOB)
	// Determine what job is marked as 'High' priority, and dress them up as such.
	var/datum/job/previewJob = get_highest_job()

	if(previewJob && preview_mode == PREVIEW_PREF_JOB)
		var/mutable_appearance/silicon_sprite
		if(istype(previewJob,/datum/job/ai))
			silicon_sprite = mutable_appearance('icons/mob/AI.dmi', resolve_ai_icon(preferred_ai_core_display), MOB_LAYER, GAME_PLANE)
		else if(istype(previewJob,/datum/job/cyborg))
			silicon_sprite = mutable_appearance('icons/mob/robots.dmi', "robot", MOB_LAYER, GAME_PLANE)
		if(silicon_sprite)
			return silicon_sprite

	// regenerate = FALSE: манекен всё равно
	// сразу переодевается и в конце проходит regenerate_icons() - восстанавливать
	// срезанные wipe_state() иконки на входе значит рендерить его дважды.
	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES, regenerate = FALSE)
	if(!mannequin)
		return null
	var/mutable_appearance/result
	try
		// Новый манекен и взятый из пула начинают с одинаково очищенного состояния.
		mannequin.wipe_state()
		copy_to(mannequin, icon_updates = FALSE, initial_spawn = TRUE)
		if(!preview_build_yield(mannequin))
			return null

		switch(preview_mode)
			if(PREVIEW_PREF_JOB)
				if(previewJob)
					mannequin.job = previewJob.title
					previewJob.equip(mannequin, TRUE, preference_source = parent)
			if(PREVIEW_PREF_LOADOUT)
				SSjob.equip_loadout(parent?.mob, mannequin, bypass_prereqs = TRUE, can_drop = FALSE, is_dummy = TRUE, preferences_source = src)
				SSjob.post_equip_loadout(parent?.mob, mannequin, bypass_prereqs = TRUE, can_drop = FALSE, is_dummy = TRUE, preferences_source = src)
		if(!preview_build_yield(mannequin))
			return null

		// Органы манекена переиспользуются: каждый кадр явно задаёт выбранную позу,
		// независимо от прошлого превью и игровых ограничений возбуждения.
		for(var/obj/item/organ/genital/genital in mannequin.internal_organs)
			if(CHECK_BITFIELD(genital.genital_flags, GENITAL_CAN_AROUSE))
				genital.aroused_state = aroused_preview
				genital.update_appearance()

		mannequin.regenerate_icons()

		result = new /mutable_appearance(mannequin)
		// Конструктор mutable_appearance сбрасывает plane: сохраняем настоящую плоскость манекена.
		result.plane = mannequin.plane
		// Сброс манекена в пуле снимает всю одежду - ещё ~8 мс, тоже отдельным тиком.
		if(!preview_build_yield(mannequin))
			return result
	catch(var/exception/error)
		release_preview_mannequin(mannequin)
		throw error
	release_preview_mannequin(mannequin)
	return result

/// Сборка манекена одним куском стоила 30-50 мс, то есть целый тик сервера (прод 10645/10646: Timer 70-98% тика). Между этапами отдаём тик; FALSE - манекен удалили, пока ждали.
/datum/preferences/proc/preview_build_yield(mob/living/carbon/human/dummy/mannequin)
	stoplag()
	return !QDELETED(mannequin)

/// Пока сборка спала, слот мог получить новый манекен, занятый другой сборкой: освобождаем только свой.
/datum/preferences/proc/release_preview_mannequin(mob/living/carbon/human/dummy/mannequin)
	if(GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_PREFERENCES] == mannequin)
		unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)

/datum/preferences/proc/get_highest_job(list/priorities)
	if(isnull(priorities))
		priorities = job_preferences
	var/highest_pref = 0
	var/datum/job/highest_job
	for(var/job in priorities)
		if(priorities["[job]"] > highest_pref)
			highest_job = SSjob.GetJob(job)
			highest_pref = priorities["[job]"]
	return highest_job
