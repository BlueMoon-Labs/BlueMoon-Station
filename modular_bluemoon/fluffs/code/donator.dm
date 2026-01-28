//Файл для выдачи предметов донатерам по сикею
// Сикеи необходимо указывать, аналогично их файлу сохрания лодаута, пример "AA-BB-ab..." нужно записывать как "aabbab"

/*
/datum/gear/donator/bm
	name = "Видишь это - пингуй Feenie#1815" //Название предмета
	slot = ITEM_SLOT_BACKPACK //Место, в который будет выдаваться предмет, конкретно тут - кладётся в рюкзак
	path = /obj/item/bikehorn/golden //Ссылка на датум объекта
	category = LOADOUT_CATEGORY_DONATOR //Категория, в которой будет содержаться предмет - собственно во вкладке лодаута донатерских
	ckeywhitelist = list("Сикей получателя") //Если вы видите этот текст ингейм, значит кто-то ебанулся с кодом - пингуйте всё того же
*/

/datum/gear/donator/bm
	name = "Crown of Pure Tyranny"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/pt_crown
	ckeywhitelist = list("snacksman")
	subcategory = LOADOUT_SUBCATEGORIES_DON03
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
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/head/helmet/space/plasmaman/security/reaper
	ckeywhitelist = list("reaperdb")

/datum/gear/donator/bm/reaper_suit
	name = "Reaper Suit"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/plasmaman/security/reaper
	ckeywhitelist = list("reaperdb")

/datum/gear/donator/bm/ellys_suit
	name = "Ellys Costume"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/ellys_suit
	ckeywhitelist = list("chowny")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/ellys_hoodie
	name = "Ellys Hoodie"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/ellys_hoodie
	ckeywhitelist = list("chowny")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/modern_watch
	name = "modern watch"
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
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/blueflame
	ckeywhitelist = list("weirdbutton", "xaeshkavd")

/datum/gear/donator/bm/gorka
	name = "Gorka"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/gorka
	ckeywhitelist = list("leony24", "vulpshiro", "dolbajob", "trustmeimengineer", "stgs", "krashly", "hazzi", "devildeadspace", "enigma418")

/datum/gear/donator/bm/pet_moro
	name = "Moro Cat"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/moro
	ckeywhitelist = list("hazzi")

/datum/gear/donator/bm/lightning_holocloak
	name = "lightning holo-cloak"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/lightning_holocloak
	ckeywhitelist = list("weirdbutton", "xaeshkavd")

/datum/gear/donator/bm/modern_suit
	name = "Modern Suit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/modern_suit
	ckeywhitelist = list("rainbowkurwa")

/datum/gear/donator/bm/case_ds
	name = "military case"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/donator/bm/case_ds
	ckeywhitelist = list("phenyamomota")

/datum/gear/donator/bm/Shigu_Kit
	name = "Butcher Knife Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/shigu_kit
	ckeywhitelist = list("lakomkin0911")

/datum/gear/donator/bm/kukri_kit
	name = "Kukri Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/kukri_kit
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "kingdeaths", "sierraiv", "ordinarylife", "milidead", "blatoff")

/datum/gear/donator/bm/Advanced_Tracksuit
	name = "Advanced Tracksuit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/syndicate/rus_army_alt
	ckeywhitelist = list("noterravija")

/datum/gear/donator/bm/cerberus_helmet
	name = "cerberus helmet"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/cerberus_helmet
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob")

/datum/gear/donator/bm/cerberus_suit
	name = "cerberus suit"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/cerberus_suit
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob")

/datum/gear/donator/bm/censor_fem_suit
	name = "censor suit"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/censor_fem_suit
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob")

/datum/gear/donator/bm/belinsky_plushie
	name = "Belinsky plushie"
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
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/magickitsune
	ckeywhitelist = list("friskis")

/datum/gear/donator/bm/oni_mask
	name = "Tactical Gasmask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/cool_version
	ckeywhitelist = list("oni3288", "smileycom")

/datum/gear/donator/bm/blackcool_mask
	name = "CFIS Gasmask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/blackcool_version
	ckeywhitelist = list("discord980")

/datum/gear/donator/bm/yekitezh
	name = "M1062"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/yekitezh
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/yekitezh_red
	name = "M1062-B"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/yekitezh_red
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/Rar_Suit
	name = "HEV Suit"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/space/hardsuit/rd/hev/cosmetic
	ckeywhitelist = list("rarslt")

/datum/gear/donator/bm/utilgen
	name = "G-66 Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/utilgen
	ckeywhitelist = list("reaperdb", "rainbowkurwa")

/datum/gear/donator/bm/multicam
	name = "Multicam"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/multicam
	ckeywhitelist = list("leony24", "vulpshiro", "dolbajob", "trustmeimengineer", "devildeadspace", "enigma418")

/datum/gear/donator/bm/baron
	name = "Terrifying Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/baron
	ckeywhitelist = list("snacksman", "krashly")

/datum/gear/donator/bm/syndiecloak
	name = "Syndicate Officer's Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/syndiecap
	ckeywhitelist = list("architect0r", "fanlexa")

/datum/gear/donator/bm/admcloak
	name = "Syndicate Admiral's Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/syndieadm
	ckeywhitelist = list("architect0r", "fanlexa", "herobrine998", "nyaaaa")

/datum/gear/donator/bm/sencloak
	name = "Senior Commander's Trenchcloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/sencloak
	ckeywhitelist = list("romontesque")

/datum/gear/donator/bm/ftucloak
	name = "FTU Cape"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/ftu
	ckeywhitelist = list("fanlexa", "kosep", "dragoncora")

/datum/gear/donator/bm/angelo
	name = "Angelo's Coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/angelo
	ckeywhitelist = list("axidant")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/malorian_mag
	name = "Malorian Mag Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/malorian_mag
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/flektarn
	name = "Flektarn Combat Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/flektarn
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "sodastrike", "lonofera", "hellsinggc", "devildeadspace", "enigma418")

/datum/gear/donator/bm/flektarn_casual
	name = "Flektarn Casual Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/flektarn_casual
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "sodastrike", "lonofera", "hellsinggc", "devildeadspace", "enigma418")

