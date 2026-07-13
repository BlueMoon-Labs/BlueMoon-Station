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
	/// Короткое описание идентичности профиля для вкладки "Профили" панели
	var/desc = ""
	/// Очков бюджета в минуту до множителей (событийные кошельки FLAVOR..MAJOR)
	var/base_drip = 1
	/// Очков в минуту в антаг-кошельки (ANTAG + GHOST, делится по pool_shares) при ПОЛНОМ
	/// дефиците антаг-нагрузки; реальная скорость = antag_drip * (1 - load/target).
	/// Раунд без живых антагов наполняется полным ходом, насыщенный не копит вовсе.
	/// Калибровка Medium: при типичном дефиците ~0.5 кошелёк ANTAG собирает лёгкую
	/// инжекцию (6-8) за 20-30 минут - раньше на долях от общей капли выходило 40-80.
	var/antag_drip = 0.9
	/// Стартовый аванс кошельков: раскладывается по pool_shares при setup_profile(). С нулевого
	/// старта первое MODERATE набиралось только к ~25 минуте - аванс оживляет первые полчаса,
	/// не меняя крейсерский темп (капля та же).
	var/initial_grant = 10
	/// Кривая множителя от минут раунда: list(list(минута, множитель), ...).
	/// Старт 0.6 и колено на 15-й минуте: прежние 0.4/20 держали первые полчаса пустыми.
	var/list/time_curve = list(list(0, 0.6), list(15, 1), list(90, 1), list(120, 0.6))
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
	/// Пауза латеджойн-канала (инжекция в окно захода игрока): трек независим от полосы битов -
	/// латеджойн не запирает биты и наоборот, темп канала держит только эта пауза и дефицит.
	var/latejoin_spacing = 8 MINUTES
	/// Целевые доли ступеней при выборе: severity -> доля (сумма ~1).
	/// Сумма ANTAG + GHOST - общая доля антагонистов раунда; баланс между экипажными
	/// и гост-инжекциями тюнится их соотношением.
	/// FLAVOR стоит 0, его доля размазывается поровну по остальным (distribute_to_budgets) -
	/// большая доля флейвора кормила дешёвый MINOR, пока MAJOR (cost 20) копил на запуск
	/// три часа и "не имел шансов появиться". Крен в тяжёлые ступени, суммарная капля та же.
	var/list/pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.15,
		DIRECTOR_SEVERITY_MINOR = 0.25,
		DIRECTOR_SEVERITY_MODERATE = 0.25,
		DIRECTOR_SEVERITY_MAJOR = 0.15,
		DIRECTOR_SEVERITY_ANTAG = 0.12,
		DIRECTOR_SEVERITY_GHOST = 0.08,
	)
	/// Затишье: если дольше этого не было запусков и intensity ниже порога - гарантированный бит
	var/max_quiet_time = 12 MINUTES
	var/quiet_intensity_threshold = 25
	/// Целевая антаг-нагрузка на голову эффективного экипажа: клапан антаг-давления.
	/// Нагрузка ниже половины цели удваивает долю антаг-пулов в капле (недоукомплектованный
	/// раундстарт на большом онлайне добирается инжекциями), нагрузка на цели - останавливает
	/// накопление и блокирует антаг-действия в битах/латеджойне. Живой лёгкий антаг = 15:
	/// при 1.5 цель на 40 экипажа = 60 = ~4 живых лёгких антага.
	var/antag_intensity_per_crew = 1.5
	/// Доступны ли профилю тяжёлые антаг-действия (antag_heavy: нюк-асолт, блоб, ксено, терор).
	/// FALSE у фоновых профилей (Light/Extended): там командный асолт не "редкий", а неуместный.
	var/antag_heavy_enabled = TRUE
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

