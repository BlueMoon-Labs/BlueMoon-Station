/// Кусочно-линейная интерполяция по списку пар list(list(x, y), ...), x по возрастанию.
/proc/piecewise_eval(list/curve, x)
	if(!length(curve))
		return 1
	var/list/first = curve[1]
	if(x <= first[1])
		return first[2]
	var/list/last = curve[length(curve)]
	if(x >= last[1])
		return last[2]
	for(var/i in 2 to length(curve))
		var/list/right = curve[i]
		if(x > right[1])
			continue
		var/list/left = curve[i - 1]
		var/t = (x - left[1]) / (right[1] - left[1])
		return left[2] + t * (right[2] - left[2])
	return last[2]

/// Все ручки темпа одного типа раунда. Числа - дефолты, переопределяются config/director.json.
/datum/director_profile
	/// Тип раунда (ROUNDTYPE_*), ключ выбора
	var/round_type
	/// Очков бюджета в минуту до множителей
	var/base_drip = 1
	/// Кривая множителя от минут раунда: list(list(минута, множитель), ...)
	var/list/time_curve = list(list(0, 0.4), list(20, 1), list(90, 1), list(120, 0.6))
	/// Кривая множителя от эффективного экипажа
	var/list/pop_curve = list(list(5, 0.4), list(15, 0.7), list(30, 1), list(60, 1.4), list(90, 1.6))
	/// Потолок суммарной активной intensity
	var/intensity_cap = 100
	/// Максимум одновременно активных MAJOR-действий
	var/max_active_major = 1
	/// Минимальные паузы между запусками, децисекунды: severity -> пауза.
	/// FLAVOR тоже ненулевая: без неё flavor-кандидат (мимо intensity_cap, дешёвый) находился бы
	/// почти на каждом бите и директор стрелял бы каждые 60 секунд - биты должны уметь простаивать.
	var/list/severity_spacing = list(
		DIRECTOR_SEVERITY_FLAVOR = 5 MINUTES,
		DIRECTOR_SEVERITY_MINOR = 4 MINUTES,
		DIRECTOR_SEVERITY_MODERATE = 8 MINUTES,
		DIRECTOR_SEVERITY_MAJOR = 25 MINUTES,
	)
	/// Минимальная пауза между ЛЮБЫМИ двумя запусками: гейт против очередей "три ивента за четыре
	/// минуты" (moderate + minor + flavor подряд легальны по ступенчатым паузам, но душат игроков).
	/// Гарантированный бит и форс админа проходят мимо.
	var/global_spacing = 2 MINUTES
	/// Пауза внутри семейства однотипных действий (director_action.family): после любого "перелива труб"
	/// другие варианты того же шаблона ждут, а не выпадают следующим же битом.
	var/family_spacing = 10 MINUTES
	/// Множители веса по навязчивости (DIRECTOR_DISRUPTION_*): мягкие профили глушат мешающие играть
	/// события внутри своей ступени, не трогая фоновые. 0 полностью исключает метку из выбора.
	/// Важно: share_correction выравнивает доли МЕЖДУ ступенями, поэтому множитель реально работает
	/// как сдвиг ВНУТРИ ступени (goo против грузовых подов в MINOR, галлюцинации против пыли во FLAVOR).
	var/list/disruption_weight_mults = list(
		DIRECTOR_DISRUPTION_AMBIENT = 1,
		DIRECTOR_DISRUPTION_MILD = 1,
		DIRECTOR_DISRUPTION_DISRUPTIVE = 1,
	)
	/// Паузы пула ANTAG (антаги из живого экипажа): лёгкие и тяжёлые отдельно
	var/antag_light_spacing = 12 MINUTES
	var/antag_heavy_spacing = 30 MINUTES
	/// Паузы пула GHOST (антаги из призраков): свой трек, полностью независимый от ANTAG
	var/ghost_light_spacing = 12 MINUTES
	var/ghost_heavy_spacing = 30 MINUTES
	/// Целевые доли ступеней при выборе: severity -> доля (сумма ~1).
	/// Сумма ANTAG + GHOST - общая доля антагонистов раунда; баланс между экипажными
	/// и гост-инжекциями тюнится их соотношением.
	var/list/pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.25,
		DIRECTOR_SEVERITY_MINOR = 0.3,
		DIRECTOR_SEVERITY_MODERATE = 0.25,
		DIRECTOR_SEVERITY_MAJOR = 0.08,
		DIRECTOR_SEVERITY_ANTAG = 0.07,
		DIRECTOR_SEVERITY_GHOST = 0.05,
	)
	/// Затишье: если дольше этого не было запусков и intensity ниже порога - гарантированный бит
	var/max_quiet_time = 12 MINUTES
	var/quiet_intensity_threshold = 25
	/// Недоукомплектованная СБ: если офицеров < ceil(экипаж / per_players), веса MAJOR и тяжёлого ANTAG *= penalty
	var/security_per_players = 12
	var/security_penalty_mult = 0.5
	/// Доля мёртвых, выше которой капля замедляется вдвое и MAJOR/тяжёлый ANTAG блокируются
	var/dead_fraction_threshold = 0.4
	/// Диапазон roundstart-бюджета (заменяет "threat/2 но не больше 30")
	var/roundstart_budget_min = 20
	var/roundstart_budget_max = 30
	/// Окно отмены выбора админом
	var/admin_cancel_time = 15 SECONDS
	/// Затухание повторов: вес действия делится на (1 + occurrences * repeat_penalty),
	/// чтобы директор не крутил одно и то же. 0 выключает; переопределяется per-action.
	var/repeat_penalty = 0.5