/datum/gear/donator/bm/flektarn_montur
	name = "Flektarn Montur"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/flektarn_montur
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "sodastrike", "lonofera", "hellsinggc", "devildeadspace", "enigma418")

/datum/gear/donator/bm/flektarn_beret
	name = "Flektarn Beret"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/flektarn_beret
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "sodastrike", "lonofera", "hellsinggc", "devildeadspace", "enigma418")

/datum/gear/donator/bm/skull_patch
	name = "PMC Skull Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/skull_patch
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob", "leony24", "snacksman", "sodastrike", "vulpshiro", "lonofera", "hellsinggc", "mihana964", "devildeadspace", "enigma418")

/datum/gear/donator/bm/monolith_patch
	name = "Monolith Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/monolith_patch
	ckeywhitelist = list("irfish", "devildeadspace", "mikolaostavkin", "allazarius", "definitelynotnesuby", "hazzi")

/datum/gear/donator/bm/tratch_patch
	name = "Tratch Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/tratch_patch
	ckeywhitelist = list("fryktik", "hazzi", "targon38", "ghos7ik", "devildeadspace", "trora", "happycrab")

/datum/gear/donator/bm/sh_jacket
	name = "Shiro Silverhand Jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/sh_jacket
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/sh_glasses
	name = "Shiro Silverhand Glasses"
	slot = ITEM_SLOT_EYES
	path = /obj/item/clothing/glasses/shiro
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/emma_plush
	name = "Emma Plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/emma
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/shiro_plush
	name = "Shiro Plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/emma/shiro
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/raita_plush
	name = "Raita Plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/emma/raita
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/who_plush
	name = "Security Officer Plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/who
	ckeywhitelist = list("stgs")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/noonar
	name = "Syndicate jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/noonar
	ckeywhitelist = list("noonar", "dasani2879")

/datum/gear/donator/bm/noonarlong
	name = "A long syndicate jacket."
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/noonarlong
	ckeywhitelist = list("noonar", "dasani2879")


/datum/gear/donator/bm/pchelik
	name = "GFYS"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/gun/ballistic/automatic/AM4B_pchelik
	ckeywhitelist = list("pchelik")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/pchelik_cloak
	name = "Coopie's Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/coopie_cloak
	ckeywhitelist = list("pchelik")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/battle_coat
	name = "Battle Coat"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/battle_coat
	ckeywhitelist = list("ghoststalin", "g3234")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/sports_jacket
	name = "Sports Jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/sports_jacket
	ckeywhitelist = list("ghoststalin", "g3234")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

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
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/omega_plushie
	name = "Omega Plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/omega
	ckeywhitelist = list("malopharan")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/nri_drg
	name = "Covert Ops Tactical Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/nri_drg
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "krashly", "sodastrike", "devildeadspace", "enigma418")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/nri_drg_head
	name = "Covert Ops Headgear"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/nri_drg_head
	ckeywhitelist = list("vulpshiro", "dolbajob", "stgs", "leony24", "krashly", "sodastrike", "devildeadspace", "enigma418")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/booma_patch
	name = "Boomah Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/booma_patch
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/booma
	name = "Boomah Turtleneck"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/booma
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife")

/datum/gear/donator/bm/silky_body
	name = "Silky Body"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/silky_body
	ckeywhitelist = list("architect0r", "trora")

/datum/gear/donator/bm/vance_plush
	name = "Vance Plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/judas/vance
	ckeywhitelist = list("littlemouse2729")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/pet
	name = "Pet Beacon"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet
	ckeywhitelist = list("mixalic")

/datum/gear/donator/bm/Dina_Kit
	name = "Kikimora Suit Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/Dina_Kit
	ckeywhitelist = list("xdinka")

/datum/gear/donator/bm/Kovac_Gun
	name = "Kovac Gun"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/Kovac_Kit
	ckeywhitelist = list("stgs", "krashly", "dolbajob", "hazzi", "devildeadspace", "enigma418", "mihana964")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/auto9_gun
	name = "Auto 9 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/auto9_kit
	ckeywhitelist = list("stgs", "sodastrike", "dolbajob", "hazzi", "krashly", "devildeadspace", "enigma418")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/m240_gun
	name = "M240 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/m240_kit
	ckeywhitelist = list("stgs", "sodastrike", "dolbajob", "hazzi", "krashly", "devildeadspace", "enigma418")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/luftkuss_gun
	name = "Luftkuss Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/old_kit
	ckeywhitelist = list("stgs", "sodastrike", "dolbajob", "hazzi", "krashly", "fiaskin", "devildeadspace", "enigma418")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/dominator
	name = "Dominator Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/dominator_kit
	ckeywhitelist = list("shalun228")

/datum/gear/donator/bm/nue
	name = "Araki Nue Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/nue_kit
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/malorian
	name = "Araki Malorian Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/malorian_kit
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "z67", "devildeadspace", "enigma418")

/datum/gear/donator/bm/pomogator
	name = "Pomogator Modification Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/pomogator_kit
	ckeywhitelist = list("danik10p")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

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
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/sponge_kit
	ckeywhitelist = list("danik10p")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/stunblade
	name = "Stunblade Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/stunblade_kit
	ckeywhitelist = list("vulpshiro", "dolbajob", "ordinarylife", "leony24", "stgs", "lonofera", "z67", "oni3288", "allazarius", "devildeadspace", "enigma418")

/datum/gear/donator/bm/stunadler
	name = "Adler stunsword Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/stunadler_kit
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/harness
	name = "Harness Armor Modification Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/harness_kit
	ckeywhitelist = list("ghoststalin", "g3234")

/datum/gear/donator/bm/ntcane
	name = "Nanotrasen Cane Modification Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/ntcane_kit
	ckeywhitelist = list("stasdvrz")

/datum/gear/donator/bm/t51armor
	name = "Old Power Armor Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/t51armor_kit
	ckeywhitelist = list("stasdvrz", "pingvas", "vovakr", "roninqwerty")

