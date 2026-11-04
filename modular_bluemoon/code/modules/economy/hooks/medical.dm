/mob/living/carbon/human
	/// Тяжесть последней травмы для выписки: ECON_INJURY_*
	var/econ_injury_severity = ECON_INJURY_NONE
	var/econ_injury_time = 0
	/// ckey нанёсшего травму, если его удар был в окне травмы
	var/econ_injury_attacker
	/// ckey убийцы на момент последней смерти
	var/econ_death_attacker

/mob/living/carbon/human/updatehealth()
	. = ..()
	econ_note_injury()

/mob/living/carbon/human/death(gibbed)
	var/was_dead = stat == DEAD
	. = ..()
	if(!was_dead && stat == DEAD)
		econ_death_attacker = econ_recent_attacker()

/mob/living/carbon/human/proc/econ_recent_attacker()
	if(lastattackerckey && world.time - lastattacker_time <= ECON_INJURY_WINDOW)
		return lastattackerckey

/mob/living/carbon/human/proc/econ_note_injury()
	var/severity = ECON_INJURY_NONE
	if(health <= crit_threshold)
		severity = ECON_INJURY_CRIT
	else if(health < maxHealth * ECON_INJURY_HEAVY_HEALTH_RATIO)
		severity = ECON_INJURY_HEAVY
	else if(health < maxHealth * ECON_INJURY_LIGHT_HEALTH_RATIO)
		severity = ECON_INJURY_LIGHT
	if(severity > econ_injury_severity || (severity && world.time - econ_injury_time > ECON_INJURY_WINDOW))
		econ_injury_severity = severity
		econ_injury_time = world.time
		econ_injury_attacker = econ_recent_attacker()

/// Травма в окне и нанесена не этим исполнителем.
/mob/living/carbon/human/proc/econ_injury_open_for(mob/performer)
	if(econ_injury_severity == ECON_INJURY_NONE || world.time - econ_injury_time > ECON_INJURY_WINDOW)
		return FALSE
	return !econ_injury_attacker || econ_injury_attacker != econ_ckey_of(performer)

/mob/living/carbon/human/proc/econ_can_discharge(mob/performer)
	return econ_injury_open_for(performer) && stat != DEAD && health >= maxHealth * ECON_DISCHARGE_HEALTH_RATIO

/proc/econ_record_revive(mob/living/user, mob/living/carbon/patient)
	if(!econ_on_station(patient))
		return 0
	if(ishuman(patient))
		var/mob/living/carbon/human/human_patient = patient
		if(human_patient.econ_death_attacker && human_patient.econ_death_attacker == econ_ckey_of(user))
			return 0
	return SSeconomy.record_work(ACCOUNT_MED, WORK_MED_REVIVE, 1, user, patient, "Реанимация: [econ_public_name(patient)]")

/datum/surgery
	/// Платит ли медицине, если лечебная
	var/econ_paid = TRUE

/datum/surgery/amputation
	econ_paid = FALSE

/datum/surgery/organ_manipulation
	econ_paid = FALSE

/datum/surgery/prosthetic_replacement
	econ_paid = FALSE

/datum/surgery/proc/econ_pay_surgeon(mob/user)
	if(!is_healing || !econ_paid || !ishuman(target) || !econ_on_station(target))
		return 0
	var/mob/living/carbon/human/patient = target
	if(!patient.econ_injury_open_for(user))
		return 0
	return SSeconomy.record_work(ACCOUNT_MED, WORK_MED_SURGERY, 1, user, patient, "Операция: [name]")

/obj/item/healthanalyzer
	/// Показывает кнопку выписки в результатах сканирования
	var/offers_discharge = TRUE

/obj/item/healthanalyzer/proc/econ_discharge_ready(mob/user, mob/living/carbon/human/patient)
	if(!offers_discharge || !istype(patient) || user == patient || !patient.mind?.key || !patient.econ_can_discharge(user) || !user.Adjacent(patient) || !econ_on_station(patient))
		return FALSE
	var/datum/bank_account/account = econ_account_of(user)
	return account?.department_id == ACCOUNT_MED

/obj/item/healthanalyzer/proc/econ_discharge_examine()
	var/list/prices = SSeconomy.settings.work_prices
	return span_notice("Медик может выписать пациента, вылеченного до [ECON_DISCHARGE_HEALTH_RATIO * 100]% здоровья в течение [ECON_INJURY_WINDOW / (1 MINUTES)] минут после травмы: в результатах сканирования появится кнопка «Выписать пациента». Медицина получит [prices[WORK_MED_DISCHARGE_LIGHT]], [prices[WORK_MED_DISCHARGE_HEAVY]] или [prices[WORK_MED_DISCHARGE_CRIT]] кр. за лёгкую, тяжёлую или критическую травму. Травму, нанесённую самим медиком, выписка не оплачивает. Выписка, операции и реанимация оплачиваются только на станции.")

/// Выписывает вылеченного пациента и платит медицине по тяжести травмы. Возвращает выплату отделу.
/obj/item/healthanalyzer/proc/try_discharge(mob/user, mob/living/carbon/human/patient)
	if(!econ_discharge_ready(user, patient))
		to_chat(user, span_warning("Выписка недоступна: медик выписывает только вылеченного пациента из последнего сканирования, стоя рядом с ним на станции."))
		return 0
	var/static/list/work_by_severity = list(WORK_MED_DISCHARGE_LIGHT, WORK_MED_DISCHARGE_HEAVY, WORK_MED_DISCHARGE_CRIT)
	. = SSeconomy.record_work(ACCOUNT_MED, work_by_severity[patient.econ_injury_severity], 1, user, patient, "Выписка: [econ_public_name(patient)]")
	if(!.)
		to_chat(user, span_warning("Выписка не засчитана: этого пациента уже выписывали за последние [SSeconomy.settings.work_subject_cooldown_minutes] мин., или его недавно ранили вы сами."))
		return
	patient.econ_injury_severity = ECON_INJURY_NONE
	to_chat(user, span_notice("Пациент [econ_public_name(patient)] выписан. Медицина получила [.] кр."))
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)

/obj/item/healthanalyzer/Topic(href, list/href_list)
	. = ..()
	if(!href_list["econ_discharge"] || !usr.canUseTopic(src, BE_CLOSE))
		return
	if(text2num(href_list["econ_discharge"]) != scan_number)
		to_chat(usr, span_warning("Данные этого сканирования были затёрты последующими."))
		return
	try_discharge(usr, scanned_patient?.resolve())
