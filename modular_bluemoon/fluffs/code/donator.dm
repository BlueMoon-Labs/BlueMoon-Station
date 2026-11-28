//Файл для выдачи предметов донатерам по сикею
// ckeywhitelist поддерживает исходный key "AA-BB-ab...", ckey "aabbab" и обратимые ID "enc1:...". Все форматы можно смешивать в одном листе.
// ID может получить игрок на вкладке персональных вещей лодаута

// Открытые имена сравниваются через ckey(), поэтому регистр и знаки в них не влияют на доступ.
// gear_ckey_id(key) шифрует исходное имя AES-256-GCM с секретом из CONFIG_GET(string/loadout_ckey_secret).
// gear_ckey_from_id(id) возвращает исходное имя; при проверке доступа оно нормализуется через ckey().

// Проверка ID и файлов вне игры: tools/loadout_crypto/README.md. Ключ нельзя публиковать или терять.


/datum/gear/donator/bm
	name = null //name = "Видишь это - пингуй Feenie#1815" //Название предмета
	slot = ITEM_SLOT_BACKPACK //Место, в который будет выдаваться предмет, конкретно тут - кладётся в рюкзак
	path = /obj/item/bikehorn/golden //Ссылка на датум объекта
	category = LOADOUT_CATEGORY_DONATOR //Категория, в которой будет содержаться предмет - собственно во вкладке лодаута донатерских
	subcategory = LOADOUT_SUBCATEGORIES_DON03
	ckeywhitelist = list() // Пример (достаточно указать в 1 любом формате): list("AA-BB-ab...", "aabbab", "enc1:unT9k2H2qbIKzt7MEgIheNaZHatKBY9AEc7Gnr54AeLG28UxZ3se") //Если вы видите этот текст ингейм, значит кто-то ебанулся с кодом - пингуйте всё того же

/datum/gear/donator/bm/tyranny_crown
	name = "Crown of Pure Tyranny"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/pt_crown
	ckeywhitelist = list("snacksman")
	donator_group_id = DONATOR_GROUP_TIER_3

/datum/gear/donator/bm/bishop_mitre
	name = "GPC Mitre"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/bishop_mitre
	ckeywhitelist = list("snacksman")

/datum/gear/donator/bm/bishop_mantle
	name = "Bishop Mantle"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/bishop_mantle
	ckeywhitelist = list("snacksman")

/datum/gear/donator/bm/reaper_helmet
	name = "Reaper Helmet"
	description = "Шлем Plasmaman Envirohelmet. С красными метками и усиленный некоторыми композитными материалами."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/helmet/space/plasmaman/security/reaper
	ckeywhitelist = list("reaperdb")

/datum/gear/donator/bm/reaper_suit
	name = "Reaper Suit"
	description = "Скафандр Plasmaman, переделанный под боевое применение. На спине фиолетовая планета, в которой течёт энергия."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/plasmaman/security/reaper
	ckeywhitelist = list("reaperdb")

/datum/gear/donator/bm/ellys_suit
	name = "Ellys Costume"
	description = "Костюм бело-чёрных цветов."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/ellys_suit
	ckeywhitelist = list("chowny")

/datum/gear/donator/bm/ellys_hoodie
	name = "Ellys Hoodie"
	description = "Худи серо-белых цветов."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/ellys_hoodie
	ckeywhitelist = list("chowny")

/datum/gear/donator/bm/modern_watch
	name = "modern watch"
	description = "Оригинальные «Delta-watch XL». Сделано на Сол-3."
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/wrists/donator/bm/modern_watch
	ckeywhitelist = list("zarshef")

/datum/gear/donator/bm/gaston
	name = "Gaston"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/gaston
	ckeywhitelist = list("gastonix")

/datum/gear/donator/bm/blueflame
	name = "horns of blue flame"
	description = "Это рога из голубого пламени. Ярко светящаяся голограмма, похожая на огонь, будто кто-то включил сварку."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/blueflame
	ckeywhitelist = list("weirdbutton", "xaeshkavd")

/datum/gear/donator/bm/gorka
	name = "Gorka"
	description = "Камуфляж, созданный для использования... ну, везде, если честно, учитывая его происхождение."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/gorka
	ckeywhitelist = list("leony24", "vulpshiro", "dolbajob", "trustmeimengineer", "stgs", "krashly", "hazzi", "devildeadspace", "enigma418")

/datum/gear/donator/bm/pet_moro
	name = "Moro Cat"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/moro
	ckeywhitelist = list("hazzi")

/datum/gear/donator/bm/lightning_holocloak
	name = "lightning holo-cloak"
	description = "При надевании активируется странная голограмма: ткань плаща исчезает, а по всему телу начинают проходить молнии."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/lightning_holocloak
	ckeywhitelist = list("weirdbutton", "xaeshkavd")

/datum/gear/donator/bm/modern_suit
	name = "Modern Suit"
	description = "Костюм красно-чёрных цветов. Включает шорты, подтяжки и галстук. На груди видна надпись «Epoque — ограниченная коллекция 2563, сделано специально для Tex»."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/modern_suit
	ckeywhitelist = list("rainbowkurwa")

/datum/gear/donator/bm/case_ds
	name = "military case"
	description = "Ящик с военным имуществом."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/donator/bm/case_ds
	ckeywhitelist = list("phenyamomota")

/datum/gear/donator/bm/Shigu_Kit
	name = "Butcher Knife Kit"
	description = "Набор для переделки Butcher Knife в Shigu Knife."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/shigu_kit
	ckeywhitelist = list("lakomkin0911")

/datum/gear/donator/bm/kukri_kit
	name = "Kukri Kit"
	description = "Набор для переделки боевого ножа в Kukri."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/kukri_kit
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "kingdeaths", "sierraiv", "ordinarylife", "milidead", "blatoff", "angelnedemon", "foxrtotlimda")

/datum/gear/donator/bm/Advanced_Tracksuit
	name = "Advanced Tracksuit"
	description = "Современные военные спортивные костюмы для передовой."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/syndicate/rus_army_alt
	ckeywhitelist = list("noterravija")

/datum/gear/donator/bm/cerberus_helmet
	name = "cerberus helmet"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/cerberus_helmet
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob", "ordinarylife", "devildeadspace")

/datum/gear/donator/bm/cerberus_suit
	name = "cerberus suit"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/cerberus_suit
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob", "ordinarylife", "devildeadspace")

/datum/gear/donator/bm/censor_fem_suit
	name = "censor suit"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/censor_fem_suit
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob", "ordinarylife", "devildeadspace")

/datum/gear/donator/bm/belinsky_plushie
	name = "Belinsky plushie"
	description = "Игрушка, очень похожая на Колю Белинского. Пушистые усы, повязка на глазу, коричневая водолазка. Всё на месте."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/belinsky
	ckeywhitelist = list("krashly", "stgs")

/datum/gear/donator/bm/atam
	name = "Atam"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/crayon/atam
	ckeywhitelist = list("foxedhuman")

/datum/gear/donator/bm/Friskis_Mask
	name = "Magic Kitsune Mask"
	description = "Восточная фарфоровая маска, эта — бело-красная. Ты чувствуешь исходящую от неё древнюю силу!"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/magickitsune
	ckeywhitelist = list("friskis")

/datum/gear/donator/bm/oni_mask
	name = "Tactical Gasmask"
	description = "Маска с красным забралом и специальными фильтрами. Похоже, на ней есть нечто вроде кошачьих усов."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/cool_version
	ckeywhitelist = list("oni3288", "smileycom", "shizalrp", "lindaastereih", "silverfoxpaws")

/datum/gear/donator/bm/blackcool_mask
	name = "CFIS Gasmask"
	description = "Тактический противогаз оперативников Службы иностранной разведки каткринов. Компактная маска с тёмным стеклом и маленькими фильтрами в передней части с выдохом."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/blackcool_version
	ckeywhitelist = list("discord980")

/datum/gear/donator/bm/yekitezh
	name = "M1062"
	description = "Штатный армейский противогаз, заменивший предыдущую серию M55 в армии Екитежа."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/yekitezh
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/yekitezh_red
	name = "M1062-B"
	description = "Штатный армейский противогаз армии Екитежа, только эта версия оптимизирована со светящимися красными линзами и чёрным покрытием для «тактических» целей."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/yekitezh_red
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/Rar_Suit
	name = "HEV Suit"
	description = "Защитный костюм. Он создан, чтобы защищать учёных от тупых травм, радиации и энергетических разрядов, которые могут возникнуть при работе с опасными материалами. Сидит как влитой. Автоматическая медицинская система, кажется, сломана... Они ждут тебя, Гордон. В испытательной камере."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/space/hardsuit/rd/hev/cosmetic
	ckeywhitelist = list("rarslt")

/datum/gear/donator/bm/utilgen
	name = "G-66 Uniform"
	description = "Форма из арамида от быстро растущей частной охранной компании, с фиолетовой планетой(?) на спине и шестёрками на плечах."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/utilgen
	ckeywhitelist = list("reaperdb", "rainbowkurwa")

/datum/gear/donator/bm/multicam
	name = "Multicam"
	description = "Камуфляж, созданный для использования в широком диапазоне условий, разработанный и производимый компанией Crye Precision, вышедшей из SCG."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/multicam
	ckeywhitelist = list("leony24", "vulpshiro", "dolbajob", "trustmeimengineer", "devildeadspace", "enigma418", "silyamg")

/datum/gear/donator/bm/baron
	name = "Terrifying Cloak"
	description = "Чёрный плащ из дорогой ткани с распущенными волосами какого-то странного существа вокруг шеи."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/donator/bm/baron
	ckeywhitelist = list("snacksman", "krashly")

/datum/gear/donator/bm/syndiecloak
	name = "Syndicate Officer's Cloak"
	description = "Плащ, вселяющий страх в сотрудников Nanotrasen; его носит величайший офицер Синдиката."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/syndiecap
	ckeywhitelist = list("architect0r", "fanlexa")

/datum/gear/donator/bm/admcloak
	name = "Syndicate Admiral's Cloak"
	description = "Глубоко-красный плащ, который носят только величайшие из Синдиката. Если ты на него смотришь — скорее всего, недолго тебе осталось смотреть."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/syndieadm
	ckeywhitelist = list("architect0r", "fanlexa", "enc1:ZSm5SLVs22RzJuB72CoClG1zO2svXDvNskZVzg7u5HC4qAvivk2TLg", "enc1:5RF1peUXV44QSOj8ZcdUrCvi0QUYOWVI7EdOr8M-0c-S3EOJ")

/datum/gear/donator/bm/sencloak
	name = "Senior Commander's Trenchcloak"
	description = "Тёмный плащ-тренч, сшитый на заказ для старших офицеров. Из очень прочной кожи и бронированной ткани. Внутри воротника бирка с написанной «V»."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/sencloak
	ckeywhitelist = list("romontesque")

/datum/gear/donator/bm/angelo
	name = "Angelo's Coat"
	description = "Толстый кожаный тренч с прошитыми красными краями воротника. Правое плечо украшено аксельбантом. На рукавах различаются узоры в виде трёхголовой гидры. Несомненно, этот плащ достался владельцу в награду от высшего командования как подтверждение его статуса. Интересно."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/angelo
	ckeywhitelist = list("axidant")

/datum/gear/donator/bm/malorian_mag
	name = "Malorian Mag Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/malorian_mag
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/flektarn
	name = "Flektarn Combat Uniform"
	description = "Чёрная водолазка с -взрывным- камуфляжными боевыми брюками."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/flektarn
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "sodastrike", "lonofera", "hellsinggc", "devildeadspace", "enigma418", "mihana964")

/datum/gear/donator/bm/flektarn_casual
	name = "Flektarn Casual Uniform"
	description = "Белая майка с -взрывным- камуфляжными боевыми брюками."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/flektarn_casual
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "sodastrike", "lonofera", "hellsinggc", "devildeadspace", "enigma418", "mihana964")

/datum/gear/donator/bm/flektarn_montur
	name = "Flektarn Montur"
	description = "Пятицветная -взрывная- форма в камуфляжных цветах, украшенная золотыми погонами и разными боевыми наградами. Инициалы говорят, что она принадлежит Koruhaundo Adoriana O."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/flektarn_montur
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "sodastrike", "lonofera", "hellsinggc", "devildeadspace", "enigma418", "mihana964")

/datum/gear/donator/bm/flektarn_beret
	name = "Flektarn Beret"
	description = "Пятицветный -взрывной- берет в камуфляжных цветах с золотым значком."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/flektarn_beret
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "sodastrike", "lonofera", "hellsinggc", "devildeadspace", "enigma418", "mihana964")

/datum/gear/donator/bm/skull_patch
	name = "PMC Skull Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/skull_patch
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob", "leony24", "snacksman", "sodastrike", "vulpshiro", "lonofera", "hellsinggc", "mihana964", "devildeadspace", "enigma418", "ordinarylife")

/datum/gear/donator/bm/monolith_patch
	name = "Monolith Patch"
	description = "Мы — стражи Монолита! Мы — его избранные воины! И каждый из нас — посланник его воли! Мы не знаем усталости! Мы не знаем страха! СЛАВА МОНОЛИТУ."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/monolith_patch
	ckeywhitelist = list("irfish", "devildeadspace", "mikolaostavkin", "allazarius", "definitelynotnesuby", "hazzi", "dimofon", "mihana964", "angelnedemon", "hateredsoul", "ordinarylife", "fanlexa")

/datum/gear/donator/bm/tratch_patch
	name = "Tratch Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/tratch_patch
	ckeywhitelist = list("fryktik", "hazzi", "targon38", "ghos7ik", "devildeadspace", "trora", "happycrab")

/datum/gear/donator/bm/sh_jacket
	name = "Shiro Silverhand Jacket"
	description = "Культовая куртка Широ Силверханда, которую он носил в свои самурайские дни."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/sh_jacket
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/sh_glasses
	name = "Shiro Silverhand Glasses"
	description = "Эти серебристые авиаторы принадлежат Широ Силверханду."
	slot = ITEM_SLOT_EYES
	path = /obj/item/clothing/glasses/shiro
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/emma_plush
	name = "Emma Plush"
	description = "Очаровательная мягкая игрушка, напоминающая вульпа."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/emma
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/shiro_plush
	name = "Shiro Plush"
	description = "Очаровательная мягкая игрушка, напоминающая вульпа."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/emma/shiro
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/raita_plush
	name = "Raita Plush"
	description = "Очаровательная мягкая игрушка, напоминающая вульпа."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/emma/raita
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/who_plush
	name = "Security Officer Plush"
	description = "Мягкая игрушка, похожая на оперативника NanoTrasen. Пахнет горелым хлопком."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/who
	ckeywhitelist = list("stgs")

