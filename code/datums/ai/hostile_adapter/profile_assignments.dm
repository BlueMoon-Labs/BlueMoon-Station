// Явные назначения специализированных профилей hostile AI.
// Базовые hostile автоматически получают melee/ranged/charger-профиль;
// здесь централизованы только кластеры, которым нужен особый контроллер.

// --- Профильные назначения кластеров ---

///Мегафауна: боссовый профиль (peaceful/enemies-гейт внутри профиля)
/mob/living/simple_animal/hostile/megafauna
	ai_profile_type = /datum/ai_controller/hostile_adapter/boss

///Лавалендские элитки: боссовый профиль (таблицы способностей внутри профиля)
/mob/living/simple_animal/hostile/asteroid/elite
	ai_profile_type = /datum/ai_controller/hostile_adapter/boss

///Terror spiders: собственный профиль с декомпозированным idle-AI
/mob/living/simple_animal/hostile/retaliate/poison/terror_spider
	ai_profile_type = /datum/ai_controller/hostile_adapter/terror_spider

///Карпы охотятся стаей: делятся агро с сородичами
/mob/living/simple_animal/hostile/carp
	ai_profile_type = /datum/ai_controller/hostile_adapter/pack_hunter

///Honour guard наследует retaliate только технически: его Found() агрессивен.
/mob/living/simple_animal/hostile/retaliate/goat/guard
	ai_profile_type = /datum/ai_controller/hostile_adapter/guard_defender/aggressive_retaliate

///Gutlunch выбирает падаль и отступает, когда ранен.
/mob/living/simple_animal/hostile/asteroid/gutlunch
	ai_profile_type = /datum/ai_controller/hostile_adapter/coward_scavenger

///Crate-мимик ждёт в засаде; динамические копии сохраняют runtime ranged-флаг.
/mob/living/simple_animal/hostile/mimic
	ai_profile_type = /datum/ai_controller/hostile_adapter/ambusher/mimic

/mob/living/simple_animal/hostile/mimic/copy
	ai_profile_type = /datum/ai_controller/hostile_adapter/adaptive_hunter

///AI-artificer координирует ремонт союзных конструктов.
/mob/living/simple_animal/hostile/construct/builder/hostile
	ai_profile_type = /datum/ai_controller/hostile_adapter/support/artificer

///Конструкты: игровые оболочки (AIStatus = AI_OFF) остаются без контроллера;
///hostile-джаггернаут воюет базовым мили-профилем, hostile-рейт - танцем
///"ужалил-отскочил" из легаси retreat_distance.
/mob/living/simple_animal/hostile/construct/wraith
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/construct_wraith

///Goose: базовый retaliate-профиль + случайная ярость (сабтри goose_random_rage).
/mob/living/simple_animal/hostile/retaliate/goose
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/goose

///Snake: охота на мышей поверх retaliate-гейта (стратегия small_prey + скорер).
/mob/living/simple_animal/hostile/retaliate/poison/snake
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/snake

///Tentacles: неподвижный захватчик - бьёт вплотную, не преследует и не бродит.
/mob/living/simple_animal/hostile/tentacles
	ai_profile_type = /datum/ai_controller/hostile_adapter/stationary_grappler

///Curseblob преследует ТОЛЬКО свою жертву проклятия собственным forceMove-циклом.
/mob/living/simple_animal/hostile/asteroid/curseblob
	ai_profile_type = /datum/ai_controller/hostile_adapter/curseblob

///Goldgrub ест руду (search_objects/wanted_objects), а живых пугается и бежит.
/mob/living/simple_animal/hostile/asteroid/goldgrub
	ai_profile_type = /datum/ai_controller/hostile_adapter/coward_scavenger/goldgrub

///Wizard: кастер-скирмишер, заклинания делегацией AutomatedCast.
/mob/living/simple_animal/hostile/wizard
	ai_profile_type = /datum/ai_controller/hostile_adapter/ranged_skirmisher/wizard

///Гигантские пауки: мили-погоня + случайные перебежки (сабтри spider_idle_skitter);
///нянька дополнительно плетёт коконы/паутину/яйца (сабтри spider_nurse_cycle).
/mob/living/simple_animal/hostile/poison/giant_spider
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/giant_spider

/mob/living/simple_animal/hostile/poison/giant_spider/nurse
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/giant_spider/nurse

///Пчёлы: опыление через search_objects-путь (стратегия/скорер) + цикл улья
///(сабтри bee_hive_cycle); вход в улей и укусы - делегацией AttackingTarget.
/mob/living/simple_animal/hostile/poison/bees
	ai_profile_type = /datum/ai_controller/hostile_adapter/bee

///Морф: засадчик с idle-маскировкой (сабтри morph_disguise); раскрытие и
///пожирание - легаси Aggro()/AttackingTarget делегацией. Sandman - игровая
///роль с AIStatus = AI_OFF, контроллер не создаётся.
/mob/living/simple_animal/hostile/morph
	ai_profile_type = /datum/ai_controller/hostile_adapter/ambusher/morph

///Floor cluwne: сценарный сталкер с закреплённой жертвой; фазы ведёт Life(),
///контроллер только преследует (сабтри floor_cluwne_stalk).
/mob/living/simple_animal/hostile/floor_cluwne
	ai_profile_type = /datum/ai_controller/hostile_adapter/floor_cluwne

///AI-сварнеры маяка: боевой контур штатной машиной, фуражирский цикл
///(починка/репликация/постройки/поедание) - сабтри swarmer_forage.
/mob/living/simple_animal/hostile/swarmer/ai
	ai_profile_type = /datum/ai_controller/hostile_adapter/swarmer

