/// Ступени тяжести действий директора
#define DIRECTOR_SEVERITY_FLAVOR "flavor"
#define DIRECTOR_SEVERITY_MINOR "minor"
#define DIRECTOR_SEVERITY_MODERATE "moderate"
#define DIRECTOR_SEVERITY_MAJOR "major"
/// Пул антаг-инжекций (midround/latejoin рулсеты)
#define DIRECTOR_SEVERITY_ANTAG "antag"

/// Вид действия
#define DIRECTOR_KIND_EVENT "event"
#define DIRECTOR_KIND_RULESET "ruleset"

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

/// Причины отсева кандидатов на бите (диагностика "почему тихо" в бит-логе и панели)
#define DIRECTOR_REJECT_BLOCKED "blocked"
#define DIRECTOR_REJECT_EVENTS_OFF "events_off"
#define DIRECTOR_REJECT_INTENSITY_CAP "intensity_cap"
#define DIRECTOR_REJECT_EVAC "evac"
#define DIRECTOR_REJECT_DEAD_CRISIS "dead_crisis"
#define DIRECTOR_REJECT_MAJOR_CAP "major_cap"
#define DIRECTOR_REJECT_SPACING "spacing"
#define DIRECTOR_REJECT_BUDGET "budget"
#define DIRECTOR_REJECT_CAN_FIRE "can_fire"
#define DIRECTOR_REJECT_NO_WEIGHT "no_weight"

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
#define DIRECTOR_CANTFIRE_SPECIAL "special"
