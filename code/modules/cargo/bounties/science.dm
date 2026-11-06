/datum/bounty/item/science/boh
	name = "Bag of Holding"
	description = "Nanotrasen пригодились бы блюспейс-<b>рюкзаки</b> повышенной вместимости. Если они у вас есть, пожалуйста, отправьте их нам."
	reward = 8000
	wanted_types = list(/obj/item/storage/backpack/holding)

/datum/bounty/item/science/tboh
	name = "Trash Bag of Holding"
	description = "Nanotrasen пригодились бы мусорные блюспейс-мешки повышенной вместимости. Если они у вас есть, пожалуйста, отправьте их нам."
	reward = 5000
	wanted_types = list(/obj/item/storage/bag/trash/bluespace)

/datum/bounty/item/science/bluespace_syringe
	name = "Bluespace Syringe"
	description = "Nanotrasen пригодились бы блюспейс-шприцы повышенной вместимости. Если они у вас есть, пожалуйста, отправьте их нам."
	reward = 1500
	wanted_types = list(/obj/item/reagent_containers/syringe/bluespace)

/datum/bounty/item/science/bluespace_body_bag
	name = "Bluespace Body Bag"
	description = "Nanotrasen пригодились бы блюспейс-мешки для трупов повышенной вместимости. Если они у вас есть, пожалуйста, отправьте их нам."
	reward = 7000
	wanted_types = list(/obj/item/bodybag/bluespace)

/datum/bounty/item/science/nightvision_goggles
	name = "Night Vision Goggles"
	description = "Из-за электрической бури на ЦентКоме перегорели все лампы. Пока руководство ждёт замены, возможно, удастся отправить очки ночного видения?"
	reward = 4250
	wanted_types = list(
		/obj/item/clothing/glasses/night,
		/obj/item/clothing/glasses/meson/night,
		/obj/item/clothing/glasses/hud/health/night,
		/obj/item/clothing/glasses/hud/security/night,
		/obj/item/clothing/glasses/hud/diagnostic/night
		)

/datum/bounty/item/science/experimental_welding_tool
	name = "Experimental Welding Tool"
	description = "Недавняя авария привела к взрыву большей части сварочных инструментов ЦентКома. Отправьте нам замену."
	reward = 8800
	required_count = 3
	wanted_types = list(/obj/item/weldingtool/experimental)

/datum/bounty/item/science/cryostasis_beaker
	name = "Cryostasis Beaker"
	description = "Химики Центрального Командования открыли новое вещество, которое можно хранить только в криостазисных мензурках. Вот только у них их нет! \
	Займитесь этим, чтобы получить оплату."
	reward = 3400
	wanted_types = list(/obj/item/reagent_containers/glass/beaker/noreact)

/datum/bounty/item/science/diamond_drill
	name = "Diamond Mining Drill"
	description = "Центральное Командование готово заплатить трёхмесячную зарплату за один алмазный шахтёрский бур."
	reward = 5500
	wanted_types = list(/obj/item/pickaxe/drill/diamonddrill, /obj/item/mecha_parts/mecha_equipment/drill/diamonddrill)

/datum/bounty/item/science/floor_buffer
	name = "Floor Buffer Upgrade"
	description = "Один из уборщиков ЦентКома сколотил небольшое состояние на ставках на гонках карпов. Теперь он хочет заказать улучшение для своей полотёрной машины."
	reward = 3700
	wanted_types = list(/obj/item/janicart_upgrade/buffer)

/datum/bounty/item/science/advanced_mop
	name = "Advanced Mop"
	description = "Прошу прощения. Мне нужно 17 кредитов на замену щетины в широкой метле. Либо, на худой конец, продвинутая швабра."
	reward = 4700
	wanted_types = list(/obj/item/mop/advanced)

/datum/bounty/item/science/advanced_egun
	name = "Advanced Energy Gun"
	description = "С ростом цен на зарядные устройства высшее руководство заинтересовано в покупке оружия с автономным питанием. Отправьте таковой образчик, и вам щедро заплатят."
	reward = 8980
	wanted_types = list(/obj/item/gun/energy/e_gun/nuclear)

/datum/bounty/item/science/bscells
	name = "Bluespace Power Cells"
	description = "Кто-то из высшего руководства вечно оправдывается тем, что батарея его планшета садится посреди работы. В последний раз у него не окажется презентации, клянусь...-"
	reward = 13000
	required_count = 10 //Easy to make
	wanted_types = list(/obj/item/stock_parts/cell/bluespace)

/datum/bounty/item/science/t4manip
	name = "Femto-Manipulators"
	description = "У одного из наших старших инженеров ОКР. Не могли бы вы прислать фемто-манипуляторы, чтобы он перестал жаловаться, что его ID-карта неидеально входит в слот КПК?"
	reward = 13000
	required_count = 20 //Easy to make
	wanted_types = list(/obj/item/stock_parts/manipulator/femto)

/datum/bounty/item/science/t4bins
	name = "Bluespace Matter Bins"
	description = "Местный профсоюз уборщиков объявил забастовку. Не могли бы вы прислать блюспейс-контейнеры, чтобы нам не приходилось самим выносить мусор?"
	reward = 13000
	required_count = 20 //Easy to make
	wanted_types = list(/obj/item/stock_parts/matter_bin/bluespace)

