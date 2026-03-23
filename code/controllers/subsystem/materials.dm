/*! How material datums work
Materials are now instanced datums, with an associative list of them being kept in SSmaterials. We only instance the materials once and then re-use these instances for everything.

These materials call on_applied() on whatever item they are applied to, common effects are adding components, changing color and changing description. This allows us to differentiate items based on the material they are made out of.area

*/

SUBSYSTEM_DEF(materials)
	name = "Materials"
	flags = SS_NO_FIRE | SS_NO_INIT
	///Dictionary of material.id || material ref
	var/list/materials
	///Dictionary of type || list of material refs
	var/list/materials_by_type
	///Dictionary of type || list of material ids
	var/list/materialids_by_type
	///Dictionary of category || list of material refs
	var/list/materials_by_category
	///Dictionary of category || list of material ids, mostly used by rnd machines like autolathes.
	var/list/materialtypes_by_category
	///A cache of all material combinations that have been used
	var/list/list/material_combos
	///List of stackcrafting recipes for materials using base recipes
	var/list/base_stack_recipes = list(
		new /datum/stack_recipe("Chair", /obj/structure/chair/greyscale, time = 5, one_per_turf = TRUE, on_floor = TRUE, applies_mats = TRUE),
		new /datum/stack_recipe("Toilet", /obj/structure/toilet/greyscale, time = 5, one_per_turf = TRUE, on_floor = TRUE, applies_mats = TRUE),
		new /datum/stack_recipe("Sink Frame", /obj/structure/sink/greyscale, time = 5, one_per_turf = TRUE, on_floor = TRUE, applies_mats = TRUE),
		new /datum/stack_recipe("Material Airlock Assembly", /obj/structure/door_assembly/door_assembly_material, 4, time = 5, one_per_turf = TRUE, on_floor = TRUE, applies_mats = TRUE),
		new /datum/stack_recipe("Material Floor Tile", /obj/item/stack/tile/material, 1, 4, 20, applies_mats = TRUE),
	)
	///List of stackcrafting recipes for materials using rigid recipes
	var/list/rigid_stack_recipes = list(
		new /datum/stack_recipe("Carving block", /obj/structure/carving_block, 5, time = 5, one_per_turf = TRUE, on_floor = TRUE, applies_mats = TRUE),
	)
	///A list of dimensional themes used by the dimensional anomaly and other things, most of which require materials to function.
	var/list/datum/dimension_theme/dimensional_themes

///Ran on initialize, populated the materials and materials_by_category dictionaries with their appropiate vars (See these variables for more info)
/datum/controller/subsystem/materials/proc/InitializeMaterials()
	materials = list()
	materials_by_category = list()
	materialtypes_by_category = list()
	material_combos = list()
	for(var/type in subtypesof(/datum/material))
		var/datum/material/ref = type
		ref = new ref
		materials[type] = ref
		for(var/c in ref.categories)
			materials_by_category[c] += list(ref)
			materialtypes_by_category[c] += list(type)
	dimensional_themes = init_subtypes_w_path_keys(/datum/dimension_theme)

/datum/controller/subsystem/materials/proc/GetMaterialRef(datum/material/fakemat)
	if(!materials)
		InitializeMaterials()
	return materials[fakemat] || fakemat

///Returns a list to be used as an object's custom_materials. Lists will be cached and re-used based on the parameters.
/datum/controller/subsystem/materials/proc/FindOrCreateMaterialCombo(list/materials_declaration, multiplier)
	if(!material_combos)
		InitializeMaterials()
	var/list/combo_params = list()
	for(var/x in materials_declaration)
		var/datum/material/mat = x
		var/path_name = ispath(mat) ? "[mat]" : "[mat.type]"
		combo_params += "[path_name]=[materials_declaration[mat] * multiplier]"
	sortTim(combo_params, GLOBAL_PROC_REF(cmp_text_asc)) // We have to sort now in case the declaration was not in order
	var/combo_index = combo_params.Join("-")
	var/list/combo = material_combos[combo_index]
	if(!combo)
		combo = list()
		for(var/mat in materials_declaration)
			combo[GetMaterialRef(mat)] = materials_declaration[mat] * multiplier
		material_combos[combo_index] = combo
	return combo

