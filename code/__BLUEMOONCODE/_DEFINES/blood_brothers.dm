#define BROTHER_TEAM_START_SIZE 2
#define BROTHER_TEAM_MAX_SIZE 3
#define BLOOD_BOND_TIER_MAX 3
#define BROTHER_OATH_CHOICE_TIME (10 MINUTES)
#define BROTHER_OATH_OFFER_COUNT 3
#define BROTHER_RECRUIT_TIME (5 SECONDS)
#define BROTHER_RECRUIT_REFUSAL_COOLDOWN (5 MINUTES)
#define BROTHER_GHOST_GRACE (10 MINUTES)
/// Сколько брат может быть без клиента, прежде чем связь сочтёт его ушедшим
#define BROTHER_SSD_GRACE (15 MINUTES)
/// Как часто клятва ищет замену ушедшей цели, если сразу не нашла
#define BROTHER_TARGET_RETRY_INTERVAL (30 SECONDS)
#define BROTHER_WHISPER_LOG_SIZE 15
#define BROTHER_SENSE_INTERVAL (2 SECONDS)
/// Пороги Чутья в тайлах: до CLOSE брат «близко», до FAR «недалеко», дальше «далеко»
#define BROTHER_SENSE_RANGE_CLOSE 8
#define BROTHER_SENSE_RANGE_FAR 16
#define BROTHER_WHISPER_VOLUME 25
/// Сколько кандидат думает над кровной клятвой
#define BROTHER_RECRUIT_ANSWER_TIME (30 SECONDS)

/// Доля здоровья, ниже которой брат считается раненым
#define BROTHER_HURT_HEALTH_FRACTION 0.6
/// Ушибы от «Ранить брата» на полигоне: столько, чтобы Чутьё показало «ранен»
#define BROTHER_TRAINING_INJURY 50
#define BROTHER_NOTIFY_VOLUME 50
#define BROTHER_STINGER_VOLUME 100
#define BROTHER_SWORN_VOLUME 60
#define BROTHER_SEAL_VOLUME 45
#define BROTHER_SEVERED_VOLUME 60
/// Сколько священник читает обряд разрыва клятвы
#define BROTHER_SEVER_RITE_TIME (20 SECONDS)
#define BROTHER_SCAR_EXCISE_TIME (5 SECONDS)
/// Сколько после разрыва клятвы на ладони виден свежий шов или ожог
#define BROTHER_FRESH_SEAM_DURATION (15 MINUTES)

/// Множитель перезарядки связи, если обет цел к третьей печати
#define BROTHER_FLAWLESS_COOLDOWN_MULT 0.75
#define BROTHER_VOW_SHOULDER_RANGE 3
#define BROTHER_VOW_SHADOW_LIMIT (60 SECONDS)
/// Обет «Без крови» ломает смерть того, кого брат бил не раньше этого срока до смерти
#define BROTHER_VOW_BLOODLESS_WINDOW (30 SECONDS)
#define BROTHER_HEIST_STASH_RANGE 1
#define BROTHER_VENDETTA_HOLD_TIME (3 MINUTES)
#define BROTHER_VENDETTA_HOLD_RANGE 2
#define BROTHER_VENDETTA_VIOLENT_HARD_MULT 1.5
#define BROTHER_VENDETTA_VIOLENT_MEDIUM_MULT 1.2
#define BROTHER_LIBERATION_RANGE 3
#define BROTHER_LIBERATION_FREE_TIME (5 MINUTES)
#define BROTHER_EXPOSURE_RANGE 3
#define BROTHER_INITIATION_RANGE 2

#define BROTHER_SIGN_DRAW_TIME (4 SECONDS)
/// Знак братства: доля нормального объёма крови на один знак
#define BROTHER_SIGN_BLOOD_FRACTION 0.05
#define BROTHER_SIGN_BLOOD_COST (BLOOD_VOLUME_NORMAL * BROTHER_SIGN_BLOOD_FRACTION)
/// Сколько отделов одновременно метит второй шаг Знака братства
#define BROTHER_SIGN_DEPARTMENTS 3
#define BROTHER_COMPROMAT_PLANT_RANGE 3
/// Узелок клятв, где надо пройти через чужие двери
#define BROTHER_KIT_BREAKIN /obj/item/clothing/gloves/color/yellow, /obj/item/multitool, /obj/item/screwdriver, /obj/item/wirecutters, /obj/item/crowbar/red
/// Скорость взлома аварийного шаттла у братьев с клятвой Угона
#define BROTHER_HIJACK_SPEED 1

/// Кровь за кровь: доля нормального объёма крови, которую отдаёт донор
#define BROTHER_TRANSFUSION_FRACTION 0.15
#define BROTHER_TRANSFUSION_AMOUNT (BLOOD_VOLUME_NORMAL * BROTHER_TRANSFUSION_FRACTION)
/// Сколько ушибов и столько же ожогов лечит переливание: часть сразу, остальное по тикам
#define BROTHER_TRANSFUSION_HEAL 20
#define BROTHER_TRANSFUSION_TICKS 4
#define BROTHER_TRANSFUSION_OXY_HEAL 20
#define BROTHER_TRANSFUSION_TIME (3 SECONDS)
#define BROTHER_TRANSFUSION_VOLUME 40
/// Сколько после чужой крови нельзя отдавать свою
#define BROTHER_TRANSFUSION_RECEIVE_LOCK (3 MINUTES)
/// Ступень связи, с которой беда брата будит Ярость
#define BROTHER_FURY_TIER 2
#define BROTHER_FURY_DURATION (20 SECONDS)
#define BROTHER_FURY_COOLDOWN (3 MINUTES)
/// Множитель оглушения и урона выносливости под Яростью
#define BROTHER_FURY_RESIST_MULT 0.5
#define BROTHER_FURY_VOLUME 50
#define BROTHER_FALLEN_VOLUME 70
/// Слёзы в глазах при смерти брата; со стороны их не видно
#define BROTHER_GRIEF_BLUR 8
#define BROTHER_GRIEF_MOOD_TIME (20 MINUTES)

