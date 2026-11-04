/// Паки личного каталога: питомцы, одежда и украшения, уют. Без оружия и снаряжения, дающего преимущество.
GLOBAL_LIST_INIT(econ_personal_catalog, typecacheof(list(
	/datum/supply_pack/critter/cat,
	/datum/supply_pack/critter/chick,
	/datum/supply_pack/critter/corgi,
	/datum/supply_pack/critter/corgis/exotic,
	/datum/supply_pack/critter/fox,
	/datum/supply_pack/critter/kiwi,
	/datum/supply_pack/critter/mouse,
	/datum/supply_pack/critter/parrot,
	/datum/supply_pack/critter/pug,
	/datum/supply_pack/goody/dyespray,
	/datum/supply_pack/costumes_toys/formalwear,
	/datum/supply_pack/costumes_toys/randomised/tesh_cloaks_vr,
	/datum/supply_pack/misc/exoticfootwear,
	/datum/supply_pack/misc/jewelry,
	/datum/supply_pack/misc/diamondring,
	/datum/supply_pack/misc/wedding,
	/datum/supply_pack/misc/candles,
	/datum/supply_pack/misc/potted_plants,
	/datum/supply_pack/misc/coloredsheets,
	/datum/supply_pack/misc/carpet_exotic,
	/datum/supply_pack/misc/artsupply,
	/datum/supply_pack/misc/book_crate,
	/datum/supply_pack/misc/fountainpens,
	/datum/supply_pack/misc/bigband,
	/datum/supply_pack/misc/jukebox,
	/datum/supply_pack/misc/microbricks,
	/datum/supply_pack/costumes_toys/randomised/plush,
	/datum/supply_pack/costumes_toys/randomised/tcg,
	/datum/supply_pack/goody/beeplush,
	/datum/supply_pack/goody/valentine,
), only_root_path = TRUE))

/proc/econ_personal_catalog_pack(datum/supply_pack/pack)
	return !!GLOB.econ_personal_catalog[pack?.type]

/// Группа «Личный каталог» окна снабжения: те же паки, что в своих группах, с пометкой.
/proc/econ_personal_catalog_group(show_contraband_partners)
	var/list/packs = list()
	for(var/pack_type in GLOB.econ_personal_catalog)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(!pack || pack.hidden || pack.contraband || pack.DropPodOnly || !pack.can_private_buy || (pack.special && !pack.special_enabled))
			continue
		var/list/entry = econ_cargo_static_entry(pack)
		entry["name"] = pack.name
		entry["id"] = pack_type
		entry["desc"] = pack.desc || pack.name
		entry["goody"] = pack.goody
		entry["access"] = pack.access
		entry["private_goody"] = pack.goody == PACK_GOODY_PRIVATE
		entry["can_private_buy"] = TRUE
		entry["personal"] = TRUE
		packs += list(entry)
	return list("name" = ECON_PERSONAL_CATALOG_GROUP, "packs" = packs)
