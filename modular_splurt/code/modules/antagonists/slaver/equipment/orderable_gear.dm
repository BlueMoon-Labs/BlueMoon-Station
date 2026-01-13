GLOBAL_LIST_INIT(slaver_gear, subtypesof(/datum/slaver_gear))

/datum/slaver_gear
	/// Name of the gear
	var/name = "Generic slaver Gear"
	/// Description of the gear
	var/description = "Generic description."
	/// Credit cost of the gear
	var/cost = 1
	/// Build path of the gear itself
	var/build_path = null
	/// Category of the gear
	var/category = "Basic Gear"

/datum/slaver_gear/slave_collars
	name = "Slave Collars"
	description = "Slave collar x 3."
	build_path = /obj/item/storage/box/slave_collars
	category = "Slaving"
	cost = 500

/datum/slaver_gear/jammers
	name = "Radio Jammers"
	description = "Radio jammer x 3."
	build_path = /obj/item/storage/box/jammers
	category = "Slaving"
	cost = 1000

/datum/slaver_gear/gloves
	name = "Combat Krav Maga Gloves"
	description = "Shock and fire-resistant gloves that also teach krav maga x 3."
	build_path = /obj/item/storage/box/krav_gloves
	category = "Slaving"
	cost = 1750

/datum/slaver_gear/codespeak
	name = "Codespeak Manual"
	description = "A handy book that teaches the user how to speak in code. Useful to stop eavesdropping! This one has unlimited uses."
	build_path = /obj/item/codespeak_manual/unlimited
	category = "Slaving"
	cost = 1250

/datum/slaver_gear/chameleon
	name = "Chameleon Kit"
	description = "A set of items that contain chameleon technology allowing you to disguise as pretty much anything on the station, and more! \
			Due to budget cuts, the shoes don't provide protection against slipping."
	build_path = /obj/item/storage/box/syndie_kit/chameleon/ghostcafe/generic
	category = "Slaving"
	cost = 1000

/datum/slaver_gear/policing
	name = "Policing Kit"
	description = "Strobe shield x 1. Strobe replacement bulbs x 2. Stunbaton x 1. Box of handcuffs x 1. Electrostaff x 1."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/policing_shipment
	category = "Slaving"
	cost = 3000

/datum/slaver_gear/slaver_gear
	name = "Slaver Gear"
	description = "A set of standard-issue slave trader items. The same you would find in your personal locker."
	build_path = /obj/structure/closet/crate/slaver_loadout
	category = "Slaving"
	cost = 1000

/datum/slaver_gear/kinkmate
	name = "Kinkmate Supply"
	description = "A fun way to spend a shift. Contains 2 packages of unspeakable desires."
	build_path = /obj/structure/closet/crate/slave_kink
	category = "Slaving"
	cost = 5000

/datum/slaver_gear/emag
	name = "Cryptographic Sequencer"
	description = "A card capable of instantly hacking open most doors."
	build_path = /obj/item/card/emag
	category = "Advanced"
	cost = 6000

/datum/slaver_gear/hardsuits
	name = "Combat Hardsuits"
	description = "Military suit supplied by our Syndicate sponsors x 2."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/slaver_hardsuits
	category = "Advanced"
	cost = 10000

/datum/slaver_gear/jetpack
	name = "Jetpack"
	description = "Back-mounted jetpack for use in zero-gravity environments."
	build_path = /obj/item/tank/jetpack/oxygen/harness
	category = "Advanced"
	cost = 3000

/datum/slaver_gear/riot
	name = "Riot Kit"
	description = "Toy L6 SAW with riot darts."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/l6saw_shipment
	category = "Advanced"
	cost = 4000

/datum/slaver_gear/medic
	name = "Medic Kit"
	description = "Advanced medical supplies for field medics."
	build_path = /obj/item/storage/firstaid/tactical/slaver
	category = "Advanced"
	cost = 3500

/datum/slaver_gear/chems
	name = "Bio Kit"
	description = "Chemical warfare? Warcrimes? Better not tell your mom! A set of items that drug your victim in case asking them nicely didn't work. \
			Contains a chem sprayer that confuses, knocks down and eventually knocks out the victim. A dart pistol. A mix of knockout and mute chems. And some teargas grenades just in case. \
			Disclaimer: Does not work on synthetic targets."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/med/sleeperbundle
	category = "Advanced"
	cost = 5500