/datum/bounty/item/science/t4capacitor
	name = "Quadratic Capacitor"
	description = "Один из наших лингвистов не понимает, почему их называют квадратичными конденсаторами. Не могли бы вы дать ему несколько штук, чтобы он от нас отстал?"
	reward = 13000
	required_count = 20 //Easy to make
	wanted_types = list(/obj/item/stock_parts/capacitor/quadratic)

/datum/bounty/item/science/t4triphasic
	name = "Triphasic Scanning Module"
	description = "Один из наших учёных объелся галлюциногенных грибов и требует новые сканирующие модули, чтобы разговаривать с призраками. \
	Сейчас мы просто хотим, чтобы он ушёл из нашего офиса."
	reward = 13000
	required_count = 20 //Easy to make
	wanted_types = list(/obj/item/stock_parts/scanning_module/triphasic)

/datum/bounty/item/science/t4microlaser
	name = "Quad-Ultra Micro-Laser"
	description = "Кошки на Веге 9 бесконтрольно размножаются. Нам нужно нечто способное загнать их в одну зону, а затем устроить там массированную бомбардировку."
	reward = 13000
	required_count = 20 //Easy to make
	wanted_types = list(/obj/item/stock_parts/micro_laser/quadultra)

/datum/bounty/item/science/fakecrystals
	name = "Synthetic Bluespace Crystals"
	description = "Только, э-э, никому не говорите, но один из наших массивов БСА мог, скажем так... слегка пострадать. \
	Отправьте нам блюспейс-кристаллы, чтобы мы перекалибровали её, пока никто не заметил. \
	Весь комплект использует искусственные блюспейс-кристаллы, поэтому нам нужны именно они, а не другие типы блюспейс-кристаллов..."
	reward = 10000
	required_count = 5
	wanted_types = list(/obj/item/stack/ore/bluespace_crystal/artificial)
	exclude_types = list(
		/obj/item/stack/ore/bluespace_crystal,
		/obj/item/stack/sheet/bluespace_crystal,
		/obj/item/stack/ore/bluespace_crystal/refined
		)

/datum/bounty/item/science/noneactive_reactivearmor
	name = "Reactive Armor Shells"
	description = "Мы не успеваем конструировать оболочки реактивной брони, ввиду аномально высокой аномальной активности. Можете ли отправить нам несколько штук?"
	reward = 5500
	required_count = 5
	wanted_types = list(/obj/item/reactive_armour_shell, /obj/item/clothing/suit/armor/reactive)
	exclude_types = list(
		/obj/item/clothing/suit/armor/reactive/repulse,
		/obj/item/clothing/suit/armor/reactive/tesla,
		/obj/item/clothing/suit/armor/reactive/teleport,
		/obj/item/clothing/suit/armor/reactive/barricade,
		/obj/item/clothing/suit/armor/reactive/ectoplasm,
		/obj/item/clothing/suit/armor/reactive/smoke,
		/obj/item/clothing/suit/armor/reactive/fire,
		/obj/item/clothing/suit/armor/reactive/stealth
		)

/datum/bounty/item/science/anomaly_core
	name = "Anomaly Core"
	description = "Появилась новая теория: в каждом секторе космоса свои аномалии. Всё началось, когда на одной станции попытались создать реактивную броню на основе пироаномалии, \
	а в итоге получили версию с невидимостью. Пожалуйста, отправьте нам ядро, чтобы мы могли изучить его подробнее."
	reward = 7500
	required_count = 1
	wanted_types = list(/obj/item/assembly/signaler/anomaly)

/datum/bounty/item/science/anomaly_neutralizer
	name = "Anomaly Neutralizers"
	description = "Давно была идея использовать нестабильный осколок суперматерии, чтобы создать \"ферму\", нестабильный участок космоса, и изучать там любые нужные нам аномалии. \
	Получилось слишком хорошо, теперь у нас закончились нейтрализаторы аномалий. Пожалуйста, отправьте нам дюжину и ещё один."
	reward = 4000
	required_count = 13
	wanted_types = list(/obj/item/anomaly_neutralizer)

/datum/bounty/item/science/integrated_circuit_printer
	name = "Integrated Circuit Printer"
	description = "Из-за ошибки в документах на недавно созданной производственной линии интегральных схем не хватает трёх принтеров, необходимых нам для работы. \
	Пока бумаги не исправят, мы отдаём эту проблему на аутсорс, так что, пожалуйста, пришлите нам три принтера интегральных схем."
	reward = 3000
	required_count = 3
	wanted_types = list(/obj/item/integrated_circuit_printer)

/datum/bounty/item/science/integrated_circuit_disks
	name = "Integrated Circuit Printer Upgrade Disks"
	description = "Отдел кадров запросил ещё десять дисков улучшения для принтера интегральных схем. Пожалуйста, отправьте их в ЦентКом как можно скорее."
	reward = 4000
	required_count = 10 //Its just metal
	wanted_types = list(/obj/item/disk/integrated_circuit/upgrade)

/datum/bounty/item/science/nanite_trash
	name = "Nanite Based Gear"
	description = "ЦентКом хочет сделать снаряжение на основе нанитов доступным для нового отдела разработок, но им не хватает ручных инструментов, \
	чтобы полностью запустить проект: ремоутеров, сканнеров нанитов. Пожалуйста, отправьте всё, что у вас есть."
	reward = 4500
	required_count = 20 //Its just metal
	wanted_types = list( /obj/item/nanite_remote, /obj/item/nanite_remote/comm, /obj/item/nanite_scanner)
