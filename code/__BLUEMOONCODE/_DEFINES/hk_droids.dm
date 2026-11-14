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
#define FACTION_HK_DROIDS "hk_droids"
#define HK50_LINE_COOLDOWN (8 SECONDS)
#define HK50_EMP_HEAVY_SEVERITY 50
#define HK50_EMP_HEAVY_BURN 30
#define HK50_EMP_HEAVY_STUN (3 SECONDS)
#define HK50_EMP_LIGHT_BURN 15
#define HK50_EMP_LIGHT_STUN (1.5 SECONDS)
#define HK50_SERVANT_PAIR_SIZE 2
#define HK50_SERVANT_LIFETIME (5 MINUTES)
#define HK50_SERVANT_FOLLOW_DISTANCE 2
#define HK50_SERVANT_SELF_DESTRUCT_DELAY (3 SECONDS)
/// Хозяин слуги HK-50 в блэкборде ИИ
#define BB_HK50_MASTER "BB_hk50_master"
#define HK50_VOICE_VOLUME 55
/// Хозяин слуг HK-50 дольше этого на другом уровне - пара догоняет его на двигателях.
#define HK50_SERVANT_CATCH_UP_DELAY (5 SECONDS)
#define HK50_PHOTORECEPTOR_CHANCE 25
/// Игрок HK-50 с разумом без клиента дольше этого - тело предлагают другому призраку.
#define HK50_GHOST_SERVANT_AWAY_TIME (150 SECONDS)
#define HK_FACTORY_MAX_DROIDS 6
#define HK_FACTORY_ASSEMBLY_DELAY (3 MINUTES)
/// Стойки засады мигают и лязгают столько, прежде чем выпустить дроидов.
#define HK_FACTORY_AMBUSH_WARNING (1.8 SECONDS)
/// Сколько стража, поднятая автономным протоколом, обыскивает щитовую.
#define HK_FACTORY_PROTOCOL_SEARCH_TIME (90 SECONDS)
#define HK_FACTORY_PATROL_REACH 16
/// Блэкборд патрульного HK-50: концы маршрута и текущая цель.
#define BB_HK50_PATROL_ENDS "BB_hk50_patrol_ends"
#define BB_HK50_PATROL_HEADING "BB_hk50_patrol_heading"
#define HK_LOYALTY_CHIP_TIME (4 SECONDS)

/// Внутренний голос HK-47 в чате: янтарный моноширинный, как его терминал.
#define span_hk47(str) ("<span class='hk47'>" + (str) + "</span>")
#define HK_PREFIX_STATEMENT "Утверждение:"
#define HK_PREFIX_QUERY "Вопрос:"
#define HK_PREFIX_EXCLAMATION "Восклицание:"
#define HK_PREFIX_ANALYSIS "Анализ:"

/// Хозяин HK сменился: (datum/mind/new_master, datum/mind/old_master)
#define COMSIG_HK_MASTER_CHANGED "hk_master_changed"

#define HK_RIFLE_SHOTS 12
#define HK_RIFLE_SHOT_COST 100
#define HK_RIFLE_FIRE_DELAY (0.8 SECONDS)
#define HK_RIFLE_RECHARGE_TIME (4 SECONDS)
#define HK_RIFLE_NUTRITION_PER_SHOT 15
#define HK_RIFLE_MIN_NUTRITION 50

#define HK51_PART_PRICE_MIN 1500
#define HK51_PART_PRICE_MAX 2500
#define HK51_MARKET /datum/blackmarket_market/blackmarket
/// Место части HK-51, выставленной лотом на чёрный рынок.
#define HK51_PLACE_BLACK_MARKET "black_market"
/// Контейнеры руин, в которые части HK-51 не кладутся: тайник может взорваться или улететь.
#define HK51_EXCLUDED_CONTAINERS list(/obj/structure/closet/crate/secure/loot, /obj/structure/closet/supplypod)
#define HK51_NAME "HK-51"
#define HK51_ASSIGNMENT "HK-51 Assassin Droid"
#define HK51_PART_COUNT 5
#define HK51_POLL_TIME (30 SECONDS)
#define HK51_ACTIVATION_RETRY (2 MINUTES)
#define HK51_VOICE_COOLDOWN (8 SECONDS)
/// Реплика о верности звучит после строки диагностики, а не поверх неё.
#define HK51_LOYALTY_LINE_DELAY (8.5 SECONDS)
#define HK51_COMBAT_CALM_TIME (60 SECONDS)
#define HK51_BODYGUARD_MARK_TIME (10 SECONDS)
/// Повторный сигнал о том же нападавшем на хозяина - не чаще этого.
#define HK51_BODYGUARD_REPEAT (5 SECONDS)
#define HK47_RIVAL_OFFER_CHANCE 50
#define HK47_RIVAL_POINTS 2