/// Множитель веса действия по его навязчивости. Неизвестная метка не штрафуется.
/datum/director_profile/proc/disruption_mult(datum/director_action/action)
	var/mult = disruption_weight_mults[action.get_disruption()]
	return isnull(mult) ? 1 : mult

/datum/director_profile/light
	round_type = ROUNDTYPE_DYNAMIC_LIGHT
	base_drip = 0.6
	intensity_cap = 60
	max_active_major = 0
	// Идентичность Light - ступень между Extended и Medium, а не копия одного из них:
	// в отличие от Extended антаги и moderate-события живут (доли 0.1 и 0.2), в отличие от
	// Medium - никаких MAJOR, мягче мешающие события (mults) и заметно реже тяжёлые запуски.
	family_spacing = 12 MINUTES
	disruption_weight_mults = list(
		DIRECTOR_DISRUPTION_AMBIENT = 1,
		DIRECTOR_DISRUPTION_MILD = 0.7,
		DIRECTOR_DISRUPTION_DISRUPTIVE = 0.3,
	)
	severity_spacing = list(
		DIRECTOR_SEVERITY_FLAVOR = 6 MINUTES,
		DIRECTOR_SEVERITY_MINOR = 5 MINUTES,
		DIRECTOR_SEVERITY_MODERATE = 10 MINUTES,
		DIRECTOR_SEVERITY_MAJOR = 60 MINUTES,
	)
	antag_light_spacing = 18 MINUTES
	antag_heavy_spacing = 60 MINUTES
	ghost_light_spacing = 18 MINUTES
	ghost_heavy_spacing = 60 MINUTES
	pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.35,
		DIRECTOR_SEVERITY_MINOR = 0.35,
		DIRECTOR_SEVERITY_MODERATE = 0.2,
		DIRECTOR_SEVERITY_MAJOR = 0,
		DIRECTOR_SEVERITY_ANTAG = 0.06,
		DIRECTOR_SEVERITY_GHOST = 0.04,
	)
	max_quiet_time = 15 MINUTES
	quiet_intensity_threshold = 20
	roundstart_budget_min = 8
	roundstart_budget_max = 15

/datum/director_profile/medium
	round_type = ROUNDTYPE_DYNAMIC_MEDIUM
	// все значения - дефолты базы