/datum/gear/donator/bm/old_world_kit
	name = "Old Wolrd Blues Kit"
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
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/gloves/fingerless/pugilist/magic
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/monolith_gloves
	name = "Monolith Gloves"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/gloves/fingerless/monolith_gloves
	ckeywhitelist = list("irfish", "devildeadspace", "mikolaostavkin", "allazarius", "definitelynotnesuby", "hazzi")

/datum/gear/donator/bm/monolith_armor
	name = "Granite M1 Vest"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/bm/monolith_armor
	ckeywhitelist = list("irfish", "devildeadspace", "mikolaostavkin", "allazarius", "definitelynotnesuby", "hazzi")

/datum/gear/donator/bm/monolith_uniform
	name = " Granite M1 ''Monolith'' Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/monolith_uniform
	ckeywhitelist = list("irfish", "devildeadspace", "mikolaostavkin", "allazarius", "definitelynotnesuby", "hazzi")

/datum/gear/donator/bm/commissar_hat
	name = "Commissar Hat"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/commissar
	ckeywhitelist = list("sketchyirishman")

/datum/gear/donator/bm/commissar_coat
	name = "Commissar Coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/commissar
	ckeywhitelist = list("sketchyirishman")

/datum/gear/donator/bm/commissar_uniform
	name = "Commissar Uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/commissar
	ckeywhitelist = list("sketchyirishman")

/datum/gear/donator/bm/officersabresheath
	name = "Officer Sabre Sheath"
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
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/pf940_kit
	ckeywhitelist = list("leony24")

/datum/gear/donator/bm/p940_g22
	name = "P940 G22 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/pf940_kit_g22
	ckeywhitelist = list("leony24")

/datum/gear/donator/bm/p940_g22
	name = "Shotgun into KS-23M Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/ks23_kit
	ckeywhitelist = list("lodagn")

/datum/gear/donator/bm/g36_kit
	name = "AK-12 into G36 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/g36_kit
	ckeywhitelist = list("lodagn")

/datum/gear/donator/bm/Anabel_kit
	name = "Miniature Energy Gun into Anabel Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/Anabel_kit
	ckeywhitelist = list("kalifasun", "dofalt")

/datum/gear/donator/bm/Doctor_K
	name = "Doctor K plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/doctor_k
	ckeywhitelist = list("sanecman")

/datum/gear/donator/bm/legax_kit
	name = "Legax Gravpulser Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/legax
	ckeywhitelist = list("sanecman")

/datum/gear/donator/bm/emagged_jukebox
	name = "Emagged Jukebox"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/jukebox/emagged
	ckeywhitelist = list("smileycom")

/datum/gear/donator/bm/upgraded_size_tool
	name = "Upgraded Size Tool"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/melee/sizetool/upgraded
	ckeywhitelist = list("enotzlodey", "herobrine998")

/datum/gear/donator/bm/pet_alta
	name = "Alta Cat"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/alta
	ckeywhitelist = list("oni3288", "discord980", "xaeshkavd")

/datum/gear/donator/bm/pet_juda
	name = "Juda shark"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/juda
	ckeywhitelist = list("mihana964")

/datum/gear/donator/bm/dogtag
	name = "Alta's dogtag"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/dogtag
	ckeywhitelist = list("oni3288", "ghos7ik", "discord980", "mihana964", "romontesque", "enigma418", "smol42", "notlikeluls",  "kladmenuwu", "alexsandoor", "scramblescream", "nai1ten", "devildeadspace", "zetneskov", "hazzi", "definitelynotnesuby", "silverfoxpaws", "pr1zrak", "earthphobia", "wafflemeow", "trora", "kosep", "urfdrf", "mikolaostavkin", "xaeshkavd", "deltarayx", "korinfellori", "troubleneko17th", "dimofon", "lichfail", "gisya", "dimakr", "cupteazee", "nopeingeneer", "silyamg", "lomodno", "valsons", "nyctealust", "abrikos", "spoopyman228", "stasdvrz", "shizalrp", "tblkba", "dragon9090", "avtobuspng", "ninjapikachushka", "ailhate", "kingdeaths")

/datum/gear/donator/bm/hateredsoul_dogtag
	name = "Combat Dogtag"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/accessory/hateredsoul_dogtag
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "kingdeaths", "sierraiv", "ordinarylife", "milidead", "blatoff")

/datum/gear/donator/bm/hateredsoul_dogtag_nt
	name = "NT Combat Dogtag"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/accessory/hateredsoul_dogtag/nt
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "kingdeaths", "sierraiv", "ordinarylife", "milidead", "blatoff")

/datum/gear/donator/bm/hateredsoul_dogtag_syndie
	name = "Syndie Combat Dogtag"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/accessory/hateredsoul_dogtag/syndie
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "kingdeaths", "sierraiv", "ordinarylife", "milidead", "blatoff")

/datum/gear/donator/bm/paws_patch
	name = "PAWS Patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/paws_patch
	ckeywhitelist = list("devildeadspace", "mikolaostavkin", "cupteazee", "dimofon", "dimakr", "definitelynotnesuby", "scramblescream", "tblkba", "hellsinggc", "aurses")

/datum/gear/donator/bm/h_soul_coat
	name = "Black coat"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/h_soul_coat
	ckeywhitelist = list("hateredsoul", "ggishka", "arion1234", "swgitty", "sw00ty", "kingdeaths", "sierraiv", "ordinarylife", "milidead", "blatoff")

/datum/gear/donator/bm/pedantcape
	name = "Corvus Pendant"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/tie/pendantcape
	ckeywhitelist = list("smol42", "weirdbutton", "sage4or")

/datum/gear/donator/bm/tricorne
	name = "Tricorne"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/tricorne
	ckeywhitelist = list("smol42", "weirdbutton", "sage4or")

/datum/gear/donator/bm/rt46
	name = "RT-46 The Tempest Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/rt46
	ckeywhitelist = list("kladmenuwu")

/datum/gear/donator/bm/Frieren_skirt
	name = "Frieren skirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/Frieren_skirt
	ckeywhitelist = list("fedor1545")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/Prosecutor
	name = "Prosecutor suit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/Prosecutor_suit
	ckeywhitelist = list("fedor1545", "berly12")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/a46_kit
	name = "A46 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/a46
	ckeywhitelist = list("nai1ten")