/datum/gear/donator/bm/noonar
	name = "Syndicate jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/noonar
	ckeywhitelist = list("noonar", "dasani2879")

/datum/gear/donator/bm/noonarlong
	name = "A long syndicate jacket."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/noonar/long
	ckeywhitelist = list("noonar", "dasani2879")


/datum/gear/donator/bm/pchelik
	name = "GFYS"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/gun/ballistic/automatic/AM4B/pchelik
	ckeywhitelist = list("pchelik")

/datum/gear/donator/bm/pchelik_cloak
	name = "Coopie's Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/coopie_cloak
	ckeywhitelist = list("pchelik")

/datum/gear/donator/bm/battle_coat
	name = "Battle Coat"
	description = "Тактическая форма с капюшоном."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/battle_coat
	ckeywhitelist = list("ghoststalin", "g3234")

/datum/gear/donator/bm/sports_jacket
	name = "Sports Jacket"
	description = "Он жёлтый."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/sports_jacket
	ckeywhitelist = list("ghoststalin", "g3234")

/datum/gear/donator/bm/cross_shielded
	name = "Shielded Cross"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/cross/shielded
	ckeywhitelist = list("kalifasun", "dofalt")

/datum/gear/donator/bm/miner_plushie
	name = "Miner Plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/miner
	ckeywhitelist = list("cheburek228")

/datum/gear/donator/bm/omega_plushie
	name = "Omega Plushie"
	description = "У этого плюшевого зверя правда пустая башка и ноль мыслей о том, чтобы совершить что-то особенно жестокое."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/omega
	ckeywhitelist = list("malopharan")

/datum/gear/donator/bm/nri_drg
	name = "Covert Ops Tactical Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/nri_drg
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "krashly", "sodastrike", "devildeadspace", "enigma418")

/datum/gear/donator/bm/nri_drg_head
	name = "Covert Ops Headgear"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/nri_drg_head
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "krashly", "sodastrike", "devildeadspace", "enigma418")

/datum/gear/donator/bm/booma_patch
	name = "Boomah Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/booma_patch
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/booma
	name = "Boomah Turtleneck"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/booma
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "architect0r")

/datum/gear/donator/bm/silky_body
	name = "Silky Body"
	description = "Идеально сшитый боди-костюм, сидит по фигуре и ни в чём не сковывает движения. По бокам видны завязки, чтобы ты мог регулировать плотность прилегания."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/silky_body
	ckeywhitelist = list("architect0r", "trora")

/datum/gear/donator/bm/silky_body_alt
	name = "V-shaped Body"
	description = "Идеально сшитый боди-костюм, сидит по фигуре и ни в чём не сковывает движения."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/silky_body_alt
	ckeywhitelist = list("architect0r", "trora", "hihitect")

/datum/gear/donator/bm/vance_plush
	name = "Vance Plush"
	description = "Мягкая игрушка-грызун, пахнет сыром и ксенобиологией!"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/judas/vance
	ckeywhitelist = list("littlemouse2729")

/datum/gear/donator/bm/pet
	name = "Pet Beacon"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet
	ckeywhitelist = list("mixalic")

/datum/gear/donator/bm/Dina_Kit
	name = "Kikimora Suit Kit"
	description = "Набор для переделки Elite Syndicate Hardsuit в Kikimora MK1."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/Dina_Kit
	ckeywhitelist = list("xdinka")

/datum/gear/donator/bm/Kovac_Gun
	name = "Kovac Gun"
	description = "Набор для переделки Enforcer Gun в Kovac Gun."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/Kovac_Kit
	ckeywhitelist = list("stgs", "krashly", "dolbajob", "hazzi", "devildeadspace", "enigma418", "mihana964", "ordinarylife")

/datum/gear/donator/bm/auto9_gun
	name = "Auto 9 Kit"
	description = "Набор для переделки WT-550 Gun в Auto 9 Gun."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/auto9_kit
	ckeywhitelist = list("stgs", "sodastrike", "dolbajob", "hazzi", "krashly", "devildeadspace", "enigma418","ordinarylife")

/datum/gear/donator/bm/m240_gun
	name = "M240 Kit"
	description = "Набор для переделки огнемёта в M240."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/m240_kit
	ckeywhitelist = list("stgs", "sodastrike", "dolbajob", "hazzi", "krashly", "devildeadspace", "enigma418", "ordinarylife")

/datum/gear/donator/bm/luftkuss_gun
	name = "Luftkuss Kit"
	description = "Набор для переделки гибридного электрошокера в H&K Luftkuss."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/old_kit
	ckeywhitelist = list("stgs", "sodastrike", "dolbajob", "hazzi", "krashly", "fiaskin", "devildeadspace", "enigma418", "ordinarylife")

/datum/gear/donator/bm/dominator
	name = "Dominator Kit"
	description = "Набор для переделки гибридного электрошокера в Dominator."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/dominator_kit
	ckeywhitelist = list("shalun228")

/datum/gear/donator/bm/nue
	name = "Araki Nue Kit"
	description = "Набор для переделки Enforcer в Araki Nue."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/nue_kit
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/malorian
	name = "Araki Malorian Kit"
	description = "Набор для переделки Enforcer в Araki Malorian."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/malorian_kit
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/pomogator
	name = "Pomogator Modification Kit"
	description = "Набор для переделки обычного рюкзака в Pomogator."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/pomogator_kit
	ckeywhitelist = list("danik10p")

/datum/gear/donator/bm/martian
	name = "Martian Backpack"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/martian
	ckeywhitelist = list("ingvarr3313")

/datum/gear/donator/bm/cheesesatchel
	name = "Cheese Satchel"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/satchel/cheese
	ckeywhitelist = list("littlemouse2729")

/datum/gear/donator/bm/sponge
	name = "Sponge Modification Kit"
	description = "Набор для переделки обычных боксёрских перчаток в жёлтые перчатки."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/sponge_kit
	ckeywhitelist = list("danik10p")

/datum/gear/donator/bm/stunblade
	name = "Stunblade Kit"
	description = "Набор для переделки дубинки в шоковый клинок."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/stunblade_kit
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "leony24", "stgs", "lonofera", "z67", "oni3288", "allazarius", "devildeadspace", "enigma418")

/datum/gear/donator/bm/stunadler
	name = "Adler stunsword Kit"
	description = "Набор для переделки дубинки в Adler stunsword."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/stunadler_kit
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/harness
	name = "Harness Armor Modification Kit"
	description = "Набор для переделки бронежилета в Harness Armor."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/harness_kit
	ckeywhitelist = list("ghoststalin", "g3234")

/datum/gear/donator/bm/ntcane
	name = "Nanotrasen Cane Modification Kit"
	description = "Набор для переделки нарядной трости в старую роскошную трость."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/ntcane_kit
	ckeywhitelist = list("stasdvrz")

/datum/gear/donator/bm/t51armor
	name = "Old Power Armor Kit"
	description = "Набор для переделки силового костюма охранника в силовую броню T-51."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/t51armor_kit
	ckeywhitelist = list("stasdvrz", "pingvas", "vovakr", "roninqwerty")

/datum/gear/donator/bm/old_world_kit
	name = "Old Wolrd Blues Kit"
	description = "Военный ящик с полным набором снаряжения Старого мира."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/old_world_kit
	ckeywhitelist = list("stasdvrz", "vlonger", "roninqwerty")

/datum/gear/donator/bm/money_100k
	name = "Extra Money"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/stack/spacecash/c100000
	ckeywhitelist = list("arvard")

/datum/gear/donator/bm/armwraps_of_n1ght1ngale
	name = "Armwraps of Mighty Fists"
	description = "Набор наручных обмоток. Тебе сразу хочется отправиться в приключения и бить драконов."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/gloves/fingerless/pugilist/magic
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/monolith_gloves
	name = "Granite M1 Gloves"
	description = "Перчатки комбинезона Granite M1 от группы «Монолит», производитель неизвестен."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/gloves/fingerless/monolith_gloves
	ckeywhitelist = list("irfish", "devildeadspace", "mikolaostavkin", "allazarius", "definitelynotnesuby", "hazzi", "dimofon", "mihana964", "angelnedemon", "hateredsoul", "ordinarylife", "fanlexa")

/datum/gear/donator/bm/monolith_armor
	name = "Granite M1 Vest"
	description = "Жилет комбинезона Granite M1 от группы «Монолит», производитель неизвестен."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/bm/monolith_armor
	ckeywhitelist = list("irfish", "devildeadspace", "mikolaostavkin", "allazarius", "definitelynotnesuby", "hazzi", "dimofon", "mihana964", "angelnedemon", "hateredsoul", "ordinarylife", "fanlexa")

/datum/gear/donator/bm/monolith_uniform
	name = " Granite M1 ''Monolith'' Uniform"
	description = "Комбинезон сталкера из группы «Монолит», производитель неизвестен. Мы благодарим за благо, дарованное твоим слугам. Монолит показал нам священный путь — путь единения с Монолитом. Мы все едины в нашей вере. Пока мы едины, мы непобедимы; проклятием неверным, отвергающим его путь, ибо они слепы в своих желаниях. Сила в единстве наших братьев, благословенна вечная сила, данная нам Монолитом во исполнение его воли. Установим вечный порядок в зоне, братья и сёстры, и да придёт вечное единение с Монолитом. СЛАВА МОНОЛИТУ."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/monolith_uniform
	ckeywhitelist = list("irfish", "devildeadspace", "mikolaostavkin", "allazarius", "definitelynotnesuby", "hazzi", "dimofon", "mihana964", "angelnedemon", "hateredsoul", "ordinarylife", "fanlexa")

/datum/gear/donator/bm/commissar_hat
	name = "Commissar Hat"
	description = "Отличный способ сделать косплей героя Империума!"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/commissar
	ckeywhitelist = list("sketchyirishman")

/datum/gear/donator/bm/commissar_coat
	name = "Commissar Coat"
	description = "Отличный способ сделать косплей героя Империума!"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/commissar
	ckeywhitelist = list("sketchyirishman")

/datum/gear/donator/bm/commissar_uniform
	name = "Commissar Uniform"
	description = "Отличный способ сделать косплей героя Империума!"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/commissar
	ckeywhitelist = list("sketchyirishman")

/datum/gear/donator/bm/officersabresheath
	name = "Officer Sabre Sheath"
	description = "Изысканные ножны, созданные для офицерского клинка."
	slot = ITEM_SLOT_BELT
	path = /obj/item/storage/belt/sabre/civil
	ckeywhitelist = list("sketchyirishman")

/datum/gear/donator/bm/summon_tentacle
	name = "Book for Summon Tentacle"
	slot = ITEM_SLOT_BELT
	path = /obj/item/book/granter/spell/summon_tentacle
	ckeywhitelist = list("roboticus")

/datum/gear/donator/bm/p940
	name = "P940 Kit"
	description = "Набор для переделки Enforcer в PF940."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/pf940_kit
	ckeywhitelist = list("leony24", "hartty")

/datum/gear/donator/bm/p940_g22
	name = "P940 G22 Kit"
	description = "Набор для переделки G22 в PF940."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/pf940_kit_g22
	ckeywhitelist = list("leony24")

/datum/gear/donator/bm/shotgun_ks22
	name = "Shotgun into KS-22M Kit"
	description = "Набор для переделки дробовика в KS-22."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/ks22_kit
	ckeywhitelist = list("lodagn")

/datum/gear/donator/bm/shotgun_mossberg
	name = "Shotgun into Mossberg-590A Kit"
	description = "Набор для переделки дробовика в Mossberg-590A."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/mossberg_kit
	ckeywhitelist = list("shizalrp", "krasler101", "kingdeaths")

/datum/gear/donator/bm/g36_kit
	name = "AK-12 into G36 Kit"
	description = "Набор для переделки AK-12 в G36."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/g36_kit
	ckeywhitelist = list("lodagn")

/datum/gear/donator/bm/Anabel_kit
	name = "Miniature Energy Gun into Anabel Kit"
	description = "Набор для переделки миниатюрного энергетического пистолета в Anabel."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/Anabel_kit
	ckeywhitelist = list("kalifasun", "dofalt")

/datum/gear/donator/bm/emagged_jukebox
	name = "Emagged Jukebox"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/jukebox/emagged
	ckeywhitelist = list("smileycom")

/datum/gear/donator/bm/upgraded_size_tool
	name = "Upgraded Size Tool"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/melee/sizetool/upgraded
	ckeywhitelist = list("enc1:0ZhIqEqjyfOXkmvUajQcLIbzJoOQ5CV8L8y4w26sqNGICe0Xv4o", "enc1:3FOMDCsG1QwEcOrt3lTBkSHXj0lAYTWXHCevAVV9wSjlmyYzKu1L3A", "enc1:6QnjOcQBWtFGfgFF1hqMR8ktwXMX03_XC8LkmrKtyjOa0SIz", "thevelocipony")

/datum/gear/donator/bm/pet_alta
	name = "Alta Cat"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/alta
	ckeywhitelist = list("oni3288", "discord980", "xaeshkavd")

/datum/gear/donator/bm/pet_juda
	name = "Juda shark"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/juda
	ckeywhitelist = list("mihana964")

/datum/gear/donator/bm/dogtag
	name = "Alta's dogtag"
	description = "Первый жетон указывает личный номер — AG-003288 — и принадлежность к наёмникам AC. Второй содержит имя и фамилию — Althea Gantia — и группу крови."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/accessory/dogtag
	ckeywhitelist = list("oni3288", "ghos7ik", "discord980", "mihana964", "romontesque", "enigma418", "smol42", "notlikeluls",  "kladmenuwu", "alexsandoor", "scramblescream", "nai1ten", "devildeadspace", "zetneskov", "hazzi", "definitelynotnesuby", "silverfoxpaws", "pr1zrak", "earthphobia", "wafflemeow", "trora", "kosep", "urfdrf", "mikolaostavkin", "xaeshkavd", "deltarayx", "korinfellori", "troubleneko17th", "dimofon", "lichfail", "gisya", "dimakr", "cupteazee", "nopeingeneer", "silyamg", "lomodno", "valsons", "nyctealust", "abrikos", "spoopyman228", "stasdvrz", "shizalrp", "tblkba", "dragon9090", "avtobuspng", "ninjapikachushka", "ailhate", "kingdeaths", "mentaleater", "lindaastereih", "gevaitrouble", "ivanokio", "blatoff", "regiska", "lander231", "exkessa", "vlonger")

/datum/gear/donator/bm/hateredsoul_dogtag
	name = "Combat Dogtag"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/accessory/hateredsoul_dogtag
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "sierraiv", "ordinarylife", "milidead", "blatoff", "angelnedemon", "foxrtotlimda", "devildeadspace", "silyamg", "hartty", "dalphy12")

