// Дефайны для системы портальных игрушек
// BLUEMOON: Expanded Portal Toy System

// Portal connection modes
#define PORTAL_MODE_PUBLIC    "public"      // Публичный режим - любой может подключиться
#define PORTAL_MODE_PRIVATE   "private"     // Приватный режим - только выбранный партнёр
#define PORTAL_MODE_GROUP     "group"       // Групповой режим - через сеть по приглашению
#define PORTAL_MODE_DISABLED  "disabled"    // Отключено - подключения запрещены

// Vibration patterns
#define VIBE_PATTERN_CONSTANT   "constant"    // Постоянная вибрация
#define VIBE_PATTERN_PULSE      "pulse"       // Пульсация с паузами
#define VIBE_PATTERN_WAVE       "wave"        // Волнообразная (синусоида)
#define VIBE_PATTERN_RANDOM     "random"      // Случайная интенсивность
#define VIBE_PATTERN_ESCALATE   "escalate"    // Постепенное усиление
#define VIBE_PATTERN_HEARTBEAT  "heartbeat"   // Ритм ускоряется с возбуждением
#define VIBE_PATTERN_TEASE      "tease"       // Дразнящая - редкие неожиданные импульсы

/// List of all valid vibration patterns for validation
#define PORTAL_VALID_PATTERNS list(\
	VIBE_PATTERN_CONSTANT,\
	VIBE_PATTERN_PULSE,\
	VIBE_PATTERN_WAVE,\
	VIBE_PATTERN_RANDOM,\
	VIBE_PATTERN_ESCALATE,\
	VIBE_PATTERN_HEARTBEAT,\
	VIBE_PATTERN_TEASE\
)

// Mood/status indicators
#define PORTAL_MOOD_IDLE      "idle"        // Синий - в ожидании
#define PORTAL_MOOD_ACTIVE    "active"      // Розовый - активен
#define PORTAL_MOOD_AROUSED   "aroused"     // Красный - сильное возбуждение
#define PORTAL_MOOD_CLIMAX    "climax"      // Фиолетовый - оргазм
#define PORTAL_MOOD_DND       "dnd"         // Серый - не беспокоить

// Control modes (D/s)
#define PORTAL_CONTROL_SELF       "self"      // Самоконтроль - только владелец управляет
#define PORTAL_CONTROL_PARTNER    "partner"   // Подчинение - только партнёр управляет

// Quick messages (default presets)
// Templates: {partner}, {me}, {intensity}, {mood}
#define PORTAL_QUICK_MESSAGES list(\
	"Мммм~",\
	"Ещё!",\
	"Помедленнее...",\
	"Не останавливайся!",\
	"Я близко...",\
	"*стон*",\
	"Сильнее, {partner}!",\
	"Так хорошо~"\
)

// Network settings
#define PORTAL_NETWORK_MAX_MEMBERS 10

// Network sensation relay
/// Sensation types for network relay
#define PORTAL_SENSATION_VIBRATION  "vibration"
#define PORTAL_SENSATION_EDGING     "edging"
#define PORTAL_SENSATION_CLIMAX     "climax"

/// Minimum interval between vibration relays to prevent spam
#define PORTAL_NETWORK_RELAY_INTERVAL   2 SECONDS
/// Only relay vibrations at this intensity or higher
#define PORTAL_NETWORK_VIBRATION_THRESHOLD 5

// Vibration settings
#define PORTAL_VIBE_MIN_INTENSITY 1
#define PORTAL_VIBE_MAX_INTENSITY 10
#define PORTAL_RELAY_MIN 25
#define PORTAL_RELAY_MAX 100

// Public emotes (3x3 area)
#define PORTAL_EMOTES_ENABLED_DEFAULT TRUE
#define PORTAL_EMOTE_COOLDOWN 30 SECONDS
#define PORTAL_EMOTE_MIN_INTENSITY 7  // Only show emotes at intensity 7+

// Эмоции с двумя формами: "third" - для других (3-е лицо), "self" - для себя (2-е лицо)
#define PORTAL_PUBLIC_EMOTES list(\
	list("third" = "слегка вздрагивает", "self" = "слегка вздрагиваете"),\
	list("third" = "краснеет", "self" = "краснеете"),\
	list("third" = "прерывисто дышит", "self" = "прерывисто дышите"),\
	list("third" = "нервно ёрзает", "self" = "нервно ёрзаете"),\
	list("third" = "закусывает губу", "self" = "закусываете губу"),\
	list("third" = "зажмуривается", "self" = "зажмуриваетесь")\
)

#define PORTAL_CLIMAX_EMOTES list(\
	list("third" = "вздрагивает всем телом", "self" = "вздрагиваете всем телом"),\
	list("third" = "громко выдыхает", "self" = "громко выдыхаете"),\
	list("third" = "на мгновение замирает", "self" = "на мгновение замираете")\
)

// Edging mode settings
#define PORTAL_EDGING_ENABLED_DEFAULT FALSE
#define PORTAL_EDGING_THRESHOLD 0.8  // Activate at 80% of climax threshold
#define PORTAL_EDGING_INTENSITY_REDUCTION 3  // Reduce intensity by this much

// Настройка приватности для публичного режима
#define PORTAL_PRIVACY_COUNT_ONLY  "count_only"    // Показывать только количество подключённых
#define PORTAL_PRIVACY_SHOW_NAMES  "show_names"    // Показывать никнеймы всех подключённых