/datum/gear/donator/bm/ots18_kit
	name = "OTs-18 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/ots18
	ckeywhitelist = list("nai1ten")

/datum/gear/donator/bm/rune_jacket
	name = "Rune Jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/rune_jacket
	ckeywhitelist = list("d0nald")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/acrador_kit
	name = "Acrador kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/acrador_kit
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")

/datum/gear/donator/bm/goal
	name = "Goal mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/balaclava/breath/goal
	ckeywhitelist = list("hazzi", "fryktik")

/datum/gear/donator/bm/rohai_helmet
	name = "Rohai Infantry helmet"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/rohai_helmet
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/rohai_armor
	name = "Rohai Infantry Armor"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/rohai_armor
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/irellia
	name = "Banner of the Irellia"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/banner/irellia
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")

/datum/gear/donator/bm/rohai
	name = "Banner of the Rohai empire"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/banner/rohai
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")

/datum/gear/donator/bm/norn
	name = "Banner of kingdom Norn"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/banner/norn
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")

/datum/gear/donator/bm/rhsa12
	name = "R-HSA-12"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/rhsa12
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/rsa12
	name = "R-SA-12"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/rsa12
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/acradorsuit
	name = "Underarmor suit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/rank/security/officer/acradorsuit
	ckeywhitelist = list("someoldvg", "enigma418", "flippingtable", "allazarius", "trora", "siamant", "mihana964", "wangig", "omantis", "sc1de", "kladmenuwu", "manafluff", "hardbass228", "flaffug")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/at41_kit
	name = "AT-41 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/at41_kit
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_combat_uniform
	name = "SATT combat uniform"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/SATT_combat_uniform
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_turtleneck
	name = "SATT turtleneck"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/SATT_turtleneck
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_vdv
	name = "SATT vdv uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/SATT_vdv
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_jackboots
	name = "SATT jackboots"
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
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/gloves/SATT_gloves
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/SATT_gloves_finger
	name = "Fingerless SATT gloves"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/gloves/fingerless/SATT_gloves_finger
	ckeywhitelist = list("allazarius", "flippingtable", "mihana964", "devildeadspace")

/datum/gear/donator/bm/wtadler
	name = "WT-550 Adler Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/wtadler
	ckeywhitelist = list("akinight", "kladmenuwu")

/datum/gear/donator/bm/aki_camo
	name = "Old Guard NRI uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/aki_camo
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/aki_adler_camo
	name = "Adler Peacekeeper uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/aki_adler_camo
	ckeywhitelist = list("akinight", "kladmenuwu")

/datum/gear/donator/bm/nri_mundir
	name = "Old mundir NRI"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/bm/nri_mundir
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/aki_seu
	name = "Corporate S.E.U."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/aki_seu
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/aki_les
	name = "L.E.S."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/bm/aki_les
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/laskaskirt
	name = "HoS cosplay skirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/laskaskirt
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/braskirt
	name = "Red bra and striped skirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/braskirt
	ckeywhitelist = list("deltarayx", "shizalrp")

/datum/gear/donator/bm/mihana_mask
	name = "Andromeda mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/cool_version/mihana_mask
	ckeywhitelist = list("mihana964", "wangig")

/datum/gear/donator/bm/tagilla_modkit
	name = "Tagilla modkit"
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
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/modkit/hammercrowbar_kit
	ckeywhitelist = list("allazarius", "hazzi", "devildeadspace", "wangig", "wather565", "sierraiv")

/datum/gear/donator/bm/dreadmk3_kit
	name = "Dread Kit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/modkit/dreadmk3_kit
	ckeywhitelist = list("stasdvrz", "mrsko", "akinight", "vovakr", "roninqwerty","pingvas","lev1932","dragon9090","cnaperdodo")

/datum/gear/donator/bm/old_laser_kit
	name = "AER9 Kit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/modkit/old_laser_kit
	ckeywhitelist = list("stasdvrz", "vlonger", "vidl")

/datum/gear/donator/bm/institute_kit
	name = "institute Kit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/modkit/institute_kit
	ckeywhitelist = list("stasdvrz", "vlonger", "vidl")

/datum/gear/donator/bm/p320_kit
	name = "P320 kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/p320_kit
	ckeywhitelist = list("pingvas", "ty4kahahebe", "scorpionch")

/datum/gear/donator/bm/dedication_kit
	name = "Dedication kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/dedication_kit
	ckeywhitelist = list("akinight", "kladmenuwu")

/datum/gear/donator/bm/cleaver_kit
	name = "Cleaver kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/cleaver_kit
	ckeywhitelist = list("akinight")

/datum/gear/donator/bm/scabbard
	name = "Scabbard belt"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/belt/scabbard
	ckeywhitelist = list("akinight")
	restricted_desc = "Captain"
	restricted_roles = list("Captain")

/datum/gear/donator/bm/shoulder_coat
	name = "Shoulder coat"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/tie/shoulder_coat
	ckeywhitelist = list("akinight", "kladmenuwu")

/datum/gear/donator/bm/renegat
	name = "Renegat armor"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/renegat
	ckeywhitelist = list("akinight", "kladmenuwu")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/renegat_helmet
	name = "Renegat helmet"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/renegat
	ckeywhitelist = list("akinight", "kladmenuwu")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/armor_shield
	name = "Shield armor"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/armor_shield
	ckeywhitelist = list("akinight", "kladmenuwu")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/helmet_shield
	name = "Shield helmet"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/helmet/sec/helmet_shield
	ckeywhitelist = list("akinight", "kladmenuwu")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

/datum/gear/donator/bm/adler_skull
	name = "Skull helmet"
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
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/poster_box
	name = "Box with posters"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/storage/box/poster_box
	ckeywhitelist = list("tonya677")

/datum/gear/donator/bm/ushankich
	name = "Soviet ushanka"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/ushankich
	ckeywhitelist = list("fedor1545")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/razorsong
	name = "Razorsong Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/razorsong_kit
	ckeywhitelist = list("xaeshkavd")

/datum/gear/donator/bm/noxscoutcoat
	name = "Military-Civilian Scout Coat"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/donator/bm/noxscoutcoat
	ckeywhitelist = list("xaeshkavd")

