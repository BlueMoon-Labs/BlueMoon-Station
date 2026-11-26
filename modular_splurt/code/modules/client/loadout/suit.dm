// removes resricted role for D.A.B. suits. RIP N.E.E.T. gear as exclusive for assistants (2019-2021).
/datum/gear/suit/neetsuit
	subcategory = LOADOUT_SUBCATEGORY_SUIT_GENERAL
	restricted_roles = list()

// Suggestion #148
/datum/gear/suit/techpriest
	name ="Techpriest robes"
	description = "Для тех, кто ОЧЕНЬ любит свои тостеры."
	path = /obj/item/clothing/suit/hooded/techpriest
	restricted_roles = list("Chief Engineer","Research Director","Scientist", "Roboticist","Atmospheric Technician","Station Engineer", "Chaplain")

// Suggestion #183
/datum/gear/suit/dracula
	name = "dracula coat"
	description = "Похоже, это из очень старой киностудии."
	path = /obj/item/clothing/suit/dracula

// Suggestion #3279
/datum/gear/suit/apron
	name = "apron, blue"
	description = "Простой синий фартук."
	path = /obj/item/clothing/suit/apron

/datum/gear/suit/overalls
	name = "overalls"
	description = "Комплект джинсового комбинезона."
	path = /obj/item/clothing/suit/apron/overalls

/datum/gear/suit/plain_apron
	name = "apron"
	description = "Простой фартук."
	path = /obj/item/clothing/suit/apron/chef/plain

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
	description = "Жёлтая куртка с пушистым воротником."
	path = /obj/item/clothing/suit/toggle/rp_jacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketorange
	name = "Orange Jacket"
	description = "Оранжевая куртка с пушистым воротником."
	path = /obj/item/clothing/suit/toggle/rp_jacket/orange
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketred
	name = "Red Jacket"
	description = "Красная куртка с пушистым воротником."
	path = /obj/item/clothing/suit/toggle/rp_jacket/red
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketpurple
	name = "Purple Jacket"
	description = "Фиолетовая куртка с пушистым воротником."
	path = /obj/item/clothing/suit/toggle/rp_jacket/purple
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacketwhite
	name = "White Jacket"
	description = "Белая куртка с пушистым воротником."
	path = /obj/item/clothing/suit/toggle/rp_jacket/white
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacket_runner_engi
	name = "Engineer Runner Jacket"
	description = "Авиаторы не включены."
	path = /obj/item/clothing/suit/jacket/runner/engi
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacket_runner_syndicate
	name = "Syndicate Runner Jacket"
	description = "Авиаторы не включены."
	path = /obj/item/clothing/suit/jacket/runner/syndicate
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/jacket_runner_winter
	name = "Winter Runner Jacket"
	description = "Авиаторы не включены."
	path = /obj/item/clothing/suit/jacket/runner/winter
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/baroness
	name = "Baroness Dress"
	description = "Это платье залито красным из-за кровавой истории предыдущего владельца."
	path = /obj/item/clothing/suit/baroness

/datum/gear/suit/ladyballat
	name = "Green Ball Dress"
	description = "Похоже на платье, которое носила бы отчуждённая тётя."
	path = /obj/item/clothing/suit/baroness/ladyballat

// Polychrome GWTB
/datum/gear/suit/gonersuit
	name = "polychromic trencher coat"
	description = "Обычный невзрачный оливковый тренч с полихромными пятнами."
	cost = 2
	path = /obj/item/clothing/suit/goner/fake/poly
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#E6E6E6", "#D6D6D6", "#D6D6D6")

/datum/gear/suit/gonersuit/classic
	name = "polychromic trencher coat (classic)"
	description = "Обычное серое пальто с полихромными пятнами."
	path = /obj/item/clothing/suit/goner/fake/poly/classic

/datum/gear/suit/tunnelfox
	name = "tunnel fox jacket"
	description = "Лисы-тоннельщики — правило!"
	path = /obj/item/clothing/suit/toggle/tunnelfox
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/invisijacket
	name = "invisifiber jacket"
	description = "Куртка из прозрачных волокон, часто используется с комплектами усиления."
	path = /obj/item/clothing/suit/invisijacket
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

//BM add
/datum/gear/suit/syndiewintercoat/civil
    name = "syndicate winter coat"
    description = "Зловещее чёрное пальто с красными акцентами и нарядной пелериной — кажется, оно выдержит удар. Бегунок молнии выглядит как трёхглавая змея в форме S — жутко."
    path = /obj/item/clothing/suit/hooded/wintercoat/syndicate/civil
    subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/syndieharness/civil
    name = "Engine Technician Harness"
    description = "Кроваво-красная портупея инженера-техника. Не можешь понять, где ей применение, но в некоторых местах она будто застёгивается магнитно."
    path = /obj/item/clothing/suit/armor/vest/infiltrator/gorlex_harness/civil

/datum/gear/suit/vest/civil
    name = "Armor vest"
    description = "Тонкий бронежилет типа I, дающий приличную защиту от большинства видов урона."
    path = /obj/item/clothing/suit/armor/vest/fake