/// Слепок всех ручек для вкладки "Профили" панели. Времена в минутах (окно отмены в секундах).
/datum/director_profile/proc/panel_snapshot()
	var/list/spacing_out = list()
	for(var/sev in severity_spacing)
		spacing_out[sev] = round(severity_spacing[sev] / (1 MINUTES), 0.1)
	return list(
		"roundType" = round_type,
		"desc" = desc,
		"baseDrip" = base_drip,
		"antagDrip" = antag_drip,
		"initialGrant" = initial_grant,
		"roundstartMin" = roundstart_budget_min,
		"roundstartMax" = roundstart_budget_max,
		"timeCurve" = time_curve,
		"popCurve" = pop_curve,
		"intensityCap" = intensity_cap,
		"maxActiveMajor" = max_active_major,
		"severitySpacing" = spacing_out,
		"globalSpacing" = round(global_spacing / (1 MINUTES), 0.1),
		"familySpacing" = round(family_spacing / (1 MINUTES), 0.1),
		"antagLightSpacing" = round(antag_light_spacing / (1 MINUTES), 0.1),
		"antagHeavySpacing" = round(antag_heavy_spacing / (1 MINUTES), 0.1),
		"ghostLightSpacing" = round(ghost_light_spacing / (1 MINUTES), 0.1),
		"ghostHeavySpacing" = round(ghost_heavy_spacing / (1 MINUTES), 0.1),
		"latejoinSpacing" = round(latejoin_spacing / (1 MINUTES), 0.1),
		"poolShares" = pool_shares,
		"disruptionMults" = disruption_weight_mults,
		"antagPerCrew" = antag_intensity_per_crew,
		"antagHeavyEnabled" = antag_heavy_enabled,
		"maxQuiet" = round(max_quiet_time / (1 MINUTES), 0.1),
		"quietThreshold" = quiet_intensity_threshold,
		"securityPerPlayers" = security_per_players,
		"securityPenaltyMult" = security_penalty_mult,
		"deadFractionThreshold" = dead_fraction_threshold,
		"adminCancelTime" = round(admin_cancel_time / (1 SECONDS), 0.1),
		"repeatPenalty" = repeat_penalty,
	)

/datum/director_profile/light
	round_type = ROUNDTYPE_DYNAMIC_LIGHT
	desc = "Ступень между Extended и Medium: антаги и средние события живут, но крупных событий и тяжёлых антаг-команд нет, мешающие играть события приглушены."
	base_drip = 0.6
	antag_drip = 0.4
	latejoin_spacing = 15 MINUTES
	intensity_cap = 60
	max_active_major = 0
	// Идентичность Light - ступень между Extended и Medium, а не копия одного из них:
	// в отличие от Extended антаги и moderate-события живут, в отличие от Medium - никаких
	// MAJOR и тяжёлых антаг-команд, мягче мешающие события (mults) и реже тяжёлые запуски.
	antag_heavy_enabled = FALSE
	// Цель нагрузки ниже медиумных 1.5: на 40 экипажа = 36 = 2-3 лёгких антага, не 4.
	antag_intensity_per_crew = 0.9
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
	// Доли антаг-пулов подняты с 0.06/0.04: при капле 0.6/мин те копили cost 8-10 по полтора часа,
	// то есть антагов на Light не существовало вовсе. Light - это "редко и мягко", а не "никогда".
	pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.3,
		DIRECTOR_SEVERITY_MINOR = 0.3,
		DIRECTOR_SEVERITY_MODERATE = 0.22,
		DIRECTOR_SEVERITY_MAJOR = 0,
		DIRECTOR_SEVERITY_ANTAG = 0.1,
		DIRECTOR_SEVERITY_GHOST = 0.08,
	)
	max_quiet_time = 15 MINUTES
	quiet_intensity_threshold = 20
	initial_grant = 8
	roundstart_budget_min = 8
	roundstart_budget_max = 15

/datum/director_profile/medium
	round_type = ROUNDTYPE_DYNAMIC_MEDIUM
	desc = "Базовый темп директора: все значения - дефолты, от них отсчитываются остальные профили."
	// все значения - дефолты базы

/datum/director_profile/hard
	round_type = ROUNDTYPE_DYNAMIC_HARD
	desc = "Плотный раунд: больше живых антагов одновременно, разгон с первых минут, крен долей из фонового шума в угрозы."
	base_drip = 1.5
	antag_drip = 1.4
	latejoin_spacing = 5 MINUTES
	intensity_cap = 140
	max_active_major = 2
	global_spacing = 1 MINUTES
	family_spacing = 6 MINUTES
	// Hard - не "быстрый Medium", а плотный раунд: больше живых антагов одновременно
	// (2.2 на голову: на 40 экипажа цель 88 = ~6 лёгких или 2 тяжёлые команды со свитой),
	// разгон с первых минут (колено кривой на 10-й) и без спада до второго часа.
	antag_intensity_per_crew = 2.2
	time_curve = list(list(0, 0.7), list(10, 1), list(100, 1), list(130, 0.7))
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
	// Крен из флейвора в антаг-пулы и мажоры: хардовый час должен состоять из угроз,
	// фоновый шум пусть занимает паузы, а не долю кошелька.
	pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.1,
		DIRECTOR_SEVERITY_MINOR = 0.18,
		DIRECTOR_SEVERITY_MODERATE = 0.27,
		DIRECTOR_SEVERITY_MAJOR = 0.17,
		DIRECTOR_SEVERITY_ANTAG = 0.15,
		DIRECTOR_SEVERITY_GHOST = 0.13,
	)
	max_quiet_time = 8 MINUTES
	quiet_intensity_threshold = 30
	initial_grant = 15
	roundstart_budget_min = 30
	roundstart_budget_max = 45

