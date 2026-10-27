/// Every atom type declares armor through an armor_type profile, never as a bare number.
/datum/unit_test/armor_declarations

/datum/unit_test/armor_declarations/Run()
	var/list/broken = list()
	for(var/atom/atom_type as anything in subtypesof(/atom))
		var/declared_armor = initial(atom_type.armor)
		if(isnum(declared_armor) || istext(declared_armor))
			broken += "[atom_type]: armor = [declared_armor]"
		var/declared_profile = initial(atom_type.armor_type)
		if(!ispath(declared_profile, /datum/armor))
			broken += "[atom_type]: armor_type = [declared_profile]"
	TEST_ASSERT(!length(broken), "Некорректная броня в объявлении типа: [broken.Join(", ")]")
