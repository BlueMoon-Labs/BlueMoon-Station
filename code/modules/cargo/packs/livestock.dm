
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
////////////////////////////// Livestock /////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/critter
	group = "Livestock"
	crate_type = /obj/structure/closet/crate/critter

/datum/supply_pack/critter/animal_feed
	name = "Animal Feed Crate"
	desc = "Корм для домашнего скота, такого как коровы и куры. Содержит пятьдесят пучков пшеницы и пятьдесят пучков овса."
	cost = 1500
	contains = list(/obj/item/reagent_containers/food/snacks/grown/wheat,
					/obj/item/reagent_containers/food/snacks/grown/oat)
	crate_name = "animal feed crate"
	crate_type = /obj/structure/closet/crate/freezer

/datum/supply_pack/critter/animal_feed/generate()
	. = ..()
	for(var/i in 1 to 49)
		new /obj/item/reagent_containers/food/snacks/grown/wheat(.)


/datum/supply_pack/critter/parrot
	name = "Bird Crate"
	desc = "Содержит пять птиц."
	cost = 4000
	contains = list(/mob/living/simple_animal/parrot)
	crate_name = "parrot crate"

/datum/supply_pack/critter/parrot/generate()
	. = ..()
	for(var/i in 1 to 5)
		switch(rand(1, 24))
			if(1)
				new /mob/living/simple_animal/parrot(.)
			if(2)
				new /mob/living/simple_animal/parrot/clock_hawk(.)
			if(3)
				new /mob/living/simple_animal/parrot/kea(.)
			if(4)
				new /mob/living/simple_animal/parrot/eclectus(.)
			if(5)
				new /mob/living/simple_animal/parrot/eclectusf(.)
			if(6)
				new /mob/living/simple_animal/parrot/greybird(.)
			if(7)
				new /mob/living/simple_animal/parrot/blue_caique(.)
			if(8)
				new /mob/living/simple_animal/parrot/white_caique(.)
			if(9)
				new /mob/living/simple_animal/parrot/green_budgerigar(.)
			if(10)
				new /mob/living/simple_animal/parrot/blue_Budgerigar(.)
			if(11)
				new /mob/living/simple_animal/parrot/bluegreen_Budgerigar(.)
			if(12)
				new /mob/living/simple_animal/parrot/commonblackbird(.)
			if(13)
				new /mob/living/simple_animal/parrot/azuretit(.)
			if(14)
				new /mob/living/simple_animal/parrot/europeanrobin(.)
			if(15)
				new /mob/living/simple_animal/parrot/goldcrest(.)
			if(16)
				new /mob/living/simple_animal/parrot/ringneckdove(.)
			if(17)
				new /mob/living/simple_animal/parrot/cockatiel(.)
			if(18)
				new /mob/living/simple_animal/parrot/white_cockatiel(.)
			if(19)
				new /mob/living/simple_animal/parrot/yellowish_cockatiel(.)
			if(20)
				new /mob/living/simple_animal/parrot/grey_cockatiel(.)
			if(21)
				new /mob/living/simple_animal/parrot/too(.)
			if(22)
				new /mob/living/simple_animal/parrot/hooded_too(.)
			if(23)
				new /mob/living/simple_animal/parrot/pink_too(.)
			if(24)
				new /mob/living/simple_animal/parrot/eclectusr(.)


/datum/supply_pack/critter/butterfly
	name = "Butterflies Crate"
	desc = "Не очень опасное насекомое, но они создают лучший образ, чем, скажем, мухи или тараканы."//is that a motherfucking worm reference
	contraband = TRUE
	cost = 5000
	contains = list(/mob/living/simple_animal/butterfly)
	crate_name = "entomology samples crate"

/datum/supply_pack/critter/butterfly/generate()
	. = ..()
	for(var/i in 1 to 49)
		new /mob/living/simple_animal/butterfly(.)

/datum/supply_pack/critter/cat
	name = "Cat Crate"
	desc = "Кот делает мяу! Поставляется с ошейником и милой кошачьей игрушкой! Чизбургер в стоимость не входит."//i can't believe im making this reference
	cost = 5000 //Cats are worth as much as corgis.
	contains = list(/mob/living/simple_animal/pet/cat,
					/obj/item/clothing/neck/petcollar,
					/obj/item/toy/cattoy)
	crate_name = "cat crate"

/datum/supply_pack/critter/cat/generate()
	. = ..()
	if(prob(50))
		var/mob/living/simple_animal/pet/cat/C = locate() in .
		qdel(C)
		new /mob/living/simple_animal/pet/cat/Proc(.)

/datum/supply_pack/critter/chick
	name = "Chicken Crate"
	desc = "Курица делает Bwaak!"
	cost = 2000
	contains = list(/mob/living/simple_animal/chick)
	crate_name = "chicken crate"

