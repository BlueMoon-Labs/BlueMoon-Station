/// Роли помощи зарегистрированы у директора, живут во FLAVOR вне антаг-пулов и не несут нагрузки.
/datum/unit_test/director_crew_relief_contract

/datum/unit_test/director_crew_relief_contract/Run()
	for(var/datum/round_event_control/crew_relief/relief_type as anything in list(/datum/round_event_control/crew_relief/repair, /datum/round_event_control/crew_relief/medical))
		var/datum/round_event_control/crew_relief/control = locate(relief_type) in SSdirector.actions
		TEST_ASSERT_NOTNULL(control, "[relief_type] должен быть зарегистрирован у директора")
		TEST_ASSERT_EQUAL(control.severity, DIRECTOR_SEVERITY_FLAVOR, "[control.name]: роль помощи обязана жить во FLAVOR")
		TEST_ASSERT(!DIRECTOR_IS_ANTAG_POOL(control.severity), "[control.name]: роль помощи не должна попадать в антаг-пул")
		TEST_ASSERT_EQUAL(control.family, "crew_relief", "[control.name]: неверное семейство")
		TEST_ASSERT_EQUAL(control.intensity, 0, "[control.name]: роль помощи не должна считаться угрозой")
		TEST_ASSERT_EQUAL(control.cost, 0, "[control.name]: роль помощи не должна тратить событийные кошельки")
		TEST_ASSERT_EQUAL(control.max_occurrences, 2, "[control.name]: не больше двух отрядов за раунд")
		TEST_ASSERT(control.enabled && !control.admin_only && control.weight > 0, "[control.name]: роль помощи должна выбираться естественно")
		TEST_ASSERT(ispath(control.typepath, /datum/round_event/ghost_role/crew_relief), "[control.name]: отряд набирается штатным гост-опросом")
		TEST_ASSERT_EQUAL(initial(relief_type.earliest_start), 20 MINUTES, "[control.name]: помощь не раньше 20-й минуты")
		TEST_ASSERT_EQUAL(initial(relief_type.min_players), 20, "[control.name]: помощь только при экипаже от 20")

/// can_fire открыт только при нехватке своего отдела, вне эвакуации и пока прошлый отряд не жив.
/datum/unit_test/director_crew_relief_gates
	var/list/saved

/datum/unit_test/director_crew_relief_gates/Destroy()
	if(saved)
		SSdirector.restore_simulation_state(saved)
	return ..()

/datum/unit_test/director_crew_relief_gates/Run()
	saved = SSdirector.capture_simulation_state()
	SSdirector.time_override = SSticker.round_start_time + 1 HOURS
	var/datum/round_event_control/crew_relief/repair/repair = allocate(/datum/round_event_control/crew_relief/repair)
	var/datum/round_event_control/crew_relief/medical/medical = allocate(/datum/round_event_control/crew_relief/medical)
	var/datum/director_signals/signals = allocate(/datum/director_signals)
	signals.effective_crew = 25
	signals.staffing = list(DIRECTOR_DEPT_SECURITY = 3, DIRECTOR_DEPT_ENGINEERING = 3,
		DIRECTOR_DEPT_MEDICAL = 3, DIRECTOR_DEPT_SCIENCE = 2, DIRECTOR_DEPT_SUPPLY = 2, DIRECTOR_DEPT_COMMAND = 2)
	TEST_ASSERT(!repair.can_fire(signals), "Укомплектованный инженерный отдел не должен вызывать ремонтную бригаду")
	TEST_ASSERT(!medical.can_fire(signals), "Укомплектованный медотдел без потерь не должен вызывать санитаров")

	signals.staffing[DIRECTOR_DEPT_ENGINEERING] = 1
	TEST_ASSERT(repair.can_fire(signals), "Один инженер на станции - повод прислать ремонтную бригаду")
	signals.dead_fraction = 0.2
	TEST_ASSERT(medical.can_fire(signals), "Массовые потери открывают санитаров даже при живых врачах")
	signals.dead_fraction = 0.1
	TEST_ASSERT(!medical.can_fire(signals), "Немного погибших при живых врачах - не повод для санитаров")
	signals.staffing[DIRECTOR_DEPT_MEDICAL] = 0
	TEST_ASSERT(medical.can_fire(signals), "Пустой медотдел - повод прислать санитаров")

	signals.effective_crew = 15
	TEST_ASSERT(!repair.can_fire(signals) && !medical.can_fire(signals), "Малому экипажу отряд помощи не положен")
	signals.effective_crew = 25

	signals.evac_state = DIRECTOR_EVAC_CALLED
	TEST_ASSERT(!repair.can_fire(signals) && !medical.can_fire(signals), "После вызова эвакуации помощь уже не нужна")
	signals.evac_state = DIRECTOR_EVAC_NONE

	SSdirector.time_override = SSticker.round_start_time + 10 MINUTES
	TEST_ASSERT(!repair.can_fire(signals), "До 20-й минуты помощь не приходит")
	SSdirector.time_override = SSticker.round_start_time + 1 HOURS

	var/mob/living/carbon/human/member = allocate(/mob/living/carbon/human)
	repair.note_relief_team(list(member))
	TEST_ASSERT(!repair.can_fire(signals), "Пока прошлая бригада жива, вторая не приходит")
	TEST_ASSERT(medical.can_fire(signals), "Живая ремонтная бригада не закрывает санитаров")
	member.death()
	TEST_ASSERT(repair.can_fire(signals), "Погибшая бригада не держит отдел закрытым")

	repair.occurrences = repair.max_occurrences
	TEST_ASSERT(!repair.can_fire(signals), "Третьей бригады за раунд не бывает")

