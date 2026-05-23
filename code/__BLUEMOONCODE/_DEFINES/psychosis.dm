// Раскомментировать для расследования (логи в data/logs/psychosis_debug.log).
//#define PSYCHOSIS_DEBUG_LOG

// Уровни тяжести объявлены здесь (а не в modular_bluemoon/.../psychosis.dm),
// чтобы быть доступными до включения unit_tests в DME.
#define PSYCHOSIS_TIER_MILD     1
#define PSYCHOSIS_TIER_MODERATE 2
#define PSYCHOSIS_TIER_SEVERE   3

// По достижении порога picker начинает выдавать эффекты следующего tier.
#define PSYCHOSIS_MILD_THRESHOLD     0
#define PSYCHOSIS_MODERATE_THRESHOLD (30 SECONDS)
#define PSYCHOSIS_SEVERE_THRESHOLD   (90 SECONDS)

// Множитель веса для типов с совпадающей темой при выборке.
#define PSYCHOSIS_THEME_BIAS 3

// Темы вынесены сюда по той же причине, что и tier-уровни выше.
#define PSYCHOSIS_THEME_STALKER     "stalker"
#define PSYCHOSIS_THEME_MASSACRE    "massacre"
#define PSYCHOSIS_THEME_RITUAL      "ritual"
#define PSYCHOSIS_THEME_WHISPERING  "whispering"
#define PSYCHOSIS_THEME_CHILDREN    "children"
#define PSYCHOSIS_THEME_MACHINERY   "machinery"