/datum/gear/donator/bm/hateredsoul_dogtag_nt
	name = "NT Combat Dogtag"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/accessory/hateredsoul_dogtag/nt
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "sierraiv", "ordinarylife", "milidead", "blatoff", "angelnedemon", "foxrtotlimda", "devildeadspace", "silyamg", "hartty", "dalphy12")

/datum/gear/donator/bm/hateredsoul_dogtag_syndie
	name = "Syndie Combat Dogtag"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/accessory/hateredsoul_dogtag/syndie
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "sierraiv", "ordinarylife", "milidead", "blatoff", "angelnedemon", "foxrtotlimda", "devildeadspace", "silyamg", "hartty", "dalphy12")

/datum/gear/donator/bm/paws_patch
	name = "PAWS Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/paws_patch
	ckeywhitelist = list("devildeadspace", "mikolaostavkin", "cupteazee", "dimofon", "dimakr", "definitelynotnesuby", "scramblescream", "tblkba", "hellsinggc", "aurses", "mihana964", "angelnedemon", "ordinarylife", "hateredsoul", "ralseidreemuurr", "troubleneko17th")

/datum/gear/donator/bm/h_soul_coat
	name = "Black coat"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/h_soul_coat
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "sierraiv", "ordinarylife", "milidead", "blatoff", "angelnedemon", "moun4l", "foxrtotlimda", "hartty", "dalphy12", "sawwarrr", "tecouwu")

/datum/gear/donator/bm/tricorne
	name = "Tricorne"
	description = "Простая трёхугольная шляпа треугольной формы."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/tricorne
	ckeywhitelist = list("smol42", "weirdbutton", "sage4or")

/datum/gear/donator/bm/rt46
	name = "RT-46 The Tempest Kit"
	description = "Набор для переделки револьвера в RT-46."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/rt46
	ckeywhitelist = list("kladmenuwu")

/datum/gear/donator/bm/Frieren_skirt
	name = "Frieren skirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/Frieren_skirt
	ckeywhitelist = list("fedor1545")

/datum/gear/donator/bm/Prosecutor
	name = "Prosecutor suit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/Prosecutor_suit
	ckeywhitelist = list("fedor1545", "berly12")

/datum/gear/donator/bm/a46_kit
	name = "A46 Kit"
	description = "Набор для переделки WT-550 Gun в A46 Gun."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/a46
	ckeywhitelist = list("nai1ten")

/datum/gear/donator/bm/ots18_kit
	name = "OTs-18 Kit"
	description = "Набор для переделки WT-550 Gun в OTs-18 Groza Gun."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/ots18
	ckeywhitelist = list("nai1ten")

/datum/gear/donator/bm/rune_jacket
	name = "Rune Jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/rune_jacket
	ckeywhitelist = list("d0nald")

/datum/gear/donator/bm/acrador_kit
	name = "Acrador kit"
	description = "Содержит полный набор снаряжения Acrador."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/acrador_kit
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")

/datum/gear/donator/bm/goal
	name = "Goal mask"
	description = "Маска, похожая на странного медведя."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/balaclava/breath/goal
	ckeywhitelist = list("hazzi", "fryktik")

/datum/gear/donator/bm/rohai_helmet
	name = "Rohai Infantry helmet"
	description = "Штатный шлем Империи Рохай сделан из полимерных материалов и имеет места для дополнительных модулей."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/rohai_helmet
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/rohai_armor
	name = "Rohai Infantry Armor"
	description = "Стандартный защитный комплект пехотинца Империи Рохай, сделанный из полимеров, обычно плотно подгоняется под владельца. На обоих наплечниках виден символ с двумя ножами."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/rohai_armor
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/irellia
	name = "Banner of the Irellia"
	description = "Знамя Иреллии."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/banner/irellia
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")

/datum/gear/donator/bm/rohai
	name = "Banner of the Rohai empire"
	description = "Знамя Империи Рохай."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/banner/rohai
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")

/datum/gear/donator/bm/norn
	name = "Banner of kingdom Norn"
	description = "Знамя королевства Норн."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/banner/norn
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")

/datum/gear/donator/bm/rhsa12
	name = "R-HSA-12"
	description = "Шлем из лёгкой брони диверсанта. Полупрозрачное забрало скрывает личность диверсанта почти без потери защитных свойств. Сбоку есть крепление для фонарика."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/rhsa12
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/rsa12
	name = "R-SA-12"
	description = "Лёгкая броня диверсанта создана, чтобы обеспечивать достаточную защиту при сохранении высокой свободы движений и скрытности — важно для заданий по подрыву, шпионажу или тихому проникновению. Раньше принадлежала Церкви Асмалгана, но теперь на груди несёт эмблему Рохай."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/rsa12
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/acradorsuit
	name = "Underarmor suit"
	description = "Тёмный плотный костюм для носки под жёсткие пластины. Не стесняет движений и защищает тело от натирания бронепластинами."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/rank/security/officer/acradorsuit
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/at41_kit
	name = "AT-41 Kit"
	description = "Набор для переделки WT-550 Gun в AT-41 Gun."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/at41_kit
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_combat_uniform
	name = "SATT combat uniform"
	description = "Высококачественная одежда из смеси флиса и хлопка. На бирке видны логотип в виде орла и надпись Strategic Assault Tactical Team. Если вдохнуть запах — пахнет срезами военного преступления."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/SATT_combat_uniform
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_turtleneck
	name = "SATT turtleneck"
	description = "Высококачественная одежда из смеси флиса и хлопка. На бирке видны логотип в виде орла и надпись Strategic Assault Tactical Team. Если вдохнуть запах — пахнет срезами военного преступления."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/SATT_turtleneck
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_vdv
	name = "SATT vdv uniform"
	description = "Высококачественная одежда из смеси флиса и хлопка. На бирке видны логотип в виде орла и надпись Strategic Assault Tactical Team. Если вдохнуть запах — пахнет срезами военного преступления."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/SATT_vdv
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_jackboots
	name = "SATT jackboots"
	description = "Высококачественная одежда из смеси флиса и хлопка. На бирке видны логотип в виде орла и надпись Strategic Assault Tactical Team. Если вдохнуть запах — пахнет срезами военного преступления."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/shoes/jackboots/SATT_jackboots
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATTdogtag
	name = "SATT dogtag"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/SATTdogtag
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_gloves
	name = "SATT gloves"
	description = "Высококачественная одежда из смеси флиса и хлопка. На бирке видны логотип в виде орла и надпись Strategic Assault Tactical Team. Если вдохнуть запах — пахнет срезами военного преступления."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/gloves/SATT_gloves
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_gloves_finger
	name = "Fingerless SATT gloves"
	description = "Высококачественная одежда из смеси флиса и хлопка. На бирке видны логотип в виде орла и надпись Strategic Assault Tactical Team. Если вдохнуть запах — пахнет срезами военного преступления."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/gloves/fingerless/SATT_gloves_finger
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/wtadler
	name = "WT-550 Adler Kit"
	description = "Набор для переделки WT-550 Gun в WT-550 Adler Gun."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/wtadler
	ckeywhitelist = list("akinight", "kladmenuwu")

/datum/gear/donator/bm/aki_camo
	name = "Old Guard NRI uniform"
	description = "Образец старой формы пограничных спецчастей гвардии NRI. Этот вариант адаптирован для антропоморфов."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/aki_camo
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/aki_adler_camo
	name = "Adler Peacekeeper uniform"
	description = "Форма миротворцев шьётся на заказ для корпораций в секторе Тайвар. Имитирует все особенности биологии меренидов, чтобы идеально подходить любой личности, а также некоторым низкокачественным расам."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/aki_adler_camo
	ckeywhitelist = list("akinight", "kladmenuwu")

/datum/gear/donator/bm/nri_mundir
	name = "Old mundir NRI"
	description = "Описание: старый мундир Новой Российской Империи. Потёртый, но всё ещё готов к бою, как в старые добрые времена... На нём вышито имя — Златчек."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/bm/nri_mundir
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/aki_seu
	name = "Corporate S.E.U."
	description = "Стандартная корпоративная инженерная форма. Форма инженеров, которую используют несколько крупных корпораций на Тайваре. Оснащена дополнительными прокладками для снижения риска травм и особыми знаками для обозначения уровня допуска к инженерным работам."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/aki_seu
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/aki_les
	name = "L.E.S."
	description = "Облегчённый экзоскелет. Экзоскелет для простых работ с использованием пневмоусилителей и инженерной магии. Нет, он не подключается к твоему позвоночнику, но и к этому его адаптировали. Иногда используется в медицинских целях после травм позвоночника или нижних конечностей. Полностью заменит твой старый кусок мяса на современный аналог."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/bm/aki_les
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/laskaskirt
	name = "HoS cosplay skirt"
	description = "Юбка, похожая на форму Начальника безопасности, но без какой-либо брони."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/laskaskirt
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/braskirt
	name = "Red bra and striped skirt"
	description = "Красная юбка с боковым разрезом и полосами! В комплекте подходящий двухцветный бюстгальтер."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/braskirt
	ckeywhitelist = list("deltarayx", "shizalrp")

/datum/gear/donator/bm/mihana_mask
	name = "Andromeda mask"
	description = "Плотно прилегающая тактическая маска, которую можно подключить к источнику воздуха."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/cool_version/mihana_mask
	ckeywhitelist = list("mihana964", "wangig", "devildeadspace")

/datum/gear/donator/bm/tagilla_modkit
	name = "Tagilla modkit"
	description = "Набор для переделки сварочного шлема в сварочный шлем Tagilla."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/tagilla
	ckeywhitelist = list("tequilasunset228")

/datum/gear/donator/bm/warai_kimono
	name = "Warai Kimono"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/kimono/warai
	ckeywhitelist =	list("germanrus")

/datum/gear/donator/bm/hammercrowbar_kit
	name = "Heavy pocket hammer Kit"
	description = "Набор для переделки тяжёлой ломы в тяжёлый карманный молоток."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/modkit/hammercrowbar_kit
	ckeywhitelist = list("allazarius", "hazzi", "devildeadspace", "wangig", "wather565", "sierraiv")

/datum/gear/donator/bm/dreadmk3_kit
	name = "Dread Kit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/modkit/dreadmk3_kit
	ckeywhitelist = list("stasdvrz", "mrsko", "akinight", "vovakr", "roninqwerty","pingvas","lev1932","dragon9090","cnaperdodo")

/datum/gear/donator/bm/aer9
	name = "AER9 Kit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/modkit/aer9
	ckeywhitelist = list("stasdvrz", "vlonger", "vidl")

/datum/gear/donator/bm/institute_kit
	name = "institute Kit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/modkit/institute_kit
	ckeywhitelist = list("stasdvrz", "vlonger", "vidl")

/datum/gear/donator/bm/p320_kit
	name = "P320 kit"
	description = "Набор для переделки Enforcer в магнитный пистолет p320."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/p320_kit
	ckeywhitelist = list("ty4kahahebe", "pingvas", "xaeshkavd")

/datum/gear/donator/bm/M9_tempest_kit
	name = "M-9 Tempest kit"
	description = "Набор для переделки гибридного электрошокера в M-9 Tempest."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/M9tempest_kit
	ckeywhitelist = list("pingvas", "ty4kahahebe")

/datum/gear/donator/bm/dedication_kit
	name = "Dedication kit"
	description = "Набор для переделки Enforcer в магнитный пистолет Dedication."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/dedication_kit
	ckeywhitelist = list("akinight", "kladmenuwu")

/datum/gear/donator/bm/cleaver_kit
	name = "Cleaver kit"
	description = "Набор для переделки Enforcer в лёгкий офицерский тесак."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/cleaver_kit
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/scabbard
	name = "Scabbard belt"
	description = "Специальные ножны хорошо подходят для офицерского тесака, который выдаётся высокопоставленным офицерам Адлера и их чиновникам. Можешь назвать их излишеством: они сделаны из кожи какого-то редкого, возможно даже разумного существа. Сами ножны крепятся к ремню сзади, чтобы было удобно резко выхватить клинок и нанести удар — именно этому учат офицеров, когда осваивают этот специализированный тесак. Для обычных людей они неудобны и сложны в использовании."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/belt/scabbard
	ckeywhitelist = list("akinight")
	restricted_desc = "Captain"
	restricted_roles = list("Captain")

/datum/gear/donator/bm/shoulder_coat
	name = "Shoulder coat"
	description = "Плащ офицера Адлера обычно носят как дополнительный опознавательный знак. Он сделан из нанофибер лёгкой ткани и обычно выдаётся офицерам, прошедшим расширенную подготовку и имеющим как минимум второй чин в иерархии офицеров. Для чиновников и старших офицеров его обычно не используют — их ранг намного выше. Но для тактического обозначения в офицерском корпусе его носить необходимо. Даже офицер второго чина уже может отдавать полные приказы офицеру первого чина, несмотря на небольшую разницу в званиях. На плащ также могут наноситься белые полосы как обозначение чина, но так обычно делают только в регулярных войсках."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/tie/shoulder_coat
	ckeywhitelist = list("akinight", "kladmenuwu")

/datum/gear/donator/bm/renegat
	name = "Renegat armor"
	description = "Броня миротворцев Адлера. Есть несколько нашивок, обозначающих чин — похоже, это форма для командиров. Производится одноимённым военно-промышленным комплексом Адлера. Похоже, носить её могут только высокопоставленные чиновники, и она помечена соответствующим буквенно-цифровым кодом."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/renegat
	ckeywhitelist = list("akinight", "kladmenuwu")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/renegat_helmet
	name = "Renegat helmet"
	description = "Шлем миротворцев Адлера. Есть несколько нашивок, обозначающих чин — похоже, это форма для командиров. Производится одноимённым военно-промышленным комплексом Адлера. Похоже, носить его могут только высокопоставленные чиновники; кажется, в него встроен специальный интерфейс опознавания «свой-чужой»."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/renegat
	ckeywhitelist = list("akinight", "kladmenuwu")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/armor_shield
	name = "Shield armor"
	description = "Тяжёлый бронированный костюм миротворцев Адлера. Прочнее обычной версии, опознавательный код указан под одной из пластин; каждая пластина, кажется, создана для отражения удара и передачи силы на несколько соседних пластин, снижая силу удара и наносимый урон. Броня хорошо сидит на теле, но для обычного человека она довольно тяжёлая — носить её без имплантов и подготовки не лучшая затея. Кодировка Адлера на броне также позволяет владельцам легче опознавать друг друга по тому же коду доступа и представляет опасность для противников и мародёров."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/armor_shield
	ckeywhitelist = list("akinight", "kladmenuwu")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/helmet_shield
	name = "Shield helmet"
	description = "Тяжёлый бронированный шлем миротворцев Адлера. Похоже, он адаптирован для длинных и сложных операций: внутри мягкая подкладка под бронёй, снаружи прочные пластины и система опознавания «свой-чужой». Дополнительные пластины спереди защищают голову."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/helmet_shield
	ckeywhitelist = list("akinight", "kladmenuwu")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/adler_skull
	name = "Skull helmet"
	description = "Тактический шлем охотников-пустынников с планеты Тиран-1 Новой Российской Империи — лёгкий шлем для действий в жарких условиях. Относительно защищает от песчаных бурь, пуль и ударов монстров, но слегка сужает обзор. Похоже, этот вариант больше антропоморфный, но подойдёт и обычному человеку. Обычно охотники сами царапают на них свои инициалы, но этот никак не помечен."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/adler_skull
	ckeywhitelist = list("akinight")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/ipai
	name = "I.P.A.I. helmet Dawn Dome"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/ipai
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "kingdeaths", "sierraiv", "ordinarylife", "milidead")

