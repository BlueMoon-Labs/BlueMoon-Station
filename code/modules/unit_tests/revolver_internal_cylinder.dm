/datum/unit_test/revolver_internal_cylinder/Run()
	var/list/L = list()
	for(var/i in typesof(/obj/item/gun/ballistic/revolver))
		var/obj/item/gun/ballistic/revolver/M = i
		if(!istype(M.mag_type, obj/item/ammo_box/magazine/internal/cylinder))
			if(!(istype(M, /obj/item/gun/ballistic/revolver/doublebarrel) || istype(M, /obj/item/gun/ballistic/revolver/mws) || istype(M, /obj/item/gun/ballistic/revolver/grenadelauncher)))
				L += "[i]"
	TEST_ASSERT(!L.len, "This revolvers have not cylinder internals: [L.Join(" ")]")