/datum/supply_pack/critter/crab
	name = "Crab Rocket"
	desc = "РАКЕТА КРААААААП. КРАБОВАЯ РАКЕТА. КРАБОВАЯ РАКЕТА."//fun fact: i actually spent like 10 minutes and transcribed the entire video.
	cost = 5000
	contains = list(/mob/living/simple_animal/crab)
	crate_name = "look sir free crabs"
	DropPodOnly = TRUE

/datum/supply_pack/critter/crab/generate()
	. = ..()
	for(var/i in 1 to 49)
		new /mob/living/simple_animal/crab(.)

/datum/supply_pack/critter/corgi
	name = "Corgi Crate"
	desc = "Считающийся оптимальной породой собак тысячами ученых-исследователей, этот корги - всего лишь одна собака из миллионов представителей благородной родословной Йена. Поставляется с милым ошейником!"
	cost = 5000
	contains = list(/mob/living/simple_animal/pet/dog/corgi,
					/obj/item/clothing/neck/petcollar)
	crate_name = "corgi crate"

/datum/supply_pack/critter/corgi/generate()
	. = ..()
	if(prob(50))
		var/mob/living/simple_animal/pet/dog/corgi/D = locate() in .
		if(D.gender == FEMALE)
			qdel(D)
			new /mob/living/simple_animal/pet/dog/corgi/Lisa(.)

/datum/supply_pack/critter/corgis/exotic
	name = "Exotic Corgi Crate"
	desc = "Корги, достойные короля, эти корги имеют уникальный окрас, подчеркивающий их превосходство. Поставляется с милым ошейником!"
	cost = 5500
	contains = list(/mob/living/simple_animal/pet/dog/corgi/exoticcorgi,
					/obj/item/clothing/neck/petcollar)
	crate_name = "exotic corgi crate"

/datum/supply_pack/critter/cow
	name = "Cow Crate"
	desc = "Корова делает Мууу!"
	cost = 3000
	contains = list(/mob/living/simple_animal/cow)
	crate_name = "cow crate"

/datum/supply_pack/critter/fox
	name = "Fox Crate"
	desc = "Лиса делает...? Поставляется с милым ошейником"//what does the fox say
	cost = 5000
	contains = list(/mob/living/simple_animal/pet/fox,
					/obj/item/clothing/neck/petcollar)
	crate_name = "fox crate"

/datum/supply_pack/critter/goat
	name = "Goat Crate"
	desc = "Козел делает бээээ!."
	cost = 2500
	contains = list(/mob/living/simple_animal/hostile/retaliate/goat)
	crate_name = "goat crate"

/datum/supply_pack/critter/goose
	name = "Goose Crate"
	desc = "Злые и жестокие птицы. Злые, порочные существа. Пожалуйста, заберите их!"
	cost = 2500
	contains = list(/mob/living/simple_animal/hostile/retaliate/goose)
	crate_name = "goose crate"

/datum/supply_pack/critter/pug
	name = "Pug Crate"
	desc = "Как обычная собака, но... раздавленная. Поставляется с красивым воротником!"
	cost = 5000
	contains = list(/mob/living/simple_animal/pet/dog/pug,
					/obj/item/clothing/neck/petcollar)
	crate_name = "pug crate"

/datum/supply_pack/critter/kiwi
	name = "Space kiwi Crate"
	cost = 2000
	contains = list( /mob/living/simple_animal/kiwi)
	crate_name = "space kiwi crate"

/datum/supply_pack/critter/snake
	name = "Snake Crate"
	desc = "Устали от этих ГРЕБАНЫХ змей на этой ГРЕБАНОЙ космической станции? Тогда этот ящик не для тебя. Содержит трех ядовитых змей."
	cost = 3000
	contains = list(/mob/living/simple_animal/hostile/retaliate/poison/snake,
					/mob/living/simple_animal/hostile/retaliate/poison/snake,
					/mob/living/simple_animal/hostile/retaliate/poison/snake)
	crate_name = "snake crate"

/datum/supply_pack/critter/mouse
	name = "Mouse Crate"
	desc = "Подходит для змей и ящериц всех возрастов. Содержит ~12 мышей."
	cost = 2000
	contains = list(/mob/living/simple_animal/mouse,)
	crate_name = "mouse crate"

/datum/supply_pack/critter/mouse/generate()
	. = ..()
	for(var/i in 1 to 11)
		new /mob/living/simple_animal/mouse(.)

/datum/supply_pack/critter/secbat
	name = "Security Bat Crate"
	desc = "Содержит пять дубинок, идеально подходящих для избиения любому сотруднику Службы безопасности."
	cost = 2500
	contains = list(/mob/living/simple_animal/hostile/retaliate/bat/secbat,
					/mob/living/simple_animal/hostile/retaliate/bat/secbat,
					/mob/living/simple_animal/hostile/retaliate/bat/secbat,
					/mob/living/simple_animal/hostile/retaliate/bat/secbat,
					/mob/living/simple_animal/hostile/retaliate/bat/secbat)
	crate_name = "security bat crate"
