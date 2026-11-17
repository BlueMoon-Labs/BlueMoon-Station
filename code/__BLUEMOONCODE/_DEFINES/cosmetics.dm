// Дефайны косметики (лак для ногтей)

/// Слой лака: над кистями (HANDS_PART_LAYER), но под перчатками (GLOVES_LAYER).
#define NAIL_POLISH_LAYER (HANDS_PART_LAYER - 0.5)
/// Сколько красить ногти другому.
#define NAIL_POLISH_APPLY_TIME (2 SECONDS)
/// Сколько мыть руку мылом, чтобы оттереть лак.
#define NAIL_POLISH_SCRUB_TIME (4 SECONDS)
/// Сколько ацетона надо плеснуть на руки, чтобы растворить лак.
#define NAIL_POLISH_ACETONE_VOLUME 5
