/datum/orbital_object/z_linked/habitable
	name = "Дружественный аванпост"
	mass = 0
	radius = 15
	maintain_orbit = TRUE
	can_dock_anywhere = TRUE

/datum/orbital_object/z_linked/habitable/New()
	. = ..()
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	name = "[initial(name)] #[rand(1, 9)][linked_map.object_count][rand(1, 9)]"

//WHITE-STEEL FIX: раньше создавался свой постоянный z-уровень на каждый habitable
//(SSmapping.add_new_zlevel в post_map_setup) без пула и переиспользования - вечный рост world.maxz.
//Теперь, как и остальные маяки, habitable берёт уровень из пула SSzclear (с лимитом и автозатиркой).
/datum/orbital_object/z_linked/habitable/post_map_setup()
	assign_z_level()

/datum/orbital_object/z_linked/habitable/finish_z_level_assignment(datum/space_level/assigned_space_level)
	. = ..()
	generate_space_ruin(world.maxx / 2, world.maxy / 2, assigned_space_level.z_value, 100, 100, allowed_flags = RUIN_PART_DEFAULT | RUIN_PART_HABITABLE)

	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	set_orbitting_around_body(linked_map.center, 2800 + 25 * rand(40, 20))
