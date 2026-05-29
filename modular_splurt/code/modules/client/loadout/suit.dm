// removes resricted role for D.A.B. suits. RIP N.E.E.T. gear as exclusive for assistants (2019-2021).
/datum/gear/suit/neetsuit
	subcategory = LOADOUT_SUBCATEGORY_SUIT_GENERAL
	restricted_roles = list()

// Suggestion #148
/datum/gear/suit/techpriest
	name ="Techpriest robes"
	path = /obj/item/clothing/suit/hooded/techpriest
	restricted_roles = list("Chief Engineer","Research Director","Scientist", "Roboticist","Atmospheric Technician","Station Engineer", "Chaplain")

// Suggestion #183
/datum/gear/suit/dracula
	name = "dracula coat"
	path = /obj/item/clothing/suit/dracula

// Suggestion #3279
/datum/gear/suit/apron
	name = "apron, blue"
	path = /obj/item/clothing/suit/apron

/datum/gear/suit/overalls
	name = "overalls"
	path = /obj/item/clothing/suit/apron/overalls

// Fixes "Fed (Modern) uniform, White" being in general suit loadout section.
/datum/gear/suit/trekcmdcapmod
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS

// Updates restrictions to accomodate new jobs (mostly trekkie stuff)
/datum/gear/suit/trekds9_coat
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Blueshield","Bridge Officer",
							"Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Scientist", "Roboticist",
							"Atmospheric Technician","Station Engineer","Warden","Detective","Security Officer","Brig Physician",
							"Cargo Technician", "Shaft Miner")

/datum/gear/suit/trekcmdcap
	restricted_roles = list("Captain","Head of Personnel","Blueshield")

/datum/gear/suit/trekcmdmov
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Warden","Detective","Security Officer","Brig Physician","Blueshield","Bridge Officer")

/datum/gear/suit/trekmedscimov
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist", "Brig Physician")

/datum/gear/suit/trekcmdmod
	restricted_roles = list("Head of Security","Captain","Head of Personnel","Chief Engineer","Research Director","Chief Medical Officer","Quartermaster","Warden","Detective","Security Officer","Brig Physician","Blueshield","Bridge Officer")

/datum/gear/suit/trekmedscimod
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Chemist","Virologist","Paramedic","Geneticist","Research Director","Scientist", "Roboticist", "Brig Physician")

/datum/gear/suit/jacketyellow
	name = "Yellow Jacket"
	path = /obj/item/clothing/suit/toggle/rp_jacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketorange
	name = "Orange Jacket"
	path = /obj/item/clothing/suit/toggle/rp_jacket/orange
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketred
	name = "Red Jacket"
	path = /obj/item/clothing/suit/toggle/rp_jacket/red
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketpurple
	name = "Purple Jacket"
	path = /obj/item/clothing/suit/toggle/rp_jacket/purple
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketwhite
	name = "White Jacket"
	path = /obj/item/clothing/suit/toggle/rp_jacket/white
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacket_runner_engi
	name = "Engineer Runner Jacket"
	path = /obj/item/clothing/suit/jacket/runner/engi
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacket_runner_syndicate
	name = "Syndicate Runner Jacket"
	path = /obj/item/clothing/suit/jacket/runner/syndicate
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacket_runner_winter
	name = "Winter Runner Jacket"
	path = /obj/item/clothing/suit/jacket/runner/winter
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/baroness
	name = "Baroness Dress"
	path = /obj/item/clothing/suit/baroness

/datum/gear/suit/ladyballat
	name = "Green Ball Dress"
	path = /obj/item/clothing/suit/baroness/ladyballat

// Polychrome GWTB
/datum/gear/suit/gonersuit
	name = "polychromic trencher coat"
	cost = 2
	path = /obj/item/clothing/suit/goner/fake/poly
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#E6E6E6", "#D6D6D6", "#D6D6D6")

/datum/gear/suit/gonersuit/classic
	name = "polychromic trencher coat (classic)"
	path = /obj/item/clothing/suit/goner/fake/poly/classic

/datum/gear/suit/tunnelfox
	name = "tunnel fox jacket"
	path = /obj/item/clothing/suit/toggle/tunnelfox
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/invisijacket
	name = "invisifiber jacket"
	description = "A jacket made of transparent fibers, often used with reinforcement kits."
	path = /obj/item/clothing/suit/invisijacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

//BM add
/datum/gear/suit/syndiewintercoat/civil
    name = "syndicate winter coat"
    path = /obj/item/clothing/suit/hooded/wintercoat/syndicate/civil
    subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/syndieharness/civil
    name = "Engine Technician Harness"
    path = /obj/item/clothing/suit/armor/vest/infiltrator/gorlex_harness/civil

/datum/gear/suit/vest/civil
    name = "Armor vest"
    path = /obj/item/clothing/suit/armor/vest/fake

/datum/gear/suit/capcarapace/winter/civil
    name = "syndicate captain's winter vest"
    path = /obj/item/clothing/suit/toggle/captains_parade/syndicate/winter/civil
    subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/capcarapace/civil
    name = "syndicate captain's vest"
    path = /obj/item/clothing/suit/toggle/captains_parade/syndicate/civil
    subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

//BM add end
/datum/gear/suit/suspenders
	name = "Suspenders"
	path = /obj/item/clothing/suit/suspenders

/datum/gear/suit/hooded/teshari/beltcloak
	name = "Black belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/hooded/teshari/beltcloak/jobs/command
	name = "Command belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/command
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Captain")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/ce
	name = "Chief Engineer belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/ce
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Engineer")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/engineer
	name = "Engineer belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/engineer
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Engineer","Station Engineer","Atmospheric Technician")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/atmos
	name = "Atmos belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/engineer/atmos
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/cmo
	name = "Chief Medical Officer belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/cmo
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical
	name = "Medic belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Virologist","Paramedic","Psychologist","Chemist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/chemistry
	name = "Chemist belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/chemistry
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Virologist","Paramedic","Psychologist","Chemist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/viro
	name = "Virologist belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/viro
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Virologist","Paramedic","Psychologist","Chemist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/para
	name = "Paramedic belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/para
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Virologist","Paramedic","Psychologist","Chemist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/sci
	name = "Scientist belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/sci
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Roboticist","Scientist","Research Director","Geneticist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/robo
	name = "Roboticist belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/robo
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Roboticist","Scientist","Research Director")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/qm
	name = "Quartermaster belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/qm
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Quartermaster")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/cargo
	name = "Cargo Worker belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/cargo
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Quartermaster","Cargo Technician")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/mining
	name = "Mining belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/mining
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Shaft Miner")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/service
	name = "Service belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/service
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Bartender","Botanist","Bouncer","Entertainer","Cook","Janitor")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/service/jani
	name = "Service belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/service/jani
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Janitor")


/datum/gear/suit/hooded/teshari/beltcloak/jobs/iaa
	name = "IAA belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/iaa
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("NanoTrasen Representative","Internal Affairs Agent")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/sec
	name = "Security belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/sec
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Head of Security","Security Officer","Warden","Peacekeeper")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/wrdn
	name = "Warden belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/sec/wrdn
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Head of Security","Warden")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/hos
	name = "Head of Security belted cloak"
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/hos
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Head of Security")
