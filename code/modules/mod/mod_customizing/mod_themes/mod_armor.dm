//Важное примечание: Любая броня у МОДа хуже версии рига на 15 единиц. Потому что МОД не замедляет и можно вернуть ему эти 15 единиц модулем брони, дав замедление
//НО! Минимальная броня МОДа в любом случае должна быть 5, так как ну не может кусок крутого сплава не защищать хоть минимальнейше.
//Если какой-либо из показателей равен аналогичному в /datum/armor/mod, то он просто не указывается. Наследование же.

/datum/armor/mod
	melee = 10
	bullet = 5
	laser = 5
	energy = 5
	bomb = 5
	bio = 100
	fire = 25
	acid = 25
	wound = 5
	rad = 5

//#MARK: Инженерный отдел
/datum/armor/mod/engineer
	melee 	= 30
	energy 	= 10
	bomb 	= 25
	fire 	= 100 //защиты от температуры нет.
	acid 	= 25
	wound 	= 15
	rad 	= 75

/datum/armor/mod/atmosphere_tech
	melee = 30
	energy = 15
	bomb = 25
	fire = 100
	acid = 75
	wound = 15
	rad = 75

//#MARK: Карго
/datum/armor/mod/mining
	melee = 30
	bomb = 30
	fire = 100
	acid = 75
	wound = 30
	rad = 50

/datum/armor/mod/cargo_miner
	melee = 20
	energy = 10
	bomb = 50
	fire = 100
	acid = 75
	wound = 15
	rad = 35

//#MARK: Мебдей
/datum/armor/mod/medical
	bomb = 10
	fire = 60
	acid = 75
	wound = 15
	rad = 30

/datum/armor/mod/paramedic
	melee = 10
	bomb = 10
	fire = 100
	acid = 100
	wound = 15
	rad = 30

//#MARK: Командование
/datum/armor/mod/research_director
	melee = 20
	bomb = 100
	fire = 100
	acid = 100
	wound = 15
	rad = 60

/datum/armor/mod/head_of_sec
	melee = 50
	bullet = 20 //на пять лучше чем просто sec
	laser = 35
	energy = 40
	bomb = 40
	fire = 100
	acid = 100
	wound = 30
	rad = 50

/datum/armor/mod/captain
	melee = 50
	bullet = 35
	laser = 35
	energy = 60
	bomb = 50
	fire = 100
	acid = 100
	wound = 30
	rad = 100

/datum/armor/mod/chief_engineer
	melee = 40
	laser = 10
	energy = 15
	bomb = 50
	fire = 100
	acid = 90
	wound = 15
	rad = 100

/datum/armor/mod/nanotrasen_representative
	melee = 40
	bullet = 35
	laser = 35
	energy = 60
	bomb = 50
	fire = 90
	acid = 100
	wound = 15
	rad = 85

//#MARK: СБ подобное
/datum/armor/mod/security_officer
	melee = 35
	bullet = 15 //на 15 хуже рига
	laser = 25
	energy = 40
	bomb = 25
	fire = 100
	acid = 75
	wound = 20
	rad = 50

/datum/armor/mod/blueshied
	melee = 40
	bullet = 35
	laser = 35
	energy = 60
	bomb = 50
	fire = 100
	acid = 100
	wound = 15
	rad = 50

//#MARK: Антажки
/datum/armor/mod/syndicate_simple
	melee = 50
	bullet = 35
	laser = 25
	energy = 50
	bomb = 40
	fire = 50
	acid = 90
	wound = 30
	rad = 80

/datum/armor/mod/inteq_nuclear
	melee = 60
	bullet = 60
	laser = 50
	energy = 25
	bomb = 55
	rad = 100
	fire = 100
	acid = 100
	wound = 30
	rad = 100

/datum/armor/mod/inteq_traitor
	melee = 40
	bullet = 35
	laser = 15
	energy = 15
	bomb = 55
	rad = 100
	fire = 50
	acid = 90
	rad = 100
	wound = 30

/datum/armor/mod/inteq_infiltrator
	melee = 45
	bullet = 50
	laser = 45
	energy = 55
	bomb = 55
	rad = 70
	fire = 100
	acid = 100
	wound = 55

/datum/armor/mod/ninja
	melee = 40
	bullet = 15
	energy = 30
	bomb = 30
	fire = 100
	acid = 100
	wound = 10
	rad = 30

/datum/armor/mod/magican
	melee = 40
	bullet = 25
	laser = 25
	energy = 50
	bomb = 35
	fire = 100
	acid = 100
	wound = 30
	rad = 50

/datum/armor/mod/syndicate_elite
	melee = 60
	bullet = 45
	laser = 35
	energy = 50
	bomb = 55
	fire = 100
	acid = 100
	wound = 45
	rad = 100

//#MARK: ОБР
/datum/armor/mod/ert_red_code
	melee = 50
	bullet = 25
	laser = 35
	energy = 50
	bomb = 50
	fire = 100
	acid = 90
	wound = 45
	rad = 100

/datum/armor/mod/deathsquad
	melee = 80
	bullet = 65
	laser = 35
	energy = 60
	bomb = 100
	fire = 100
	acid = 100
	wound = 30
	rad = 100

//MARK: Дебаг
/datum/armor/mod/debug
	melee = 100
	bullet = 100
	laser = 100
	energy = 100
	bomb = 100
	fire = 100
	acid = 100
	wound = 100
	rad = 100
