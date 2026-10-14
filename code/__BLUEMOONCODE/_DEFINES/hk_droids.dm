#define SPECIES_HK "hk_droid"
#define SPECIES_HK47 "hk_droid_47"
#define SPECIES_HK50 "hk_droid_50"
#define SPECIES_HK51 "hk_droid_51"

#define HK_MODEL_47 "hk47"
#define HK_MODEL_50 "hk50"
#define HK_MODEL_51 "hk51"

#define HK_ARMOR 25
#define HK50_ARMOR 15
#define HK_EMP_HEAVY_SEVERITY 50
#define HK_EMP_HEAVY_STUN (5 SECONDS)
#define HK_EMP_LIGHT_STUN (2.5 SECONDS)
#define HK_EMP_STUN_COOLDOWN (15 SECONDS)
/// Удар HK-51 оглушает реже, чем у HK-47: шасси экипажа не сильнее офицера в жилете.
#define HK51_PUNCH_STUN_THRESHOLD 18
/// Перепрошитый HK: каналы R и B меняются местами, и янтарные глаза светятся голубым.
#define HK_REPROGRAMMED_EYE_MATRIX list(0,0,1, 0,1,0, 1,0,0)
#define HK_LOYALTY_READER_JOBS list("Roboticist", "Research Director")

/// Глаза HK в крите гаснут и загораются раз в столько тиков Life
#define HK_EYE_BLINK_TICKS 2

#define HK_PREFIX_STATEMENT "Утверждение:"
#define HK_PREFIX_QUERY "Вопрос:"
#define HK_PREFIX_EXCLAMATION "Восклицание:"

/// Хозяин HK сменился: (datum/mind/new_master, datum/mind/old_master)
#define COMSIG_HK_MASTER_CHANGED "hk_master_changed"

#define HK_RIFLE_SHOTS 12
#define HK_RIFLE_SHOT_COST 100
#define HK_RIFLE_FIRE_DELAY (0.8 SECONDS)
#define HK_RIFLE_RECHARGE_TIME (4 SECONDS)
#define HK_RIFLE_NUTRITION_PER_SHOT 15
#define HK_RIFLE_MIN_NUTRITION 50

#define HK47_SNIPER_AIM_TIME (1.5 SECONDS)
#define HK47_SNIPER_DAMAGE 60
#define HK47_SNIPER_ARMOUR_PENETRATION 40
/// Сколько обычных выстрелов винтовки стоит снайперский.
#define HK47_SNIPER_SHOT_CHARGES 3
#define HK47_SNIPER_COOLDOWN (10 SECONDS)
/// Маскировка HK-47 включена: пеленгатор теряет сигнал.
#define TRAIT_HK47_DISGUISED "hk47_disguised"

#define HK47_VOICE_VOLUME 60
#define HK47_VOICE_EXTRA_RANGE 2
