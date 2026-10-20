/// Наработка авангарда: старые названия роли в role_time.
///
/// У роли менялось название: "Expeditor" -> "Vanguard operative" -> "Vanguard Operative"
/// (commits 37970aa2658, e6ef4e66416, 06a17c2419b).
///
/// Проблема: PRIMARY KEY (ckey, job) в role_time сравнивается без учёта регистра
/// (utf8mb4_*_ci), а запись идёт через ON DUPLICATE KEY UPDATE (job_exp.dm).
/// Поэтому строка, созданная под старым названием/регистром, навсегда остаётся с ним же,
/// и новые минуты дописываются в неё же, а не в каноничное "Vanguard Operative".
/// TrackedPlaytime (job_report.dm) и требования работ (calc_exp_type) ищут часы строго
/// по каноничному названию роли, поэтому получают ноль и не показывают строку вообще.

/// Старые названия ролей, которые могли остаться в role_time.
/// Ключ — как записано в БД, значение — актуальное название роли.
GLOBAL_LIST_INIT(exp_legacy_role_names, list(
	"Expeditor" = "Vanguard Operative",
))

/// Сводит ключи записей role_time к актуальным названиям ролей:
/// алиасы переименований + регистронезависимое совпадение, минуты суммируются.
/// Неизвестные названия (например, ещё не добавленный алиас) сохраняются как есть.
/// Вызывается из client.set_exp_from_db() (code/modules/jobs/job_exp.dm).
/proc/normalize_exp_records(list/play_records)
	if(!length(play_records))
		return play_records

	var/list/canonical_names = list()
	for(var/job_title in SSjob.name_occupations)
		canonical_names[job_title] = TRUE
	for(var/category in GLOB.exp_specialmap)
		canonical_names[category] = TRUE
		for(var/special_name in GLOB.exp_specialmap[category])
			canonical_names[special_name] = TRUE
	canonical_names[EXP_TYPE_ADMIN] = TRUE

	// регистронезависимый поиск нужен для вариантов вроде "Vanguard operative"
	var/list/canonical_by_lowercase = list()
	for(var/known_name in canonical_names)
		canonical_by_lowercase[lowertext(known_name)] = known_name

	var/list/normalized = list()
	for(var/role_name in play_records)
		var/value = play_records[role_name]
		var/minutes = isnum(value) ? value : (text2num(value) || 0)
		var/canonical_name = role_name
		if(!canonical_names[role_name])
			canonical_name = GLOB.exp_legacy_role_names[role_name] || canonical_by_lowercase[lowertext(role_name)] || role_name
		var/existing = normalized[canonical_name]
		normalized[canonical_name] = (isnull(existing) ? 0 : (isnum(existing) ? existing : (text2num(existing) || 0))) + minutes

	return normalized
