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
/// Maximum recipe tier for auto-dispensing (matches max manipulator rating)
#define CHEM_RECIPE_MAX_TIER 6