/datum/director_profile/teambased
	round_type = ROUNDTYPE_DYNAMIC_TEAMBASED
	desc = "Одна большая война вместо парада одиночек: антаг-пулы забирают крупную долю капли, события служат фоном конфликта."
	base_drip = 0.8
	antag_drip = 1.1
	latejoin_spacing = 6 MINUTES
	intensity_cap = 140
	max_active_major = 2
	// Идентичность Teambased - одна большая война, а не парад одиночек: цель нагрузки 2.0
	// вмещает тяжёлую роундстарт-команду (45) со свитой, но не две команды разом; события
	// уступают долю антаг-пулам (0.4 на двоих) и служат фоном конфликта.
	antag_intensity_per_crew = 2
	// Антаг-доли профиля не прожать через дефолтные паузы 12/30 - антаг-треки чаще
	antag_light_spacing = 10 MINUTES
	antag_heavy_spacing = 25 MINUTES
	ghost_light_spacing = 10 MINUTES
	ghost_heavy_spacing = 25 MINUTES
	pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.1,
		DIRECTOR_SEVERITY_MINOR = 0.15,
		DIRECTOR_SEVERITY_MODERATE = 0.22,
		DIRECTOR_SEVERITY_MAJOR = 0.13,
		DIRECTOR_SEVERITY_ANTAG = 0.22,
		DIRECTOR_SEVERITY_GHOST = 0.18,
	)
	max_quiet_time = 10 MINUTES
	quiet_intensity_threshold = 30
	initial_grant = 12
	roundstart_budget_min = 45
	roundstart_budget_max = 60

/datum/director_profile/extended
	round_type = ROUNDTYPE_EXTENDED
	desc = "Фоновый профиль: события разбавляют игру, а не ведут её; из антагов - только штучные гост-спавнеры."
	base_drip = 0.4
	// Вся антаг-капля уходит в GHOST (доля ANTAG = 0): один мирный гост-спавнер (10) за ~час
	// хронического дефицита, что и есть штучный темп эксты.
	antag_drip = 0.15
	intensity_cap = 40
	max_active_major = 0
	// Самый мягкий профиль: экста - фоновые раунды, события должны разбавлять, а не вести игру.
	// Паузы шире дефолта (жалобы "4-5 ивентов за 10 минут"), глобальная пауза режет очереди,
	// мешающие играть события почти выключены множителями навязчивости.
	antag_heavy_enabled = FALSE
	// Гост-антаги на эксте по правилам проекта только мирные к экипажу (в авто-пуле беглецы и
	// синдикат-хранитель диска; враждебное - через OPFOR/форс админа), и штучно: цель 0.5 на
	// голову - один гост-антаг насыщает клапан на 30 экипажа, следующий - после его затухания.
	antag_intensity_per_crew = 0.5
	severity_spacing = list(
		DIRECTOR_SEVERITY_FLAVOR = 8 MINUTES,
		DIRECTOR_SEVERITY_MINOR = 6 MINUTES,
		DIRECTOR_SEVERITY_MODERATE = 12 MINUTES,
		DIRECTOR_SEVERITY_MAJOR = 25 MINUTES,
	)
	global_spacing = 3 MINUTES
	family_spacing = 15 MINUTES
	ghost_light_spacing = 25 MINUTES
	disruption_weight_mults = list(
		DIRECTOR_DISRUPTION_AMBIENT = 1,
		DIRECTOR_DISRUPTION_MILD = 0.4,
		DIRECTOR_DISRUPTION_DISRUPTIVE = 0.08,
	)
	// ANTAG (экипажные инжекции) на эксте нет вовсе - динамик не регистрирует рулсеты.
	// GHOST - события-спавнеры из призраков, единственный антаг-канал эксты.
	pool_shares = list(
		DIRECTOR_SEVERITY_FLAVOR = 0.45,
		DIRECTOR_SEVERITY_MINOR = 0.35,
		DIRECTOR_SEVERITY_MODERATE = 0.12,
		DIRECTOR_SEVERITY_MAJOR = 0,
		DIRECTOR_SEVERITY_ANTAG = 0,
		DIRECTOR_SEVERITY_GHOST = 0.08,
	)
	max_quiet_time = 20 MINUTES
	quiet_intensity_threshold = 15
	initial_grant = 0 // экста фоновая: первые полчаса без событий - это нормально
	roundstart_budget_min = 0
	roundstart_budget_max = 0

/// Профиль для типа раунда; ROUNDTYPE_DYNAMIC (рандом) отдаёт medium как основу.
/proc/director_profile_for(round_type)
	for(var/datum/director_profile/path as anything in subtypesof(/datum/director_profile))
		if(initial(path.round_type) == round_type)
			return new path
	return new /datum/director_profile/medium