#define BROTHER_MARK_DURATION (30 SECONDS)
#define BROTHER_MARK_COLOR "#a01010"
/// Копия облика цели под Меткой лежит чуть ниже самой цели, наружу выглядывает только обводка
#define BROTHER_MARK_LAYER_OFFSET 0.01
/// Вспышки над братом поднимаются на полтайла, чтобы не закрывать лицо
#define BROTHER_EFFECT_RAISE 16
/// Длина анимации seal_flash
#define BROTHER_SEAL_FLASH_TIME (0.8 SECONDS)
#define BROTHER_STASH_MAX_ITEMS 5
#define BROTHER_BULWARK_DURATION (15 SECONDS)
#define BROTHER_BULWARK_RANGE 7
/// Доля ушибов и ожогов, которую подзащитный Заслона получает сам; столько же ложится на брата
#define BROTHER_BULWARK_SHARE 0.5
#define TRAIT_BROTHER_BULWARK "brother_bulwark"
#define BROTHER_SIGN_EYES_DURATION (10 SECONDS)
#define BROTHER_BLACKOUT_FLICKER_TIME (3 SECONDS)
#define BROTHER_BLACKOUT_FLICKERS 6
#define BROTHER_BLACKOUT_DURATION (20 SECONDS)
#define BROTHER_CIRCLE_RANGE 3
#define BROTHER_CIRCLE_HEAL 2
/// Круг троих лечит, только если никого из троих столько не ранили
#define BROTHER_CIRCLE_QUIET_TIME (10 SECONDS)
#define BROTHER_UNSHACKLE_VOLUME 50

#define BROTHER_STATE_OK "ok"
#define BROTHER_STATE_HURT "hurt"
#define BROTHER_STATE_CRIT "crit"
#define BROTHER_STATE_DEAD "dead"
#define BROTHER_STATE_CUFFED "cuffed"
#define BROTHER_STATE_MUTED "muted"
#define BROTHER_STATE_GONE "gone"
/// Только в окне: клятву брата разорвали обрядом или операцией
#define BROTHER_STATE_SEVERED "severed"
/// Нить между именами братьев в итогах раунда: целая и порванная
#define BROTHER_ROUNDEND_THREAD "-~-~-"
#define BROTHER_ROUNDEND_TORN "-~/ /~-"

#define BROTHER_DEPARTURE_CRYO "cryo"
#define BROTHER_DEPARTURE_GHOST "ghost"
#define BROTHER_DEPARTURE_DELETED "deleted"
#define BROTHER_DEPARTURE_SEVERED "severed"
#define BROTHER_DEPARTURE_SSD "ssd"

#define BROTHER_SEVER_RITE "rite"
#define BROTHER_SEVER_SURGERY "surgery"
#define BROTHER_SEVER_ADMIN "admin"

#define BLOOD_OATH_TRAIT "blood_oath"
#define TRAIT_BLOOD_OATH_SCAR "blood_oath_scar"
/// На разуме: его кровную клятву разорвали, братом он больше не станет
#define TRAIT_BLOOD_OATH_SEVERED "blood_oath_severed"

/// Должности, недоступные братьям: раскрывается в list(...) рулсетов и GLOB.brother_protected_roles
#define BROTHER_PROTECTED_ROLE_NAMES "Vanguard Operative", "NanoTrasen Representative", "Internal Affairs Agent", "Security Officer", "Blueshield", "Peacekeeper", "Brig Physician", "Warden", "Detective", "Head of Security", "Bridge Officer", "Captain", "Head of Personnel", "Quartermaster", "Chief Engineer", "Chief Medical Officer", "Research Director"

/// Отправляется команде братьев: (new_tier, old_tier)
#define COMSIG_BROTHER_TEAM_TIER_CHANGED "brother_team_tier_changed"
/// Отправляется команде братьев: (datum/blood_oath_step/sealed_step, datum/mind/sealer)
#define COMSIG_BROTHER_TEAM_STEP_SEALED "brother_team_step_sealed"
/// Отправляется команде братьев: (datum/blood_oath/oath)
#define COMSIG_BROTHER_TEAM_OATH_SWORN "brother_team_oath_sworn"
/// Отправляется команде братьев: (datum/mind/member)
#define COMSIG_BROTHER_TEAM_MEMBER_JOINED "brother_team_member_joined"
/// Отправляется команде братьев: (datum/mind/member, reason)
#define COMSIG_BROTHER_TEAM_MEMBER_LEFT "brother_team_member_left"
/// Отправляется команде братьев: (datum/mind/fallen)
#define COMSIG_BROTHER_TEAM_BROTHER_DIED "brother_team_brother_died"
/// Отправляется команде братьев после Крови за кровь: (mob/living/donor, mob/living/recipient)
#define COMSIG_BROTHER_BLOOD_GIVEN "brother_blood_given"
