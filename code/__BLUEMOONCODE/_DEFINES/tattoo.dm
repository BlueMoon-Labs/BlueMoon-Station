// Дефайны для системы татуировок

// Кастомные зоны для интимных татуировок (не стандартные BODY_ZONE)
#define TATTOO_ZONE_GROIN "groin"
#define TATTOO_ZONE_BUTT "butt"
#define TATTOO_ZONE_PUSSY "pussy"
#define TATTOO_ZONE_TESTICLES "testicles"
#define TATTOO_ZONE_BREASTS "breasts"
#define TATTOO_ZONE_PENIS "penis"
#define TATTOO_ZONE_LIPS "lips"
#define TATTOO_ZONE_HORNS "horns"
#define TATTOO_ZONE_TAIL "tail"
#define TATTOO_ZONE_LEFT_THIGH "left_thigh"
#define TATTOO_ZONE_RIGHT_THIGH "right_thigh"
#define TATTOO_ZONE_EARS "ears"
#define TATTOO_ZONE_WINGS "wings"
#define TATTOO_ZONE_BELLY "belly"
#define TATTOO_ZONE_CHEEKS "cheeks"
#define TATTOO_ZONE_FOREHEAD "forehead"
#define TATTOO_ZONE_CHIN "chin"
#define TATTOO_ZONE_LEFT_HAND "left_hand"
#define TATTOO_ZONE_RIGHT_HAND "right_hand"
#define TATTOO_ZONE_LEFT_FOOT "left_foot"
#define TATTOO_ZONE_RIGHT_FOOT "right_foot"

/// Специальный флаг покрытия для губ (проверяет маски через flags_cover)
#define TATTOO_COVERED_MOUTH "mouth"

/// Специальный флаг покрытия для щёк (проверяет HIDEFACE на маске/шлеме через flags_inv)
#define TATTOO_COVERED_FACE "face"

/// Специальный флаг покрытия для хвоста (проверяет HIDETAUR на костюме через flags_inv)
#define TATTOO_COVERED_TAIL "tail"

/// Все интимные зоны татуировок (хранятся на BODY_ZONE_CHEST)
#define TATTOO_INTIMATE_ZONES list(TATTOO_ZONE_GROIN, TATTOO_ZONE_BUTT, TATTOO_ZONE_PUSSY, TATTOO_ZONE_TESTICLES, TATTOO_ZONE_BREASTS, TATTOO_ZONE_PENIS, TATTOO_ZONE_LIPS, TATTOO_ZONE_HORNS, TATTOO_ZONE_TAIL, TATTOO_ZONE_LEFT_THIGH, TATTOO_ZONE_RIGHT_THIGH, TATTOO_ZONE_EARS, TATTOO_ZONE_WINGS, TATTOO_ZONE_BELLY, TATTOO_ZONE_CHEEKS, TATTOO_ZONE_FOREHEAD, TATTOO_ZONE_CHIN, TATTOO_ZONE_LEFT_HAND, TATTOO_ZONE_RIGHT_HAND, TATTOO_ZONE_LEFT_FOOT, TATTOO_ZONE_RIGHT_FOOT)
