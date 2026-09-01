/// Псевдовысота стоит на движимом, а не на /atom: её задают столы, подушки и шесты, а слот
/// на каждом из 1.2 млн турфов мира стоит мегабайты. У неподвижного высота всегда нулевая.
/atom/movable
	var/pseudo_z_axis

/atom/proc/get_fake_z()
	return 0

/atom/movable/get_fake_z()
	return pseudo_z_axis

/obj/structure/table
	pseudo_z_axis = 8

/turf/open/get_fake_z()
	var/objschecked
	for(var/obj/structure/structurestocheck in contents)
		objschecked++
		if(structurestocheck.pseudo_z_axis)
			return structurestocheck.pseudo_z_axis
		if(objschecked >= 25)
			break
	return 0

/mob/living/Move(atom/newloc, direct)
	. = ..()
	if(. && !HAS_TRAIT(src, IGNORE_FAKE_Z_AXIS)) //SPLURT edit. don't worry, i hate this too.
		pseudo_z_axis = newloc.get_fake_z()
		pixel_z = pseudo_z_axis