/datum/director_profile/hard
	round_type = ROUNDTYPE_DYNAMIC_HARD
	base_drip = 1.5
	intensity_cap = 140
	max_active_major = 2
	global_spacing = 1 MINUTES
	family_spacing = 6 MINUTES
	severity_spacing = list(
		DIRECTOR_SEVERITY_FLAVOR = 4 MINUTES,
		DIRECTOR_SEVERITY_MINOR = 3 MINUTES,
		DIRECTOR_SEVERITY_MODERATE = 6 MINUTES,
		DIRECTOR_SEVERITY_MAJOR = 18 MINUTES,
	)
	antag_light_spacing = 8 MINUTES
	antag_heavy_spacing = 20 MINUTES
	ghost_light_spacing = 8 MINUTES
	ghost_heavy_spacing = 20 MINUTES
	pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.15,
		DIRECTOR_SEVERITY_MINOR = 0.2,
		DIRECTOR_SEVERITY_MODERATE = 0.3,
		DIRECTOR_SEVERITY_MAJOR = 0.15,
		DIRECTOR_SEVERITY_ANTAG = 0.11,
		DIRECTOR_SEVERITY_GHOST = 0.09,
	)
	max_quiet_time = 8 MINUTES
	quiet_intensity_threshold = 30
	roundstart_budget_min = 30
	roundstart_budget_max = 45

/datum/director_profile/teambased
	round_type = ROUNDTYPE_DYNAMIC_TEAMBASED
	base_drip = 0.8
	intensity_cap = 140
	max_active_major = 2
	// Антаг-доли профиля (0.35 на двоих) не прожать через дефолтные паузы 12/30 - антаг-треки чаще
	antag_light_spacing = 10 MINUTES
	antag_heavy_spacing = 25 MINUTES
	ghost_light_spacing = 10 MINUTES
	ghost_heavy_spacing = 25 MINUTES
	pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.1,
		DIRECTOR_SEVERITY_MINOR = 0.15,
		DIRECTOR_SEVERITY_MODERATE = 0.25,
		DIRECTOR_SEVERITY_MAJOR = 0.15,
		DIRECTOR_SEVERITY_ANTAG = 0.2,
		DIRECTOR_SEVERITY_GHOST = 0.15,
	)
	max_quiet_time = 10 MINUTES
	quiet_intensity_threshold = 30
	roundstart_budget_min = 45
	roundstart_budget_max = 60

/datum/director_profile/extended
	round_type = ROUNDTYPE_EXTENDED
	base_drip = 0.4
	intensity_cap = 40
	max_active_major = 0
	// Самый мягкий профиль: экста - фоновые раунды, события должны разбавлять, а не вести игру.
	// Паузы шире дефолта (жалобы "4-5 ивентов за 10 минут"), глобальная пауза режет очереди,
	// мешающие играть события почти выключены множителями навязчивости.
	severity_spacing = list(
		DIRECTOR_SEVERITY_FLAVOR = 8 MINUTES,
		DIRECTOR_SEVERITY_MINOR = 6 MINUTES,
		DIRECTOR_SEVERITY_MODERATE = 12 MINUTES,
		DIRECTOR_SEVERITY_MAJOR = 25 MINUTES,
	)
	global_spacing = 3 MINUTES
	family_spacing = 15 MINUTES
	disruption_weight_mults = list(
		DIRECTOR_DISRUPTION_AMBIENT = 1,
		DIRECTOR_DISRUPTION_MILD = 0.4,
		DIRECTOR_DISRUPTION_DISRUPTIVE = 0.08,
	)
	pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.55,
		DIRECTOR_SEVERITY_MINOR = 0.4,
		DIRECTOR_SEVERITY_MODERATE = 0.05,
		DIRECTOR_SEVERITY_MAJOR = 0,
		DIRECTOR_SEVERITY_ANTAG = 0,
		DIRECTOR_SEVERITY_GHOST = 0,
	)
	max_quiet_time = 20 MINUTES
	quiet_intensity_threshold = 15
	roundstart_budget_min = 0
	roundstart_budget_max = 0

/// Профиль для типа раунда; ROUNDTYPE_DYNAMIC (рандом) отдаёт medium как основу.
/proc/director_profile_for(round_type)
	for(var/datum/director_profile/path as anything in subtypesof(/datum/director_profile))
		if(initial(path.round_type) == round_type)
			return new path
	return new /datum/director_profile/medium
