//This is the file that handles donator loadout items.

/datum/gear/donator
	name = "Golden Horn!"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bikehorn/golden
	category = LOADOUT_CATEGORY_DONATOR
	subcategory = LOADOUT_SUBCATEGORIES_DON01
	donator_group_id = DONATOR_GROUP_TIER_1
	ckeywhitelist = list()

//////////////////////// DONATOR_GROUP_TIER_2 ////////////////////////
/datum/gear/donator/t2
	name = null
	donator_group_id = DONATOR_GROUP_TIER_2
	subcategory = LOADOUT_SUBCATEGORIES_DON02

/datum/gear/donator/t2/syndicate_id_civilian
	name = "Civilian Syndicate Card"
	path = /obj/item/card/id/syndicate/one_access_copy/loadout
	cost = 2

/datum/gear/donator/t2/maskscream
	name = "Mask Scream"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/screammask

/datum/gear/donator/t2/summon_pie
	name = "Book: Summon Pie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/book/granter/spell/summon_pie
	cost = 6

/datum/gear/donator/t2/foam_lmg
	name = "Foam LMG"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/gun/ballistic/automatic/l6_saw/toy/unrestricted/riot
	cost = 6

/datum/gear/donator/t2/foam_lmg_ammo
	name = "Foam LMG Ammo"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/ammo_box/magazine/toy/m762/riot
	cost = 2

/datum/gear/donator/t2/money
	name = "Тысяча Денег (красивое)"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/stack/spacecash/c1000

/datum/gear/donator/t2/chameleon_kit
	name = "Chameleon Box"
	path = /obj/item/storage/box/syndie_kit/chameleon
	cost = 8

////////////////////////////////////////////////////////////////////////

/datum/gear/donator/muck_kit
	name = "Muck activity kit"
	path = /obj/item/storage/box/deviant_kit/muck
	cost = 1

/datum/gear/donator/backpack/penetrator
	name = "The Penetrator"
	path = /obj/item/dildo/flared/huge

/datum/gear/donator/deskbox
	name = "Desk Box"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/box/desk

/datum/gear/donator/cleanercloak
	name = "Teshari Cleaner Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/cleanercloak

/datum/gear/donator/fishingcloak
	name = "Teshari Fishing Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/fishingcloak

/datum/gear/donator/gamercloak
	name = "Teshari Gamer Cloack"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/gamercloak

/datum/gear/donator/minercloak
	name = "Teshari Miner Cloack"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/minercloak

/datum/gear/donator/smithingcloak
	name = "Teshari Smithing Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/smithingcloak

/datum/gear/donator/productioncloak
	name = "Teshari Production Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/productioncloak

/datum/gear/donator/playercloak
	name = "Teshari Player Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/teshari/standard/playercloak

/datum/gear/donator/pet
	name = "Pet Beacon"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/pet

/datum/gear/donator/rationpack
	name = "Ration Pack"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/mre/random_safe

/datum/gear/donator/rawk_satchel
	name = "Rawk Satchel"
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/rawk

/datum/gear/donator/gasmask_syndicate
	name = "The Syndicate Mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/syndicate

/datum/gear/donator/jukebox
	name = "Handled Jukebox"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/jukebox
	cost = 4

/datum/gear/donator/purple_zippo
	name = "Purple Zippo"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/lighter/purple
	cost = 1

/datum/gear/donator/neck_gaiter
	name = "The Neck Gaiter"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/sechailer/syndicate

/datum/gear/donator/pseudo_euclidean_tennis_sphere
	name = "Pseudo-Euclidean Interdimensional Tennis Sphere"
	slot = ITEM_SLOT_MASK
	path = /obj/item/toy/fluff/tennis_poly/tri/squeak/rainbow

/datum/gear/donator/syndicate
	name = "Syndicate's Tactical Turtleneck"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate

/datum/gear/donator/syndicate_skirt
	name = "Syndicate's Tactical Skirtleneck"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/skirt

/datum/gear/donator/syndicate_overalls
	name = "Utility Overalls Turtleneck"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/overalls

/datum/gear/donator/syndicate_overalls_skirt
	name = "Utility Overalls Skirtleneck"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/overalls/skirt

