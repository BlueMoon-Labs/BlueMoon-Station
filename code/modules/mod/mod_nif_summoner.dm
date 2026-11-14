/datum/nifsoft/summoner
	name = "Grimoire Caeruleam"
	program_desc = "Создаёт голографические игрушки, трости, игральные кости, карты и зажигалку. Созданные предметы можно развеять; при удалении программы они исчезают."
	purchase_price = 175
	category = "Гримуары"
	active_mode = FALSE
	activation_cost = 100
	var/max_summoned_items = 5
	var/list/summoned_items = list()
	var/list/summonable_items = list(/obj/item/toy/katana, /obj/item/toy/foamblade, /obj/item/cane, /obj/item/storage/dice, /obj/item/toy/cards/deck, /obj/item/toy/cards/deck/tarot, /obj/item/lighter)
	var/working = FALSE
	var/tool_speed

/datum/nifsoft/summoner/Destroy()
	QDEL_LIST(summoned_items)
	return ..()

/datum/nifsoft/summoner/activate()
	if(working || !can_activate())
		return FALSE
	working = TRUE
	var/result = open_summoner()
	if(!QDELETED(src))
		working = FALSE
	return result

/datum/nifsoft/summoner/proc/open_summoner()
	var/choice = tgui_alert(linked_mob, "Создать или развеять голографический предмет?", name, list("Создать", "Развеять", "Отмена"))
	if(!can_activate())
		return FALSE
	if(choice == "Развеять")
		var/obj/item/item = tgui_input_list(linked_mob, "Выберите предмет.", name, summoned_items)
		if(can_activate() && (item in summoned_items))
			qdel(item)
			return TRUE
		return FALSE
	if(choice != "Создать")
		return FALSE
	var/list/options = list()
	for(var/obj/item/item_type as anything in summonable_items)
		options[initial(item_type.name)] = item_type
	var/selected = tgui_input_list(linked_mob, "Выберите предмет для создания.", name, options)
	return selected && summon_item(options[selected])

/datum/nifsoft/summoner/proc/summon_item(item_type)
	if(!can_activate() || !(item_type in summonable_items))
		return FALSE
	if(length(summoned_items) >= max_summoned_items)
		to_chat(linked_mob, span_warning("NIF: достигнут лимит созданных предметов ([max_summoned_items])."))
		return FALSE
	if(!linked_mob.get_empty_held_indexes())
		to_chat(linked_mob, span_warning("NIF: освободите руку."))
		return FALSE
	var/obj/item/organ/cyberimp/brain/nif/implant = parent_nif.resolve()
	if(!implant.change_power_level(activation_cost))
		to_chat(linked_mob, span_warning("NIF: недостаточно энергии."))
		return FALSE
	var/obj/item/created = new item_type(get_turf(linked_mob))
	created.AddComponent(/datum/component/nif_construct)
	if(tool_speed)
		created.toolspeed = tool_speed
	if(!linked_mob.put_in_hands(created) || QDELETED(src) || !can_activate())
		qdel(created)
		if(!QDELETED(implant))
			implant.change_power_level(-activation_cost)
		return FALSE
	summoned_items += created
	RegisterSignal(created, COMSIG_PARENT_QDELETING, PROC_REF(on_item_deleted))
	COOLDOWN_START(src, use_cooldown, NIF_SOFT_COOLDOWN)
	return TRUE

/datum/nifsoft/summoner/proc/on_item_deleted(obj/item/source)
	SIGNAL_HANDLER
	summoned_items -= source

/datum/component/nif_construct
	var/list/generated_contents = list()

/datum/component/nif_construct/Initialize()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	var/obj/item/item = parent
	item.flags_1 |= HOLOGRAM_1
	item.item_flags |= NO_MAT_REDEMPTION
	item.custom_materials = null
	item.alpha = NIF_SUMMON_ALPHA
	item.add_atom_colour(NIF_SUMMON_COLOR, FIXED_COLOUR_PRIORITY)
	item.set_light(NIF_SUMMON_LIGHT)
	item.name = "голографический [item.name]"
	item.force = 0
	item.throwforce = 0
	item.wound_bonus = 0
	for(var/obj/item/child in item.GetAllContents())
		if(child == item)
			continue
		track_child(child)

/datum/component/nif_construct/proc/track_child(obj/item/child)
	if(child in generated_contents)
		return
	generated_contents += child
	child.AddComponent(/datum/component/nif_construct)
	RegisterSignal(child, COMSIG_PARENT_QDELETING, PROC_REF(on_child_deleted))

