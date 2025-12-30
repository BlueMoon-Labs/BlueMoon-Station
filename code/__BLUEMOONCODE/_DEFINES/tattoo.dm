// Дефайны для системы татуировок

// Кастомные зоны для интимных татуировок (не стандартные BODY_ZONE)
#define TATTOO_ZONE_GROIN "groin"
#define TATTOO_ZONE_BUTT "butt"
#define TATTOO_ZONE_PUSSY "pussy"
#define TATTOO_ZONE_TESTICLES "testicles"
#define TATTOO_ZONE_BREASTS "breasts"
#define TATTOO_ZONE_PENIS "penis"
#define TATTOO_ZONE_LIPS "lips"

/// Специальный флаг покрытия для губ (проверяет маски через flags_cover)
#define TATTOO_COVERED_MOUTH "mouth"

/// Все интимные зоны татуировок (хранятся на BODY_ZONE_CHEST)
#define TATTOO_INTIMATE_ZONES list(TATTOO_ZONE_GROIN, TATTOO_ZONE_BUTT, TATTOO_ZONE_PUSSY, TATTOO_ZONE_TESTICLES, TATTOO_ZONE_BREASTS, TATTOO_ZONE_PENIS, TATTOO_ZONE_LIPS)