/datum/gear/donator/bm/rsh_future
	name = "Special .38 Mars Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/rsh_future
	ckeywhitelist = list("xaeshkavd", "sosnovskii")

/datum/gear/donator/bm/rawk_sat
	name = "Rawk Satchel"
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/rawk_sat
	ckeywhitelist = list("xaeshkavd","silverfoxpaws", "heathkit1", "sosnovskii")

/datum/gear/donator/bm/echoes_jacket
	name = "Technical Jacket"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/donator/bm/echoes_jacket
	ckeywhitelist = list("xaeshkavd", "scramblescream", "illa_3000", "discord980", "heathkit1", "sosnovskii", "trora")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/oftok
	name = "Officer token"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/tie/oftok
	ckeywhitelist = list("xaeshkavd", "akinight", "heathkit1", "scramblescream", "definitelynotnesuby", "sosnovskii")

/datum/gear/donator/bm/agentcape
	name = "Marketing agent's cape"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/agentcape
	ckeywhitelist = list("sosnovskii")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/kladmen_panties
	name = "Panties"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/briefs/kladmen_panties
	ckeywhitelist = list("kladmenuwu", "scramblescream")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/kladmen_bra
	name = "Bra - A bra"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/shirt/bra/kladmen_bra
	ckeywhitelist = list("kladmenuwu", "scramblescream")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/troubleneko_bra
	name = "Laced lingerie bra"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/shirt/bra/troubleneko_bra
	ckeywhitelist = list("troubleneko17th", "tblkba")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/troubleneko_panties
	name = "Panties"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/briefs/troubleneko_panties
	ckeywhitelist = list("troubleneko17th", "tblkba")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/troubleneko_socks
	name = "Socks"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/underwear/socks/thigh/troubleneko_socks
	ckeywhitelist = list("troubleneko17th", "tblkba")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/f_haori
	name = "Flaming Haori"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/f_haori
	ckeywhitelist = list ("romontesque")

/datum/gear/donator/bm/SMART_fabric_boatcloak
	name = "SMART-fabric boatcloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/SMART_fabric_boatcloak
	ckeywhitelist = list("kijoking")

/datum/gear/donator/bm/famas098_NoirSuitskirt
	name = "Noir suitskirt"
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
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/paper/underhair
	ckeywhitelist = list("kijoking")

/datum/gear/donator/bm/sierra_shock_collar
	name = "Shock Collar"
	slot = ITEM_SLOT_POCKETS
	path = /obj/item/electropack/shockcollar
	ckeywhitelist = list("sierraiv")

/datum/gear/donator/bm/sierra_remotecontrol
	name = "remote signaling device"
	slot = ITEM_SLOT_POCKETS
	path = /obj/item/assembly/signaler
	ckeywhitelist = list("sierraiv")

/datum/gear/donator/bm/lurban_misteran
	name = "urban camouflage uniform"
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
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/royal_hunters
	ckeywhitelist = list("gisya")

/datum/gear/donator/bm/angel_vulgar_dress
	name = "Angelic Vulgar Dress"
	slot = ITEM_SLOT_UNDERWEAR
	path = /obj/item/clothing/under/bm/angelrevskirt
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/ghotic_vulgar_dress
	name = "Ghotic Vulgar Dress"
	slot = ITEM_SLOT_UNDERWEAR
	path = /obj/item/clothing/under/bm/gothrevskirt
	ckeywhitelist = list("angrylaska")

/datum/gear/donator/bm/prisoner
	name = "prison jumpsuit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/rank/prisoner
	ckeywhitelist = list("borisovych")

/datum/gear/donator/bm/borisovych_SecurityJumpskirt
	name = "security jumpskirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/rank/security/officer/skirt/no_armor
	ckeywhitelist = list("borisovych")

/datum/gear/donator/bm/savannah_tailbow
	name = "tailbow"
	path = /obj/item/clothing/wrists/donator/bm/savannah_tailbow
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_piercing
	name = "piercings and bracers"
	path = /obj/item/clothing/underwear/socks/savannah_piercing
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_boots
	name = "Archangel Group boots"
	path = /obj/item/clothing/shoes/archangel_boots
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_sleepwear
	name = "sleepwear"
	path = /obj/item/clothing/underwear/shirt/toggle/savannah_sleepwear
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_z_turtleneck
	name = "Archangel Group turtleneck"
	path = /obj/item/clothing/under/donator/bm/archangel_turtleneck
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/savannah_plusie
	name = "Plushy Savannah"
	path = /obj/item/toy/plush/bm/plushy_savannah
	ckeywhitelist = list("n1ght1ngale")

/datum/gear/donator/bm/pet_jruttie
	name = "Jruttie Cat"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/jruttie
	ckeywhitelist = list("scramblescream", "nai1ten", "discord980", "alexsandoor")

/datum/gear/donator/bm/pet_wertyan
	name = "Wertyan Mothroach"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/wertyanmoth
	ckeywhitelist = list("silverfoxpaws", "wertan", "vlonger", "techgrid", "saimon228")

/datum/gear/donator/bm/pet_lilmoth
	name = "Little pet Moth"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/lilmoth
	ckeywhitelist = list("saimon228")

/datum/gear/donator/bm/tavern_skirt
	name = "Tavern skirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/tavern_skirt
	ckeywhitelist = list("fedor1545")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/elf_bottle
	name = "Potion bottle"
	path = /obj/item/reagent_containers/glass/beaker/elf_bottle
	ckeywhitelist = list("fedor1545")
	subcategory = LOADOUT_SUBCATEGORIES_DON04

/datum/gear/donator/bm/wh_kit
	name = "A box of Unholy Armor"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/donator/bm/wh_kit
	ckeywhitelist = list("darksungwyndolin")

/datum/gear/donator/bm/lotos_skirt
	name = "Lotos Skort"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/lotos_skirt
	ckeywhitelist = list("angrylaska")
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION

/datum/gear/donator/bm/copium
	name = "Copium Bottle"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/reagent_containers/glass/bottle/copium
	ckeywhitelist = list("angrylaska")
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION

/datum/gear/donator/bm/moniq
	name = "Muz-TV"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/sign/moniq
	ckeywhitelist = list("finkrld")
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION

/////////////////////////////////////

/datum/gear/donator/bm/impactbaton_jitte
	name = "Jitte impact Baton"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/impactbaton_kit
	ckeywhitelist = list("silverfoxpaws", "nai1ten", "oni3288")

/datum/gear/donator/bm/mengineer_hardhat
	name = "Master Engineer's Hardhat"
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
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/hazardvest/hahun_vest
	ckeywhitelist = list("dolbajob", "enigma418")
	restricted_desc = "Station Engineer"
	restricted_roles = list("Station Engineer")

/datum/gear/donator/bm/hahun_hardhat
	name = "Welding hood"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/hardhat/weldhat/hahun
	ckeywhitelist = list("dolbajob", "enigma418")
	restricted_desc = "Station Engineer"
	restricted_roles = list("Station Engineer")
	cost = 2

/datum/gear/donator/bm/hahun_exosuit
	name = "Praxil Mk.6 Exosuit"
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
	cost = 0

/datum/gear/donator/bm/hahun_medvest
	name = "Rescue task force vest"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/belt/medical/hahun_medvest
	ckeywhitelist = list("dolbajob", "enigma418")
	restricted_desc = "MD, Paramedic, CMO"
	restricted_roles = list("Chief Medical Officer", "Medical Doctor", "Paramedic")
	cost = 3

/datum/gear/donator/bm/hahun_bag
	name = "Unloading bag"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/backpack/satchel/hahun_bag
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/hahun_case
	name = "Irellian rescue compartment case"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/case/medical/hahun
	ckeywhitelist = list("dolbajob", "enigma418")
	cost = 5

/datum/gear/donator/bm/hahun_uniform
	name = "Irellian combat uniform"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/syndicate/tacticool/hahun_uniform
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/hahun_mask
	name = "MI13 infiltrator mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/hahun_mask
	ckeywhitelist = list("dolbajob", "enigma418", "silverfoxpaws")

/datum/gear/donator/bm/hahun_mask_2
	name = "EIDOVOX Type-3 mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/hahun_mask/eidovox
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/hahun_cape
	name = "MI13 cape"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/tie/hahun_cape
	ckeywhitelist = list("dolbajob", "enigma418")

/datum/gear/donator/bm/hahun_jukebox
	name = "Irrelian Jukebox"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/hahun_jukebox
	ckeywhitelist = list("dolbajob", "enigma418")

/////////////////////////////////////

/datum/gear/donator/bm/panophobia_hos_beret
	name = "White beret"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/HoS/beret/white
	ckeywhitelist = list("earthphobia")
	restricted_roles = list("Head of Security")

/datum/gear/donator/bm/panophobia_hos_trench
	name = "White armored trenchcoat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/armor/hos/trenchcoat/white
	ckeywhitelist = list("earthphobia")
	restricted_roles = list("Head of Security")

/datum/gear/donator/bm/panophobia_hos_jackboots
	name = "White jackboots"
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
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/belt/military/srt_chesrig
	ckeywhitelist = list("hellsinggc")
	restricted_desc = "Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")
	cost = 2

/datum/gear/donator/bm/srt_suit
	name = "SRT combat uniform"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/srt_suit
	ckeywhitelist = list("hellsinggc")

/datum/gear/donator/bm/srt_
	name = "SRT Balaclava with Eye patch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/srt_mask
	ckeywhitelist = list("hellsinggc")

/datum/gear/donator/bm/millie_plushe
	name = "Millie plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/millie
	ckeywhitelist = list("pingvas", "ty4kahahebe", "scorpionch")

/datum/gear/donator/bm/praxil_seven
	name = "Praxil-7 Mark II Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/fluff_praxil_seven_kit
	ckeywhitelist = list("enigma418", "dolbajob")
	cost = 0

/datum/gear/donator/bm/m_9922
	name = "M-9922 Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/fluff_m_9922_kit
	ckeywhitelist = list("enigma418", "dolbajob")
	cost = 0

/datum/gear/donator/bm/dark_montur
	name = "Dark Montur"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/dark_montur
	ckeywhitelist = list("enigma418", "dolbajob")
	subcategory = LOADOUT_SUBCATEGORIES_DON03

/datum/gear/donator/bm/MI13_uniform
	name = "MI13 combat uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/MI13_uniform
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/eidolon_cape
	name = "Eidolon officer cape"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/eidolon_cape
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/eo95_mask
	name = "EO-95 mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/hahun_mask/eo95_mask
	ckeywhitelist = list("enigma418", "dolbajob")

/datum/gear/donator/bm/lissara_plush
	name = "Lissara plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/lissara
	ckeywhitelist = list("herobrine998", "nyaaaa")

/datum/gear/donator/bm/araminta_plush
	name = "Araminta plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/bm/araminta
	ckeywhitelist = list("herobrine998", "nyaaaa")

/datum/gear/donator/bm/dilivery_bag
	name = "Delivery Bag"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/backpack/satchel/dilivery_bag
	ckeywhitelist = list("troubleneko17th", "dimofon", "hazzi", "cupteazee", "kolhozniik", "dimakr")

/datum/gear/donator/bm/dar_beacon
	name = "Dar Jr beacon"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/dar
	ckeywhitelist = list("avtobuspng", "dimofon", "definitelynotnesuby")

/datum/gear/donator/bm/pawpack
	name = "Paw Backpack"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/backpack/satchel/pawpack
	ckeywhitelist = list("deltarayx")

/datum/gear/donator/bm/coffin
	name = "Black Rose atelier worker coffin."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/backpack/coffin
	ckeywhitelist = list("hateredsoul", "ggishka")

/datum/gear/donator/bm/coffinb2
	name = "Black Rose atelier worker cofin"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/backpack/coffin/b2
	ckeywhitelist = list("hateredsoul", "ggishka")

/datum/gear/donator/bm/coffinw
	name = "Black Rose atelier worker. Coffin"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/backpack/coffin/w
	ckeywhitelist = list("hateredsoul", "ggishka")