///Ran on initialize, populated the materials and materials_by_category dictionaries with their appropiate vars (See these variables for more info)
/datum/controller/subsystem/materials/proc/_InitializeMaterials()
	materials = list()
	materials_by_type = list()
	materialids_by_type = list()
	materials_by_category = list()
	materialtypes_by_category = list()
	material_combos = list()
	for(var/type in subtypesof(/datum/material))
		var/datum/material/mat_type = type
		if(!(initial(mat_type.init_flags) & MATERIAL_INIT_MAPLOAD))
			continue // Do not initialize at mapload
		_InitializeMaterial(list(mat_type))

/** Creates and caches a material datum.
 *
 * Arugments:
 * - [arguments][/list]: The arguments to use to create the material datum
 *   - The first element is the type of material to initialize.
 */
/datum/controller/subsystem/materials/proc/_InitializeMaterial(list/arguments)
	var/datum/material/mat_type = arguments[1]
	if(initial(mat_type.init_flags) & MATERIAL_INIT_BESPOKE)
		arguments[1] = _GetIdFromArguments(arguments)

	var/datum/material/mat_ref = new mat_type
	if(!mat_ref.Initialize(arglist(arguments)))
		return null

	var/mat_id = mat_ref.id
	materials[mat_id] = mat_ref
	materials_by_type[mat_type] += list(mat_ref)
	materialids_by_type[mat_type] += list(mat_id)
	for(var/category in mat_ref.categories)
		materials_by_category[category] += list(mat_ref)
		materialtypes_by_category[category] += list(mat_id)

	return mat_ref

/** Fetches a cached material singleton when passed sufficient arguments.
 *
 * Arguments:
 * - [arguments][/list]: The list of arguments used to fetch the material ref.
 *   - The first element is a material datum, text string, or material type.
 *     - [Material datums][/datum/material] are assumed to be references to the cached datum and are returned
 *     - Text is assumed to be the text ID of a material and the corresponding material is fetched from the cache
 *     - A material type is checked for bespokeness:
 *       - If the material type is not bespoke the type is assumed to be the id for a material and the corresponding material is loaded from the cache.
 *       - If the material type is bespoke a text ID is generated from the arguments list and used to load a material datum from the cache.
 *   - The following elements are used to generate bespoke IDs
 */
/datum/controller/subsystem/materials/proc/_GetMaterialRef(list/arguments)
	if(!materials)
		_InitializeMaterials()

	var/datum/material/key = arguments[1]
	if(istype(key))
		return key // We are assuming here that the only thing allowed to create material datums is [/datum/controller/subsystem/materials/proc/InitializeMaterial]

	if(istext(key)) // Handle text id
		. = materials[key]
		if(!.)
			WARNING("Attempted to fetch material ref with invalid text id '[key]'")
		return

	if(!ispath(key, /datum/material))
		CRASH("Attempted to fetch material ref with invalid key [key]")

	if(!(initial(key.init_flags) & MATERIAL_INIT_BESPOKE))
		. = materials[key]
		if(!.)
			WARNING("Attempted to fetch reference to an abstract material with key [key]")
		return

	key = _GetIdFromArguments(arguments)
	return materials[key] || _InitializeMaterial(arguments)

/** I'm not going to lie, this was swiped from [SSdcs][/datum/controller/subsystem/processing/dcs].
 * Credit does to ninjanomnom
 *
 * Generates an id for bespoke ~~elements~~ materials when given the argument list
 * Generating the id here is a bit complex because we need to support named arguments
 * Named arguments can appear in any order and we need them to appear after ordered arguments
 * We assume that no one will pass in a named argument with a value of null
 **/
/datum/controller/subsystem/materials/proc/_GetIdFromArguments(list/arguments)
	var/datum/material/mattype = arguments[1]
	var/mat_id = initial(mattype.id)
	if(!mat_id)
		mat_id = "[mattype]"
	var/list/fullid = list(mat_id)
	var/list/named_arguments = list()
	for(var/i in 2 to length(arguments))
		var/key = arguments[i]
		var/value
		if(istext(key))
			value = arguments[key]
		if(!(istext(key) || isnum(key)))
			key = REF(key)
		key = "[key]" // Key is stringified so numbers dont break things
		if(!isnull(value))
			if(!(istext(value) || isnum(value)))
				value = REF(value)
			named_arguments["[key]"] = value
		else
			fullid += "[key]"

	if(length(named_arguments))
		named_arguments = sort_list(named_arguments)
		fullid += named_arguments
	return list2params(fullid)
