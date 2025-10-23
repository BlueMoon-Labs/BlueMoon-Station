// ============================================================
// BlueMoon Knotting Defines //By Stasdvrz
// ============================================================

// --- Knotting state defines ---
#define KNOTTED_NULL 0
#define KNOTTED_AS_TOP 1
#define KNOTTED_AS_BTM 2

// Knotting balance caps
#ifndef KNOTTING_MAX_CHANCE
#define KNOTTING_MAX_CHANCE 80
#endif

// --- Global round stats key ---
#define STATS_KNOTTED "knottings"

GLOBAL_VAR_INIT(knottings, 0)