/// Спаун отряда переходит на живой трекинг без вклада в антаг-нагрузку, intensity и кошельки.
/datum/unit_test/director_crew_relief_spawn_accounting
	var/list/saved

/datum/unit_test/director_crew_relief_spawn_accounting/Destroy()
	if(saved)
		SSdirector.restore_simulation_state(saved)
	return ..()

/datum/unit_test/director_crew_relief_spawn_accounting/Run()
	saved = SSdirector.capture_simulation_state()
	SSdirector.profile = allocate(/datum/director_profile/medium)
	SSdirector.reset_budgets(0)
	SSdirector.intensity_ledger = list()
	SSdirector.live_ghost_role_spawns = list()
	var/datum/round_event_control/crew_relief/repair/control = allocate(/datum/round_event_control/crew_relief/repair)
	SSdirector.actions = list(control)
	var/load_before = SSdirector.antag_load()
	var/intensity_before = SSdirector.get_active_intensity()

	var/list/station_levels = SSmapping.levels_by_trait(ZTRAIT_STATION)
	TEST_ASSERT(length(station_levels), "В тестовом мире нет станционного z-уровня")
	var/mob/living/carbon/human/member = allocate(/mob/living/carbon/human)
	member.mind_initialize()
	member.forceMove(locate(round(world.maxx / 2), round(world.maxy / 2), station_levels[1]))
	var/datum/antagonist/ert/engineer/relief_role = new
	relief_role.silent = TRUE
	relief_role.equip_ert = FALSE
	member.mind.add_antag_datum(relief_role, allocate(/datum/team/ert, list()))
	TEST_ASSERT(!member.mind.is_ghost_role(), "Контроль: до подготовки боец ещё не помечен гост-ролью")

	var/datum/round_event/ghost_role/crew_relief/repair/event = allocate(/datum/round_event/ghost_role/crew_relief/repair, FALSE)
	event.kill()
	event.prepare_member(member)
	TEST_ASSERT(member.mind.is_ghost_role(), "Боец отряда помощи не должен становиться целью антагов")
	TEST_ASSERT(HAS_TRAIT(member, TRAIT_NO_MIDROUND_ANTAG), "Боец отряда помощи не должен становиться мидраунд-антагом")

	TEST_ASSERT(SSdirector.track_ghost_role_spawn(control, list(member), budget_backed = TRUE, log_execution = FALSE), "Отряд должен перейти на живой трекинг")
	TEST_ASSERT_EQUAL(length(SSdirector.live_ghost_role_spawns), 1, "Живой отряд должен учитываться директором")
	var/list/entry = SSdirector.live_ghost_role_spawns[1]
	TEST_ASSERT_EQUAL(entry["severity"], DIRECTOR_SEVERITY_FLAVOR, "Запись отряда должна остаться во FLAVOR")
	TEST_ASSERT_EQUAL(SSdirector.antag_load(), load_before, "Отряд помощи не должен расти антаг-нагрузку")
	TEST_ASSERT_EQUAL(SSdirector.get_active_intensity(), intensity_before, "Отряд помощи не должен давать intensity")
	TEST_ASSERT_EQUAL(SSdirector.total_budget(), 0, "Отряд помощи не должен печатать бюджет")
	member.mind.remove_antag_datum(/datum/antagonist/ert/engineer)