#define HK47_SNIPER_AIM_TIME (1.5 SECONDS)
#define HK47_SNIPER_AIM_RANGE 12
#define HK47_SNIPER_DAMAGE 60
#define HK47_SNIPER_ARMOUR_PENETRATION 40
/// Сколько обычных выстрелов винтовки стоит снайперский.
#define HK47_SNIPER_SHOT_CHARGES 3
#define HK47_SNIPER_COOLDOWN (10 SECONDS)
#define HK47_PLATES_ARMOR 10
#define HK47_DISGUISE_NAME "протокольный дроид"
#define HK47_DISGUISE_COOLDOWN (30 SECONDS)
#define HK47_DISGUISE_GREET_RANGE 2
/// Маскировка HK-47 включена: пеленгатор теряет сигнал.
#define TRAIT_HK47_DISGUISED "hk47_disguised"
#define HK47_THRUSTER_NUTRITION_PER_TILE 1
/// Ниже этого заряда двигатели и самовосстановление не работают, как и подзарядка винтовки.
#define HK47_UPGRADE_MIN_NUTRITION HK_RIFLE_MIN_NUTRITION
#define HK47_REPAIR_DELAY (15 SECONDS)
#define HK47_REPAIR_PER_SECOND 1.5
#define HK47_REPAIR_HEALTH_CAP 0.7
#define HK47_REPAIR_NUTRITION_PER_HP 2
#define HK47_REPAIR_WOUND_TIME (10 SECONDS)
#define HK47_REPAIR_WOUND_NUTRITION 10
#define HK47_GHOST_SERVANT_POLL_TIME (30 SECONDS)
#define HK47_TRACKER_NEAR 8
#define HK47_TRACKER_MID 24
/// Где сигнал относительно пеленгатора в связке уровней.
#define HK47_LEVEL_SAME "same"
#define HK47_LEVEL_ABOVE "above"
#define HK47_LEVEL_BELOW "below"

#define HK47_NAME "HK-47"
#define HK47_CONTRACTS_TO_WIN 3

#define HK_CONTRACT_OFFERED "offered"
#define HK_CONTRACT_ACTIVE "active"
#define HK_CONTRACT_DONE "done"
#define HK_CONTRACT_FAILED "failed"
#define HK_CONTRACT_REFUSED "refused"
#define HK_CONTRACT_DROPPED "dropped"

#define HK_CLIENT_SYNDICATE "syndicate"
#define HK_CLIENT_CORP "corp"
#define HK_CLIENT_PRIVATE "private"
#define HK_CLIENT_CENTCOM "cc"

/// Контракт HK-47 выполнен, шлётся телу HK до удаления контракта: (datum/hk_contract/contract, witnessed)
#define COMSIG_HK47_CONTRACT_COMPLETED "hk47_contract_completed"