/datum/slaver_gear/disablers
	name = "Disablers"
	description = "An energy weapon that exhausts organic targets, weakening them until they collapse x 2"
	build_path = /obj/item/storage/backpack/duffelbag/syndie/disablers
	category = "Firearms"
	cost = 5000

/datum/slaver_gear/energy
	name = "Energy Weapons"
	description = "A basic hybrid energy gun with two settings: disable and kill x 2"
	build_path = /obj/item/storage/backpack/duffelbag/syndie/energy
	category = "Firearms"
	cost = 12000

/datum/slaver_gear/smg_rubber
	name = "SMG Kit (rubber)"
	description = "WT-550 Semi-Automatic SMG with rubber munitions. Spare magazine x 3."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/smg_rubber
	category = "Firearms"
	cost = 10000

/datum/slaver_gear/ion
	name = "Ion carbines"
	description = "Ion carbine x 2."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/ion
	category = "Firearms"
	cost = 7500

/datum/slaver_gear/marksman
	name = "Marksman Kit"
	description = ".50 cal sniper rifle with sleep-inducing rounds."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/slaver_marksman
	category = "Firearms"
	cost = 50000

/datum/slaver_gear/p50crocineammo
	name = "Ammo (.50 Crocine)"
	description = "Lewd ammo filled with aphrodisiac and capabable of knocking targets down. 12 rounds total. Compatible with .50 cal slaver sniper rifle."
	build_path = /obj/item/storage/belt/cummerbund/slaver
	category = "Firearms"
	cost = 15000

/datum/slaver_gear/freedom
	name = "Freedom Implant"
	description = "An implant that instantly releases you from handcuffs."
	build_path = /obj/item/storage/box/syndie_kit/imp_freedom
	category = "Implants"
	cost = 4000

/datum/slaver_gear/xray
	name = "X-Ray Implant"
	description = "An implant that lets you see through solid walls."
	build_path = /obj/item/autosurgeon/syndicate/xray_eyes
	category = "Implants"
	cost = 10000

/datum/slaver_gear/implant_teleport
	name = "Emergency Teleport Implants"
	description = "Emergency teleport implant x 2. Once activated, user needs to stand still for 5 seconds, after which they will be teleported from any location back to the slaver hideout. Has only one use."
	build_path = /obj/item/storage/box/slaver_teleport
	category = "Implants"
	cost = 15000

/datum/slaver_gear/implant_heart
	name = "Biomorphed Heart"
	description = "Экспериментальный орган, что используется некоторыми отрядами супер-солдат в различных 'чёрных операциях'. Даёт усиленную регенерацию, и защиту от сердечного приступа."
	build_path = /datum/uplink_item/implants/biomorphedheart
	category = "Implants"
	cost = 10000

/datum/slaver_gear/implant_liver
	name = "Biomorphed Liver"
	description = "Экспериментальный орган, что используется некоторыми отрядами супер-солдат в различных 'чёрных операциях'. Даёт усиленное восстановление от токсинов и уменьшает изнурение."
	build_path = /datum/uplink_item/implants/biomorphedliver
	category = "Implants"
	cost = 10000

/datum/slaver_gear/implant_lungs
	name = "Biomorphed Lungs"
	description = "Экспериментальный орган, что используется некоторыми отрядами супер-солдат в различных 'чёрных операциях'. Даёт усиленное восстановление от изнурения и частичную защиту от атмосферных угроз для дыхания."
	build_path = /datum/uplink_item/implants/biomorphedlungs
	category = "Implants"
	cost = 10000

/datum/slaver_gear/implant_thrusters
	name = "Implantable Thrusters Set"
	description = "An implantable set of thruster ports. They use the gas from environment or subject's internals for propulsion in zero-gravity areas. \
	Unlike regular jetpacks, this device has no stabilization system."
	build_path = /obj/item/organ/cyberimp/chest/thrusters
	category = "Implants"
	cost = 10000