/// Роли помощи доходят до кандидатов бита во всех профилях; Extended весит их вдвое легче.
/// Глобальная пауза не душит флейвор: она короче паузы ступени FLAVOR в каждом профиле.
/datum/unit_test/director_crew_relief_profile_weights
	var/list/saved

/datum/unit_test/director_crew_relief_profile_weights/Destroy()
	if(saved)
		SSdirector.restore_simulation_state(saved)
	return ..()

/datum/unit_test/director_crew_relief_profile_weights/Run()
	saved = SSdirector.capture_simulation_state()
	CONFIG_SET(flag/allow_random_events, TRUE)
	SSdirector.time_override = SSticker.round_start_time + 1 HOURS
	SSdirector.reset_budgets(0)
	SSdirector.intensity_ledger = list()
	SSdirector.live_ghost_role_spawns = list()
	SSdirector.fired_counts = list()
	SSdirector.last_fired_at = list()
	SSdirector.family_fired_counts = list()
	SSdirector.family_last_fired_at = list()
	SSdirector.action_failure_cooldowns = list()
	var/datum/round_event_control/crew_relief/repair/repair = allocate(/datum/round_event_control/crew_relief/repair)
	var/datum/round_event_control/crew_relief/medical/medical = allocate(/datum/round_event_control/crew_relief/medical)
	repair.director_ghost_minimum = 0
	medical.director_ghost_minimum = 0
	SSdirector.actions = list(repair, medical)
	var/datum/director_signals/signals = allocate(/datum/director_signals)
	signals.effective_crew = 25
	signals.staffing = list(DIRECTOR_DEPT_SECURITY = 3, DIRECTOR_DEPT_ENGINEERING = 0,
		DIRECTOR_DEPT_MEDICAL = 0, DIRECTOR_DEPT_SCIENCE = 2, DIRECTOR_DEPT_SUPPLY = 2, DIRECTOR_DEPT_COMMAND = 2)

	var/list/expected_mults = list(
		/datum/director_profile/light = 1,
		/datum/director_profile/medium = 1,
		/datum/director_profile/hard = 1,
		/datum/director_profile/teambased = 1,
		/datum/director_profile/extended = 0.5,
	)
	for(var/profile_type in expected_mults)
		var/datum/director_profile/profile = allocate(profile_type)
		SSdirector.profile = profile
		TEST_ASSERT(profile.global_spacing < profile.severity_spacing[DIRECTOR_SEVERITY_FLAVOR], "[profile.round_type]: глобальная пауза не должна быть длиннее паузы флейвора")
		var/list/candidates = SSdirector.filter_candidates(signals)
		for(var/datum/round_event_control/crew_relief/control as anything in list(repair, medical))
			TEST_ASSERT_EQUAL(candidates[control], round(control.weight * expected_mults[profile_type] * 100), "[profile.round_type]: неожиданный вес [control.name] в кандидатах бита")

	SSdirector.config_error = null
	SSdirector.apply_profile_config(SSdirector.profile, list("crew_relief_weight_mult" = 0))
	var/config_error = SSdirector.config_error
	SSdirector.config_error = null
	TEST_ASSERT_NULL(config_error, "Множитель ролей помощи должен быть известным ключом конфига")
	TEST_ASSERT_EQUAL(length(SSdirector.filter_candidates(signals)), 0, "Нулевой множитель из конфига выключает роли помощи в профиле")

/// Без желающих призраков отряд не собирается, а шаблон ОБР не оставляет пустую команду.
/datum/unit_test/director_crew_relief_no_volunteers

/datum/unit_test/director_crew_relief_no_volunteers/Run()
	var/datum/round_event/ghost_role/crew_relief/repair/event = allocate(/datum/round_event/ghost_role/crew_relief/repair, FALSE)
	event.kill()
	var/status = event.spawn_role()
	TEST_ASSERT(status == NOT_ENOUGH_PLAYERS || status == MAP_ERROR, "Без призраков спаун должен честно провалиться, а не вернуть [status]")
	TEST_ASSERT_EQUAL(length(event.spawned_mobs), 0, "Без призраков никто не должен заспауниться")

	var/teams_before = length(GLOB.antagonist_teams)
	var/datum/ert/template = new /datum/ert/engineer_ert
	var/mob/dead/observer/absent = allocate(/mob/dead/observer)
	var/list/candidates = list(absent)
	TEST_ASSERT_EQUAL(length(template.spawn_members(candidates, 3)), 0, "Кандидат без клиента не должен получить тело")
	TEST_ASSERT_EQUAL(length(GLOB.antagonist_teams), teams_before, "Несобранный отряд не должен оставлять пустую команду")
