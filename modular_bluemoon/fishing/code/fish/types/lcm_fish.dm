// рыбы в духе Lobotomy Corporation
/obj/item/fish/lcm
	icon = 'modular_bluemoon/fishing/icons/fish_sprites.dmi'
	required_fluid_type = AQUARIUM_FLUID_FRESHWATER
	favorite_bait = list(/obj/item/bait/worm)

/obj/item/fish/lcm/bass
	name = "largemouth bass"
	desc = "Крупная хищная пресноводная рыба, популярная у рыбаков-спортсменов."
	fish_id = "lcm_bass"
	icon_state = "bass"
	average_size = 40
	average_weight = 5000
	stable_population = 3
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/trout
	name = "steelhead trout"
	desc = "Прибрежная форель, близкая к лососю и давно используемая в пищу."
	fish_id = "lcm_trout"
	icon_state = "trout"
	required_fluid_type = AQUARIUM_FLUID_ANADROMOUS
	average_size = 60
	average_weight = 12000
	stable_population = 3
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/eel
	name = "freshwater eel"
	desc = "Угри охотятся ночью, а днём спят в иле у берега."
	fish_id = "lcm_eel"
	icon_state = "eel_fresh"
	average_size = 90
	average_weight = 2000
	stable_population = 3
	fish_traits = list(/datum/fish_trait/predator, /datum/fish_trait/nocturnal)

/obj/item/fish/lcm/northernpike
	name = "northern pike"
	desc = "Северные щуки - территориальные хищники, атакующие добычу рывком."
	fish_id = "lcm_northernpike"
	icon_state = "northernpike"
	average_size = 91
	average_weight = 9071
	stable_population = 2
	fish_traits = list(/datum/fish_trait/predator, /datum/fish_trait/territorial)
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/salmon
	name = "atlantic salmon"
	desc = "Атлантический лосось - проходная рыба с серебристо-синей окраской."
	fish_id = "lcm_salmon"
	icon_state = "salmon_sockeye"
	required_fluid_type = AQUARIUM_FLUID_ANADROMOUS
	average_size = 100
	average_weight = 4000
	stable_population = 3

/obj/item/fish/lcm/yang
	name = "yang carp"
	desc = "Уникальная порода карпов, посвящённая ян."
	fish_id = "lcm_yang"
	icon_state = "yangfish"
	average_size = 50
	average_weight = 6803
	random_case_rarity = FISH_RARITY_VERY_RARE
	beauty = FISH_BEAUTY_EXCELLENT

/obj/item/fish/lcm/yin
	name = "yin carp"
	desc = "Уникальная порода карпов, посвящённая инь."
	fish_id = "lcm_yin"
	icon_state = "yinfish"
	average_size = 50
	average_weight = 6803
	random_case_rarity = FISH_RARITY_VERY_RARE
	beauty = FISH_BEAUTY_EXCELLENT

/obj/item/fish/lcm/mosb
	name = "mountain of smiling fish"
	desc = "Эта масса пытается вцепиться в детрит и живые организмы, чтобы расти."
	fish_id = "lcm_mosb"
	icon_state = "mosb"
	show_in_catalog = FALSE
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	required_fluid_type = AQUARIUM_FLUID_ANADROMOUS
	average_size = 100
	average_weight = 16000
	beauty = FISH_BEAUTY_DISGUSTING

/obj/item/fish/lcm/ufo
	name = "UFO"
	desc = "Объект низко гудит, словно бросая вызов законам физики."
	fish_id = "lcm_ufo"
	icon_state = "ufo"
	random_case_rarity = FISH_RARITY_VERY_RARE
	average_size = 40
	average_weight = 7000
	fish_traits = list(/datum/fish_trait/antigrav)
	beauty = FISH_BEAUTY_GREAT

/obj/item/fish/lcm/unidentified_fish_object
	name = "Unidentified Fish Object"
	desc = "Что за чёрт."
	fish_id = "lcm_ufo_object"
	icon_state = "unidentified-fish-object"
	random_case_rarity = FISH_RARITY_VERY_RARE
	average_size = 40
	average_weight = 5000
	beauty = FISH_BEAUTY_BAD

/obj/item/fish/lcm/walkin_man
	name = "Walkin Man"
	desc = "Я тут иду!"
	fish_id = "lcm_walkin_man"
	icon_state = "walkin_man"
	random_case_rarity = FISH_RARITY_VERY_RARE
	average_size = 50
	average_weight = 5600
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/boxin_man
	name = "Boxin Man"
	desc = "Я тут боксирую!"
	fish_id = "lcm_boxin_man"
	icon_state = "boxin_man"
	random_case_rarity = FISH_RARITY_VERY_RARE
	average_size = 50
	average_weight = 5600
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/weever_blue_album
	name = "Weever Blue Album"
	desc = "Только во снах!"
	fish_id = "lcm_weever_blue_album"
	icon_state = "weever_blue_album"
	random_case_rarity = FISH_RARITY_VERY_RARE
	average_size = 50
	average_weight = 10000
	beauty = FISH_BEAUTY_GREAT

/obj/item/fish/lcm/waterflea
	name = "water flea"
	desc = "Водяных блох иногда используют в научных исследованиях."
	fish_id = "lcm_waterflea"
	icon_state = "waterflea"
	random_case_rarity = FISH_RARITY_RARE
	average_size = 1
	average_weight = 1
	stable_population = 2
	beauty = FISH_BEAUTY_NULL

