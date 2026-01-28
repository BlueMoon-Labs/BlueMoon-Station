
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
///////////////////////////// Engineering ////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/engineering
	group = "Engineering"
	crate_type = /obj/structure/closet/crate/engineering

/datum/supply_pack/engineering/shieldgen
	name = "Anti-breach Shield Projector Crate"
	desc = "Снова пробоины в корпусе? Ни слова больше с Nanotrasen Anti-Breach Shield Projector! Использует технологию силового поля, чтобы удерживать воздух внутри и космос снаружи. Содержит два проектора ."
	cost = 2500
	contains = list(/obj/machinery/shieldgen,
					/obj/machinery/shieldgen)
	crate_name = "anti-breach shield projector crate"

/datum/supply_pack/engineering/conveyor
	name = "Conveyor Assembly Crate"
	desc = "Поддерживайте движение производства вместе с пятнадцатью конвейерными лентами. Переключатель конвейера включен. Если у вас есть какие-либо вопросы, ознакомьтесь с прилагаемой инструкцией."
	cost = 750
	contains = list(/obj/item/stack/conveyor/fifteen,
					/obj/item/paper/guides/conveyor)
	crate_name = "conveyor assembly crate"

/datum/supply_pack/engineering/engiequipment
	name = "Engineering Gear Crate"
	desc = "Вооружитесь тремя поясами для инструментов, жилетами повышенной видимости, сварочными шлемами, касками и двумя парами мезонных очков!"
	cost = 1500
	contains = list(/obj/item/storage/belt/utility,
					/obj/item/storage/belt/utility,
					/obj/item/storage/belt/utility,
					/obj/item/clothing/suit/hazardvest,
					/obj/item/clothing/suit/hazardvest,
					/obj/item/clothing/suit/hazardvest,
					/obj/item/clothing/head/welding,
					/obj/item/clothing/head/welding,
					/obj/item/clothing/head/welding,
					/obj/item/clothing/head/hardhat,
					/obj/item/clothing/head/hardhat,
					/obj/item/clothing/head/hardhat,
					/obj/item/clothing/glasses/meson/engine,
					/obj/item/clothing/glasses/meson/engine)
	crate_name = "engineering gear crate"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/engihardsuit
	name = "Engineering Hardsuit"
	desc = "Вы можете получить больше скафандров, если понадобится! ОБРАТИТЕ ВНИМАНИЕ, ЧТО В ЭТОМ ЯЩИКЕ НАХОДИТСЯ ОДИН ЗАЩИТНЫЙ КОСТЮМ, а также один баллон с воздухом и маска!"
	cost = 2250
	access = ACCESS_ENGINE
	contains = list(/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/hardsuit/engine)
	crate_name = "engineering hardsuit"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/atmoshardsuit
	name = "Atmospherics Hardsuit"
	desc = "Слишком много техников и недостаточно скафандров? Время купить еще немного! Поставляется с противогазом и воздушным баллоном."
	cost = 5000
	access = ACCESS_ATMOSPHERICS //100% Fire and Bio resistance
	contains = list(/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/hardsuit/engine/atmos)
	crate_name = "atmospherics hardsuit"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/radvoidsuit
	name = "Radiation Voidsuit"
	desc = "Лорд Сингуляро вышел погулять? Вам нужно внести несколько изменений в его защитную оболочку и вы не хотите провести остаток смены под душем? Надень этот радиационный скафандр! Он защищает только от радиации и космоса."
	cost = 2250
	access = ACCESS_ENGINE
	contains = list(/obj/item/tank/internals/air,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/suit/space/rad,
					/obj/item/clothing/head/helmet/space/rad)
	crate_name = "radiation hardsuit"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/industrialrcd
	name = "Industrial RCD"
	desc = "Три промышленных RCD на случай, если станция прошла через более чем один метеоритный шторм и инженерам необходимо установить что-то более надежное. Данная модель уже улучшена ЦК, не содержит запасных зарядников."
	cost = 9000
	access = ACCESS_ENGINE
	contains = list(/obj/item/construction/rcd/industrial,
					/obj/item/construction/rcd/industrial,
					/obj/item/construction/rcd/industrial)
	crate_name = "industrial rcd"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/inducers
	name = "NT-75 Electromagnetic Power Inducers Crate"
	desc = "Нет питания ? Без проблем, с NT-75 EPI вы можете заряжать любое стандартное оборудование в любое время и в любом месте. Содержит два индуктора."
	cost = 2300
	contains = list(/obj/item/inducer/sci/supply, /obj/item/inducer/sci/supply)
	crate_name = "inducer crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/pacman
	name = "P.A.C.M.A.N Generator Crate"
	desc = "Инженеры не могут настроить двигатель? Для вас это не проблема, как только вы получите в свои руки этот генератор P.A.C.M.A.N.! Вбирает плазму и выплевывает сладкую-сладкую энергию."
	cost = 2250
	contains = list(/obj/machinery/power/port_gen/pacman)
	crate_name = "PACMAN generator crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/airpump
	name = "Portable Air Pump Crate"
	desc = "Мы все знаем, что вы работаете на рабочем месте с высоким давлением. Продолжайте в том же духе с помощью двух дополнительных воздушных насосов!"
	cost = 3000
	contains = list(/obj/machinery/portable_atmospherics/pump,
					/obj/machinery/portable_atmospherics/pump)
	crate_name = "portable air pump crate"

