#define VACANCY_PROBE_CKEY "unittestreliefjoin"
#define VACANCY_PROBE_DEAD_CKEY "unittestreliefdead"
#define VACANCY_PROBE_EVAC_CKEY "unittestreliefevac"

/// Приглашение уходит после 5 минут пустоты и не раньше 10-й минуты раунда, повторяется раз в 15 минут и молчит при эвакуации.
/datum/unit_test/director_vacancy_invite_timing

/datum/unit_test/director_vacancy_invite_timing/Run()
	var/datum/director_vacancies/vacancies = allocate(/datum/director_vacancies)
	var/round_start = 1 HOURS
	var/list/staffing = list(DIRECTOR_DEPT_SECURITY = 2, DIRECTOR_DEPT_ENGINEERING = 2, DIRECTOR_DEPT_MEDICAL = 0, DIRECTOR_DEPT_SCIENCE = 0)

	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 1 MINUTES, round_start, DIRECTOR_EVAC_NONE)), 0, "В первые минуты раунда приглашений нет")
	TEST_ASSERT(vacancies.is_vacant(DIRECTOR_DEPT_MEDICAL), "Пустой медотдел должен числиться вакантным сразу")
	TEST_ASSERT(!vacancies.is_vacant(DIRECTOR_DEPT_SCIENCE), "Научный отдел не входит в критичные")
	TEST_ASSERT(!vacancies.is_vacant(DIRECTOR_DEPT_SECURITY), "Укомплектованная СБ не вакантна")
	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 9 MINUTES, round_start, DIRECTOR_EVAC_NONE)), 0, "До 10-й минуты раунда приглашений нет")

	var/list/invited = vacancies.update(staffing, round_start + 10 MINUTES, round_start, DIRECTOR_EVAC_NONE)
	TEST_ASSERT_EQUAL(invited.Join(","), DIRECTOR_DEPT_MEDICAL, "На 10-й минуте должно уйти приглашение в медотдел")
	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 24 MINUTES, round_start, DIRECTOR_EVAC_NONE)), 0, "Повтор раньше 15 минут")
	invited = vacancies.update(staffing, round_start + 25 MINUTES, round_start, DIRECTOR_EVAC_NONE)
	TEST_ASSERT_EQUAL(invited.Join(","), DIRECTOR_DEPT_MEDICAL, "Через 15 минут приглашение повторяется")

	staffing[DIRECTOR_DEPT_ENGINEERING] = 0
	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 30 MINUTES, round_start, DIRECTOR_EVAC_NONE)), 0, "Инженеры только что пропали")
	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 34 MINUTES, round_start, DIRECTOR_EVAC_NONE)), 0, "Четыре минуты пустоты - ещё рано")
	invited = vacancies.update(staffing, round_start + 35 MINUTES, round_start, DIRECTOR_EVAC_NONE)
	TEST_ASSERT_EQUAL(invited.Join(","), DIRECTOR_DEPT_ENGINEERING, "Ровно через 5 минут пустоты зовут инженеров")

	staffing[DIRECTOR_DEPT_MEDICAL] = 1
	vacancies.update(staffing, round_start + 36 MINUTES, round_start, DIRECTOR_EVAC_NONE)
	TEST_ASSERT(!vacancies.is_vacant(DIRECTOR_DEPT_MEDICAL), "Пришедший медик снимает вакансию")
	staffing[DIRECTOR_DEPT_MEDICAL] = 0
	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 37 MINUTES, round_start, DIRECTOR_EVAC_NONE)), 0, "Отсчёт пустоты начинается заново")
	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 41 MINUTES, round_start, DIRECTOR_EVAC_NONE)), 0, "Четыре минуты новой пустоты - ещё рано")
	invited = vacancies.update(staffing, round_start + 42 MINUTES, round_start, DIRECTOR_EVAC_NONE)
	TEST_ASSERT_EQUAL(invited.Join(","), DIRECTOR_DEPT_MEDICAL, "Снова пустой медотдел зовут после 5 минут")

	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 60 MINUTES, round_start, DIRECTOR_EVAC_CALLED)), 0, "При вызванной эвакуации приглашений нет")
	TEST_ASSERT_EQUAL(length(vacancies.update(staffing, round_start + 61 MINUTES, round_start, DIRECTOR_EVAC_GONE)), 0, "После отлёта шаттла приглашений нет")
	invited = vacancies.update(staffing, round_start + 62 MINUTES, round_start, DIRECTOR_EVAC_NONE)
	TEST_ASSERT_EQUAL(invited.Join(","), "[DIRECTOR_DEPT_MEDICAL],[DIRECTOR_DEPT_ENGINEERING]", "Отозванная эвакуация не съедает кулдаун")

	vacancies.note_filled(DIRECTOR_DEPT_MEDICAL)
	TEST_ASSERT(!vacancies.is_vacant(DIRECTOR_DEPT_MEDICAL), "Вошедший в отдел снимает вакансию до следующего бита")

/// Приглашение не получают те, кто его выключил, и те, кому весь отдел закрыт джоббаном.
/datum/unit_test/director_vacancy_invite_recipients