/obj/item/fish/lcm/sheephead
	name = "california sheephead"
	desc = "Калифорнийские шейпхеды - протогинные гермафродиты."
	fish_id = "lcm_sheephead"
	icon_state = "sheephead"
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_RARE
	average_size = 91
	average_weight = 16000
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/bluefintuna
	name = "bluefin tuna"
	desc = "Голубые тунцы - крупнейшие тунцы, мигрирующие через все океаны."
	fish_id = "lcm_bluefintuna"
	icon_state = "bluefintuna"
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_RARE
	average_size = 150
	average_weight = 60000
	beauty = FISH_BEAUTY_GREAT

/obj/item/fish/lcm/smolshark
	name = "small shark"
	desc = "Яйца акул бывают разными."
	fish_id = "lcm_smolshark"
	icon_state = "shark_smol"
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_RARE
	average_size = 60
	average_weight = 6000
	fish_traits = list(/datum/fish_trait/predator)
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/marine_shrimp
	name = "marine shrimp"
	desc = "Креветки - всеядные первичные консументы, в основном питаются водорослями."
	fish_id = "lcm_marine_shrimp"
	icon_state = "shrimp"
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	average_size = 2
	average_weight = 2
	stable_population = 5
	beauty = FISH_BEAUTY_NULL

/obj/item/fish/lcm/lobster
	name = "lobster"
	desc = "Омары не слабеют с возрастом."
	fish_id = "lcm_lobster"
	icon_state = "lobster"
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	average_size = 50
	average_weight = 6803
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/blue_tang
	name = "blue tang"
	desc = "У голубых хирургов есть шипы сверху и снизу тела."
	fish_id = "lcm_blue_tang"
	icon_state = "blue_tang"
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	average_size = 30
	average_weight = 500
	stable_population = 4
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/deep_fry
	name = "deep fry"
	desc = "Мы спустимся в чёрные бездны... и поселимся в логове Глубинных."
	fish_id = "lcm_deep_fry"
	icon_state = "deep_fry"
	show_in_catalog = FALSE
	required_fluid_type = AQUARIUM_FLUID_ANADROMOUS
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	average_size = 100
	average_weight = 16000
	beauty = FISH_BEAUTY_DISGUSTING

/obj/item/fish/lcm/pigfish
	name = "mini pigfish"
	desc = "Почти как босс из популярной игры."
	fish_id = "lcm_pigfish"
	icon_state = "pigfish"
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	average_size = 150
	average_weight = 60000
	beauty = FISH_BEAUTY_GREAT

/obj/item/fish/lcm/piscine_mermaid
	name = "lovestruck fish"
	desc = "Карп, переживший воздействие пения русалки."
	fish_id = "lcm_piscine_mermaid"
	icon_state = "mermaid"
	show_in_catalog = FALSE
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	average_size = 100
	average_weight = 16000
	beauty = FISH_BEAUTY_GREAT

/obj/item/fish/lcm/tuna_pallid
	name = "pallidified tuna"
	desc = "Тунец, проглоченный и искажённый великим китом. Фу."
	fish_id = "lcm_tuna_pallid"
	icon_state = "pallid_tuna"
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_RARE
	average_size = 150
	average_weight = 50000
	fish_traits = list(/datum/fish_trait/toxic)
	beauty = FISH_BEAUTY_UGLY

/obj/item/fish/lcm/fishmael
	name = "Fishmael"
	desc = "Если позволите, зовите меня Фишмаэль."
	fish_id = "lcm_fishmael"
	icon_state = "fishmael"
	show_in_catalog = FALSE
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_RARE
	average_size = 30
	average_weight = 500
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/seabunny
	name = "Sea Bunny"
	desc = "Существо похоже на маленького белого кролика. Но оно очень ядовито."
	fish_id = "lcm_seabunny"
	icon_state = "seabunny"
	show_in_catalog = FALSE
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_RARE
	average_size = 30
	average_weight = 300
	fish_traits = list(/datum/fish_trait/toxic)
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/searabbit
	name = "Sea Rabbit"
	desc = "Существо похоже на маленького кролика R-Corp. Но не очень ядовито... наверное."
	fish_id = "lcm_searabbit"
	icon_state = "searabbit"
	show_in_catalog = FALSE
	required_fluid_type = AQUARIUM_FLUID_SALTWATER
	random_case_rarity = FISH_RARITY_RARE
	average_size = 30
	average_weight = 300
	fish_traits = list(/datum/fish_trait/predator)
	beauty = FISH_BEAUTY_GOOD

/obj/item/fish/lcm/siltcurrent
	name = "silt current"
	desc = "Странная тяжёлая рыба, на ощупь как мокрый камень."
	fish_id = "lcm_siltcurrent"
	icon_state = "siltcurrent"
	show_in_catalog = FALSE
	average_size = 60
	average_weight = 9000
	beauty = FISH_BEAUTY_BAD

/obj/item/fish/lcm/victim
	name = "victim fish"
	desc = "Она знавала лучшие дни."
	fish_id = "lcm_victim"
	icon_state = "unidentified-fish-object"
	show_in_catalog = FALSE
	average_size = 40
	average_weight = 3000
	beauty = FISH_BEAUTY_DISGUSTING
