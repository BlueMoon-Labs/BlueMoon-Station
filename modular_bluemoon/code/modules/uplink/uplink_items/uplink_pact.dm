//Технологии ПАКТа

/datum/uplink_item/pact
	category = "Nanotrasen Technologies"
	surplus = 0
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/datum/uplink_item/pact/pact_ninja_case
	name = "Pact Ninja Case"
	desc = "Хранит в себе специализированный боевой костюм с оружием ближнего боя"
	item = /obj/item/storage/toolbox/infiltrator/pact_ninja
	cost = 5

/datum/uplink_item/pact/alliance_case
	name = "Alliance Assassin suit"
	desc = "Комплект с практичным и удобным боевым костюмом белого цвета. Кажется, это женская модель."
	item = /obj/item/storage/toolbox/infiltrator/alliance
	cost = 3

/datum/uplink_item/pact/combat_rcd
	name = "Combat RCD"
	desc = "A device used to rapidly build and deconstruct. Reload with metal, plasteel, glass or compressed matter cartridges."
	item = /obj/item/construction/rcd/combat
	cost = 4 //Дешёво, но не слишком, дабы не покупали все подряд

/datum/uplink_item/pact/enforcer_vector
	name = "MK60 Vector"
	desc = "Потомок пистолета Энфорсер, автоматический пистолет-пулемёт калибра .45, Вектор"
	item = /obj/item/gun/ballistic/automatic/mk60/vector
	cost = 6 //дороже стечкина на 1 ТК

//Аммуниция, патроны Nanotrasen

/datum/uplink_item/ammo/wt550
	name = "WT-550 Ammo"
	desc = "Стандартный магазин на 32 патрона для полуавтоматического пистолета WT-550 SMG"
	item = /obj/item/ammo_box/magazine/wt550m9
	cost = 1
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/datum/uplink_item/ammo/wt550/rubber
	name = "WT-550 Ammo (Rubber bullets 4.6x30mm)"
	desc = "Стандартный магазин резиновых на 32 патрона для полуавтоматического пистолета WT-550 SMG"
	item = /obj/item/ammo_box/magazine/wt550m9/wtrubber
	cost = 1
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/datum/uplink_item/ammo/wt550/inced
	name = "WT-550 Ammo (Incendiary 4.6x30mm)"
	desc = "Стандартный магазин зажигательных на 32 патрона для полуавтоматического пистолета WT-550 SMG"
	item = /obj/item/ammo_box/magazine/wt550m9/wtic
	cost = 2
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/datum/uplink_item/ammo/wt550/ap
	name = "WT-550 Ammo (Armour Piercing 4.6x30mm)"
	desc = "Стандартный магазин бронебойных на 32 патрона для полуавтоматического пистолета WT-550 SMG"
	item = /obj/item/ammo_box/magazine/wt550m9/wtap
	cost = 3
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/datum/uplink_item/ammo/enforcer_letal
	name = "Enforcer letal drum"
	desc = "Барабан на Энфорсер с летальными патронами"
	item = /obj/item/ammo_box/magazine/e45/e45_drum/lethal
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW
	cost = 3

/datum/uplink_item/ammo/enforcer_rubber
	name = "Enforcer rubber drum"
	desc = "Барабан на Энфорсер с резиновыми патронами"
	item = /obj/item/ammo_box/magazine/e45/e45_drum
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW
	cost = 1

/datum/uplink_item/ammo/enforcer_taser
	name = "Enforcer taser drum"
	desc = "Барабан на Энфорсер с тазерными патронами"
	item = /obj/item/ammo_box/magazine/e45/e45_drum/taser
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW
	cost = 2

/datum/uplink_item/ammo/enforcer_laser
	name = "Enforcer laser drum"
	desc = "Барабан на Энфорсер с лазерными патронами"
	item = /obj/item/ammo_box/magazine/e45/e45_drum/laser
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW
	cost = 2

//Взрывчатка

/datum/uplink_item/explosives/shredbang
	name = "Shredbang"
	desc = "Граната, работающая по принципу stingbang, но имеющая летальные поражающие элементы"
	item = /obj/item/grenade/stingbang/shred
	cost = 8
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/datum/uplink_item/explosives/stingbang
	name = "Stingbang"
	desc = "Почти безвредная граната с резиновыми шариками. Часть дополнительного снаряжения офицеров СБ"
	item = /obj/item/grenade/stingbang
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW
	cost = 2

/datum/uplink_item/explosives/megastingbang
	name = "Megastingbang"
	desc = "Более сильная версия стингбанг, содержащая коллосальное количество резиновых шариков."
	item = /obj/item/grenade/stingbang/mega
	cost = 5
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

//Импланты
/datum/uplink_item/implants/chem_implant
	name = "Corporate Chemical Implant"
	desc = "Химический имплант, работающий в зависимости от текущего уровня тревоги."
	item = /obj/item/autosurgeon/syndicate/corp_chem_implant
	cost = 4
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/obj/item/autosurgeon/syndicate/corp_chem_implant
	starting_organ = /obj/item/organ/cyberimp/chest/chem_implant/sec_level

