// -- Chem Dispenser defines --

/// Base power efficiency for standard chem dispensers (1 unit costs ~15 charge)
#define CHEM_DISPENSER_BASE_EFFICIENCY 0.0666666
/// Power efficiency bonus per matter bin rating level
#define CHEM_DISPENSER_EFFICIENCY_PER_RATING 0.0166666666
/// Base power efficiency for apothecary dispensers (less efficient)
#define CHEM_DISPENSER_APOTHECARY_EFFICIENCY 0.0833333
/// Base energy recharge amount per cycle
#define CHEM_DISPENSER_BASE_RECHARGE 300
/// Number of process() ticks between recharge cycles
#define CHEM_DISPENSER_RECHARGE_INTERVAL 4
/// Base internal storage volume (multiplied by matter bin rating)
#define CHEM_DISPENSER_BASE_STORAGE 200
/// Minimum playtime (in minutes) before anti-grief alerts stop
#define CHEM_DISPENSER_GRIEF_PLAYTIME_THRESHOLD 480
/// Cooldown between anti-grief admin alerts
#define CHEM_DISPENSER_GRIEF_ALERT_COOLDOWN (15 MINUTES)
/// Maximum recipe tier for auto-dispensing
#define CHEM_RECIPE_MAX_TIER 6
/// Tier value indicating recipe requires emag (not reachable via manipulator upgrades)
#define CHEM_RECIPE_EMAG_TIER 6
/// Maximum batch multiplier for recipe dispensing (supports large beakers up to 900u)
#define CHEM_RECIPE_MAX_BATCH 300

// -- Dispenser type flags (for cross-dispenser recipe analysis) --
/// Standard chemistry dispenser
#define DISPENSER_TYPE_CHEM   (1<<0)
/// Soda dispenser (non-alcoholic drinks)
#define DISPENSER_TYPE_SODA   (1<<1)
/// Booze dispenser (alcoholic drinks)
#define DISPENSER_TYPE_BOOZE  (1<<2)
/// Both drink dispensers combined
#define DISPENSER_TYPE_DRINKS (DISPENSER_TYPE_SODA | DISPENSER_TYPE_BOOZE)