/datum/gear/donator/carpet
	name = "Carpet Beacon"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/box/carpet

/datum/gear/donator/chameleon_bedsheet
	name = "Chameleon Bedsheet"
	slot = ITEM_SLOT_NECK
	path = /obj/item/bedsheet/chameleon

/datum/gear/donator/donortestingbikehorn
	name = "Donor item testing bikehorn"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bikehorn
	geargroupID = list("DONORTEST") //This is a list mainly for the sake of testing, but geargroupID works just fine with ordinary strings

/datum/gear/donator/kevhorn
	name = "Airhorn"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bikehorn/airhorn

/datum/gear/donator/kiaracloak
	name = "Kiara's cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/inferno

/datum/gear/donator/kiaracollar
	name = "Kiara's collar"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/inferno

/datum/gear/donator/kiaramedal
	name = "Insignia of Steele"
	slot = ITEM_SLOT_ACCESSORY
	path = /obj/item/clothing/accessory/medal/steele
	handle_post_equip = TRUE

/datum/gear/donator/hheart
	name = "The Hollow Heart"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/hheart

/datum/gear/donator/engravedzippo
	name = "Engraved zippo"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/lighter/gold

/datum/gear/donator/geisha
	name = "Geisha suit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/costume/geisha

/datum/gear/donator/specialscarf
	name = "Special scarf"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/scarf/zomb

/datum/gear/donator/redmadcoat
	name = "The Mad's labcoat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/labcoat/mad/red

/datum/gear/donator/santahat
	name = "Santa hat"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/santa/fluff

/datum/gear/donator/reindeerhat
	name = "Reindeer hat"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/hardhat/reindeer/fluff

/datum/gear/donator/treeplushie
	name = "Christmas tree plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/tree

/datum/gear/donator/santaoutfit
	name = "Santa costume"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/space/santa/fluff

/datum/gear/donator/treecloak
	name = "Christmas tree cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/festive

/datum/gear/donator/carrotplush
	name = "Carrot plushie"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/carrot

/datum/gear/donator/carrotcloak
	name = "Carrot cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/carrot

/datum/gear/donator/albortorosamask
	name = "Alborto Rosa mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/luchador/

/datum/gear/donator/mankini
	name = "Mankini"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/misc/stripper/mankini

/datum/gear/donator/pinkshoes
	name = "Pink shoes"
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/sneakers/pink

/datum/gear/donator/reecesgreatcoat
	name = "Reece's Great Coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/trenchcoat/green

/datum/gear/donator/russianflask
	name = "Russian flask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/reagent_containers/food/drinks/flask/russian
	cost = 2

/datum/gear/donator/stalkermask
	name = "S.T.A.L.K.E.R. mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/stalker

/datum/gear/donator/stripedcollar
	name = "Striped collar"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/stripe

/datum/gear/donator/performersoutfit
	name = "Bluish performer's outfit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/costume/singer/yellow/custom

/datum/gear/donator/vermillion
	name = "Vermillion clothing"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/suit/vermillion

/datum/gear/donator/AM4B
	name = "Foam Force AM4-B"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/gun/ballistic/automatic/AM4B

/datum/gear/donator/carrotsatchel
	name = "Carrot Satchel"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/storage/backpack/satchel/carrot

/datum/gear/donator/naomisweater
	name = "worn black sweater"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/sweater/black/naomi

/datum/gear/donator/naomicollar
	name = "worn pet collar"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/naomi

/datum/gear/donator/gladiator
	name = "Gladiator Armor"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/costume/gladiator

/datum/gear/donator/bloodredtie
	name = "Blood Red Tie"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/tie/bloodred

/datum/gear/donator/puffydress
	name = "Puffy Dress"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/puffydress

/datum/gear/donator/labredblack
	name = "Black and Red Coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/toggle/labcoat/labredblack

/datum/gear/donator/torisword
	name = "Rainbow Zweihander"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/dualsaber/hypereutactic/toy/rainbow

/datum/gear/donator/darksabre
	name = "Dark Sabre"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/darksabre

/datum/gear/donator/darksabresheath
	name = "Dark Sabre Sheath"
	slot = ITEM_SLOT_BELT
	path = /obj/item/storage/belt/sabre/darksabre