/datum/gear/donator/bm/soviet_coat
	name = "Soviet coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/soviet_coat
	ckeywhitelist = list("fedor1545")

/datum/gear/donator/bm/poster_box
	name = "Box with posters"
	description = "Внутри три плаката."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/storage/box/poster_box
	ckeywhitelist = list("tonya677")

/datum/gear/donator/bm/ushankich
	name = "Soviet ushanka"
	description = "Идеально для сибирской зимы, да?"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/ushankich
	ckeywhitelist = list("fedor1545")

/datum/gear/donator/bm/echoes_jacket
	name = "Technical Jacket"
	description = "Экзоскелет с пиджаком офицера Синдиката Триглава."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/donator/bm/echoes_jacket
	ckeywhitelist = list("xaeshkavd", "scramblescream", "illa_3000", "discord980", "heathkit1", "sosnovskii", "trora")

/datum/gear/donator/bm/oftok
	name = "Officer token"
	description = "Странная голографическая жетон-метка из прочного материала — чтобы что-то отмечать."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/tie/oftok
	ckeywhitelist = list("xaeshkavd", "akinight", "heathkit1", "scramblescream", "definitelynotnesuby", "sosnovskii","hellsinggc")

/datum/gear/donator/bm/hecu_black
	name = "Black HECU Backpack"
	description = "Ты носишь это на спине и складываешь внутрь вещи."
	path = /obj/item/storage/backpack/hecu/black
	slot = ITEM_SLOT_BACK
	ckeywhitelist = list("xaeshkavd")

/datum/gear/donator/bm/noxscoutcoat
	name = "Military-Civilian Scout Coat"
	description = "Специализированная военно-гражданская куртка с защитой первого класса, для решения различных задач. Внутри вшит номер — 228321."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/donator/bm/noxscoutcoat
	ckeywhitelist = list("xaeshkavd")

/datum/gear/donator/bm/kladmen_panties
	name = "Panties"
	description = "Не ходить без трусов."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/briefs/kladmen_panties
	ckeywhitelist = list("kladmenuwu", "scramblescream")

/datum/gear/donator/bm/kladmen_bra
	name = "Bra - A bra"
	description = "Бюстгальтер."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/shirt/bra/kladmen_bra
	ckeywhitelist = list("kladmenuwu", "scramblescream")

/datum/gear/donator/bm/kladmen_jacket
	name = "Jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/kladmenuwu_jacket
	ckeywhitelist = list("kladmenuwu")

/datum/gear/donator/bm/kladmen_bodysuit
	name = "Bodysuit"
	description = "Рубашка."
	slot = ITEM_SLOT_SHIRT
	path = /obj/item/clothing/underwear/shirt/bm/kladmen_bodysuit
	ckeywhitelist = list("kladmenuwu")

/datum/gear/donator/bm/troubleneko_bra
	name = "Laced lingerie bra"
	description = "Бюстгальтер."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/shirt/bra/troubleneko_bra
	ckeywhitelist = list("troubleneko17th", "tblkba")

/datum/gear/donator/bm/troubleneko_panties
	name = "Panties"
	description = "Не ходить без трусов."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/briefs/troubleneko_panties
	ckeywhitelist = list("troubleneko17th", "tblkba")

/datum/gear/donator/bm/troubleneko_socks
	name = "Socks"
	description = "Пара носков."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/socks/thigh/troubleneko_socks
	ckeywhitelist = list("troubleneko17th", "tblkba")

/datum/gear/donator/bm/f_haori
	name = "Flaming Haori"
	description = "Белый хаори с узором пламени на конце. Кажется, оно излучает тепло и энергию."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/f_haori
	ckeywhitelist = list ("romontesque")

/datum/gear/donator/bm/SMART_fabric_boatcloak
	name = "SMART-fabric boatcloak"
	description = "Ткань способна менять структуру, считывая слабые нервные импульсы тела."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/SMART_fabric_boatcloak
	ckeywhitelist = list("kijoking")

/datum/gear/donator/bm/famas098_NoirSuitskirt
	name = "Noir suitskirt"
	description = "Серый костюм-юбка закалённого частного детектива, с зажимом для галстука в комплекте."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/rank/security/detective/grey/skirt/no_armor
	ckeywhitelist = list("famas098")

/datum/gear/donator/bm/letuale
	name = "Элегантное красное платье"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/ElegantRedDress
	ckeywhitelist = list("loonel")

/datum/gear/donator/bm/papermaskunderhair
	name = "The paper mask"
	description = "Аккуратная круглая маска из бумаги."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/paper/underhair
	ckeywhitelist = list("kijoking")

/datum/gear/donator/bm/sierra_shock_collar
	name = "Shock Collar"
	description = "Укреплённый металлический ошейник. Спереди вроде бы есть какая-то проводка. Странно.."
	slot = ITEM_SLOT_POCKETS
	path = /obj/item/electropack/shockcollar
	ckeywhitelist = list("sierraiv")

/datum/gear/donator/bm/sierra_remotecontrol
	name = "remote signaling device"
	description = "Используется для дистанционного включения устройств. Позволяет синхронизироваться, если на другом устройстве используется защищённый сигнализатор."
	slot = ITEM_SLOT_POCKETS
	path = /obj/item/assembly/signaler
	ckeywhitelist = list("sierraiv")

/datum/gear/donator/bm/lurban_misteran
	name = "urban camouflage uniform"
	description = "Городской расцвеченный военный костюм, разработанный Bibis&Co. Обычно ассоциируется с ЧВК CEHU и LonoMith."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/urban_misteran
	ckeywhitelist = list("misteran")

/datum/gear/donator/bm/SyndAngelicJaket
	name = "Angelic-made Syndicate parade Jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/SyndAngelicJaket
	ckeywhitelist = list("akiyamagw")

/datum/gear/donator/bm/royal_hunters
	name = "Royal hunters hat"
	description = "Даже охотники умирают — но не воспоминания."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/royal_hunters
	ckeywhitelist = list("gisya")

/datum/gear/donator/bm/angel_vulgar_dress
	name = "Angelic Vulgar Dress"
	description = "Ангельское платье вульгарного характера, белое — как же благословенно!"
	slot = ITEM_SLOT_UNDERWEAR
	path = /obj/item/clothing/under/bm/angelrevskirt
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/ghotic_vulgar_dress
	name = "Ghotic Vulgar Dress"
	description = "Готическое платье откровенного характера, чёрно-красное, едва прикрывает пах и грудь владельца!"
	slot = ITEM_SLOT_UNDERWEAR
	path = /obj/item/clothing/under/bm/gothrevskirt
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/prisoner
	name = "prison jumpsuit"
	description = "Это стандартная форма заключённых NanoTrasen. Датчики костюма застряли в положении «Полностью включено»."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/rank/prisoner
	ckeywhitelist = list("borisovych")

/datum/gear/donator/bm/borisovych_SecurityJumpskirt
	name = "security jumpskirt"
	description = "«Тактический» комбинезон охранника, у которого вместо штанин юбка."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/rank/security/officer/skirt/no_armor
	ckeywhitelist = list("borisovych")

/datum/gear/donator/bm/savannah_tailbow
	name = "tailbow"
	description = "Нарядный хвостик-бант для твоего сахарного котика."
	path = /obj/item/clothing/wrists/donator/bm/savannah_tailbow
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_piercing
	name = "piercings and bracers"
	description = "Золотые пирсинг и наручи."
	path = /obj/item/clothing/underwear/socks/savannah_piercing
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_boots
	name = "Archangel Group boots"
	description = "Пара нарядных ботинок от Archangel Group."
	path = /obj/item/clothing/shoes/archangel_boots
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_sleepwear
	name = "sleepwear"
	description = "Ночная рубашка. Нарядная?"
	path = /obj/item/clothing/underwear/shirt/toggle/savannah_sleepwear
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_z_turtleneck
	name = "Archangel Group turtleneck"
	description = "Водолазка Archangel group для особых заданий. Чёрная и стильная."
	path = /obj/item/clothing/under/donator/bm/archangel_turtleneck
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_plusie
	name = "Plushy Savannah"
	description = "Плюшевый котик для лесбийских забав и обнимашек."
	path = /obj/item/toy/plush/bm/plushy_savannah
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/pet_jruttie
	name = "Jruttie Cat"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/jruttie
	ckeywhitelist = list("scramblescream", "nai1ten", "discord980", "alexsandoor")

/datum/gear/donator/bm/pet_wertyan
	name = "Wertyan Mothroach"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/wertyanmoth
	ckeywhitelist = list("silverfoxpaws", "wertan", "vlonger", "techgrid", "saimon228")

/datum/gear/donator/bm/pet_lilmoth
	name = "Little pet Moth"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/lilmoth
	ckeywhitelist = list("saimon228")

/datum/gear/donator/bm/tavern_skirt
	name = "Tavern skirt"
	description = "Платье из таверны для эльфов сшито из лёгкого материала, мягко облегающего фигуру. Это бледно-зелёное платье подчёркивает грацию и изящество эльфийского народа."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/tavern_skirt
	ckeywhitelist = list("fedor1545")

/datum/gear/donator/bm/elf_bottle
	name = "Potion bottle"
	path = /obj/item/reagent_containers/glass/beaker/elf_bottle
	ckeywhitelist = list("fedor1545")

/datum/gear/donator/bm/wh_kit
	name = "A box of Unholy Armor"
	description = "Это коробка, пропитанная демонским влиянием Тёмных богов; внутри набор для модификации брони."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/donator/bm/wh_kit
	ckeywhitelist = list("darksungwyndolin")

/datum/gear/donator/bm/lotos_skirt
	name = "Lotos Skort"
	description = "Чёрное платье чёрного котёнка."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/lotos_skirt
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/copium
	name = "Copium Bottle"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/reagent_containers/glass/bottle/copium
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/moniq
	name = "Muz-TV"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/sign/moniq
	ckeywhitelist = list("finkrld")

/datum/gear/donator/bm/broadcast_camera
	name = "broadcast camera"
	description = "Большая камера, которая ведёт прямую трансляцию видео и звука на развлекательные мониторы по всей станции, так что каждый может смотреть эфир."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/broadcast_camera
	ckeywhitelist = list("finkrld")

/datum/gear/donator/bm/microphone
	name = "Microphone"
	description = "Микрофон для вещания."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/radio/microphone
	ckeywhitelist = list("finkrld")

/////////////////////////////////////

/datum/gear/donator/bm/impactbaton_jitte
	name = "Jitte impact Baton"
	description = "Набор для переделки полицейской дубинки в джитэй-дубинку."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/impactbaton_kit
	ckeywhitelist = list("silverfoxpaws", "nai1ten", "oni3288")

/datum/gear/donator/bm/mengineer_hardhat
	name = "Master Engineer's Hardhat"
	description = "Модифицированный сварочный шлем с наушниками. Бело-жёлтая окраска, кажется, обозначает какой-то средний инженерный чин — в стандартах NanoTrasen такого нет. Внутри шлема виден выцарапанный личный номер: KVM:829917."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/hardhat/weldhat/mengineer
	ckeywhitelist = list("silverfoxpaws")
	restricted_desc = "Station Engineer"
	restricted_roles = list("Station Engineer")
	cost = 2

/datum/gear/donator/bm/halvedspectacles
	name = "Halved Violet Spectacles"
	slot = ITEM_SLOT_EYES
	path = /obj/item/clothing/glasses/halvedspectacles
	ckeywhitelist = list("silverfoxpaws", "ninjapikachushka")

/////////////////////////////////////

/datum/gear/donator/bm/hahun_vest
	name = "Field technician suit"
	description = "Модифицированный инженерный костюм иреллийцев с дополнительными слоями для защиты от ударов током и холодной погоды; встроена третья рука и сварочный капюшон."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/hazardvest/hahun_vest
	ckeywhitelist = list("dolbajob", "enigma418")
	restricted_desc = "Station Engineer"
	restricted_roles = list("Station Engineer")

/datum/gear/donator/bm/hahun_hardhat
	name = "Welding hood"
	description = "Часть костюма полевого техника: закрывает уши владельца и при необходимости превращается в сварочный щиток, со встроенным фонариком."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/hardhat/weldhat/hahun
	ckeywhitelist = list("dolbajob", "enigma418")
	restricted_desc = "Station Engineer"
	restricted_roles = list("Station Engineer")
	cost = 2

/datum/gear/donator/bm/hahun_exosuit
	name = "Praxil Mk.6 Exosuit"
	description = "Арктически-белое зимнее пальто с маленьким синим кадуцеем вместо бегунка молнии. Броско."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/hooded/wintercoat/medical/hahun_exosuit
	ckeywhitelist = list("dolbajob", "enigma418")
	restricted_desc = "Medical Department"
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist")

/datum/gear/donator/bm/hahun_gloves
	name = "Eidolon's gloves kits"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/hahun_eidolon
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/hahun_medvest
	name = "Rescue task force vest"
	description = "Удобный предмет, который крепится на груди; множество карманов и застёжек для медицинских инструментов, лекарств и бинтов."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/belt/medical/hahun_medvest
	ckeywhitelist = list("dolbajob", "enigma418")
	restricted_desc = "MD, Paramedic, CMO"
	restricted_roles = list("Chief Medical Officer", "Medical Doctor", "Paramedic")
	cost = 3

/datum/gear/donator/bm/hahun_bag
	name = "Unloading bag"
	description = "Тактическая и удобная поясная сумка с большим свободным пространством и карманами; на ней эмблема отряда Eidolon."
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/hahun_bag
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/hahun_case
	name = "Irellian rescue compartment case"
	description = "Кейс, полный медицинской одежды и снаряжения Acrador. Внутри медицинский жилет, перчатки и экзокостюм."
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/case/medical/hahun
	ckeywhitelist = list("dolbajob", "enigma418")
	cost = 5