/datum/slaver_gear/implant_thrusters
	name = "Revitalizing Cortex"
	description = "This attachable to the torso cortex optimizes the body's processes in order to preserve the body. Provides overall basic mending."
	build_path = /obj/item/organ/cyberimp/chest/revitilzer
	category = "Implants"
	cost = 25000

/datum/slaver_gear/borg_generic
	name = "Cyborg (Generic)"
	description = "A hacked cyborg, capable of using any module."
	build_path = /obj/item/antag_spawner/slaver_borg
	category = "Mech"
	cost = 50000

/datum/slaver_gear/borg_medical
	name = "Cyborg (Medical)"
	description = "A hacked medical combat cyborg, outfitted with a regenerative beam-gun and more powerful healing chemical."
	build_path = /obj/item/antag_spawner/slaver_borg/medical
	category = "Mech"
	cost = 50000

/datum/slaver_gear/smg22
	name = "FTU SMG Kit (rubber)"
	description = "Free Trade Union SMG with rubber munitions. Great for crowd control and pinning down Security forces. Not much else. Spare magazine x 3."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/smg22
	category = "Firearms"
	cost = 10000

/datum/slaver_gear/garandrubber
	name = "Mars Service Rifle Kit (Rubber)"
	description = "Mars Semi-Automatic Service rifle with rubber munitions. Spare clips x 6."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/garand_rubber
	category = "Firearms"
	cost = 10000

/datum/slaver_gear/garandmixed
	name = "Mars Service Rifle Kit (Mixed)"
	description = "Mars Semi-Automatic Service rifle with rubber and Soporific munitions. Spare clips x 6."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/garand_mixed
	category = "Firearms"
	cost = 12500

//datum/slaver_gear/fallehtal
//	name = "FTU Rifle Kit (Lethal)"
//	description = "Free Trade Union Select Fire rifle with lehtal munitions. Spare Mags x 6."
//	build_path = /obj/item/storage/backpack/duffelbag/syndie/fal_lehtal
//	category = "Firearms"
//	cost = 25000

/datum/slaver_gear/falrubber
	name = "FTU Rifle Kit (rubber)"
	description = "Free Trade Union Select Fire rifle with rubber munitions. Spare Mags x 6."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/fal_rubber
	category = "Firearms"
	cost = 20000

/datum/slaver_gear/falmixed
	name = "FTU Rifle Kit (mixed)"
	description = "Free Trade Union Select Fire rifle with rubber and Soporific munitions. Spare Mags x 6."
	build_path = /obj/item/storage/backpack/duffelbag/syndie/fal_mix
	category = "Firearms"
	cost = 22500

//BLUEMOON ADD
/datum/slaver_gear/synd_magboots
	name = "Blood-Red Magboots"
	description = "A pair of magnetic boots with a Syndicate paintjob that assist with freer movement in space or on-station during gravitational generator failures. These reverse-engineered knockoffs of Nanotrasen's 'Advanced Magboots' not slow you down in simulated-gravity environments and provide protection against slipping on the space lube"
	build_path = /obj/item/clothing/shoes/magboots/syndie/advance
	category = "Advanced"
	cost = 7500

/datum/slaver_gear/seclite
	name = "Seclite"
	description = "A robust flashlight used by security."
	build_path = /obj/item/flashlight/seclite
	category = "Advanced"
	cost = 100

/datum/slaver_gear/donk_sniper
	name = "donksoft sniper rifle"
	description = "Harmless Donk Soft sniper rifle."
	build_path = /obj/item/gun/ballistic/automatic/sniper_rifle/toy
	category = "Firearms"
	cost = 25000

/datum/slaver_gear/gygax
	name = "Dark Gygax"
	description = "A lightweight exosuit, painted in a dark scheme. This model appears to have some modifications. Disabler gun included."
	build_path = /obj/vehicle/sealed/mecha/combat/gygax/dark/disable_loaded
	category = "Mech"
	cost = 100000

/datum/slaver_gear/elitehardsuits
	name = "elite syndicate hardsuit"
	description = "Upgraded military suit supplied by our Syndicate sponsors. But there is only ONE!"
	category = "Advanced"
	cost = 10500

/datum/slaver_gear/headsetUpgrader
	name = "Headset Upgrader"
	description = "Upgrader for hedset supplied by our Syndicate sponsors."
	category = "Advanced"
	cost = 500