/datum/gear/donator/toriball
	name = "Rainbow Tennis Ball"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/fluff/tennis_poly/tri/squeak/rainbow

/datum/gear/donator/izzyball
	name = "Katlin's Ball"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/fluff/tennis_poly/tri/squeak/izzy

/datum/gear/donator/cloak
	name = "Green Cloak"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/green

/datum/gear/donator/steelflask
	name = "Steel Flask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/reagent_containers/food/drinks/flask/steel
	cost = 2

/datum/gear/donator/paperhat
	name = "Paper Hat"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/paperhat
	// BLUEMOON EDIT START - иконки лодаута
	item_icon = 'icons/obj/clothing/hats.dmi'
	item_icon_state = "paper"
	// BLUEMOON EDIT END

/datum/gear/donator/cloakce
	name = "Polychromic CE Cloak"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/cloak/polychromic/polyce
	loadout_flags = LOADOUT_CAN_COLOR_POLYCHROMIC
	loadout_initial_colors = list("#808080", "#8CC6FF", "#FF3535")

/datum/gear/donator/ssk
	name = "Stun Sword Kit"
	slot = ITEM_SLOT_BACKPACK
	path = 	/obj/item/ssword_kit

/datum/gear/donator/techcoat
	name = "Techomancers Labcoat"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/toggle/labcoat/mad/techcoat

/datum/gear/donator/leechjar
	name = "Jar of Leeches"
	slot = ITEM_SLOT_BACKPACK
	path = 	/obj/item/custom/leechjar

/datum/gear/donator/darkarmor
	name = "Dark Armor"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/suit/armor/vest/darkcarapace

/datum/gear/donator/devilwings
	name = "Strange Wings"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/devilwings

/datum/gear/donator/flagcape
	name = "US Flag Cape"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/neck/flagcape

/datum/gear/donator/luckyjack
	name = "Lucky Jackboots"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/shoes/jackboots/lucky

/datum/gear/donator/m41
	name = "Toy M41"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/gun/m41

/datum/gear/donator/Divine_robes
	name = "Divine robes"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/lunasune

/datum/gear/donator/gothcoat
	name = "Goth Coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/gothcoat

/datum/gear/donator/corgisuit
	name = "Corgi Suit"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/hooded/ian_costume

/datum/gear/donator/sharkcloth
	name = "Leon's Skimpy Outfit"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/custom/leoskimpy

/datum/gear/donator/mimemask
	name = "Mime Mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/mime

/datum/gear/donator/mimeoveralls
	name = "Mime's Overalls"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/under/custom/mimeoveralls

/datum/gear/donator/soulneck
	name = "Soul Necklace"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/undertale

/datum/gear/donator/frenchberet
	name = "French Beret"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/frenchberet

/datum/gear/donator/zuliecloak
	name = "Project: Zul-E"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/hooded/cloak/zuliecloak

/datum/gear/donator/blackredgold
	name = "Black, Red, and Gold Coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/blackredgold

/datum/gear/donator/kimono
	name = "Kimono"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/kimono

/datum/gear/donator/commjacket
	name = "Dusty Commisar's Cloak"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/commjacket

/datum/gear/donator/mw2_russian_para
	name = "Russian Paratrooper Jumper"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/mw2_russian_para

/datum/gear/donator/longblackgloves
	name = "Luna's Gauntlets"
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/longblackgloves

/datum/gear/donator/trendy_fit
	name = "Trendy Fit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/trendy_fit

/datum/gear/donator/singery
	name = "Yellow Performer Outfit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/costume/singer/yellow

/datum/gear/donator/csheet
	name = "NT Bedsheet"
	slot = ITEM_SLOT_NECK
	path = /obj/item/bedsheet/captain

/datum/gear/donator/borgplush
	name = "Robot Plush"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/toy/plush/borgplushie

/datum/gear/donator/donorberet
	name = "Atmos Beret"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/blueberet

/datum/gear/donator/donorgoggles
	name = "Flight Goggles"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/flight

/datum/gear/donator/onionneck
	name = "Onion Necklace"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/necklace/onion

/datum/gear/donator/mikubikini
	name = "starlight singer bikini"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/mikubikini

