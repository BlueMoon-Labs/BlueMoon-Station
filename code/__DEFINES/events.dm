#define SUCCESSFUL_SPAWN 2
#define NOT_ENOUGH_PLAYERS 3
#define MAP_ERROR 4
#define WAITING_FOR_SOMETHING 5

/// Event timer in seconds
#define EVENT_SECONDS *0.5

#define EVENT_CANT_RUN 0
#define EVENT_READY 1
#define EVENT_CANCELLED 2
#define EVENT_INTERRUPTED 3

///Events that mess with or create artificial intelligences, such as vending machines and the AI itself
#define EVENT_CATEGORY_AI "AI issues"
///Events that spawn anomalies, which might be the source of anomaly cores
#define EVENT_CATEGORY_ANOMALIES "Anomalies"
///Events that spawn portal a portal or something like that
#define EVENT_CATEGORY_SPAWNERS "Spawners"
///Events pertaining cargo, messages incoming to the station and job slots
#define EVENT_CATEGORY_BUREAUCRATIC "Bureaucratic"
///Events that cause breakages and malfunctions that could be fixed by engineers
#define EVENT_CATEGORY_ENGINEERING "Engineering"
///Events that spawn creatures with simple desires, such as to hunt
#define EVENT_CATEGORY_ENTITIES "Entities"
///Events that should have no harmful effects, and might be useful to the crew
#define EVENT_CATEGORY_FRIENDLY "Friendly"
///Events that affect the body and mind
#define EVENT_CATEGORY_HEALTH "Health"
///Events reserved for special occassions
#define EVENT_CATEGORY_HOLIDAY "Holiday"
///Events with enemy groups with a more complex plan
#define EVENT_CATEGORY_INVASION "Invasion"
///Events that make a mess
#define EVENT_CATEGORY_JANITORIAL "Janitorial"
///Events that summon meteors and other debris, and stationwide waves of harmful space weather
#define EVENT_CATEGORY_SPACE "Space Threats"
///Events summoned by a wizard
#define EVENT_CATEGORY_WIZARD "Wizard"

/// Return from admin setup to stop the event from triggering entirely.
#define ADMIN_CANCEL_EVENT "cancel event"

// ---------------------------------------------------------------------------
// Фазы космического явления
// ---------------------------------------------------------------------------

/**
 * Явление за бортом идёт тремя фазами, и это не украшение: от фазы считается
 * интенсивность, а от интенсивности - и картинка в иллюминаторе, и всё воздействие
 * на станцию. Голый activeFor подтипам не выдаётся, чтобы длительность фаз можно
 * было менять, не переписывая каждое явление.
 */
#define PHENOMENON_PHASE_NONE 0
/// Явление подходит: слабое воздействие, время подготовиться.
#define PHENOMENON_PHASE_APPROACH 1
/// Пик: максимум и возможности, и риска.
#define PHENOMENON_PHASE_PEAK 2
/// Уход: воздействие гаснет, собранное остаётся, несобранное пропадает.
#define PHENOMENON_PHASE_DEPARTURE 3

/// Потолок интенсивности на подходе. Он же нижняя точка пика - кривая непрерывна.
#define PHENOMENON_APPROACH_TOP 0.35
/// Интенсивность на стыке пика и ухода.
#define PHENOMENON_DEPARTURE_TOP 0.7
/// Доля пика, за которую он выходит на единицу (и столько же на спад с неё).
#define PHENOMENON_PEAK_RAMP 0.33

/// Насколько должна измениться интенсивность, чтобы каркас перетянул цвет сцены.
/// Без порога плато пика анимировало бы слои каждый тик в тот же самый цвет.
#define PHENOMENON_TINT_STEP 0.05
/// Длительность перетяжки цвета. Совпадает с тиком директора, поэтому переходы стыкуются.
#define PHENOMENON_TINT_TIME (2 SECONDS)
/// Затухание пикового слоя на выходе из пика.
#define PHENOMENON_PEAK_FADE_TIME (5 SECONDS)
