#define HERETIC_HAMMER_START 3
#define HERETIC_HAMMER_CAPACITY 8
#define HERETIC_HAMMER_ASCENDED_CAPACITY 12
#define HERETIC_HAMMER_HIT_GAIN_GAP (1 SECONDS)
/// Одной рукой удары копят Накал вдвое реже.
#define HERETIC_HAMMER_ONEHAND_GAIN_GAP (HERETIC_HAMMER_HIT_GAIN_GAP * 2)
/// Накал стынет на единицу за каждые столько секунд без удара по живому врагу.
#define HERETIC_HAMMER_COOL_TIME (12 SECONDS)
/// Вода или пена на теле гасят Накал в ноль и столько не дают его копить.
#define HERETIC_HAMMER_QUENCH_TIME (4 SECONDS)
#define HERETIC_HAMMER_GRASP_HEAT 2
#define HERETIC_HAMMER_FORCE 18
#define HERETIC_HAMMER_WIELDED_FORCE 33
#define HERETIC_HAMMER_WIELDED_AP MELEE_AP_ANTAGONIST
#define HERETIC_HAMMER_ONEHAND_AP (HERETIC_HAMMER_WIELDED_AP / 2)
#define HERETIC_HAMMER_WIELDED_WOUND_BONUS 15
#define HERETIC_HAMMER_ATTACK_SPEED (CLICK_CD_MELEE * 1.25)
/// Стойка кузнеца: пока Молот в двух руках, ушибы и ожоги от ударов и снарядов слабее на столько процентов.
#define HERETIC_HAMMER_STANCE_CUT 20
/// Оглушение и падение в стойке короче на столько процентов, с Несокрушимым - на HERETIC_HAMMER_UNBROKEN_STUN_CUT.
#define HERETIC_HAMMER_STANCE_STUN_CUT 30
#define HERETIC_HAMMER_UNBROKEN_STUN_CUT 50
/// Жар горна: удар в двух руках по живому врагу с разумом лечит столько ушибов и ожогов.
#define HERETIC_HAMMER_FORGE_HEAL 4
/// Во сколько раз Молот в двух руках сильнее бьёт постройки, машины, окна, шлюзы и мехи.
#define HERETIC_HAMMER_OBJECT_MULT 3
#define HERETIC_HAMMER_GREAT_MACHINE_MULT 4

#define HERETIC_HAMMER_SWING_WINDUP (1 SECONDS)
#define HERETIC_HAMMER_SWING_WINDOW (4 SECONDS)
#define HERETIC_HAMMER_SWING_COOLDOWN (4 SECONDS)
#define HERETIC_HAMMER_SWING_SLOWDOWN 1
#define HERETIC_HAMMER_CRUSH_DAMAGE 20
#define HERETIC_HAMMER_CRUSH_THROW 3
#define HERETIC_HAMMER_SLAM_DAMAGE 12
#define HERETIC_HAMMER_SLAM_KNOCKDOWN (1.5 SECONDS)
#define HERETIC_HAMMER_SLAM_OTHER_KNOCKDOWN (1 SECONDS)

#define HERETIC_HAMMER_BRAND_LIMIT 6
#define HERETIC_HAMMER_BRAND_RANGE 2
#define HERETIC_HAMMER_BRAND_WELD_TIME (2 SECONDS)
#define HERETIC_HAMMER_BRAND_NOTICE_GAP (1 MINUTES)

#define HERETIC_HAMMER_RAM_COST 2
#define HERETIC_HAMMER_RAM_FREE_COOLDOWN (30 SECONDS)
#define HERETIC_HAMMER_RAM_RANGE 5
#define HERETIC_HAMMER_RAM_KNOCKDOWN (1.5 SECONDS)
#define HERETIC_HAMMER_RAM_COOLDOWN (6 SECONDS)
#define HERETIC_HAMMER_RAM_DOOR_DAMAGE 60

#define HERETIC_HAMMER_NAIL_COST 2
#define HERETIC_HAMMER_NAIL_TIME (12 SECONDS)
#define HERETIC_HAMMER_NAIL_PRY_TIME (3 SECONDS)
/// Каждый удар Молота еретика по вбитому сокращает вбивку на столько.
#define HERETIC_HAMMER_NAIL_HIT_CUT (2 SECONDS)
#define HERETIC_HAMMER_NAIL_SINK -4
#define HERETIC_HAMMER_CAPTURE "hammer_nail"