/datum/gear/donator/bm/coffinw2
	name = "Black Rose Atelier worker coffin"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/backpack/coffin/w2
	ckeywhitelist = list("hateredsoul", "ggishka")

/datum/gear/donator/bm/bishop_mitre
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
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/accessory/ring/syntech/winterschock
	ckeywhitelist = list("winterschock")

/datum/gear/donator/bm/ouroboroswinterschock/on_spawn(mob/living/carbon/human/user, obj/item/clothing/accessory/ring/syntech/winterschock/I)
	if(!istype(user))
		return
	I.owner = user
	if(user.dna?.features["normalized_size"])
		I.current_normalized_size = user.dna.features["normalized_size"]
		I.try_update_size(user, TRUE)

/datum/gear/donator/bm/tesh_hcloak_br
	name = "black and red hooded cloak"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/hooded/teshari/standard/black_red
	ckeywhitelist = list("heathkit1")

/datum/gear/donator/bm/pg
	name = "powder ganger jacket"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/pg
	ckeywhitelist = list("heathkit1")

/datum/gear/donator/bm/cybercoat
	name = "Cybercoat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/hooded/bm/cybercoat
	ckeywhitelist = list("cnaperdodo")

/datum/gear/donator/bm/diamond_ring
	name = "A diamond ring"
	path = /obj/item/clothing/accessory/ring/diamond
	slot = ITEM_SLOT_ACCESSORY
	ckeywhitelist = list("herobrine998", "nyaaaa")

/datum/gear/donator/bm/cybersun_cloak
	name = "Cybersun Cloak"
	path = /obj/item/clothing/neck/cloak/cybersun/civil
	slot = ITEM_SLOT_NECK
	ckeywhitelist = list("herobrine998", "nyaaaa", "sheya")

/datum/gear/donator/bm/toggles_combat_maid_civil
	name = "Combat Maid Sleeves"
	path = /obj/item/clothing/gloves/toggled/hug/combat_maid_civil
	slot = ITEM_SLOT_GLOVES
	ckeywhitelist = list("nyaaaa")

/datum/gear/donator/bm/long_fancy_kimono
	name = "Long Fancy Kimono"
	path = /obj/item/clothing/suit/donator/bm/long_fancy_kimono
	slot = ITEM_SLOT_OCLOTHING
	ckeywhitelist = list("nyaaaa")

/datum/gear/donator/bm/toggles_poly_evening
	name = "Polychromic evening gloves"
	path = /obj/item/clothing/gloves/toggled/hug/poly_evening
	slot = ITEM_SLOT_GLOVES
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION | LOADOUT_CAN_COLOR_POLYCHROMIC
	loadout_initial_colors = list("#FEFEFE")
	ckeywhitelist = list("herobrine998")

/datum/gear/donator/bm/moonflower
	name = "Moonflower"
	path = /obj/item/reagent_containers/food/snacks/grown/moonflower
	slot = ITEM_SLOT_HEAD
	ckeywhitelist = list("herobrine998")

