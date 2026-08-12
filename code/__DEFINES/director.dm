/// Ступени тяжести действий директора
#define DIRECTOR_SEVERITY_FLAVOR "flavor"
#define DIRECTOR_SEVERITY_MINOR "minor"
#define DIRECTOR_SEVERITY_MODERATE "moderate"
#define DIRECTOR_SEVERITY_MAJOR "major"
/// Пул антаг-инжекций из живого экипажа (crew-миды и latejoin-рулсеты)
#define DIRECTOR_SEVERITY_ANTAG "antag"
/// Пул гост-антагонистов: рулсеты, чьи игроки приходят из призраков (required_type = observer)
#define DIRECTOR_SEVERITY_GHOST "ghost"

/// Обе антаг-ступени: общие гейты (эвакуация, dead_crisis, недобор СБ) бьют по обеим
#define DIRECTOR_IS_ANTAG_POOL(sev) ((sev) == DIRECTOR_SEVERITY_ANTAG || (sev) == DIRECTOR_SEVERITY_GHOST)

/// Вид действия
#define DIRECTOR_KIND_EVENT "event"
#define DIRECTOR_KIND_RULESET "ruleset"

/// Уровни навязчивости действий: насколько запуск мешает играть (director_action.disruption).
/// Мягкие профили режут вес по этой метке через profile.disruption_weight_mults.
#define DIRECTOR_DISRUPTION_AMBIENT "ambient"
#define DIRECTOR_DISRUPTION_MILD "mild"
#define DIRECTOR_DISRUPTION_DISRUPTIVE "disruptive"

/// Отделы для staffing-подсчёта
#define DIRECTOR_DEPT_SECURITY "security"
#define DIRECTOR_DEPT_ENGINEERING "engineering"
#define DIRECTOR_DEPT_MEDICAL "medical"
#define DIRECTOR_DEPT_SCIENCE "science"
#define DIRECTOR_DEPT_SUPPLY "supply"
#define DIRECTOR_DEPT_COMMAND "command"

/// Статус эвакуации для сигналов
#define DIRECTOR_EVAC_NONE 0
#define DIRECTOR_EVAC_CALLED 1
#define DIRECTOR_EVAC_GONE 2

/// Результаты бита
#define DIRECTOR_BEAT_FIRED "fired"
#define DIRECTOR_BEAT_GUARANTEED "guaranteed"
#define DIRECTOR_BEAT_BLOCKED "blocked"
#define DIRECTOR_BEAT_IDLE "idle"
#define DIRECTOR_BEAT_CANCELLED "cancelled"
/// Рулсет принят директором и поставлен на исполнение (опрос/выдача роли ещё впереди)
#define DIRECTOR_BEAT_SCHEDULED "scheduled"
/// Отложенный рулсет действительно выдал роль/запустился
#define DIRECTOR_BEAT_EXECUTED "executed"
/// Выбранное действие не прошло execute_action() либо отложенный запуск/опрос провалился
#define DIRECTOR_BEAT_FAILED "failed"

/// Причины отсева кандидатов на бите (диагностика "почему тихо" в бит-логе и панели)
#define DIRECTOR_REJECT_BLOCKED "blocked"
#define DIRECTOR_REJECT_EVENTS_OFF "events_off"
#define DIRECTOR_REJECT_INTENSITY_CAP "intensity_cap"
#define DIRECTOR_REJECT_EVAC "evac"
#define DIRECTOR_REJECT_DEAD_CRISIS "dead_crisis"
#define DIRECTOR_REJECT_MAJOR_CAP "major_cap"
#define DIRECTOR_REJECT_SPACING "spacing"
#define DIRECTOR_REJECT_FAMILY "family_spacing"
#define DIRECTOR_REJECT_GLOBAL "global_spacing"
#define DIRECTOR_REJECT_DISRUPTION "disruption"
#define DIRECTOR_REJECT_BUDGET "budget"
#define DIRECTOR_REJECT_CAN_FIRE "can_fire"
/// Рулсет прошёл can_fire(), но сейчас не наберёт кандидатов/контрролей или не имеет точки спауна
#define DIRECTOR_REJECT_READINESS "readiness"
#define DIRECTOR_REJECT_RECENT_FAILURE "recent_failure"
#define DIRECTOR_REJECT_NO_WEIGHT "no_weight"
/// Антаг-нагрузка достигла цели профиля (crew * antag_intensity_per_crew) - новых антагов не льём
#define DIRECTOR_REJECT_ANTAG_SATURATED "antag_saturated"
/// Пул копит кошелёк на выбранную цель (pool_saving) - дешёвые соседи по пулу ждут
#define DIRECTOR_REJECT_SAVING "saving"
/// Тяжёлые антаг-действия выключены профилем (Light/Extended: блоб-асолты не для фоновых раундов)
#define DIRECTOR_REJECT_ANTAG_HEAVY "antag_heavy_off"
/// Тяжёлая антаг-команда ждёт достаточно пустой раунд: живая нагрузка выше
/// profile.antag_heavy_load_fraction цели. Команда - главное блюдо пустого раунда, а не
/// довесок: рейдеры с intensity 45, купленные в запас 9.8, пробивали цель почти вдвое
/// и запирали антаг-каналы гейтом насыщения до конца смены (прод-раунд).
#define DIRECTOR_REJECT_ANTAG_HEADROOM "antag_headroom"