/mob/living/simple_animal/hostile/swarmer/ai/resource
	ai_profile_type = /datum/ai_controller/hostile_adapter/swarmer/resource

/mob/living/simple_animal/hostile/swarmer/ai/ranged_combat
	ai_profile_type = /datum/ai_controller/hostile_adapter/swarmer/skirmisher

/mob/living/simple_animal/hostile/swarmer/ai/melee_combat
	ai_profile_type = /datum/ai_controller/hostile_adapter/swarmer/brawler

///Плачущий ангел: погоня замирает под взглядами (гейты can_be_seen).
/mob/living/simple_animal/hostile/statue
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/statue

///Insane clown: телепорт-сталкер с закреплённой жертвой (делегат stalk()).
/mob/living/simple_animal/hostile/retaliate/clown/insane
	ai_profile_type = /datum/ai_controller/hostile_adapter/insane_clown

///Крысиный король: вражда королей живёт в CanAttack (делегация стратегии),
///дела двора (riot/coffer) - сабтри regalrat_royal_duties.
/mob/living/simple_animal/hostile/regalrat
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/regalrat

///Крысы короля: служат ему наводками-контактами и грызут кабели.
/mob/living/simple_animal/hostile/rat
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/rat

///Gremlin: порча техники делегацией, поводок погони и вент-брождение - сабтри.
/mob/living/simple_animal/hostile/gremlin
	ai_profile_type = /datum/ai_controller/hostile_adapter/vent_hunter/gremlin

///Minebot: легаси-переключатели режимов + сабтри minebot_mode_sync.
/mob/living/simple_animal/hostile/mining_drone
	ai_profile_type = /datum/ai_controller/hostile_adapter/minebot

///Ксеноморфы: дрон и королева ведут дела улья (сорняки/яйца) сабтри с гейтом
///"нет цели"; охотник/горничная - база, сентинел - авто-скирмишер по флагам.
/mob/living/simple_animal/hostile/alien/drone
	ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser/alien_drone

/mob/living/simple_animal/hostile/alien/queen
	ai_profile_type = /datum/ai_controller/hostile_adapter/ranged_skirmisher/alien_queen

///Джунглевая фауна: фазовые машины атак делегацией. Мук и сидлинг замирают в
///фазах (jungle_phase_guard), леапер прыгает сабтри leaper_assault, мега-
///арахнид дышит кайт-бандом из BiologicalLife (mega_arachnid_band_sync).
/mob/living/simple_animal/hostile/jungle/mook
	ai_profile_type = /datum/ai_controller/hostile_adapter/ranged_chaser/jungle_staged

/mob/living/simple_animal/hostile/jungle/seedling
	ai_profile_type = /datum/ai_controller/hostile_adapter/ranged_chaser/jungle_staged

/mob/living/simple_animal/hostile/jungle/leaper
	ai_profile_type = /datum/ai_controller/hostile_adapter/leaper

/mob/living/simple_animal/hostile/jungle/mega_arachnid
	ai_profile_type = /datum/ai_controller/hostile_adapter/ranged_skirmisher/mega_arachnid

///Чумная крыса: вент-охотник
/mob/living/simple_animal/hostile/plaguerat
	ai_profile_type = /datum/ai_controller/hostile_adapter/vent_hunter

///Космический дракон: гост-роль, но живёт и без игрока (админ-спавн, гост
///из тела) - боссовый профиль. Без таблицы способностей огненное дыхание
///идёт легаси-сабтри boss_legacy_ranged через делегацию OpenFire; фаза
///крыло-порыва запирает движение через can_ai_controller_move. С клиентом
///контроллер штатно гаснет (COMSIG_MOB_CLIENT_LOGIN).
/mob/living/simple_animal/hostile/space_dragon
	ai_profile_type = /datum/ai_controller/hostile_adapter/boss

///Блоб-мобы (споры/зомби/блоббернавты) воюют базовым мили-профилем
///(наследуют дефолт melee_chaser, строка не нужна); приказ Rally Spores
///оверлорда ходит мостом receive_rally_order -> receive_combat_contact
///(точка сбора, не GPS-цель). Игровые блоббернавты гаснут контроллером
///при вселении гост-кандидата.

///Иллюзии: боевые клоны (щит-зеркало, копьё серого прилива, самокопии) -
///базовый melee_chaser (дефолт, строка не нужна): спавн с целью работает
///зеркалом GiveTarget -> блэкборд, размножение при ударе - легаси
///AttackingTarget делегацией. Escape-приманка не дерётся вовсе - профиль
///decoy_escape: бегство от закреплённого владельца/перехваченного
///преследователя до легаси-кольца retreat_distance.
/mob/living/simple_animal/hostile/illusion/escape
	ai_profile_type = /datum/ai_controller/hostile_adapter/decoy_escape

///Пилот меха: сабтри-делегат его FSM пилотирования (curseblob-паттерн).
///Вне меха - обычный пехотинец штатной машины (угон меха делегацией
///CanAttack/AttackingTarget); в мехе паун живёт внутри объекта - оператор
///mecha_pilot_operate водит САМ МЕХ мув-лупами и гоняет фазы легаси-проком
///ai_operate_mecha_phase; can_idle = FALSE (Moved пауна в мехе не стреляет,
///окно интересности не переезжает - будить уснувшего было бы некому).
/mob/living/simple_animal/hostile/syndicate/mecha_pilot
	ai_profile_type = /datum/ai_controller/hostile_adapter/mecha_pilot