/datum/supply_pack/engineering/airscrubber
	name = "Portable Scrubber Crate"
	desc = "Миазмы сбивают тебя с ног? Плазма в вентиляции? Освежите воздух с помощью этих двух совершенно новых скрубберов!"
	cost = 3000
	contains = list(/obj/machinery/portable_atmospherics/scrubber,
					/obj/machinery/portable_atmospherics/scrubber)
	crate_name = "portable scrubber crate"

/datum/supply_pack/engineering/power
	name = "Power Cell Crate"
	desc = "Ищете сногшибательную силу? Ни слова больше ! Содержит три высоковольтных батареи."
	cost = 1000
	contains = list(/obj/item/stock_parts/cell/high,
					/obj/item/stock_parts/cell/high,
					/obj/item/stock_parts/cell/high)
	crate_name = "power cell crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/shuttle_engine
	name = "Shuttle Engine Crate"
	desc = "Благодаря передовым блюспейс-разработкам нашим инженерам удалось поместить целый двигатель шаттла в один крошечный ящик. Для открытия требуется доступ CE."
	cost = 5000
	access = ACCESS_CE
	contains = list(/obj/structure/shuttle/engine/propulsion/burst/cargo)
	crate_name = "shuttle engine crate"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/tools
	name = "Toolbox Crate"
	desc = "Любой крепкий космонавт никогда не отходит далеко от своего надежного набора инструментов. Содержит три электрических ящика  инструментов и три механических ящика инструментов."
	contains = list(/obj/item/storage/toolbox/electrical,
					/obj/item/storage/toolbox/electrical,
					/obj/item/storage/toolbox/electrical,
					/obj/item/storage/toolbox/mechanical,
					/obj/item/storage/toolbox/mechanical,
					/obj/item/storage/toolbox/mechanical)
	cost = 1200
	crate_name = "toolbox crate"
	special = TRUE //Department resupply shuttle loan event.

/datum/supply_pack/engineering/bsa
	name = "Bluespace Artillery Parts"
	desc = "Гордость Центрального командования. Легендарная артиллерийская пушка Bluespace - это разрушительный подвиг человеческой инженерии и свидетельство решимости военного времени. Для правильного строительства требуются высокоразвитые исследования. "
	cost = 15000
	special = TRUE
	contains = list(/obj/item/circuitboard/machine/bsa/front,
					/obj/item/circuitboard/machine/bsa/middle,
					/obj/item/circuitboard/machine/bsa/back,
					/obj/item/circuitboard/computer/bsa_control)
	crate_name= "Bluespace Artillery Parts crate"

/datum/supply_pack/engineering/bluespace_tap
	name = "Bluespace Harvester Parts"
	desc = "Гордость Центрального Командования. Собиратель Блюспейс-Частиц."
	cost = 15000
	special = TRUE
	contains = list(/obj/item/circuitboard/machine/bluespace_tap,
					/obj/item/paper/bluespace_tap)
	crate_name= "Bluespace Harvester parts crate"

/datum/supply_pack/engineering/dna_vault
	name = "DNA Vault Parts"
	desc = "Обеспечьте долговечность нынешнего состояния цивилизации с помощью этой огромной библиотеки научных знаний, способных наделять сверхчеловеческими силами и способностями. Для правильного строительства требуются высокоразвитые исследования. Также содержит пять ДНК-зондов."
	cost = 12000
	special = TRUE
	contains = list(
					/obj/item/circuitboard/machine/dna_vault,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe)
	crate_name= "dna vault parts crate"

/datum/supply_pack/engineering/dna_probes
	name = "DNA Vault Samplers"
	desc = "Содержит пять ДНК-зондов для использования в хранилище ДНК."
	cost = 8000
	special = TRUE
	contains = list(/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe)
	crate_name= "dna samplers crate"

/datum/supply_pack/engineering/shield_sat
	name = "Shield Generator Satellite"
	desc = "Защитите само существование этой станции с помощью этих средств противометеоритной защиты. Содержит три генератора щита."
	cost = 8000
	contains = list(
					/obj/machinery/satellite/meteor_shield,
					/obj/machinery/satellite/meteor_shield,
					/obj/machinery/satellite/meteor_shield)
	crate_name= "shield sat crate"

/datum/supply_pack/engineering/shield_sat_control
	name = "Shield System Control Board"
	desc = "Система управления для спутниковой системы генератора щита."
	cost = 12000
	contains = list(/obj/item/circuitboard/computer/sat_control)
	crate_name= "shield control board crate"

/datum/supply_pack/engineering/advtools
	name = "Advanced Engineering tools crate"
	desc = "Нужно быстро что то починить, но учёные станции клюют носом? Engi-vend предостовляет эти продвинутые инструменты для таких случаев!"
	cost = 6500
	contains = list(/obj/item/crowbar/power,
					/obj/item/screwdriver/power,
					/obj/item/multitool/tricorder,
					/obj/item/weldingtool/experimental,
					/obj/item/storage/belt/utility)
	crate_name= "Advanced Engineering tools"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/advtools
	name = "Mini-Rapid-Light-Device (MRLD) crate"
	desc = "Устройство, используемое для быстрого освещения местности. Заряжается железом, пласталью, стеклом или любым другим прессованным материалом."
	cost = 2000
	contains = list(/obj/item/construction/rld/mini)
	crate_name= "Mini-Rapid-Light-Device (MRLD)"
	crate_type = /obj/structure/closet/crate/secure/engineering