/datum/gear/suit/capcarapace/winter/civil
    name = "syndicate captain's winter vest"
    description = "Зловещий, но удобный на вид жилет продвинутой брони, надетый поверх чёрно-красной огнеупорной куртки. Говорят, мех с волков ледяной луны."
    path = /obj/item/clothing/suit/toggle/captains_parade/syndicate/winter/civil
    subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

/datum/gear/suit/capcarapace/civil
    name = "syndicate captain's vest"
    description = "Зловещий жилет продвинутой брони, надетый поверх чёрно-красной огнеупорной куртки. Золотой воротник и плечи означают, что это высокопоставленный офицер синдиката."
    path = /obj/item/clothing/suit/toggle/captains_parade/syndicate/civil
    subcategory = LOADOUT_SUBCATEGORY_SUIT_JACKETS

//BM add end
/datum/gear/suit/suspenders
	name = "Suspenders"
	description = "Они поддерживают иллюзию пантомимы."
	path = /obj/item/clothing/suit/suspenders

/datum/gear/suit/hooded/teshari/beltcloak
	name = "Black belted cloak"
	description = "Более жёсткий и стилизованный плащ тешари."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak
	subcategory = LOADOUT_SUBCATEGORY_SUIT_COATS

/datum/gear/suit/hooded/teshari/beltcloak/jobs/command
	name = "Command belted cloak"
	description = "Премиальный плащ тешари с бронированной подкладкой, сделанный для Капитана."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/command
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Captain")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/ce
	name = "Chief Engineer belted cloak"
	description = "Мягкий плащ тешари для главного инженера со специальным радиационно-огнеупорным сплавом."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/ce
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Engineer")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/engineer
	name = "Engineer belted cloak"
	description = "Мягкий плащ тешари для инженерного отдела со стандартным радиационно-огнеупорным сплавом."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/engineer
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Engineer","Station Engineer","Atmospheric Technician")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/atmos
	name = "Atmos belted cloak"
	description = "Мягкий плащ тешари для техника атмосферных систем со стандартным радиационно-огнеупорным сплавом."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/engineer/atmos
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Engineer","Atmospheric Technician","Station Engineer")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/cmo
	name = "Chief Medical Officer belted cloak"
	description = "Мягкий плащ тешари для главного врача."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/cmo
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical
	name = "Medic belted cloak"
	description = "Мягкий плащ тешари, сделанный для медицинского отдела."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Virologist","Paramedic","Psychologist","Chemist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/chemistry
	name = "Chemist belted cloak"
	description = "Мягкий плащ тешари, сделанный для химика."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/chemistry
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Virologist","Paramedic","Psychologist","Chemist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/viro
	name = "Virologist belted cloak"
	description = "Мягкий плащ тешари, сделанный для виролога."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/viro
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Virologist","Paramedic","Psychologist","Chemist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/para
	name = "Paramedic belted cloak"
	description = "Мягкий плащ тешари, сделанный для фельдшера."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/para
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Chief Medical Officer","Medical Doctor","Virologist","Paramedic","Psychologist","Chemist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/sci
	name = "Scientist belted cloak"
	description = "Мягкий плащ тешари, сделанный для научного отдела."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/sci
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Roboticist","Scientist","Research Director","Geneticist")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/robo
	name = "Roboticist belted cloak"
	description = "Мягкий плащ тешари, сделанный для робототехника."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/robo
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Roboticist","Scientist","Research Director")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/medical/qm
	name = "Quartermaster belted cloak"
	description = "Мягкий плащ тешари, сделанный для квартирмейстера."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/medical/qm
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Quartermaster")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/cargo
	name = "Cargo Worker belted cloak"
	description = "Мягкий плащ тешари, сделанный для грузового отдела."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/cargo
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Quartermaster","Cargo Technician")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/mining
	name = "Mining belted cloak"
	description = "Утеплённый для шахты плащ тешари, сделанный для горного дела."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/mining
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Shaft Miner")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/service
	name = "Service belted cloak"
	description = "Мягкий плащ тешари, сделанный для отдела обслуживания."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/service
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Bartender","Botanist","Bouncer","Entertainer","Cook","Janitor")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/service/jani
	name = "Service belted cloak"
	description = "Мягкий плащ тешари, сделанный для уборщика."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/service/jani
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Janitor")


/datum/gear/suit/hooded/teshari/beltcloak/jobs/iaa
	name = "IAA belted cloak"
	description = "Мягкий плащ тешари, сделанный для агента внутренних дел."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/iaa
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("NanoTrasen Representative","Internal Affairs Agent")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/sec
	name = "Security belted cloak"
	description = "Плащ тешари с бронированной подкладкой, сделанный для службы безопасности."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/sec
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Head of Security","Security Officer","Warden","Peacekeeper")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/wrdn
	name = "Warden belted cloak"
	description = "Плащ тешари с бронированной подкладкой, сделанный для надзирателя."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/sec/wrdn
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Head of Security","Warden")

/datum/gear/suit/hooded/teshari/beltcloak/jobs/hos
	name = "Head of Security belted cloak"
	description = "Плащ тешари с жёсткой бронированной подкладкой, сделанный для Начальника безопасности."
	path = /obj/item/clothing/suit/hooded/teshari/beltcloak/jobs/hos
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	restricted_roles = list("Head of Security")