/datum/uplink_item/implants/arm_shied
	name = "Corporate Arm Shield"
	desc = "A deployable riot shield to help deal with civil unrest."
	item = /obj/item/autosurgeon/syndicate/corp_arm_shied
	cost = 3
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/obj/item/autosurgeon/syndicate/corp_arm_shied
	starting_organ = /obj/item/organ/cyberimp/arm/shield/sec_level

// /datum/uplink_item/implants/anti_stun
// 	name = "Corporate CNS Rebooter"
// 	desc = "This implant will automatically give you back control over your central nervous system, reducing downtime when stunned."
// 	item = /obj/item/autosurgeon/syndicate/corp_anti_stun
// 	cost = 3

/obj/item/autosurgeon/syndicate/corp_anti_stun
	starting_organ = /obj/item/organ/cyberimp/brain/anti_stun/sec_level

// /datum/uplink_item/implants/thermals
// 	name = "Corporate Thermals"
// 	desc = "These cybernetic eye implants will give you thermal vision. Vertical slit pupil included."
// 	item = /obj/item/autosurgeon/syndicate/corp_thermals
// 	cost = 4

/obj/item/autosurgeon/syndicate/corp_thermals
	starting_organ = /obj/item/organ/eyes/robotic/toggled/thermals/sec_level

// /datum/uplink_item/implants/anti_drop
// 	name = "Corporate Anti drop implant"
// 	desc = "This cybernetic brain implant will allow you to force your hand muscles to contract, preventing item dropping. Twitch ear to toggle"
// 	item = /obj/item/autosurgeon/syndicate/corp_antidrop
// 	cost = 5

/obj/item/autosurgeon/syndicate/corp_antidrop
	starting_organ = /obj/item/organ/cyberimp/brain/anti_drop/sec_level

// /datum/uplink_item/implants/arm_blade
// 	name = "Corporate Blade implant"
// 	desc = "An integrated blade implant designed to be installed into a persons arm. Stylish and deadly; Although, being caught with this without proper permits is sure to draw unwanted attention"
// 	item = /obj/item/autosurgeon/syndicate/corp_arm_blade
// 	cost = 4

/obj/item/autosurgeon/syndicate/corp_arm_blade
	starting_organ = /obj/item/organ/cyberimp/arm/mantis_blade/sec_level

/datum/uplink_item/implants/nutriment_pump
	name = "Extreme Nutriment Pump"
	desc = "This implant will synthesize and pump into your bloodstream a small amount of nutriment when you are hungry. This version of the pump also provides a proper water supply."
	item = /obj/item/autosurgeon/syndicate/nutriment_pump
	cost = 2
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/obj/item/autosurgeon/syndicate/nutriment_pump
	starting_organ = /obj/item/organ/cyberimp/chest/nutrimentextreme

/datum/uplink_item/implants/internal_health_analyzer
	name = "Internal Health Analyzer"
	desc = "An advanced health analyzer implant, designed to directly interface with a host's body and relay scan information to the brain on command."
	item = /obj/item/autosurgeon/syndicate/scanner
	cost = 1
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/obj/item/autosurgeon/syndicate/scanner
	starting_organ = /obj/item/organ/internal/cyberimp/chest/scanner

/datum/uplink_item/implants/thrusters
	name = "Implantable Thrusters Set"
	desc = "An implantable set of thruster ports. They use the gas from environment or subject's internals for propulsion in zero-gravity areas. Unlike regular jetpacks, this device has no stabilization system."
	item = /obj/item/autosurgeon/syndicate/thrusters
	cost = 3
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/obj/item/autosurgeon/syndicate/thrusters
	starting_organ = /obj/item/organ/cyberimp/chest/thrusters

/datum/uplink_item/implants/binocular_lenses
	name = "Binocular Lenses"
	desc = "A pair of binocular lenses, that can be attached to the eyes."
	item = /obj/item/autosurgeon/syndicate/binocular_lenses
	cost = 2
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/obj/item/autosurgeon/syndicate/binocular_lenses
	starting_organ = /obj/item/organ/cyberimp/arm/lenses

/datum/uplink_item/implants/arm_taser
	name = "Arm-mounted Taser Implant"
	desc = "A variant of the arm cannon implant that fires electrodes and disabler shots. The cannon emerges from the subject's arm and remains inside when not in use."
	item = /obj/item/autosurgeon/syndicate/arm_taser
	cost = 8
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/obj/item/autosurgeon/syndicate/arm_taser
	starting_organ = /obj/item/organ/cyberimp/arm/gun/taser

/datum/uplink_item/implants/high_intensity_photon_projector
	name = "Integrated High-Intensity Photon Projector"
	desc = "An integrated projector mounted onto a user's arm that is able to be used as a powerful flash."
	item = /obj/item/autosurgeon/syndicate/high_intensity_photon_projector
	cost = 2
	purchasable_from = UPLINK_SYNDICATE_PACT_CREW

/obj/item/autosurgeon/syndicate/high_intensity_photon_projector
	starting_organ = /obj/item/organ/cyberimp/arm/flash
