#define AIRLOCK_POWERON_LIGHT_COLOR "#3aa7c2"
#define AIRLOCK_BOLTS_LIGHT_COLOR "#c22323"
#define AIRLOCK_ACCESS_LIGHT_COLOR "#57e69c"
#define AIRLOCK_EMERGENCY_LIGHT_COLOR "#d1d11d"
#define AIRLOCK_ENGINEERING_LIGHT_COLOR "#ED760E"
#define AIRLOCK_MEDICAL_LIGHT_COLOR "#9400D3"
#define AIRLOCK_SECURITY_LIGHT_COLOR "#E40B0B"
#define AIRLOCK_DENY_LIGHT_COLOR "#c22323"

// Задержка от начала анимации до освобождения прохода у шлюзов и фаерлоков.
#define DOOR_OPENING_PASSABLE_DELAY (0.1 SECONDS)

// Ограничивает повторные отказы при столкновении; клики и открытие с доступом не задерживает.
#define AIRLOCK_DENY_COOLDOWN (1 SECONDS)
