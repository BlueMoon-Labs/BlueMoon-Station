/// Saved loadout colors fill every polychromic layer with a valid color and stay detached from the preferences list.
/datum/unit_test/loadout_polychromic_colors

/datum/unit_test/loadout_polychromic_colors/Run()
	var/obj/item/clothing/mask/kitsune/black/mask = allocate(/obj/item/clothing/mask/kitsune/black)
	var/datum/gear/mask/black_kitsune/gear = new
	var/list/color_matrix = list(1,0,0, 0,1,0, 0,0,1, 0,0,0)
	var/list/saved_colors = list("#123456", color_matrix)

	SSjob.apply_loadout_colors(mask, gear, saved_colors)

	var/datum/element/polychromic/polychromic = LAZYACCESS(mask.comp_lookup, COMSIG_ITEM_WORN_OVERLAYS)
	TEST_ASSERT(istype(polychromic), "test premise: the kitsune mask must carry the polychromic element")
	var/list/layer_colors = polychromic.colors_by_atom[mask]
	TEST_ASSERT_EQUAL(length(layer_colors), 3, "Every layer of the mask must keep a color after loading a short saved list")
	TEST_ASSERT_EQUAL(layer_colors[1], "#123456", "A valid saved color must be applied to its layer")
	TEST_ASSERT_EQUAL(layer_colors[2], "#CC9933", "A color matrix saved by the colormate must not replace a layer color")
	TEST_ASSERT_EQUAL(layer_colors[3], "#000000", "A layer missing from the saved list must keep its default")
	TEST_ASSERT(layer_colors != saved_colors, "The element must not share the list stored in the preferences")

	mask.update_icon()
	mask.worn_overlays(FALSE, mask.mob_overlay_icon, mask.icon_state)

	layer_colors[1] = "#ffffff"
	TEST_ASSERT_EQUAL(saved_colors[1], "#123456", "Recoloring the item in game must not edit the saved preferences")
	TEST_ASSERT_EQUAL(length(saved_colors), 2, "Loading colors must not resize the saved preferences list")
	qdel(gear)