#define HK47_CONTRACT_OFFERS 3
#define HK47_MODIFIER_CHANCE 50
#define HK47_MODIFIER_POINTS 1
#define HK47_REROLL_COOLDOWN (3 MINUTES)
#define HK47_OFFER_RETRY_COOLDOWN (30 SECONDS)
#define HK47_SCAN_TIME (5 SECONDS)
#define HK47_SCAN_RANGE 1
#define HK47_CAPTURE_RETURN_TIME (3 MINUTES)
#define HK47_PROTECT_TIME (15 MINUTES)
#define HK47_URGENT_TIME (10 MINUTES)
#define HK47_WITNESS_RANGE 7
/// Сколько удар или выстрел считается причиной смерти: попадания HK и слуг для модификаторов и лицензии, чужие - для журнала убийств охоты.
#define HK47_HIT_MEMORY (30 SECONDS)
/// Сколько напавший на HK или охраняемого считается нападавшим: его убийство лицензию не отзывает.
#define HK47_AGGRESSION_MEMORY (30 SECONDS)
/// След цели охоты старше этого считается остывшим.
#define HK47_TRACE_COLD_TIME (10 MINUTES)
#define HK47_HUNT_NEAR_RANGE 5
#define HK47_IDENTIFY_RANGE 2
#define HK47_IDENTIFY_COOLDOWN (20 SECONDS)
/// Подозреваемый прозрачнее этого считается невидимым для сверки сигнатуры.
#define HK47_STEALTH_ALPHA 60
/// Шанс, что первые предложения партии пойдут по командованию и СБ.
#define HK47_ROLE_PRIORITY_CHANCE 50
/// Капсула захвата ждёт цель столько, затем улетает пустой.
#define HK47_CAPTURE_POD_WAIT (3 MINUTES)
/// Доставка в бриг засчитывается, только если HK тащит цель или стоит не дальше этого.
#define HK47_BRIG_ESCORT_RANGE 7
/// Охрана: как часто терминал сверяет, рядом ли HK с подопечным, на каком расстоянии и какую долю срока.
#define HK47_PROTECT_SAMPLE (10 SECONDS)
#define HK47_PROTECT_RANGE 7
#define HK47_PROTECT_PRESENCE_PERCENT 40
#define HK47_LICENSE_PRESENT_COOLDOWN (3 SECONDS)
/// Пара HK-50 конкурента ищет посадку для капсулы в этом радиусе от своей цели.
#define HK47_RIVAL_LANDING_RANGE 4
#define HK47_RIVAL_FACTION "hk50_rival"
#define HK47_RIVAL_DEPART_DELAY (5 SECONDS)
/// Прибавка к оценке цели для HK-50 конкурента: подопечный или сам HK-47 перебивает любую другую.
#define HK47_RIVAL_MARK_SCORE 1000
#define HK47_SYNDICATE_BONUS_POINTS 1
/// Вещи, которыми корпорация доплачивает за контракт.
#define HK47_CORP_REWARD_ITEMS list(/obj/item/storage/box/zipties, /obj/item/grenade/smokebomb, /obj/item/grenade/flashbang, /obj/item/weldingtool/largetank)
/// Сколько помнится список фирменных вещей на станции: поиск по миру дорогой.
#define HK47_RELIC_CACHE_TIME (10 MINUTES)
/// Фирменные вещи отделов из целей кражи предателя: кража ценности ищет их на станции.
#define HK47_THEFT_RELICS list(/obj/item/gun/energy/laser/captain, /obj/item/hand_tele, /obj/item/clothing/shoes/magboots/advance, /obj/item/hypospray/mkii/CMO, /obj/item/clothing/suit/armor/reactive, /obj/item/gun/energy/e_gun/hos, /obj/item/clothing/suit/hooded/ablative, /obj/item/areaeditor/blueprints, /obj/item/storage/belt/utility/chief, /obj/item/clothing/accessory/medal/gold/captain)
/// Машины саботажа по видам: вид выбирается поровну, чтобы не выпадали одни серверы телекомов.
#define HK47_SABOTAGE_TYPES list(/obj/machinery/rnd/server, /obj/machinery/telecomms/server, /obj/machinery/telecomms/hub, /obj/machinery/computer/upload, /obj/machinery/computer/communications, /obj/machinery/power/smes, /obj/machinery/clonepod)
/// Антаги, о которых станции объявляют: охота HK может выйти на них без других улик.
#define HK47_OVERT_ANTAG_TYPES list(/datum/antagonist/wizard, /datum/antagonist/nukeop, /datum/antagonist/ninja)
/// Камеры, доставка в которые закрывает охоту ЦК на задержание.
#define HK47_BRIG_AREAS list(/area/security/brig, /area/security/brig_cells, /area/security/prison)
#define HK47_VOICE_COOLDOWN (8 SECONDS)
#define HK47_VOICE_VOLUME 60
#define HK47_VOICE_EXTRA_RANGE 2
/// Сколько занят вокабулятор, если длину файла прочитать не удалось (в деплое без звуков на диске).
#define HK_VOICE_LINE_FALLBACK_LENGTH (5 SECONDS)
/// «Режим боя» звучит на первом выстреле или ударе после стольких секунд без боя.
#define HK47_COMBAT_CALM_TIME (60 SECONDS)
/// Ниже этой доли прочности HK сообщает о тяжёлых повреждениях.
#define HK47_DAMAGE_LINE_HEALTH 0.5
/// Цены модулей шасси по порядку установки: первый, второй, ... последняя держится дальше.
#define HK47_MODULE_PRICES list(1, 1, 2, 2, 3)
/// Цена пары HK-50 по номеру вызова.
#define HK47_SERVANT_PRICES list(1, 2, 3)
#define HK47_GHOST_SERVANT_MIN_CONTRACTS 2