/datum/unit_test/director_vacancy_invite_recipients/Run()
	var/datum/preferences/prefs = new
	allocated += prefs
	TEST_ASSERT(prefs.shift_invites, "Приглашения включены по умолчанию")
	TEST_ASSERT(shift_invite_wanted(prefs, null, DIRECTOR_DEPT_MEDICAL), "Игрок без банов получает приглашение")
	TEST_ASSERT(!shift_invite_wanted(null, null, DIRECTOR_DEPT_MEDICAL), "Без префов приглашений нет")

	prefs.shift_invites = FALSE
	TEST_ASSERT(!shift_invite_wanted(prefs, null, DIRECTOR_DEPT_MEDICAL), "Выключенная настройка глушит приглашения")
	prefs.shift_invites = TRUE

	var/list/jobbans = list()
	for(var/title in GLOB.medical_positions)
		jobbans[title] = "unit test"
	TEST_ASSERT(!shift_invite_wanted(prefs, jobbans, DIRECTOR_DEPT_MEDICAL), "Джоббан на весь медотдел - приглашение не нужно")
	TEST_ASSERT(shift_invite_wanted(prefs, jobbans, DIRECTOR_DEPT_SECURITY), "Бан медотдела не закрывает СБ")
	jobbans -= "Paramedic"
	TEST_ASSERT(shift_invite_wanted(prefs, jobbans, DIRECTOR_DEPT_MEDICAL), "Одна доступная должность - приглашение уходит")

/// Бонус за вход в пустой отдел ставится при летджойне, начисляется один раз и только при выполненных условиях.
/datum/unit_test/metadollars_relief_bonus
	var/list/saved_joins
	var/datum/director_vacancies/saved_vacancies

/datum/unit_test/metadollars_relief_bonus/Destroy()
	for(var/joined_ckey in SSmetadollars.relief_joins)
		var/datum/relief_join/join = SSmetadollars.relief_joins[joined_ckey]
		deltimer(join.check_timer)
	if(saved_joins)
		SSmetadollars.relief_joins = saved_joins
	if(saved_vacancies)
		SSdirector.vacancies = saved_vacancies
	return ..()

/datum/unit_test/metadollars_relief_bonus/Run()
	saved_joins = SSmetadollars.relief_joins
	SSmetadollars.relief_joins = list()
	saved_vacancies = SSdirector.vacancies
	SSdirector.vacancies = allocate(/datum/director_vacancies)
	SSdirector.vacancies.empty_since[DIRECTOR_DEPT_MEDICAL] = world.time

	var/mob/living/carbon/human/sec_joiner = allocate(/mob/living/carbon/human)
	sec_joiner.ckey = VACANCY_PROBE_DEAD_CKEY
	SSdirector.on_job_latejoin(null, SSjob.GetJob("Security Officer"), sec_joiner)
	TEST_ASSERT(!(VACANCY_PROBE_DEAD_CKEY in SSmetadollars.relief_joins), "Вход в занятый отдел не даёт отметки")

	var/mob/living/carbon/human/joiner = allocate(/mob/living/carbon/human)
	joiner.ckey = VACANCY_PROBE_CKEY
	SSdirector.on_job_latejoin(null, SSjob.GetJob("Medical Doctor"), joiner)
	var/datum/relief_join/join = SSmetadollars.relief_joins[VACANCY_PROBE_CKEY]
	TEST_ASSERT_NOTNULL(join, "Вход в пустой медотдел ставит отметку")
	TEST_ASSERT(join.check_timer, "Проверка 30 минут должна стоять в таймере")
	TEST_ASSERT(!SSdirector.vacancies.is_vacant(DIRECTOR_DEPT_MEDICAL), "Вход снимает вакансию сразу")

	var/mob/living/carbon/human/second_joiner = allocate(/mob/living/carbon/human)
	second_joiner.ckey = VACANCY_PROBE_EVAC_CKEY
	SSdirector.on_job_latejoin(null, SSjob.GetJob("Paramedic"), second_joiner)
	TEST_ASSERT(!(VACANCY_PROBE_EVAC_CKEY in SSmetadollars.relief_joins), "Второй вошедший в тот же отдел уже не первый")

	TEST_ASSERT_EQUAL(length(SSmetadollars.collect_relief_bonuses(FALSE)), 0, "До 30 минут без эвакуации бонуса нет")
	SSmetadollars.check_relief_join(VACANCY_PROBE_CKEY)
	TEST_ASSERT(join.earned, "Живой и в игре через 30 минут - бонус заработан")
	SSmetadollars.note_relief_join(joiner)
	TEST_ASSERT_EQUAL(SSmetadollars.relief_joins[VACANCY_PROBE_CKEY], join, "Повторный вход не заводит вторую отметку")

	SSmetadollars.note_relief_join(sec_joiner)
	sec_joiner.death()
	SSmetadollars.check_relief_join(VACANCY_PROBE_DEAD_CKEY)
	TEST_ASSERT(!(VACANCY_PROBE_DEAD_CKEY in SSmetadollars.relief_joins), "Погибший до 30 минут теряет отметку")

	SSmetadollars.note_relief_join(second_joiner)
	var/list/paid = SSmetadollars.collect_relief_bonuses(FALSE)
	TEST_ASSERT_EQUAL(paid.Join(","), VACANCY_PROBE_CKEY, "Без эвакуации платится только заработанный бонус")
	paid = SSmetadollars.collect_relief_bonuses(TRUE)
	TEST_ASSERT_EQUAL(paid.Join(","), VACANCY_PROBE_EVAC_CKEY, "Доживший до эвакуации получает бонус, уже оплаченный - нет")
	TEST_ASSERT_EQUAL(length(SSmetadollars.collect_relief_bonuses(TRUE)), 0, "Второй выплаты за раунд нет")

#undef VACANCY_PROBE_CKEY
#undef VACANCY_PROBE_DEAD_CKEY
#undef VACANCY_PROBE_EVAC_CKEY
