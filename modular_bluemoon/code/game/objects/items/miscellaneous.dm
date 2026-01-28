/obj/item/choice_beacon/ert_mech
	name = "ERT mech beacon"
	desc = "To summon your own steel titan."

/obj/item/choice_beacon/ert_mech/generate_display_names()
	var/static/list/ert_mech_list = list("Marauder" = /obj/vehicle/sealed/mecha/combat/marauder/loaded,
		"Seraph" = /obj/vehicle/sealed/mecha/combat/marauder/seraph)
	if(!ert_mech_list)
		ert_mech_list = list()
		var/list/templist = typesof(/obj/item/storage/box/hero) //we have to convert type = name to name = type, how lovely!
		for(var/V in templist)
			var/atom/A = V
			ert_mech_list[initial(A.name)] = A
	return ert_mech_list

/obj/item/choice_beacon/nri_mech
	name = "NRI mech beacon"
	desc = "To summon your own steel titan. For the Emperor!"

/obj/item/choice_beacon/nri_mech/generate_display_names()
	var/static/list/nri_mech_list = list("TU-802 Solntsepyok" = /obj/vehicle/sealed/mecha/combat/durand/tu802,
		"Savannah-Ivanov" = /obj/vehicle/sealed/mecha/combat/savannah_ivanov/loaded)
	if(!nri_mech_list)
		nri_mech_list = list()
		var/list/templist = typesof(/obj/item/storage/box/hero) //we have to convert type = name to name = type, how lovely!
		for(var/V in templist)
			var/atom/A = V
			nri_mech_list[initial(A.name)] = A
	return nri_mech_list

/obj/item/choice_beacon/sol_mech
	name = "SolFed mech beacon"
	desc = "Feel the power of the tesla. Glory to the Humanity!"

/obj/item/choice_beacon/sol_mech/generate_display_names()
	var/static/list/sol_mech_list = list("Zeus" = /obj/vehicle/sealed/mecha/combat/durand/zeus)
	if(!sol_mech_list)
		sol_mech_list = list()
		var/list/templist = typesof(/obj/item/storage/box/hero) //we have to convert type = name to name = type, how lovely!
		for(var/V in templist)
			var/atom/A = V
			sol_mech_list[initial(A.name)] = A
	return sol_mech_list

/obj/item/choice_beacon/pet/moro
	pets = list("Crab" = /mob/living/simple_animal/crab,
		"Cat" = /mob/living/simple_animal/pet/cat,
		"Space cat" = /mob/living/simple_animal/pet/cat/space,
		"Kitten" = /mob/living/simple_animal/pet/cat/kitten,
		"Dog" = /mob/living/simple_animal/pet/dog,
		"Corgi" = /mob/living/simple_animal/pet/dog/corgi,
		"Pug" = /mob/living/simple_animal/pet/dog/pug,
		"Exotic Corgi" = /mob/living/simple_animal/pet/dog/corgi/exoticcorgi,
		"Fox" = /mob/living/simple_animal/pet/fox,
		"Red Panda" = /mob/living/simple_animal/pet/redpanda,
		"Possum" = /mob/living/simple_animal/opossum,
		"Moro" = /mob/living/simple_animal/pet/cat/moro)

/obj/item/choice_beacon/pet/alta
	pets = list("Crab" = /mob/living/simple_animal/crab,
		"Cat" = /mob/living/simple_animal/pet/cat,
		"Space cat" = /mob/living/simple_animal/pet/cat/space,
		"Kitten" = /mob/living/simple_animal/pet/cat/kitten,
		"Dog" = /mob/living/simple_animal/pet/dog,
		"Corgi" = /mob/living/simple_animal/pet/dog/corgi,
		"Pug" = /mob/living/simple_animal/pet/dog/pug,
		"Exotic Corgi" = /mob/living/simple_animal/pet/dog/corgi/exoticcorgi,
		"Fox" = /mob/living/simple_animal/pet/fox,
		"Red Panda" = /mob/living/simple_animal/pet/redpanda,
		"Possum" = /mob/living/simple_animal/opossum,
		"Alta" = /mob/living/simple_animal/pet/cat/alta,
		"Space Alta" = /mob/living/simple_animal/pet/cat/space/alta,
		"Zlat" = /mob/living/simple_animal/pet/dog/corgi/Lisa/zlatchek)

/obj/item/choice_beacon/pet/dar
	pets = list("Dar Jr" = /mob/living/simple_animal/pet/cat/alta/dar)

/obj/item/choice_beacon/pet/emma
	pets = list("Crab" = /mob/living/simple_animal/crab,
		"Cat" = /mob/living/simple_animal/pet/cat,
		"Space cat" = /mob/living/simple_animal/pet/cat/space,
		"Kitten" = /mob/living/simple_animal/pet/cat/kitten,
		"Dog" = /mob/living/simple_animal/pet/dog,
		"Corgi" = /mob/living/simple_animal/pet/dog/corgi,
		"Pug" = /mob/living/simple_animal/pet/dog/pug,
		"Exotic Corgi" = /mob/living/simple_animal/pet/dog/corgi/exoticcorgi,
		"Fox" = /mob/living/simple_animal/pet/fox,
		"Red Panda" = /mob/living/simple_animal/pet/redpanda,
		"Possum" = /mob/living/simple_animal/opossum,
		"Emma" = /mob/living/simple_animal/pet/fox/emma)

/obj/item/choice_beacon/pet/jruttie
	pets = list("Jruttie" = /mob/living/simple_animal/pet/cat/jruttie)

/obj/item/choice_beacon/pet/juda
	pets = list("Judas" = /mob/living/simple_animal/pet/dog/juda)

/obj/item/choice_beacon/pet/wertyanmoth
	pets = list("Wertyan" = /mob/living/simple_animal/pet/dog/corgi/mothroach/wertyanmoth)

/obj/item/choice_beacon/pet/lilmoth
	pets = list("Little moth" = /mob/living/simple_animal/pet/dog/corgi/mothroach/lilmoth,
				"Little moth with funny hat"  = /mob/living/simple_animal/pet/dog/corgi/mothroach/lilmoth/dressed,
				)