/datum/gear/donator/bm/hahun_uniform
	name = "Irellian combat uniform"
	description = "Чёрная водолазка с камуфляжными боевыми брюками."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/syndicate/tacticool/hahun_uniform
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/hahun_mask
	name = "MI13 infiltrator mask"
	description = "Высококачественная маска из дорогих материалов, с фильтрационной системой и улучшенным сканированием окружающей среды. Три линзы мерцают красным."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/hahun_mask
	ckeywhitelist = list("dolbajob", "enigma418", "silverfoxpaws")

/datum/gear/donator/bm/hahun_mask_2
	name = "EIDOVOX Type-3 mask"
	description = "Высококачественная маска из дорогих материалов, с фильтрационной системой и улучшенным сканированием окружающей среды. Три линзы мерцают красным."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/hahun_mask/eidovox
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/hahun_jukebox
	name = "Irellian Jukebox"
	description = "Набор для переделки музыкального автомата в акрадорскую версию."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/hahun_jukebox
	ckeywhitelist = list("dolbajob", "enigma418")

/////////////////////////////////////

/datum/gear/donator/bm/panophobia_hos_beret
	name = "White beret"
	description = "Бронированный берет белого цвета для хороших мальчиков и девочек NanoTrasen."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/HoS/beret/white
	ckeywhitelist = list("earthphobia")
	restricted_roles = list("Head of Security")

/datum/gear/donator/bm/panophobia_hos_trench
	name = "White armored trenchcoat"
	description = "Белое бронированное пальто. Бронированное пальто белого цвета для хороших мальчиков и девочек NanoTrasen."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/armor/hos/trenchcoat/white
	ckeywhitelist = list("earthphobia")
	restricted_roles = list("Head of Security")

/datum/gear/donator/bm/panophobia_hos_jackboots
	name = "White jackboots"
	description = "Белые кирзовые сапоги охранника."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/jackboots/sec/white
	ckeywhitelist = list("earthphobia")
	restricted_roles = list("Head of Security")

/datum/gear/donator/bm/sierra_iris_plushie
	name = "I.R.I.S. plushie"
	slot = ITEM_SLOT_POCKETS
	path = /obj/item/toy/plush/bm/tiamat/sierra_iris_plushie
	ckeywhitelist = list("sierraiv", "oroshimuraiori")

/datum/gear/donator/bm/srt_chestrig
	name = "SRT Bluerock chest-rig"
	description = "Изготовленный на заказ нагрудный жилет для носки поверх брони в ближнем бою. Прочный и универсальный, с системами крепления MOLLE и ALICE. Похоже, к нему уже прикреплена старомодная кобура."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/belt/military/srt_chesrig
	ckeywhitelist = list("hellsinggc")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")
	cost = 2

/datum/gear/donator/bm/srt_suit
	name = "SRT combat uniform"
	description = "Форма сил специального реагирования отличается сдержанным и минималистичным дизайном, где функциональность важнее броских эстетик. Это позволяет владельцу сливаться с окружением и оставаться незаметным во время скрытных операций. Форма SRT отражает доскональное внимание к деталям и непоколебимую приверженность, которые отличают эту грозную силу."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/srt_suit
	ckeywhitelist = list("hellsinggc")

/datum/gear/donator/bm/srt_
	name = "SRT Balaclava with Eye patch"
	description = "Обычная балаклава с необычной повязкой на глазу. Это оптоэлектронное устройство, изобретённое неизвестной компанией Синдиката. Устройство напоминает пластиковую повязку на глаз, спереди напечатаны название модели и серийный номер, а ниже расположена маленькая линза камеры. Оно определяет температуру тела, пульс и потоотделение, чтобы вычислять физическое и эмоциональное состояние человека."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/srt_mask
	ckeywhitelist = list("hellsinggc")

/datum/gear/donator/bm/millie_plushe
	name = "Millie plush"
	description = "Милая розовая девочка. Мягкий силикон источает приятный запах клубники и малины. Если слегка сжать куклу, её язык смешно высовывается."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/millie
	ckeywhitelist = list("pingvas", "ty4kahahebe", "scorpionch", "blatoff")

/datum/gear/donator/bm/praxil_seven
	name = "Praxil-7 Mark II Kit"
	description = "Набор для переделки инженерного силового костюма в Praxil-7 Mark II."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/fluff_praxil_seven_kit
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/m_9922
	name = "M-9922 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/fluff_m_9922_kit
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/dark_montur
	name = "Dark Montur"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/dark_montur
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/MI13_uniform
	name = "MI13 combat uniform"
	description = "Чёрная водолазка с камуфляжными боевыми брюками, сделанная для агентов MI13 в поле."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/MI13_uniform
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/eo95_mask
	name = "EO-95 mask"
	description = "Высококачественная маска из дорогих материалов, с фильтрационной системой и улучшенным сканированием окружающей среды. Три линзы мерцают красным."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/hahun_mask/eo95_mask
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/lissara_plush
	name = "Lissara plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/lissara
	ckeywhitelist = list("enc1:HfL74qz9SYsWj1sl3G7cmRAA-TJsUjaLbqENaxODVwkrYOBAHDc6lw", "enc1:hGA4yPBBCnkiBPggAzGU0OlnwdSbTou7AaKvQJ3CXGhAMH53")

/datum/gear/donator/bm/araminta_plush
	name = "Araminta plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/araminta
	ckeywhitelist = list("enc1:hMWYWPkGFVRawiIkNDxMaEfrYRdTUwosBftTUJPqpjCOJjNP8ZVwSg", "enc1:biIANg5mBQNChLoydOEFmKJjTyub1DZfq4rTACAfeV6yqnLX")

/datum/gear/donator/bm/dilivery_bag
	name = "Delivery Bag"
	description = "Рюкзак службы доставки еды с алюминиевой фольгой внутри, которая сохраняет тепло. Странно пахнет жареной курицей."
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/dilivery_bag
	ckeywhitelist = list("troubleneko17th", "dimofon", "hazzi", "cupteazee", "kolhozniik", "dimakr", "hartty")

/datum/gear/donator/bm/dar_beacon
	name = "Dar Jr beacon"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/dar
	ckeywhitelist = list("avtobuspng", "dimofon", "definitelynotnesuby", "angelnedemon", "deltarayx")

/datum/gear/donator/bm/pawpack
	name = "Paw Backpack"
	description = "Модный на вид рюкзак в форме лапы."
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/pawpack
	ckeywhitelist = list("deltarayx", "pingvas")

/datum/gear/donator/bm/coffin
	name = "Black Rose atelier worker coffin."
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/coffin
	ckeywhitelist = list("hateredsoul", "ggishka")

/datum/gear/donator/bm/coffinb2
	name = "Black Rose atelier worker cofin"
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/coffin/b2
	ckeywhitelist = list("hateredsoul", "ggishka")

/datum/gear/donator/bm/coffinw
	name = "Black Rose atelier worker. Coffin"
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/coffin/w
	ckeywhitelist = list("hateredsoul", "ggishka")

/datum/gear/donator/bm/coffinw2
	name = "Black Rose Atelier worker coffin"
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/coffin/w2
	ckeywhitelist = list("hateredsoul", "ggishka")

/datum/gear/donator/bm/steal_book
	name = "Book of stealing"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/book_of_stealing
	ckeywhitelist = list("deadlizard")
	cost = 3

/datum/gear/donator/bm/inlaid_data_dress
	name = "Inlaid Data Dress"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/inlaid_data_dress
	ckeywhitelist = list("1darkwater1")

/datum/gear/donator/bm/hair_module
	name = "Hair Module"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/hair_module
	ckeywhitelist = list("1darkwater1")

/datum/gear/donator/bm/modsuit_anomalous
	name = "anomalous mod suit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/mod/construction/armor/anomalous_archeotech
	ckeywhitelist = list("1darkwater1")

/datum/gear/donator/bm/ouroboroswinterschock
	name = "Ouroboros"
	description = "Дорогая и индивидуально доработанная версия кольца-нормализатора с небольшими изменениями."
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/accessory/ring/syntech/winterschock
	ckeywhitelist = list("winterschock")

/datum/gear/donator/bm/ouroboroswinterschock/on_spawn(mob/living/carbon/human/user, obj/item/clothing/accessory/ring/syntech/winterschock/I)
	if(!istype(user))
		return
	I.owner_ref = WEAKREF(user)
	if(user.dna?.features["normalized_size"])
		I.current_normalized_size = user.dna.features["normalized_size"]
		I.try_update_size(user, TRUE)

/datum/gear/donator/bm/tesh_hcloak_br
	name = "black and red hooded cloak"
	description = "Мягкий плащ тешари с добавленным капюшоном."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/hooded/teshari/standard/black_red
	ckeywhitelist = list("heathkit1")

/datum/gear/donator/bm/pg
	name = "powder ganger jacket"
	description = "Напомни охранникам об их ошибке — выдавать заключённым взрывные заряды."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/pg
	ckeywhitelist = list("heathkit1")

/datum/gear/donator/bm/cybercoat
	name = "Cybercoat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/hooded/bm/donator/cybercoat
	ckeywhitelist = list("cnaperdodo")

// /datum/gear/donator/bm/hood_armored
// 	name = "Большой капюшон"
// 	slot = ITEM_SLOT_HEAD
// 	path = /obj/item/clothing/head/donator/bm/hood_armored
// 	ckeywhitelist = list("cnaperdodo")

// /datum/gear/donator/bm/rebel_armor
// 	name = "Кольчуга контрабандистов"
// 	slot = ITEM_SLOT_OCLOTHING
// 	path = /obj/item/clothing/suit/armor/donator/bm/rebel_armor
// 	ckeywhitelist = list("cnaperdodo")

/datum/gear/donator/bm/clf_uniform
	name = "Перекрашенный комплект ЧВК"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/clf_uniform
	ckeywhitelist = list("cnaperdodo")

/datum/gear/donator/bm/diamond_ring
	name = "A diamond ring"
	description = "Дорогое кольцо с бриллиантом. Люди веками дарили такие кольца при ухаживании."
	path = /obj/item/clothing/accessory/ring/diamond
	slot = ITEM_SLOT_ACCESSORY
	ckeywhitelist = list("enc1:9a_7wwtg3FGNvdmGjwfh_3E0vuLoztjlunQttIbCQgKrxoZuf4Y22Q", "enc1:wjCE29ihhHhkiF8eSq5OSvomLGfmkncpfi08cJalqnsar1xR")

/datum/gear/donator/bm/cybersun_cloak
	name = "Cybersun Cloak"
	description = "Сувенирная версия без защиты плаща, который носят высокопоставленные сотрудники Cybersun. Cybersun восстанет!"
	path = /obj/item/clothing/neck/cloak/cybersun/civil
	slot = ITEM_SLOT_NECK
	ckeywhitelist = list("enc1:0VJlsOQoD7-7axhvl2k7IwGh_k9-GsKrXERto7YOL2V9SZHubh66Ew", "enc1:HP390l2garT2JwvNwjxJyX6wPuosjwnf125AwXCMvZhQgLPI", "sheya")

/datum/gear/donator/bm/toggles_combat_maid_civil
	name = "Combat Maid Sleeves"
	description = "Эти «тактические» перчатки и нарукавники огнеупорны и электроизолированы. Ещё и тёплые."
	path = /obj/item/clothing/gloves/toggled/hug/combat_maid_civil
	slot = ITEM_SLOT_GLOVES
	ckeywhitelist = list("enc1:SZvkmjU-7oC84CG7gVRA6jpYoa2n8AlFeFZDXNxvZbBzKh_h")

/datum/gear/donator/bm/long_fancy_kimono
	name = "Long Fancy Kimono"
	description = "Традиционная одежда из Японии. Специальное издание."
	path = /obj/item/clothing/suit/donator/bm/long_fancy_kimono
	slot = ITEM_SLOT_OCLOTHING
	ckeywhitelist = list("enc1:XagCJcs1DtEsWWM_y4Pi7EQfwAqbioXo6NsPWKX1QLK83Kcz")

/datum/gear/donator/bm/long_wintercoat
	name = "Long Winter Coat"
	description = "Тяжёлая меховая куртка с вставками из металлопокрытого аэрогеля, отлично сохраняющая тепло."
	path = /obj/item/clothing/suit/hooded/wintercoat/bm/donator/long_wintercoat
	slot = ITEM_SLOT_OCLOTHING
	ckeywhitelist = list("enc1:rozpGAp0vjEPGcxZ55baKOJibncZ8aD6-a10tseFS7NoTbTB6RI2oQ", "enc1:UAq_ejnBwTuhvSfsC5wBissC0hOHpWPWyify8o7LVuGDCVWl")

/datum/gear/donator/bm/wardrobe_box
	name = "Wardrobe Box"
	path = /obj/item/storage/box/wardrobe_box
	slot = ITEM_SLOT_BACKPACK
	ckeywhitelist = list("enc1:vRA_b0DHwCYJDDhET4zVt_kb2WZygOOhwBFcvSRZ-6jYgEGwv5_OvA", "enc1:X98CCFEfpaxjOlQ4zQbTQjBReTyCR8tHWgjpppkgH53IOKXI")

/datum/gear/donator/bm/toggles_poly_evening
	name = "Polychromic evening gloves"
	description = "Тонкие красивые полихромные перчатки для королевского женского наряда."
	path = /obj/item/clothing/gloves/toggled/hug/poly_evening
	slot = ITEM_SLOT_GLOVES
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#FEFEFE")
	ckeywhitelist = list("enc1:FcB3klMqU5S5TexFTJxWjWE66IBn9yTi-GZiVecDZjFdpYfmNQGRoQ")

/datum/gear/donator/bm/moonflower
	name = "Moonflower"
	description = "Храни в месте не менее 50 ярдов от оборотней."
	path = /obj/item/reagent_containers/food/snacks/grown/moonflower
	slot = ITEM_SLOT_HEAD
	ckeywhitelist = list("enc1:S3sZH1l3C4vLhYdSWAw9t6Er_RbmUa3_cmZF09vPCGSgttcBa-ITXQ")