/// Статус HK-47 для станции; первые три - легенды прибытия.
#define HK47_STATUS_COVERT "covert"
#define HK47_STATUS_LICENSED "licensed"
#define HK47_STATUS_BODYGUARD "bodyguard"
#define HK47_STATUS_OUTLAW "outlaw"
/// Лицензия закончилась вместе с контрактом, под который её выдали.
#define HK47_STATUS_EXPIRED "expired"
/// ЦК закрыл все дела HK без лицензии: станция о нём знает, но розыска нет.
#define HK47_STATUS_PARDONED "pardoned"
#define HK47_LEGEND_WEIGHTS list(HK47_STATUS_COVERT = 2, HK47_STATUS_LICENSED = 1, HK47_STATUS_BODYGUARD = 1)
/// Аванс заказчика тайному HK-47: прикрытия у него нет, первый модуль ставится сразу после посадки.
#define HK47_COVERT_ADVANCE_POINTS 1
/// Доля урона выносливости по шасси HK-47 поверх брони шасси: дубинки и дизейблеры валят его медленнее, ЭМИ - как прежде.
#define HK47_STAMINA_MOD 0.6
#define HK47_SPIKE_HACK_TIME (6 SECONDS)
#define HK47_SPIKE_HACK_NUTRITION 25
#define HK47_SPIKE_CARD_TIME (1 SECONDS)
#define HK47_SPIKE_SKIM_TIME (4 SECONDS)
/// Сколько оплавленная щупом панель шлюза выдаёт взлом при осмотре.
#define HK47_HACK_TRACE_TIME (10 MINUTES)
#define HK47_ACCESS_PROFILES 3
#define HK47_STUN_BOLT_STAMINA 35
#define HK47_SHIELD_ARMOR 40
#define HK47_SHIELD_DURATION (8 SECONDS)
#define HK47_SHIELD_COOLDOWN (60 SECONDS)
#define HK47_SHIELD_NUTRITION 100
#define HK47_REPAIR_KIT_HEAL 40
#define HK47_REPAIR_KIT_TIME (4 SECONDS)
#define HK47_REPAIR_KITS_PER_ORDER 2
#define HK47_CRASH_CHANCE 50
#define HK47_CRASH_FALL_TIME (3 SECONDS)
#define HK47_CRASH_FALL_HEIGHT 256
/// Насколько в сторону уходит начало падения: болид заходит наискось и виден сбоку.
#define HK47_CRASH_FALL_DRIFT 160
#define HK47_CRASH_TRAIL_STEP (0.1 SECONDS)
#define HK47_CRASH_TRAIL_FADE (2 SECONDS)
#define HK47_CRASH_RUMBLE_RANGE 15
#define HK47_CRASH_PARALYZE (3 SECONDS)
#define HK47_CARGO_AREAS list(/area/cargo/storage, /area/cargo/office, /area/cargo)
#define HK47_TRACKER_AREAS list(/area/security/brig, /area/security/office, /area/security)
/// Раскрытие, после которого в бриг летит пеленгатор, а карго получает заказ на ядро.
#define HK47_TRACKER_REVEAL 2
/// Раскрытие, после которого СБ приказано уничтожить HK, а в бриг летит ионное оружие.
#define HK47_EXECUTE_REVEAL 3
#define HK47_CORE_BOUNTY_REWARD 15000
#define HK47_EXTRACTION_TIME (60 SECONDS)
/// Прерванный сигнал эвакуации можно подать снова только через это время.
#define HK47_EXTRACTION_RETRY_COOLDOWN (90 SECONDS)
#define HK47_BEACON_PULSE (0.6 SECONDS)
#define HK47_BEACON_DIM_ALPHA 90
/// Строка «готов служить» ждёт, пока доиграет «вижу, вы меня купили».
#define HK47_REPROGRAM_READY_DELAY (6 SECONDS)