/datum/gear/donator/mikujacket
	name = "starlight singer jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/mikujacket

/datum/gear/donator/mikuhair
	name = "starlight singer hair"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/head/mikuhair

/datum/gear/donator/mikugloves
	name = "starlight singer gloves"
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/mikugloves

/datum/gear/donator/mikuleggings
	name = "starlight singer leggings"
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/sneakers/mikuleggings

/datum/gear/donator/cosmos
	name = "cosmic space bedsheet"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bedsheet/cosmos

/datum/gear/donator/customskirt
	name = "custom atmos skirt"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/under/custom/customskirt

/datum/gear/donator/hisakaki
	name = "halo"
	slot = ITEM_SLOT_HEAD
	path = 	/obj/item/clothing/head/halo

/datum/gear/donator/vest
	name = "vest and shirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/custom/vest

/datum/gear/donator/exo
	name = "exo frame"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/custom/exo

/datum/gear/donator/choker
	name = "NT Choker"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/petcollar/donorchoker

/datum/gear/donator/strangemask
	name = "Strange Metal Mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/breath/mmask

/datum/gear/donator/smaiden
	name = "shrine maiden outfit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/smaiden

/datum/gear/donator/mgasmask
	name = "Military Gas Mask"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/gas/military

/datum/gear/donator/clownmask
	name = "Clown Mask"
	path = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/clown_hat

/datum/gear/donator/spacehoodie
	name = "Space Hoodie"
	path = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/spacehoodie

/datum/gear/donator/pokerchips
	name = "pokerchip set"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/pockerchips

/datum/gear/donator/psychedelicjumpsuit
	name = "psychedelic jumpsuit"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/misc/psyche

/datum/gear/donator/switchblade
	name = "Cool Switchblade"
	slot = ITEM_SLOT_LPOCKET
	path = /obj/item/switchblade
	cost = 6

/datum/gear/donator/noir_trenchcoat
	name = "Noir Trenchcoat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/det_suit/grey

/datum/gear/donator/bluespacePetCarrier
	name = "The Bluespace Jar"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/pet_carrier/bluespace

/datum/gear/donator/glassworkTools
	name = "The Glasswork Tools"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/glasswork/glasskit

/datum/gear/donator/glassblowingRod
	name = "The Glassblowing Rod"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/glasswork/blowing_rod

/datum/gear/donator/gonzoFistZippo
	name = "Gonzo Fist Zippo"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/lighter/gonzofist

/datum/gear/donator/bottleOfLizardWine
	name = "Bottle of Lizard Wine"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/reagent_containers/food/drinks/bottle/lizardwine

/datum/gear/donator/collectableWizardHat
	name = "The Collectable Wizard's Hat"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/head/collectable/wizard

/datum/gear/donator/bp_helmet
	name = "Old bullet proof helmet"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/assu_helmet/bp_helmet

/datum/gear/donator/aviator_helmet
	name = "Aviator Helmet"
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/helmet/aviator_helmet/no_armor

/datum/gear/donator/old_wrappings
	name = "Old Wrappings"
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/mantle/cowboy

/datum/gear/donator/book_alch
	name = "Alchemist's Book"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/paper/book_alch

/datum/gear/donator/cigpack_cannabis
	name = "Freak Brother's Special Cigpack"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/fancy/cigarettes/cigpack_cannabis

/// Личный маяк: призывает kit с owner_ckey; развернуть мультитулом может только владелец. Остальные собирают крафтом (5 коробок + pie cannon).
/datum/gear/donator/cardboard_tank_summon_beacon
	name = "Маяк призыва: картонный танк (личный)"
	description = "Заказной складной танк. Развернуть мультитулом сможете только вы."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/choice_beacon/bm_cardboard_tank
	cost = 2

/datum/gear/donator/justice
	name = "Backpack of justice"
	slot = ITEM_SLOT_BACK
	path = /obj/item/storage/backpack/satchel/justice
	cost = 2

/datum/gear/donator/coconut_bong
	name = "Coconut Bong"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bong/coconut

/datum/gear/donator/portallight_box
	name = "Portal Fleshlight and Underwear"
	path = /obj/item/storage/box/portallight