/datum/gear/donator/bm/saareuni
	name = "SAARE BDU G3"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/donator/bm/saareuni
	ckeywhitelist = list("pingvas", "ordinarylife", "leony24", "kennedykiller", "theatlasplay", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus", "hateredsoul", "theatlasgaming")

/datum/gear/donator/bm/saareflag
	name = "SAARE flag"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/sign/flag/saaref
	ckeywhitelist = list("pingvas", "ordinarylife", "leony24", "kennedykiller", "theatlasplay", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus", "hateredsoul", "theatlasgaming")

/datum/gear/donator/bm/saarepatch
	name = "SFP Armpatch"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/accessory/armband/sfparmband
	ckeywhitelist = list("pingvas", "ordinarylife", "leony24", "kennedykiller", "theatlasplay", "ninjapikachushka", "devildeadspace", "trustmeimengineer", "izakfromrus")

/datum/gear/donator/bm/bongepop_boxers
	name = "Bongepop Boxers"
	slot = ITEM_SLOT_UNDERWEAR
	path = /obj/item/clothing/underwear/briefs/bongepop
	ckeywhitelist = list("ordinarylife", "leony24", "kennedykiller", "theatlasplay", "ninjapikachushka", \
	"devildeadspace", "trustmeimengineer", "izakfromrus", "hazzi", "dolbajob", "vulpshiro")

/datum/gear/donator/bm/breadboots
	name = "Breadshoe"
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/breadboots
	ckeywhitelist = list("ordinarylife")

/datum/gear/donator/bm/breadboots/baguette
	name = "Baguetteshoe"
	path = /obj/item/clothing/shoes/breadboots/baguette

/datum/gear/donator/bm/breadpack
	name = "Breadpack"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/breadpack
	ckeywhitelist = list("ordinarylife")

/datum/gear/donator/bm/pet_emma
	name = "Emma Fox"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet/emma
	ckeywhitelist = list("ordinarylife")

/datum/gear/donator/bm/skirt_tacticool
	name = "Tactical skirt"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/dress/skirt/tacticool
	ckeywhitelist = list("definitelynotnesuby")

/datum/gear/donator/bm/portalabomination_kit
	name = "The WRONG portal kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/portalabomination_kit
	ckeywhitelist = list("architect0r")

/datum/gear/donator/bm/hecu_black
	name = "Black HECU Backpack"
	path = /obj/item/storage/backpack/hecu/black
	slot = ITEM_SLOT_BACKPACK
	ckeywhitelist = list("xaeshkavd")

/datum/gear/donator/bm/legion_mask_frank
	name = "Frank mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/legion_mask_frank
	ckeywhitelist = list("dimofon", "devildeadspace", "dimakr", "oroshimuraiori", "troubleneko17th", "dcp9371", "oni3288", "misteran")

/datum/gear/donator/bm/legion_mask_julie
	name = "Julie mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/legion_mask_julie
	ckeywhitelist = list("dimofon", "devildeadspace", "dimakr", "oroshimuraiori", "troubleneko17th", "dcp9371", "oni3288", "misteran")

/datum/gear/donator/bm/legion_mask_joey
	name = "Joey mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/legion_mask_joey
	ckeywhitelist = list("dimofon", "devildeadspace", "dimakr", "oroshimuraiori", "troubleneko17th", "dcp9371", "oni3288", "misteran")

/datum/gear/donator/bm/legion_mask_susie
	name = "Susie mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate/legion_mask_susie
	ckeywhitelist = list("dimofon", "devildeadspace", "dimakr", "oroshimuraiori", "troubleneko17th", "dcp9371", "oni3288", "misteran")

/datum/gear/donator/bm/kladmen_dress
	name = "Gothic Dress"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/donator/bm/kladmen_dress
	ckeywhitelist = list("kladmenuwu")

/datum/gear/donator/bm/modsuit_syndicate
	name = "Syndicate Modsuit Plate"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/mod/construction/armor/security/syndicate
	ckeywhitelist = list("domilion")
	restricted_desc = "Security, Head of Security, Warden, Detective, Security Officer, Brig Physician, Peacekeeper, Blueshield."
	restricted_roles = list("Captain", "Head of Security", "Warden", "Detective", "Security Officer", "Brig Physician", "Peacekeeper", "Blueshield")

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
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/fall_out_kit
	ckeywhitelist = list("dimofon", "devildeadspace")

/datum/gear/donator/bm/player_zippo
	name = "Player Zippo"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/lighter/plighter
	ckeywhitelist = list("stasdvrz", "dimofon")

/datum/gear/donator/bm/horror_mask
	name = "Horror_mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/syndicate/horror_mask
	ckeywhitelist = list("dimakr")

/datum/gear/donator/bm/naivo_ushanka
	name = "Soviet Black Ushanka"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/ushanka/black
	ckeywhitelist = list("naivo")

/datum/gear/donator/bm/naivo_uniform
	name = "Soviet Black Uniform"
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
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/jackboots/tall/soviet_jackboots
	ckeywhitelist = list("naivo")

/datum/gear/donator/bm/mu88
	name = "M.U. 88 New hope coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/armor/vest/bluesheid/mu88
	ckeywhitelist = list("milidead", "hateredsoul")
	restricted_desc = "Brig Physician, Blueshield."
	restricted_roles = list("Brig Physician, Blueshield.")

/datum/gear/donator/bm/mu88_swimsuit
	name = "M.U. 88 New hope swimcoat"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/rank/brigdoc/mu88_swimsuit
	ckeywhitelist = list("milidead", "hateredsoul")
	restricted_desc = "Brig Physician, Blueshield."
	restricted_roles = list("Brig Physician, Blueshield.")

/datum/gear/donator/bm/mu88_boots
	name = "M.U. 88 New hope boots"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/shoes/jackboots/tall/mu88_boots
	ckeywhitelist = list("milidead", "hateredsoul")

/datum/gear/donator/bm/mu88_horns
	name = "M.U. 88 New hope horns"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/head/blueshield/mu88_horns
	ckeywhitelist = list("milidead", "hateredsoul")
	restricted_desc = "Brig Physician, Blueshield."
	restricted_roles = list("Brig Physician, Blueshield.")

/datum/gear/donator/bm/mu88_tie
	name = "M.U. 88 New hope tie"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/neck/tie/mu88_tie
	ckeywhitelist = list("milidead", "hateredsoul")

/datum/gear/donator/bm/cesar_tunic
	name = "Fancy tunic"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/cesar_tunic
	ckeywhitelist = list("nopeingeneer")

/datum/gear/donator/bm/cesar_crown
	name = "Golden laurel wreath"
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

///////////////////////////////////////////////

/datum/gear/donator/bm/dm_pzuniform
	name = "Grenadier uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/donator/bm/dm_pzgrnd_uniform
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby")

/datum/gear/donator/bm/dm_pzsuit
	name = "Grenadier jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/dm_pzgrnd_suit
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby")

/datum/gear/donator/bm/dm_pzhelmet
	name = "Pionier helmet"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/dm_pzgrnd_helmet
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby")

/datum/gear/donator/bm/dm_case
	name = "Infantry clothing case"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/case/dm_staff
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby")
	cost = 2

/datum/gear/donator/bm/dm_stg56
	name = "StG-56"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/stg56
	ckeywhitelist = list("dimofon", "devildeadspace", "silverfoxpaws", "oni3288", "definitelynotnesuby")

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
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/toggle/shark
	ckeywhitelist = list("shizalrp", "deltarayx")

///////////////////////////////////////////////

/datum/gear/donator/bm/lsweater
	name = "Sweater"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/lsweater
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/longtie
	name = "Long Tie"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/longtie
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/lskirt
	name = "Short Skirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/dress/skirt/lskirt
	ckeywhitelist = list("lindaastereih")

/datum/gear/donator/bm/invis_belt_kit
	name = "Invisible Belt Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/invis_belt
	ckeywhitelist = list("herobrine998", "nyaaaa")
	cost = 0

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
	ckeywhitelist = list("monolithxxv")

/datum/gear/donator/bm/gestapo_cloak
	name = "Truth Enforcer cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/gestapo
	ckeywhitelist = list("monolithxxv")

/datum/gear/donator/bm/gestapo_head
	name = "Truth Enforcer Cap"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/donator/bm/gestapo
	ckeywhitelist = list("monolithxxv")

/datum/gear/donator/bm/gestapo_mask
	name = "Truth Enforcer Mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/breath/gestapo
	ckeywhitelist = list("monolithxxv")

/datum/gear/donator/bm/cultist_poly
	name = "Aged Robe"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/donator/bm/cultist_poly
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION | LOADOUT_CAN_COLOR_POLYCHROMIC
	loadout_initial_colors = list("#202020", "#C5302D")
	ckeywhitelist = list("monolithxxv")

/datum/gear/donator/bm/exo_legs
	name = "Exo Legs"
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/exo_legs
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION | LOADOUT_CAN_COLOR_POLYCHROMIC
	loadout_initial_colors = list("#202020", "#C5302D")
	ckeywhitelist = list("monolithxxv")

/datum/gear/donator/bm/dark_sabre_kit
	name = "Dark Omen Sword Kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/modkit/dark_sabre_kit
	ckeywhitelist = list("hellsinggc")