// --- Активность антагов (динамическая мера "как громко играет") ---
/// Полураспад score активности: тихие 10 минут - и буйный антаг снова считается обычным
#define DIRECTOR_ACTIVITY_HALF_LIFE (10 MINUTES)
/// Потолок score: дальше кап - один антаг не должен изображать нагрузку целого рулсета бесконечно
#define DIRECTOR_ACTIVITY_CAP 60
/// Бонус за атаку по игроку (log_combat): перестрелка с СБ быстро набирает счёт
#define DIRECTOR_ACTIVITY_ATTACK 2
/// Бонус за убийство игрока (death с атрибуцией lastattackerckey)
#define DIRECTOR_ACTIVITY_KILL 25
/// Бонус за объявление в розыск/на казнь (set_criminal_status): СБ уже занята этим антагом
#define DIRECTOR_ACTIVITY_WANTED 10
/// Множитель вклада в intensity: тихоня даёт минимум, буйный - до максимума.
/// Пол 0.5, а не 0.75: полностью пассивный антаг (прод-жалоба "4 трейтора ничего не вносят")
/// оставляет директору половину своего слота нагрузки - дефицитная антаг-капля доливает новых.
#define DIRECTOR_ACTIVITY_MULT_MIN 0.5
#define DIRECTOR_ACTIVITY_MULT_MAX 2
/// Делитель score при переводе в множитель: при капе 60 множитель ровно 0.5 + 60/40 = 2
#define DIRECTOR_ACTIVITY_MULT_SCALE 40

/// Вес присутствия члена отслеживаемой гост-команды вне станции: улетевшие с лутом рейдеры
/// или абдукторы на своей тарелке давят на клапан вполсилы, а не держат полную intensity
/// из любой точки мира (возрастное затухание добирает остальное).
#define DIRECTOR_OFFSTATION_ANTAG_MULT 0.5
/// Пол множителя веса лёгкой антаг-покупки по запасу цели (headroom / intensity): роль,
/// не влезающая в остаток цели, сильно уступает влезающим, но из выбора не исчезает.
#define DIRECTOR_HEADROOM_WEIGHT_FLOOR 0.25

/// Базовый вклад в antag_load живого жёсткого антага, не отслеживаемого рулсетом или гост-ролью
/// (выдан админом/жетоном, спавнер карты, обращённый культом/ревами). Тир лёгкого соло-антага;
/// домножается на antag_activity_mult, поэтому тихий = 0.5x, буйный = до 2x.
#define DIRECTOR_UNTRACKED_ANTAG_INTENSITY 15
/// Имя строки untracked-источника в разбивке antag_load: под ним панель показывает суммарный
/// вклад антагов вне рулсетов/гост-ролей ("от кого нагрузка" при вербовке и админ-выдачах).
#define DIRECTOR_UNTRACKED_SOURCE_NAME "Антаги вне рулсетов (вербовка/админ)"

/// Псевдо-ступень в reject_stats бита, отсечённого глобальной паузой: гейт бьёт по всем ступеням сразу
#define DIRECTOR_REJECT_SEV_ALL "all"

/// Вердикты оценки пула действий для панели (поверх причин DIRECTOR_REJECT_*)
#define DIRECTOR_VERDICT_OK "ok"
#define DIRECTOR_VERDICT_LATEJOIN "latejoin"

/// Расшифровка DIRECTOR_REJECT_CAN_FIRE по полям базового контракта (для панели)
#define DIRECTOR_CANTFIRE_DISABLED "disabled"
#define DIRECTOR_CANTFIRE_ADMIN_ONLY "admin_only"
#define DIRECTOR_CANTFIRE_OCCURRENCES "max_occurrences"
#define DIRECTOR_CANTFIRE_EARLY "early"
#define DIRECTOR_CANTFIRE_MIN_PLAYERS "min_players"
#define DIRECTOR_CANTFIRE_ROUND_TYPE "round_type"
#define DIRECTOR_CANTFIRE_STAFFING "staffing"
/// Событие недоступно из-за режима Summon Events (wizardmode): обычные события заглушены,
/// пока активен маг, и наоборот - wizard-события доступны только в этом режиме.
#define DIRECTOR_CANTFIRE_WIZARDMODE "summon_events"
/// Событие привязано к празднику, которого сейчас нет (holidayID)
#define DIRECTOR_CANTFIRE_HOLIDAY "holiday"
#define DIRECTOR_CANTFIRE_SPECIAL "special"