/datum/gear/donator/bm/saareuni
	name = "SAARE BDU G3"
	description = "Стандартизированная форма GEN3 BATTLE DRESS UNIFORM, выдаётся каждому оперативнику для всех видов задач. Характерная эмблема SAARE на предплечье."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/donator/bm/saareuni
	ckeywhitelist = list("pingvas", "ordinarylife", "leony24", "kennedykiller", "theatlasplay", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus", "hateredsoul", "theatlasgaming", "silyamg", "hartty")

/datum/gear/donator/bm/saareflag
	name = "SAARE flag"
	description = "Сложенный флаг SAARE."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/sign/flag/saaref
	ckeywhitelist = list("pingvas", "ordinarylife", "leony24", "kennedykiller", "theatlasplay", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus", "hateredsoul", "theatlasgaming", "silyamg", "hartty")

/datum/gear/donator/bm/saarepatch
	name = "SFP Armpatch"
	description = "Нарукавная нашивка одного из превосходящих сил Federal Agencies на территории SolGov. Эта принадлежит Агенту."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/armband/sfparmband
	ckeywhitelist = list("pingvas", "ordinarylife", "leony24", "kennedykiller", "theatlasplay", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus", "silyamg", "hartty")

/datum/gear/donator/bm/bongepop_boxers
	name = "Bongepop Boxers"
	slot = ITEM_SLOT_UNDERWEAR
	path = /obj/item/clothing/underwear/briefs/bongepop
	ckeywhitelist = list("ordinarylife", "leony24", "kennedykiller", "theatlasplay", "ninjapikachushka", \
	"devildeadspace", "trustmeimengineer", "izakfromrus", "hazzi", "dolbajob", "vulpshiro", "pingvas", "silyamg", "hateredsoul")

/datum/gear/donator/bm/breadboots
	name = "Breadshoe"
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/breadboots
	ckeywhitelist = list("ordinarylife", "pingvas", "architect0r", "silyamg")

/datum/gear/donator/bm/breadboots/baguette
	name = "Baguetteshoe"
	path = /obj/item/clothing/shoes/breadboots/baguette

/datum/gear/donator/bm/breadpack
	name = "Breadpack"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/breadpack
	ckeywhitelist = list("ordinarylife", "pingvas", "architect0r", "silyamg")

/datum/gear/donator/bm/pet_emma
	name = "Emma Fox"
	description = "Эй, почему ты это смотришь?!! Пожалуйста, сообщи в Centcom об этом странном случае."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/emma
	ckeywhitelist = list("ordinarylife")

/datum/gear/donator/bm/skirt_tacticool
	name = "Tactical skirt"
	description = "Неприметная и слегка подозрительная юбка."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/dress/skirt/tacticool
	ckeywhitelist = list("definitelynotnesuby")

/datum/gear/donator/bm/portalabomination_kit
	name = "The WRONG portal kit"
	description = "Набор для переделки телескопической дубинки в богоуродливое оружие. Держи крепче."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/portalabomination_kit
	ckeywhitelist = list("architect0r")

/datum/gear/donator/bm/legion_mask_frank
	name = "Frank mask"
	description = "Безумная улыбка, которая преследует жертв в их кошмарах."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/legion
	ckeywhitelist = list("dimofon", "devildeadspace", "dimakr", "oroshimuraiori", "troubleneko17th", "dcp9371", "oni3288", "misteran")

/datum/gear/donator/bm/legion_mask_julie
	name = "Julie mask"
	description = "Безумная улыбка, которая преследует жертв в их кошмарах."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/legion/julie
	ckeywhitelist = list("dimofon", "devildeadspace", "dimakr", "oroshimuraiori", "troubleneko17th", "dcp9371", "oni3288", "misteran")

/datum/gear/donator/bm/legion_mask_joey
	name = "Joey mask"
	description = "Безумная улыбка, которая преследует жертв в их кошмарах."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/legion/joey
	ckeywhitelist = list("dimofon", "devildeadspace", "dimakr", "oroshimuraiori", "troubleneko17th", "dcp9371", "oni3288", "misteran")

/datum/gear/donator/bm/legion_mask_susie
	name = "Susie mask"
	description = "Безумная улыбка, которая преследует жертв в их кошмарах."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/legion/susie
	ckeywhitelist = list("dimofon", "devildeadspace", "dimakr", "oroshimuraiori", "troubleneko17th", "dcp9371", "oni3288", "misteran")

/datum/gear/donator/bm/kladmen_dress
	name = "Gothic Dress"
	description = "Длинное готическое платье, украшенное кружевными узорами."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/kladmen_dress
	ckeywhitelist = list("kladmenuwu")

/datum/gear/donator/bm/modsuit_syndicate
	name = "Syndicate Modsuit modkit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modsuit_modkit/syndicate_sec
	ckeywhitelist = list("domilion")
	//Это не целая плитка, её не нужно никак ограничивать. Не имея полноценного МОДа, это бесполезная вещь.
	// restricted_desc = "Security, Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	// restricted_roles = list("Captain", "Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/modsuit_magnate_heavy
	name = "Heavy Magnete Modsuit Plate"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/mod/construction/armor/magnate/heavy
	ckeywhitelist = list("cnaperdodo")
	restricted_desc = "Captain."
	restricted_roles = list("Captain")

/datum/gear/donator/bm/mentalplushie
	name = "Catshark Plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/catshark
	ckeywhitelist = list("mentaleater")

/datum/gear/donator/bm/fall_out_kit
	name = "Ranger Coat"
	description = "Военный ящик с полным набором формы рейнджера."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/fall_out_kit
	ckeywhitelist = list("dimofon", "devildeadspace", "mihana964")

/datum/gear/donator/bm/player_zippo
	name = "Player Zippo"
	description = "Потёртая зажигалка с неизвестным механизмом. Сзади видна вмятина..."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/lighter/plighter
	ckeywhitelist = list("stasdvrz", "dimofon", "devildeadspace", "angelnedemon")

/datum/gear/donator/bm/horror_mask
	name = "Horror_mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/horror_mask
	ckeywhitelist = list("dimakr")

/datum/gear/donator/bm/naivo_ushanka
	name = "Soviet Black Ushanka"
	description = "За союз!"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/ushanka/black
	ckeywhitelist = list("naivo")

/datum/gear/donator/bm/naivo_uniform
	name = "Soviet Black Uniform"
	description = "Стандартная форма Special Unit Rangers рассчитана на долгую и умеренную носку; лёгкие композитные ткани дают хорошую подвижность и лёгкость."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/soviet_uniform
	ckeywhitelist = list("naivo")

/datum/gear/donator/bm/naivo_gloves
	name = "Soviet Black Gloves"
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/color/black/soviet_gloves
	ckeywhitelist = list("naivo")

/datum/gear/donator/bm/naivo_jackboots
	name = "Soviet Black Jackboots"
	description = "Высококачественная одежда из смеси флиса и хлопка. На бирке видны логотип в виде орла и надпись Strategic Assault Tactical Team. Если вдохнуть запах — пахнет срезами военного преступления."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/jackboots/tall/soviet_jackboots
	ckeywhitelist = list("naivo")

/datum/gear/donator/bm/mu88
	name = "M.U. 88 New hope coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/mu88
	ckeywhitelist = list("hateredsoul", "milidead")

/datum/gear/donator/bm/mu88_swimsuit
	name = "M.U. 88 New hope swimsuit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/mu88_swimsuit
	ckeywhitelist = list("hateredsoul", "milidead")

/datum/gear/donator/bm/mu88_boots
	name = "M.U. 88 New hope boots"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/shoes/jackboots/tall/mu88_boots
	ckeywhitelist = list("hateredsoul", "milidead")

/datum/gear/donator/bm/mu88_horns
	name = "M.U. 88 New hope horns"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/head/donator/bm/mu88_horns
	ckeywhitelist = list("hateredsoul", "milidead")

/datum/gear/donator/bm/mu88_tie
	name = "M.U. 88 New hope tie"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/neck/tie/mu88_tie
	ckeywhitelist = list("hateredsoul", "milidead")

/datum/gear/donator/bm/cesar_tunic
	name = "Fancy tunic"
	description = "Удобная туника из дорогих тканей, украшенная золотыми нитями."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/cesar_tunic
	ckeywhitelist = list("nopeingeneer")

/datum/gear/donator/bm/cesar_crown
	name = "Golden laurel wreath"
	description = "Венок из лавровых листьев, сделанный из золота."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/laurel_crown
	ckeywhitelist = list("nopeingeneer")

/datum/gear/donator/bm/sheya_plush
	name = "Vampire plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/Sheya
	ckeywhitelist = list("sheya")

/datum/gear/donator/bm/sheya_plush_slime
	name = "Sheya plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/Sheya/slime
	ckeywhitelist = list("sheya")

/datum/gear/donator/bm/sheya_plush_melting
	name = "Melting love plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/Sheya/melting
	ckeywhitelist = list("sheya")

/datum/gear/donator/bm/vella
	name = "Vella plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/vella
	ckeywhitelist = list("aurses")

/datum/gear/donator/bm/belfor
	name = "Belfor plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/belfor
	ckeywhitelist = list("belf0r")

/datum/gear/donator/bm/nova_plush
	name = "Nova plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/nova
	ckeywhitelist = list("architect0r")

/datum/gear/donator/bm/zetta_plush
	name = "Zetta plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/zetta
	ckeywhitelist = list("hellsinggc", "tblkba")

///////////////////////////////////////////////

/datum/gear/donator/bm/dm_pzuniform
	name = "Grenadier uniform"
	description = "Удобная, прочная и надёжная форма, созданная для долгих переходов в суровых условиях. Внутри бирка с надписью «DM Arms»."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/dm_pzgrnd_uniform
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby", "fryktik", "deltarayx", "troubleneko17th")

/datum/gear/donator/bm/dm_pzsuit
	name = "Grenadier jacket"
	description = "Просторная куртка для подразделений сопровождения транспорта. Множество карманов и прочный кожаный ремень! Внутри бирка с надписью «DM Arms»."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/dm_pzgrnd_suit
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby", "fryktik", "deltarayx", "troubleneko17th")

/datum/gear/donator/bm/dm_pzhelmet
	name = "Pionier helmet"
	description = "Прочный шлем, в первую очередь для военных инженеров. В комплекте очки для защиты от пыли и обломков. Внутри видна надпись «DM Arms»."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/dm_pzgrnd_helmet
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby", "fryktik", "deltarayx", "troubleneko17th")

/datum/gear/donator/bm/dm_case
	name = "Infantry clothing case"
	description = "Кейс с готовой формой в лесном камуфляже. Видна бирка «DM Arms». Внутри комбинезон пехотинца, куртка и шлем."
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/case/dm_staff
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby", "fryktik", "deltarayx", "troubleneko17th")
	cost = 2

/datum/gear/donator/bm/dm_stg56
	name = "StG-56"
	description = "Набор для переделки WT-550 в Sturmgewehr-56."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/stg56
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby", "fryktik")

///////////////////////////////////////////////

/datum/gear/donator/bm/mk6_suit
	name = "MK-VII Tactical suit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/mk6_suit
	ckeywhitelist = list("dragon9090")

/datum/gear/donator/bm/apronchef_red
	name = "Gubby Family Apron"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/apronchef_red
	ckeywhitelist = list("artgel11")

///////////////////////////////////////////////

/datum/gear/donator/bm/shark_pajamas
	name = "Shark Pajamas"
	description = "Мягкая пижама в форме акулы — разве это не мило?"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/toggle/shark
	ckeywhitelist = list("shizalrp", "deltarayx")

///////////////////////////////////////////////

/datum/gear/donator/bm/lsweater
	name = "Sweater"
	description = "Свитер, принадлежащий какой-то лисе."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/lsweater
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/longtie
	name = "Long Tie"
	description = "Какой-то длинный галстук."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/longtie
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/lskirt
	name = "Short Skirt"
	description = "Короткая плиссированная юбка."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/dress/skirt/lskirt
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/invis_belt_kit
	name = "Invisible Belt Kit"
	description = "Набор для переделки чего-то во что-то."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/invis_belt
	ckeywhitelist = list("enc1:D5TDsqpqFc0DDW2927vJnDyLXpoEZJ07NBHp64oPeZQZoPxSbNoOhg", "enc1:owrU4CHVDDC6Ef2XlHdwNlhpjuutJJ-2X_hJvwoJ9ded8NQG")

/datum/gear/donator/bm/verdant_suit
	name = "Verdant Tactical Suit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/verdant
	ckeywhitelist = list("dragon9090")

/datum/gear/donator/bm/imperium_flags
	name = "Imperium flag kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/imperium_flags
	ckeywhitelist = list("domilion")

/datum/gear/donator/bm/gestapo_uniform
	name = "Truth Enforcer Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/gestapo
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/gestapo_cloak
	name = "Truth Enforcer cloak"
	description = "Отлично!"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/gestapo
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/gestapo_head
	name = "Truth Enforcer Cap"
	description = "Верши правосудие..!~"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/gestapo
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/gestapo_mask
	name = "Truth Enforcer Mask"
	description = "Фильтруй их мысли."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/breath/gestapo
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/cultist_poly
	name = "Aged Robe"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/cultist_poly
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#202020", "#C5302D")
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/exo_legs
	name = "Exo Legs"
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/exo_legs
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#202020", "#C5302D")
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/dark_sabre_kit
	name = "Dark Omen Sword Kit"
	description = "Набор для переделки энергетического/плазменного меча в меч Dark Omen."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/dark_sabre_kit
	ckeywhitelist = list("hellsinggc")

/datum/gear/donator/bm/gosei
	name = "Gosei.H.mk27"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/helmet/sec/gosei
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/mark40k_helmet
	name = "Mark40k Armored Head plates"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/mark40k_helmet
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/saibasan
	name = "Cybersun Surplus"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/saibasan
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/opssrt
	name = "OPS-SRT Helmet"
	description = "Даётся тем, кто хорошо служил."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/opssrt
	ckeywhitelist = list("monolithxxv", "mishanok")

/datum/gear/donator/bm/medaldoblest
	name = "Медаль"
	description = "Сделано из мельхиора, круглой формы, диаметром 32 мм с выпуклым ободом с обеих сторон."
	slot = ITEM_SLOT_ACCESSORY
	path = /obj/item/clothing/accessory/medaldoblest
	ckeywhitelist = list("monolithxxv", "mishanok")

/datum/gear/donator/bm/opssrtclothes
	name = "OPS-SRT Clothing"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/opssrtclothes
	ckeywhitelist = list("monolithxxv", "mishanok")

/datum/gear/donator/bm/opssrtarmor
	name = "OPS-SRT Plate Carrier"
	description = "Система плиточного носителя."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/opssrtarmor
	ckeywhitelist = list("monolithxxv", "mishanok")

/datum/gear/donator/bm/mark50k_helmet
	name = "Mark50k Armored Head plates"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/mark50k_helmet
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/mark40k_armor
	name = "Mark40k Armored Chest plates"
	description = "Быстросъёмные бронеплиты."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/mark40k_armor
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/mark50k_armor
	name = "Mark50k Armored Chest plates"
	description = "Быстросъёмные бронеплиты."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/mark50k_armor
//	ckeywhitelist = list("monolithxxv")
	subcategory = LOADOUT_SUBCATEGORIES_DON05

/datum/gear/donator/bm/ntrdrip
	name = "Nanotrasen Representative Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/ntrdrip
	ckeywhitelist = list("monolithxxv", "sketchyirishman")

/datum/gear/donator/bm/chetky_cap
	name = "Chetky Cap"
	description = "крутая кепка."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/chetky_cap
	ckeywhitelist = list("ordinarylife", "pingvas", "leony24", "kennedykiller", "theatlasplay", "theatlasgaming", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus", "hateredsoul", "vulpshiro", "dolbajob", "stgs")

/datum/gear/donator/bm/chetky_g3jacket
	name = "Chetky G3 Jacket"
	description = "крутая куртка."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/chetky_g3jacket
	ckeywhitelist = list("ordinarylife", "pingvas", "leony24", "kennedykiller", "theatlasplay", "theatlasgaming", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus", "hateredsoul", "vulpshiro", "dolbajob", "stgs")

/datum/gear/donator/bm/lizared_exposed
	name = "LIZARED Open Panties"
	slot = ITEM_SLOT_UNDERWEAR
	path = /obj/item/clothing/underwear/briefs/panties/lizared/exposed
	ckeywhitelist = list("pingvas", "ty4kahahebe", "blatoff")

/datum/gear/donator/bm/custom_vape
	name = "Custom E-Cigarette"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/vape/custom
	ckeywhitelist = list("ordinarylife", "pingvas", "leony24", "kennedykiller", "theatlasplay", "theatlasgaming", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus", "hateredsoul", "vulpshiro", "dolbajob", "stgs", "silyamg", "tblkba", "dimofon")

/datum/gear/donator/bm/crocinsmoke
	name = "Crocin smoke"
	description = "Эта книга переполнена похотливыми искусствами."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/book/granter/spell/smoke/crocin
	ckeywhitelist = list("deadlizard")
	cost = 2

/datum/gear/donator/bm/crocinsmoke/on_spawn(mob/living/carbon/human/user, obj/item/book/granter/spell/smoke/crocin/I)
	if(!istype(user))
		return
	I.on_reading_finished(user)
	qdel(I)

/datum/gear/donator/bm/twilight_spike
	name = "Twilight Spike"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/donator/bm/twilight_spike
	ckeywhitelist = list("dragon9090", "hellsinggc", "pingvas")

/datum/gear/donator/bm/sf_coat
	name = "S.F. Coat"
	description = "Это пальто потрясающее, правда?"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/sf_coat
	ckeywhitelist = list("hihitect", "xaeshkavd")

/datum/gear/donator/bm/freak_case
	name = "Cool Case With Presents"
	description = "Это специальный кейс, сделанный только для офицеров NanoTrasen."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/backpack/case/command/freak
	ckeywhitelist = list("freakowo")
	handle_post_equip = TRUE

/datum/gear/donator/bm/fire_blossom
	name = "Fire blossom"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/fire_blossom
	ckeywhitelist = list("sheya", "dagran")

/datum/gear/donator/bm/desert_nanosuit
	name = "Desert Nanosuit"
	description = "Удобное бельё, которое облегает всё тело и защищает от мелких частиц. Особенно полезно в пустынях, где песок везде. Только для каткринов!"
	slot = ITEM_SLOT_UNDERWEAR
	path = /obj/item/clothing/underwear/briefs/nano_suit
	ckeywhitelist = list("lindaastereih", "kingdeaths", "heathkit1", "dimofon", "tblkba", "deltarayx")

/datum/gear/donator/bm/bear_patch
	name = "BEAR Patch"
	description = "BEAR — символы 446-й специальной разведывательной группы Charlie-отряда USCM."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/bear_patch
	ckeywhitelist = list("hihitect", "hateredsoul", "hellsinggc", "silyamg", "dimofon", "xaeshkavd", "hartty", "ordinarylife")

/datum/gear/donator/bm/usec_patch
	name = "USEC Patch"
	description = "USEC — стандартная символика солдат-контрактников PCCMG. Как говорят: всегда настороже, всегда под наблюдением."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/usec_patch
	ckeywhitelist = list("hihitect", "hateredsoul", "hellsinggc", "silyamg", "dimofon", "xaeshkavd", "hartty", "ordinarylife")

/datum/gear/donator/bm/transparent_gloves
	name = "Transparent Gloves"
	description = "Обычные перчатки из прозрачного материала."
	path = /obj/item/clothing/gloves/color/black/transparent
	slot = ITEM_SLOT_GLOVES
	ckeywhitelist = list("lindaastereih", "deltarayx")

/datum/gear/donator/bm/winter_mask
	name = "Ami's Winter Mask"
	description = "Если присмотреться, внутри маски написано имя владельца — Ami'Ira Vel'Ssaran. Снаружи это обычная белая маска военного образца."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/cool_version/winter_mask
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/p226_syndicate
	name = "P226 'Syndicate' Kit"
	description = "Набор для переделки Enforcer Gun в P226 «Syndicate»."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/p226_syndicate
	ckeywhitelist = list("vladtv05")

/datum/gear/donator/bm/toy_plasma_scythe
	name = "Toy Plasma Scythe"
	description = "Дешёвая пластиковая копия плазменной косы. Реалистичные свет и звуки! С 8 лет."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/plasmascythe/toy
	ckeywhitelist = list("freakowo")

/datum/gear/donator/bm/toy_sledgehammer
	name = "Toy Sledgehammer"
	description = "Дешёвая пластиковая копия кувалды InteQ. БОНК!"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/inteq_sledgehammer/toy
	ckeywhitelist = list("freakowo", "belf0r")

/datum/gear/donator/bm/invisible_ac
	name = "Invisible Armored Coat"
	path = /obj/item/clothing/suit/toggle/captains_parade/hos_formal/ac/invisible
	slot = ITEM_SLOT_OCLOTHING
	restricted_desc = "Head of Security, Warden, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Blueshield")
	ckeywhitelist = list("lapkee")

/datum/gear/donator/bm/kladmenuwu_sweater
	name = "Worm Sweater"
	description = "Очень мягкий и тёплый свитер с бантиками, пришитыми на рукавах."
	path = /obj/item/clothing/suit/donator/bm/kladmenuwu_sweater
	slot = ITEM_SLOT_OCLOTHING
	ckeywhitelist = list("kladmenuwu")

/datum/gear/donator/bm/cybersun_kit
	name = "Cybersun kit"
	description = "Военный ящик с полным набором снаряжения Cybersun."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/cybersun_kit
	ckeywhitelist = list("sheya")

/datum/gear/donator/bm/sheya_dress
	name = "Gothic dress"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/sheya
	ckeywhitelist = list("sheya")

/datum/gear/donator/bm/nul_kit
	name = "Sword of Nul Kit"
	description = "Набор для переделки боевого ножа в Меч Нуля."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/nul_kit
	ckeywhitelist = list("lev1932")

/datum/gear/donator/bm/casull_kit
	name = "Casull Kit"
	description = "Набор для переделки Enforcer Gun в Casull."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/casull_kit
	ckeywhitelist = list("lev1932")

/datum/gear/donator/bm/bwal_special_kit
	name = "B-Wal-Special Kit"
	description = "Набор для переделки B-Wal-2572 в B-Wal-Special."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/bwal_special_kit
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/captain_rifle_kit
	name = "Antique Laser Rifle Kit"
	description = "Набор для переделки антикварного лазерного пистолета в антикварную лазерную винтовку."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/captain_rifle_kit
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/ftucloak
	name = "FTU Cape"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/ftu
	ckeywhitelist = list("fanlexa", "kosep", "dragoncora")

/datum/gear/donator/bm/binary_cloak
	name = "Binary Cloak"
	description = "Пушистый тёмный плащ с шестиугольными золотыми узорами, покрывающими его правую сторону."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/binary/alt
	ckeywhitelist = list("homandos")

/datum/gear/donator/bm/pedantcape
	name = "Corvus Pendant"
	description = "Вороны чёрные, с зоркими глазами, воруют блестящие кулоны с серебряным отливом."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/tie/pendantcape
	ckeywhitelist = list("smol42", "weirdbutton", "sage4or")

/datum/gear/donator/bm/agentcape
	name = "Marketing agent's cape"
	description = "Плащ рекламного агента пропитан запахом лапши быстрого приготовления."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/agentcape
	ckeywhitelist = list("sosnovskii")

/datum/gear/donator/bm/hahun_cape
	name = "MI13 cape"
	description = "Плащ, который вручается доверенным агентам Синдиката; приятный на ощупь и очень стильный, при этом вообще не сковывает движения."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/tie/hahun_cape
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/eidolon_cape
	name = "Eidolon officer cape"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/eidolon_cape
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/winter_cape
	name = "Winter Cape"
	description = "Плащ из довольно плотной ткани с золотой отделкой. Сам плащ выполнен в зимнем стиле, со ледяными акцентами и заметными золотыми погонами."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/wintercape
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/eclipse_cape
	name = "Eclipse cape"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/eclipse_cape
	ckeywhitelist = list("shizalrp", "krasler101")

/datum/gear/donator/bm/Gelriter_kit
	name = "Gelriter-22 kit"
	description = "Набор для переделки G-22 M.1 в Gelriter-22 M-1."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/Gelriter_22
	ckeywhitelist = list("tblkba","lindaastereih")

/datum/gear/donator/bm/fancy_laser_kit
	name = "Fancy Laser Rifle Kit"
	description = "Набор для переделки антикварного лазерного пистолета в нарядную лазерную винтовку."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/fancy_rifle_kit
	ckeywhitelist = list("tblkba", "lindaastereih")

/datum/gear/donator/bm/blood_suit
	name = "crimson aristocracy suit"
	description = "Изысканный костюм, окрашенный в глубокие красные тона. Пиджак дополнен золотой нитью и свободной белой рубашкой."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/blood_suit
	ckeywhitelist = list("tblkba")

/datum/gear/donator/bm/blood_shinel
	name = "crimson aristocracy shinel"
	description = "Пальто, напоминающее военную шинель, в бордовых цветах, прошитое золотыми нитями и дополненное такими же янтарными пуговицами."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/captains_parade/blood_shinel
	ckeywhitelist = list("tblkba")
	restricted_desc = "Captain."
	restricted_roles = list("Captain")

/datum/gear/donator/bm/blood_boots
	name = "crimson aristocracy boots"
	description = "Кожаные ботинки бордовых оттенков, прошитые кроваво-красной нитью."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/blood_boots
	ckeywhitelist = list("tblkba")

/datum/gear/donator/bm/armolex_box
	name = "Armolex Box"
	description = "Военный ящик с несколькими наборами оружия. Привет от XVD."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/donator/bm/armolex_box
	ckeywhitelist = list("xaeshkavd", "sosnovskii", "hellsinggc", "ty4kahahebe", "enc1:cqe8OokEA5MzamwCWfeHJEIgBZllmKLlOJBOyMOT2YvPmul1kJDJXA")

/datum/gear/donator/bm/jason_mask
	name = "Jason Mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/plaguedoctor/jason
	ckeywhitelist = list("goblin335", "mixalic")

/datum/gear/donator/bm/skull_flag
	name = "PMC Skull flag"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/sign/flag/skull
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob", "vulpshiro", "sodastrike", "lonofera", "mihana964", "hellsinggc", "devildeadspace")

/datum/gear/donator/bm/vape
	name = "Vape"
	description = "Классная и крайне изысканная электронная сигарета для классных и достойных джентльменов. На предупредительной наклейке написано: «Внимание: не заполнять горючими материалами»."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/vape
	ckeywhitelist = list("trollandrew")

/datum/gear/donator/bm/electropack
	name = "Electropack"
	description = "Танцуй, мои обезьяны! ТАНЦУЙ!!!"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/electropack
	ckeywhitelist = list("trollandrew")

/datum/gear/donator/bm/straight_jacket
	name = "Straight Jacket"
	description = "Костюм, полностью сковывающий владельца. Произведено корпорацией Antyphun."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/straight_jacket
	ckeywhitelist = list("trollandrew")

/datum/gear/donator/bm/boxing
	name = "Boxing Gloves"
	description = "Потому что тебе правда нужен был ещё один повод ударить напарника."
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/boxing
	ckeywhitelist = list("trollandrew")

/datum/gear/donator/bm/dc_helmet
	name = "Agent Headgear"
	description = "Похищай со стилем — стилем шипов."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/helmet/dragoncora
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_suit
	name = "Agent Suit"
	description = "Жилет, оснащённый передовой технологией скрытности. Есть два режима — боевой и скрытный."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/armor/dragoncora
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_helmet2
	name = "FTU Combat Skull"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/helmet/skull/ftu
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_suit2
	name = "FTU Security Armor"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/armor/vest/dragoncora
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_gloves
	name = "SpecOps Guerrilla Gloves"
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/color/black/dragoncora
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_gorka
	name = "SpecOps Gorka"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/inteq/tactical_gorka
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_boots
	name = "Combat Boots"
	description = "Боевые ботинки с высокой скоростью и низким сопротивлением."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/dragoncora
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_backpack
	name = "Tactical Backpack"
	description = "Ты носишь это на спине и складываешь внутрь вещи."
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/dragoncora
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_suit3
	name = "Trench Coat"
	description = "Многоцелевой тренч XVIII века. У этого на шее шнурок."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/det_suit/lanyard/dragoncora
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_headset
	name = "Alien Headset"
	description = "Продвинутый инопланетный гарнитур, созданный для прослушивания коммуникаций человеческих космических станций. Почему у него есть микрофон? Никто не знает."
	slot = ITEM_SLOT_EARS
	path = /obj/item/radio/headset/dragoncora
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/dc_mask
	name = "Russian Balaclava"
	description = "Защищает твоё лицо от снега."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/russian_balaclava
	ckeywhitelist = list("dragoncora")

/datum/gear/donator/bm/anti_armor
	name = "Armor Softening Nanites Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/anti_armor
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/lapkee_kit
	name = "Nebula Box"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/lapkee_kit
	ckeywhitelist = list("lapkee")

/datum/gear/donator/backpack/lipstick/heartboom
	name = "Heartboom Lipstick"
	path = /obj/item/lipstick/heartboom
	ckeywhitelist = list("liesbee")

/datum/gear/donator/bm/personal_ward
	name = "Personal Ward Box"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/donator/bm/personal_ward
	ckeywhitelist = list("shizalrp", "krasler101", "kingdeaths", "vlonger")

/datum/gear/donator/bm/kila_mask
	name = "Mask-1Щ 'Killa edition'"
	description = "Это странный шлем, ни от чего не защищает."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/kila_mask
	ckeywhitelist = list("vlonger")

/datum/gear/donator/bm/h_pmc_jeans
	name = "PMC jeans"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/h_pmc_jeans
	ckeywhitelist = list("hateredsoul")

/datum/gear/donator/bm/h_thin_tshirt
	name = "Thin T-shirt"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/shirt/h_thin_tshirt
	ckeywhitelist = list("hateredsoul", "angelnedemon", "dregendur")

/datum/gear/donator/bm/h_slim_tshirt
	name = "Slim T-shirt"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/briefs/h_thin_slim_tshirt
	ckeywhitelist = list("hateredsoul", "angelnedemon", "dregendur")

/datum/gear/donator/bm/h_eslim_tshirt
	name = "EXTRA slim T-shirt"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/briefs/h_thin_eslim_tshirt
	ckeywhitelist = list("hateredsoul", "angelnedemon", "dregendur")

/datum/gear/donator/bm/scream_knife_kit
	name = "Scream Knife Kit"
	description = "Набор для переделки боевого ножа в нож Scream."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/scream_knife_kit
	ckeywhitelist = list("dimofon", "pingvas", "devildeadspace", "dimakr")

/datum/gear/donator/bm/sport_abibas_bag
	name = "Sport 'ABIBAS' satchel"
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/sport_abibas_bag
	ckeywhitelist = list("ty4kahahebe", "pingvas")

/datum/gear/donator/bm/renory_jumpsuit
	name = "Leather Jumpsuit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/renory_jumpsuit
	ckeywhitelist = list("kumikoshouko")

/datum/gear/donator/bm/renory_helmet
	name = "Motorcycle Helmet"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/renory_helmet
	ckeywhitelist = list("kumikoshouko")

/datum/gear/donator/bm/krieg_mask
	name = "Противогаз Крига"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/krieg
	ckeywhitelist = list("vlonger", "pingavas", "dragon9090")

/datum/gear/donator/bm/krieg_helmet
	name = "Шлем Крига"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/krieg_helmet
	ckeywhitelist = list("vlonger",  "dragon9090")

/datum/gear/donator/bm/krieg_shinel
	name = "Шенель Крига"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/krieg_shinel
	ckeywhitelist = list("vlonger", "pingavas", "dragon9090")

/datum/gear/donator/bm/krieg_backpack
	name = "Рюкзак Крига"
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/krieg
	ckeywhitelist = list("vlonger", "pingavas", "dragon9090")

/datum/gear/donator/bm/pmc_skull_mask
	name = "Skull mask"
	description = "Без страха, без сожалений, без пощады."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/pmc_skull_mask
	ckeywhitelist = list("hateredsoul", "hartty")

/datum/gear/donator/bm/sc_winter_coat
	name = "Security winter coat"
	description = "Красное зимнее пальто с бронированной подкладкой. Блестит лёгким абляционным покрытием и солидным видом власти. Бегунок молнии — пара дребезжащих наручников, которые начинают раздражать уже через первые десять секунд."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/hooded/wintercoat/security/no_armor
	ckeywhitelist = list("iistrizhii")

/datum/gear/donator/bm/oversize_shirt

	name = "Oversized checkered shirt"
	description = "Простая прочная рубашка навыпуск неизвестной марки с нашивкой на кармане груди: «Позволь моему сердцу говорить»."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/oversize
	ckeywhitelist = list("moun4l")

/datum/gear/donator/bm/slim_body_and_shorts
	name = "Comfortable short bodysuit with athletic shorts"
	description = "Прочитай имя, не знаю."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/h_slim_body_and_shorts
	ckeywhitelist = list("hateredsoul")

/datum/gear/donator/bm/torn_veil
	name = "Shimmering torn veil"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/torn_veil
	ckeywhitelist = list("hateredsoul")

/datum/gear/donator/bm/stupid_cap
	name = "Propeller beanie"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/stupid_cap
	ckeywhitelist = list("angelnedemon", "keerw1n")

/datum/gear/donator/bm/infovisor
	name = "Infovisor"
	description = "Стандартный старый забрало, позволяющий быстро осмотреть местность."
	slot = ITEM_SLOT_EYES
	path = /obj/item/clothing/glasses/cover/infovisor
	ckeywhitelist = list("lindaastereih", "deltarayx")

/datum/gear/donator/bm/vulpix_pilot_badge
	name = "Pilots Federation Badge"
	slot = ITEM_SLOT_ACCESSORY
	path = /obj/item/clothing/accessory/medal/vulpix_pilot_badge
	cost = 0
	ckeywhitelist = list("alexhosted", "gsvden")

/datum/gear/donator/bm/yun_cap
	name = "strange chinese cap"
	description = "Строй призраков."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/yun_cap
	ckeywhitelist = list("victorpoplavsy")

/datum/gear/donator/bm/yun_outfit
	name = "strange chinese clothing"
	description = "Готовься к битве, готовься к войне, готовься к настоящей УЛИЧНОЙ КРОВАВОЙ ВОЙНЕ!"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/bm/yun_outfit
	ckeywhitelist = list("victorpoplavsy")

/datum/gear/donator/bm/yun_sneakers
	name = "strange sneakers"
	description = "Обычные кроссовки. Или нет."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/yun_sneakers
	ckeywhitelist = list("victorpoplavsy")

/datum/gear/donator/bm/antique_cape
	name = "Antique cape"
	description = "Антикварный плащ, напоминающий ушедшие времена."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/donator/bm/antique_cape
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#777777", "#FFFFCC", "#66FFFF")
	ckeywhitelist = list("ingvarr3313", "shizalrp", "enc1:pkq2i9bnjHJwyQ1lyRkpsDIAm2vKB3R0uvIY9-OhtCGGRCeG4xiAhw")

/datum/gear/donator/bm/longshirt
	name = "Long Shirt"
	description = "Просто длинная рубашка, и всё."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/longshirt
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/custom_helmet
	name = "Custom helmet"
	description = "Старый шлем, хорошо сделанный энтузиастом. Выглядит как настоящий, но ощущается как модель — такой лёгкий. Пластины сняты, как и электроника."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/custom_helmet
	ckeywhitelist = list("hartty", "hateredsoul", "ordinarylife", "dalphy12")

/datum/gear/donator/bm/commando_beret
	name = "Commando beret"
	description = "В память о Коваке."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/commando_beret
	ckeywhitelist = list("hartty", "hateredsoul", "leony24", "rockymed", "coshak", "mihana964")

/datum/gear/donator/bm/vp78tactic
	name = "VP78 Tactic ModKit"
	description = "Набор для переделки тактической версии пистолета Enforcer."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/vp78tactic
	ckeywhitelist = list("rockymed", "hartty", "leony24", "dragon9090")

/datum/gear/donator/bm/flag_marine
	name = "UA flag"
	description = "Сложенный флаг Соединённых Америк, сокращённо UA."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/sign/flag/marine/ua
	ckeywhitelist = list("rockymed")

/datum/gear/donator/bm/kumikoshouko_case
	name = "Supply Case"
	description = "Военный ящик с оружием, выданный одному коллекционеру. На крышке выгравировано: «Один ящик, чтобы править всеми». Внутри полный набор наборов для модификации личного оружия."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/kumikoshouko_case
	ckeywhitelist = list("kumikoshouko", "ottasuka", "foxrtotlimda", "1hollowknight1")

/datum/gear/donator/bm/skull_half_mask
	name = "Skull Gaiter"
	description = "Гайтер из высококачественных материалов. Внутри бирка: Harr."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/half_mask_skull
	ckeywhitelist = list("hartty")

/datum/gear/donator/bm/mountaineering_jacket
    name = "Mountaineering Jacket"
    description = "Куртка из плотного качественного материала. На бирке написано: «Сделано в Таркове». На второй — «Harr». Она напоминает о человеке с прозвищем Штурман."
    slot = ITEM_SLOT_OCLOTHING
    path = /obj/item/clothing/suit/hooded/wintercoat/mountaineering_jacket
    ckeywhitelist = list("hartty", "ordinarylife", "spoopyman228")

/datum/gear/donator/bm/robosleek
	name = "Sleek roboticist's jumpsuit"
	description = "Стройный чёрный с укреплёнными швами — отлично для промышленной работы."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/rank/rnd/roboticist/sleek
	ckeywhitelist = list("deltarayx")

/datum/gear/donator/bm/black_sneakers
	name = "Black Sneakers"
	description = "Чёрные кроссовки из лимитированной коллекции. На бирке: «Harr»."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/black_sneakers
	ckeywhitelist = list("hartty", "sawwarrr")

/datum/gear/donator/bm/wypmckit
	name = "Arctic PMC kit"
	description = "Военный ящик с полным набором арктического ЧВК."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/wypmcbox
	ckeywhitelist = list("foxrtotlimda")

/datum/gear/donator/bm/wypmcbackpack
	name = "Arctic PMC packed radiostation"
	description = "Судя по камуфляжу и разным видам печатей, эта портативная радиостанция со встроенным рюкзаком для хранения различных вещей принадлежит частной военной организации."
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/wypmcbackpack
	ckeywhitelist = list("foxrtotlimda")

/datum/gear/donator/bm/wypmcgasmask
	name = "Arctic PMC gasmask"
	description = "Специализированный противогаз для специальных полицейских подразделений. Это довольно хорошее средство индивидуальной защиты органов дыхания, глаз и лица от токсичных веществ, радиоактивной пыли и продуктов горения."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/wypmc_gasmask
	ckeywhitelist = list("foxrtotlimda")

/datum/gear/donator/bm/atomas_fluted_armor
	name = "Fluted Plate Armor"
	description = "Костюм из изысканных лат, благородный и внешне, и по защите. Такие великолепные доспехи традиционно предназначаются для высших слоёв знати; закалённые рыцари, почитаемые короли и пузатые советники, желающие щегольнуть богатством перед немытыми массами."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/fulted_plate_armor
	ckeywhitelist = list("atomas")

/datum/gear/donator/bm/atomas_hounskull
	name = "Hounskull With Aventail"
	description = "Стальной бавникет с толстой кольчужной барбетой, укреплённой изнутри. Как лягушачий шлем подобает рыцарю на турнире, так и бавникет с барбетой подобает рыцарю на поле боя: непревзойдён по покрытию, прочности и весу."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/hounskull_with_aventail
	ckeywhitelist = list("atomas")

/datum/gear/donator/bm/melatonin_bodysuit
	name = "Lycanthrope's Form-Fitting Bodysuit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/melatonin_bodysuit
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/melatonin_coat
	name = "Lycanthrope's Worn Coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/melatonin_coat
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/melatonin_kit
	name = "Melatonin Kit Box"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/melatonin_kit
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/melatonin_bola_kit
	name = "Entangling Bola Crafting Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/melatonin_bola_kit
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/tau_kit
	name = "Tau modkits Box"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/tau_box
	ckeywhitelist = list("modyrator")

/datum/gear/donator/bm/melatonin_disco_shirt
	name = "Lycanthrope Disco Shirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/melatonin_disco
	ckeywhitelist = list("melatonin1")

/datum/gear/donator/bm/sawwr_coat
	name = "Dark Amber"
	description = "Практичный плащ, сделанный в глубоких чёрных тонах с янтарно-золотыми акцентами — суровый, но при этом как бы неуклюжий. Необычное сочетание деталей создаёт впечатление одежды, собранной ради удобства, а не красоты."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/sawwr_coat
	ckeywhitelist = list("hartty", "sawwarrr")

/datum/gear/donator/bm/sawwr_ice_axe_kit
	name = "Ice Axe Kit"
	description = "Набор для переделки дубинки в ледоруб."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/ice_axe_kit
	ckeywhitelist = list("hartty")

/datum/gear/donator/bm/the_stylish_one_tracksuit
	name = "The stylish one's tracksuit"
	description = "Дорогие гости прибыли."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/the_stylish_one_tracksuit
	ckeywhitelist = list("hartty", "meowonty")

/datum/gear/donator/bm/xeno_waller
	name = "Xeno Wallet"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/wallet/xeno
	ckeywhitelist = list("kumikoshouko", "foxrtotlimda")

/datum/gear/donator/bm/skeleton_suit
	name = "Skeleton suit"
	description = "Плотный чёрный костюм с рисунком в виде костей."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/skeleton_suit
	ckeywhitelist = list("kumikoshouko", "1hollowknight1")

/datum/gear/donator/bm/pumpkin_cat
	name = "Pumpkin"
	description = "Странная тыква с кошачьими ушами сверху."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/donator/bm/pumpkin_cat
	ckeywhitelist = list("kumikoshouko", "1hollowknight1")

/datum/gear/donator/bm/light_plate_carrier
	name = "Light plate carrier"
	description = "Набор для переделки бронежилета в облегчённый плиточный носитель."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/light_plate_carrier
	ckeywhitelist = list("hartty", "spoopyman228", "dalphy12", "leony24", "rockymed", "hateredsoul")

/datum/gear/donator/bm/honorable_coat
	name = "Honorable coa"
	description = "Старый почётный пальто, довольно дорогое."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/donator/bm/honorable_coat
	ckeywhitelist = list("kumikoshouko")

/datum/gear/donator/bm/mall_cop_chic
	name = "Mall Cop Chic"
	description = "Брюки из секонд-хенда, которые кто-то перешил, добавил ремни от старого рюкзака и назвал это «стилем». Кто-то явно хотел выглядеть элитным наёмником, а получилось как у охранника торгового центра. Они прикрывают твою задницу. Спасибо."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/mall_cop_chic
	ckeywhitelist = list("sawwarrr", "boroven", "hartty")

/datum/gear/donator/bm/arsmaid_suit
	name = "Maid Suit"
	description = "Костюм горничной."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/arsmaid_suit
	ckeywhitelist = list("TheARS")

/datum/gear/donator/bm/taxedo
	name = "Taxedo Suit"
	description = "Смокинг с узорами в виде скелета, аккуратный."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/taxedo
	ckeywhitelist = list("kumikoshouko")

/datum/gear/donator/bm/crimson_dress
	name = "Crimson Dress"
	description = "Пурпурное платье с чёрными рукавами и корсетом в комплекте. При ближайшем рассмотрении видно, что одежда сшита на заказ из дорогих качественных материалов. От неё пахнет розами, цвета которого она и напоминает."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/crimson_dress
	ckeywhitelist = list("sawwarrr", "angelnedemon", "hartty")

/datum/gear/donator/bm/pumpkin_bag
	name = "Pumpkin Bag"
	description = "Сумка в форме тыквы, в которой помещается всякая вкуснятина!"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/spooky
	ckeywhitelist = list("kumikoshouko")

/datum/gear/donator/bm/br_pilotsuit_mk1
	name = "BLACKROSE© Mark.I Pilot Suit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/br_pilotsuit_mk1
	ckeywhitelist = list("hateredsoul")

/datum/gear/donator/bm/br_pilotjacket_s5
	name = "BLACKROSE© Pilot Jacket Series V"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/br_pilotjacket_s5
	ckeywhitelist = list("hateredsoul", "angelnedemon")

/datum/gear/donator/bm/solgoy_box
	name = "Sol Fed army box"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/solgoy_box
	ckeywhitelist = list("rockymed", "hartty", "dragon9090", "leony24", "theatlasgaming", "kennedykiller")