#define HERETIC_HAMMER_QUAKE_COST 3
#define HERETIC_HAMMER_QUAKE_WINDUP (0.6 SECONDS)
#define HERETIC_HAMMER_QUAKE_NEAR_DAMAGE 15
#define HERETIC_HAMMER_QUAKE_NEAR_KNOCKDOWN (1 SECONDS)
#define HERETIC_HAMMER_QUAKE_RANGE 3
#define HERETIC_HAMMER_QUAKE_STAMINA 25
#define HERETIC_HAMMER_QUAKE_SLOW (2 SECONDS)
#define HERETIC_HAMMER_QUAKE_COOLDOWN (12 SECONDS)
#define HERETIC_HAMMER_CRACKS_TIME (20 SECONDS)

#define HERETIC_HAMMER_GRASP_THROW 2
/// Окно «подхвата»: снова взяв Молот в две руки после Хватки, вы бьёте Сокрушающим без Замаха.
#define HERETIC_HAMMER_CATCH_TIME (3 SECONDS)

#define HERETIC_HAMMER_MARK_CRACKS 3
/// Метка без трещин видна приглушённо.
#define HERETIC_HAMMER_MARK_FAINT_ALPHA 90
#define HERETIC_HAMMER_SHATTER_TIME (10 SECONDS)
#define HERETIC_HAMMER_SHATTER_ARMOR 40
#define HERETIC_HAMMER_SHATTER_KNOCKDOWN (1 SECONDS)

#define HERETIC_HAMMER_ANVIL_COST 3
#define HERETIC_HAMMER_ANVIL_RANGE 7
#define HERETIC_HAMMER_ANVIL_TELEGRAPH (1.2 SECONDS)
#define HERETIC_HAMMER_ANVIL_DAMAGE 35
#define HERETIC_HAMMER_ANVIL_KNOCKDOWN (2 SECONDS)
#define HERETIC_HAMMER_ANVIL_SPLASH_STAMINA 10
#define HERETIC_HAMMER_ANVIL_LIFETIME (15 SECONDS)
#define HERETIC_HAMMER_ANVIL_INTEGRITY 100
#define HERETIC_HAMMER_ANVIL_COOLDOWN (15 SECONDS)

#define HERETIC_HAMMER_STAMINA_CUT 40
/// Ярость кузни: падение или паралич дольше этого срока сокращаются до него.
#define HERETIC_HAMMER_RAGE_LIMIT (1 SECONDS)
#define HERETIC_HAMMER_RAGE_HEAT 3

#define HERETIC_HAMMER_FISSURE_COST 4
#define HERETIC_HAMMER_FISSURE_WINDUP (0.8 SECONDS)
#define HERETIC_HAMMER_FISSURE_LENGTH 6
/// Трещина Раскола добегает до следующей клетки за этот срок.
#define HERETIC_HAMMER_FISSURE_STEP_DELAY (0.1 SECONDS)
#define HERETIC_HAMMER_FISSURE_DAMAGE 20
#define HERETIC_HAMMER_FISSURE_KNOCKDOWN (1.5 SECONDS)
#define HERETIC_HAMMER_FISSURE_COOLDOWN (25 SECONDS)

#define HERETIC_HAMMER_SHOCKWAVE_DAMAGE 12
#define HERETIC_HAMMER_GREAT_PROJECTILE_CUT 50
/// Стойка и Великий Молот вместе ослабляют снаряды не больше чем на столько процентов.
#define HERETIC_HAMMER_PROJECTILE_CUT_CAP 60
#define HERETIC_HAMMER_HOT_ANVILS 3
#define HERETIC_HAMMER_HOT_ANVIL_INTEGRITY 200
#define HERETIC_HAMMER_HOT_ANVIL_DOUSES 3
/// Ведро воды разом: столько единиц воды или пены за одно касание остужают наковальню целиком.
#define HERETIC_HAMMER_HOT_ANVIL_BUCKET 30
#define HERETIC_HAMMER_HOT_ANVIL_BURN 10
#define HERETIC_HAMMER_HOT_ANVIL_HEAL 2
#define HERETIC_HAMMER_TOLL_PERIOD (90 SECONDS)
#define HERETIC_HAMMER_ANVIL_ALERT "heretic_hammer_anvils"

#define HERETIC_HAMMER_HIT_SFX "heretic_hammer_hit"
#define HERETIC_HAMMER_GRASP_SFX "heretic_hammer_grasp"
#define HERETIC_HAMMER_ICON 'modular_bluemoon/icons/obj/heretic_hammer.dmi'
#define HERETIC_HAMMER_FX_ICON 'modular_bluemoon/icons/obj/heretic_hammer_fx.dmi'
#define HERETIC_HAMMER_LARGE_ICON 'modular_bluemoon/icons/obj/heretic_hammer_large.dmi'
/// Привычка к весу: громоздкое в руках не замедляет.
#define TRAIT_HERETIC_HAMMER_HEFT "heretic_hammer_heft"