/datum/component/nif_construct/proc/on_child_deleted(obj/item/source)
	SIGNAL_HANDLER
	generated_contents -= source

/datum/component/nif_construct/Destroy()
	var/obj/item/item = parent
	for(var/atom/movable/content as anything in item.contents.Copy())
		if(!(content in generated_contents))
			content.forceMove(item.drop_location())
	QDEL_LIST(generated_contents)
	return ..()

/datum/nifsoft/summoner/book
	name = "Grimoire Akasha"
	program_desc = "Создаёт голографические справочники из библиотеки. Программа бесплатна; создание книги расходует энергию."
	purchase_price = 0
	max_summoned_items = 2
	summonable_items = list()

/datum/nifsoft/summoner/book/New(obj/item/organ/cyberimp/brain/nif/implant)
	. = ..()
	if(!QDELETED(src))
		summonable_items = subtypesof(/obj/item/book/manual/wiki)

/datum/nifsoft/summoner/dorms
	name = "Grimoire Libidine"
	program_desc = "Создаёт голографические версии игрушек и аксессуаров KinkMate. Одновременно доступны пять предметов."
	purchase_price = 150
	summonable_items = list(/obj/item/dildo/custom, /obj/item/buttplug/small, /obj/item/buttplug/med, /obj/item/clothing/mask/muzzle/ballgag, /obj/item/clothing/neck/petcollar, /obj/item/restraints/handcuffs/fake/kinky, /obj/item/clothing/glasses/sunglasses/blindfold, /obj/item/clothing/gloves/evening)

/datum/nifsoft/summoner/job
	max_summoned_items = 2
	activation_cost = 150
	tool_speed = 1.5

/datum/nifsoft/summoner/job/tools
	name = "Grimoire Opera"
	program_desc = "Создаёт инженерные инструменты. Одновременно доступны два предмета; работа инструментами медленнее штатной."
	summonable_items = list(/obj/item/screwdriver, /obj/item/wrench, /obj/item/wirecutters, /obj/item/crowbar, /obj/item/weldingtool/mini, /obj/item/multitool, /obj/item/wirebrush)

/datum/nifsoft/summoner/job/service
	name = "Grimoire Hestia"
	program_desc = "Создаёт голографические инструменты для кухни, уборки и садоводства. Одновременно доступны три предмета."
	max_summoned_items = 3
	activation_cost = 100
	tool_speed = null
	summonable_items = list(/obj/item/storage/bag/tray, /obj/item/reagent_containers/food/drinks/shaker, /obj/item/reagent_containers/rag, /obj/item/kitchen/knife, /obj/item/kitchen/rollingpin, /obj/item/cultivator, /obj/item/shovel/spade, /obj/item/hatchet, /obj/item/mop)

/datum/nifsoft/summoner/job/surgery
	name = "Grimoire Asclepius"
	program_desc = "Создаёт хирургические инструменты и медицинские сканеры. Одновременно доступны два предмета; операции выполняются медленнее."
	summonable_items = list(/obj/item/scalpel, /obj/item/retractor, /obj/item/hemostat, /obj/item/circular_saw, /obj/item/surgicaldrill, /obj/item/cautery, /obj/item/surgical_drapes, /obj/item/healthanalyzer)

/datum/nifsoft/summoner/job/detective
	name = "Grimoire Vacholiere"
	program_desc = "Создаёт криминалистический сканер, папку, бинокль или белый мелок. Одновременно доступны два предмета."
	activation_cost = 200
	tool_speed = null
	summonable_items = list(/obj/item/detective_scanner, /obj/item/folder/yellow, /obj/item/binoculars, /obj/item/toy/crayon/white)

/obj/item/disk/nifsoft_uploader/summoner
	name = "Grimoire Caeruleam NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/summoner

/obj/item/disk/nifsoft_uploader/summoner/book
	name = "Grimoire Akasha NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/summoner/book

/obj/item/disk/nifsoft_uploader/summoner/dorms
	name = "Grimoire Libidine NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/summoner/dorms

/obj/item/disk/nifsoft_uploader/summoner/tools
	name = "Grimoire Opera NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/summoner/job/tools

/obj/item/disk/nifsoft_uploader/summoner/service
	name = "Grimoire Hestia NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/summoner/job/service

/obj/item/disk/nifsoft_uploader/summoner/surgery
	name = "Grimoire Asclepius NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/summoner/job/surgery

/obj/item/disk/nifsoft_uploader/summoner/detective
	name = "Grimoire Vacholiere NIFSoft disk"
	loaded_nifsoft = /datum/nifsoft/summoner/job/detective
