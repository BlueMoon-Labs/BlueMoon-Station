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
