
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Science /////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/science
	group = "Science"
	crate_type = /obj/structure/closet/crate/science

/datum/supply_pack/science/modsuit
	name = "Научный MOD"
	desc = "Один научный MOD с батареей и установленными штатными модулями."
	cost = 2500
	access = ACCESS_RESEARCH
	contains = list(/obj/item/mod/control/pre_equipped/research)
	crate_name = "научный MOD"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/ape  //Ape out!
	name = "Ape Cube Crate"
	desc = "Псс...что за новый испытуемый с суперсилой, скоростью и любовью к бананам одновременно? Больше ничего не говори... Содержит один куб обезьяны. Не добавляйте воду!"
	contraband = TRUE
	cost = 2500
	contains = list (/obj/item/reagent_containers/food/snacks/cube/ape)
	crate_name = "ape cube crate"
	can_private_buy = FALSE

/datum/supply_pack/science/beakers
	name = "Chemistry Beakers Crate"
	desc = "Стеклянная посуда для любой химической лаборатории! Содержит четыре маленьких стакана, три больших, два пластиковых и один из метаматериала. А также три капельницы и две пары латексных перчаток."
	cost = 1500
	contains = list(/obj/item/reagent_containers/glass/beaker,
					/obj/item/reagent_containers/glass/beaker,
					/obj/item/reagent_containers/glass/beaker,
					/obj/item/reagent_containers/glass/beaker,
					/obj/item/reagent_containers/glass/beaker/large,
					/obj/item/reagent_containers/glass/beaker/large,
					/obj/item/reagent_containers/glass/beaker/large,
					/obj/item/reagent_containers/glass/beaker/plastic,
					/obj/item/reagent_containers/glass/beaker/plastic,
					/obj/item/reagent_containers/glass/beaker/meta,
					/obj/item/reagent_containers/glass/beaker/noreact,
					/obj/item/reagent_containers/dropper,
					/obj/item/reagent_containers/dropper,
					/obj/item/reagent_containers/dropper,
					/obj/item/clothing/gloves/color/latex,
					/obj/item/clothing/gloves/color/latex)
	crate_name = "chemistry beaker crate"

/datum/supply_pack/science/robotics/mecha_odysseus
	name = "Circuit Crate (Odysseus)"
	desc = "Вы когда-нибудь хотели построить своего собственного гигантского медицинского робота? Что ж, теперь ты можешь! Содержит основную плату управления Odysseus и плату периферийных устройств Odysseus. Для открытия требуется доступ к робототехнике."
	cost = 1500
	access = ACCESS_ROBOTICS
	contains = list(/obj/item/circuitboard/mecha/odysseus/peripherals,
					/obj/item/circuitboard/mecha/odysseus/main)
	crate_name = "\improper Odysseus circuit crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/robotics/mecha_ripley
	name = "Circuit Crate (Ripley APLU)"
	desc = "Разрывайте камни и ксеноморфов одинаково с помощью Ripley APLU. Содержит основную плату управления Ripley, а также плату периферийных устройств Ripley. Для открытия требуется доступ к робототехнике."
	cost = 1200
	access = ACCESS_ROBOTICS
	contains = list(/obj/item/book/manual/ripley_build_and_repair,
					/obj/item/circuitboard/mecha/ripley/main,
					/obj/item/circuitboard/mecha/ripley/peripherals)
	crate_name = "\improper APLU Ripley circuit crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/circuitry
	name = "Circuitry Starter Pack Crate"
	desc = "Отправьтесь в таинственный мир схемотехники с этим стартовым пакетом. Содержит принтер схем, анализатор, отладчик и провод. Элементы питания в комплект не входят."
	cost = 1000
	contains = list(/obj/item/integrated_electronics/analyzer,
					/obj/item/integrated_circuit_printer,
					/obj/item/integrated_electronics/debugger,
					/obj/item/integrated_electronics/wirer)
	crate_name = "circuitry starter pack crate"

/datum/supply_pack/science/glasswork
	name = "Glass Blower Kit Crate"
	desc = "Учитесь и делайте из стекла полезные вещи с прибылью! Содержит инструменты для обработки стекла и выдувные стержни. Стекло в комплект не входит."
	cost = 1000
	contains = list(/obj/item/glasswork/glasskit,
					/obj/item/glasswork/glasskit,
					/obj/item/glasswork/blowing_rod,
					/obj/item/glasswork/blowing_rod)
	crate_name = "glassblower gear crate"

/datum/supply_pack/science/monkey
	name = "Monkey Cube Crate"
	desc = "Хватит валять дурака! Содержит семь кубиков обезьяны. Просто добавьте воды!"
	cost = 1500
	contains = list (/obj/item/storage/box/monkeycubes)
	crate_name = "monkey cube crate"

/datum/supply_pack/science/nitrilegloves
	name = "Nitrile Gloves Crate"
	desc = "Обращение с токсичными химикатами? Ну, не волнуйтесь, сохраняйте свою плоть нетронутой с помощью нитриловых перчаток! Содержит три пары нитриловых перчаток."
	cost = 1500
	contains = list(/obj/item/clothing/gloves/color/latex/nitrile,
					/obj/item/clothing/gloves/color/latex/nitrile,
					/obj/item/clothing/gloves/color/latex/nitrile)
	crate_name = "nitrile gloves crate"

/datum/supply_pack/science/plasma
	name = "Plasma Assembly Crate"
	desc = "Все, что вам нужно, чтобы сжечь что-то дотла, содержит три набора для сборки плазмы. Каждый набор содержит плазменный бак, воспламенитель, датчик приближения и таймер! Гарантия аннулируется при воздействии высоких температур. Требуется доступ к токсинам, чтобы открыть."
	cost = 1800
	access = ACCESS_TOX_STORAGE
	contains = list(/obj/item/tank/internals/plasma,
					/obj/item/tank/internals/plasma,
					/obj/item/tank/internals/plasma,
					/obj/item/assembly/igniter,
					/obj/item/assembly/igniter,
					/obj/item/assembly/igniter,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/timer,
					/obj/item/assembly/timer,
					/obj/item/assembly/timer)
	crate_name = "plasma assembly crate"
	crate_type = /obj/structure/closet/crate/secure/plasma

/datum/supply_pack/science/relic
	name = "Relic Crate"
	desc = "Вы когда-нибудь хотели поиграть со старыми игрушками со скидкой? Ни слова больше. Содержит две реликвии."
	cost = 1000
	contraband = TRUE
	contains = list(/obj/item/relic,
					/obj/item/relic)
	crate_name = "relic crate"

/datum/supply_pack/science/robotics
	name = "Robotics Assembly Crate"
	desc = "Инструменты, необходимые вам, чтобы заменить этих привередливых людей верной армией роботов! Содержит три датчика приближения, две мощные батареи, шесть вспышек и электрический набор инструментов. Для открытия требуется доступ к робототехнике."
	cost = 1500
	access = ACCESS_ROBOTICS
	contains = list(/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/storage/toolbox/electrical,
					/obj/item/storage/box/flashes,
					/obj/item/stock_parts/cell/high,
					/obj/item/stock_parts/cell/high)
	crate_name = "robotics assembly crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/robotics_repair
	name = "Robotics Repair Kit"
	desc = "Набор крайне полезных инструментов для ремонта синтетических товарищей. Содержит пять ёмкостей с SysCleaner. Для открытия требуется доступ к робототехнике."
	cost = 3000
	access = ACCESS_ROBOTICS
	contains = list(/obj/item/reagent_containers/glass/bottle/system_cleaner,
					/obj/item/reagent_containers/glass/bottle/system_cleaner,
					/obj/item/reagent_containers/glass/bottle/system_cleaner,
					/obj/item/reagent_containers/glass/bottle/system_cleaner,
					/obj/item/reagent_containers/glass/bottle/system_cleaner)
	crate_name = "robotics repair crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/rped
	name = "RPED crate"
	desc = "Нужно восстановить ORM, но наука была уничтожена после испытания бомбы? Купите это для самых продвинутых деталей, которые NT может вам предоставить."
	cost = 1500
	contains = list(/obj/item/storage/part_replacer/cargo)
	crate_name = "\improper RPED crate"

/datum/supply_pack/science/shieldwalls
	name = "Shield Generator Crate"
	desc = "Эти мощные генераторы щита гарантированно удержат любые нежелательные формы жизни снаружи, там, где им самое место! Содержит четыре генератора щита. Для открытия требуется доступ к телепорту."
	cost = 2000
	access = ACCESS_TELEPORTER
	contains = list(/obj/machinery/shieldwallgen,
					/obj/machinery/shieldwallgen,
					/obj/machinery/shieldwallgen,
					/obj/machinery/shieldwallgen)
	crate_name = "shield generators crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/slime
	name = "Slime Core Crate"
	desc = "Закончились слаймы? Нет проблем, содержит одно ядро серой слизи. Для открытия требуется доступ к Ксенобиологии."
	cost = 1000
	access = ACCESS_XENOBIOLOGY
	contains = list(/obj/item/slime_extract/grey)
	crate_name = "slime core crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/tablets
	name = "Tablet Crate"
	desc = "Что такое компьютер? Содержит пять  планшетов."
	cost = 1500
	contains = list(/obj/item/modular_computer/tablet/preset/cargo,
					/obj/item/modular_computer/tablet/preset/cargo,
					/obj/item/modular_computer/tablet/preset/cargo,
					/obj/item/modular_computer/tablet/preset/cargo,
					/obj/item/modular_computer/tablet/preset/cargo)
	crate_name = "tablet crate"

/datum/supply_pack/science/transfer_valves
	name = "Tank Transfer Valves Crate"
	desc = "Ключевой ингредиент для того, чтобы очень быстро разозлить многих людей. Содержит два перекачивающих клапана бака. Для открытия требуется РД доступ."
	cost = 6000
	access = ACCESS_RD
	contains = list(/obj/item/transfer_valve,
					/obj/item/transfer_valve)
	crate_name = "tank transfer valves crate"
	crate_type = /obj/structure/closet/crate/secure/science
	dangerous = TRUE

//////// RAW ANOMALY CORES

/datum/supply_pack/science/raw_flux_anomaly
	name = "Raw Flux Anomaly"
	desc = "Необработанное ядро аномалии потока, готовое к сжатию при взрыве в мощный артефакт."
	cost = 5000
	access = ACCESS_TOX
	contains = list(/obj/item/raw_anomaly_core/flux)
	crate_name = "raw flux anomaly"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/raw_grav_anomaly
	name = "Raw Gravitational Anomaly"
	desc = "Необработанное ядро гравитационной аномалии, готовое к сжатию при взрыве в мощный артефакт."
	cost = 5000
	access = ACCESS_TOX
	contains = list(/obj/item/raw_anomaly_core/grav)
	crate_name = "raw pyro anomaly"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/raw_vortex_anomaly
	name = "Raw Vortex Anomaly"
	desc = "Необработанное ядро вихревой аномалии, готовое к сжатию при взрыве в мощный артефакт."
	cost = 5000
	access = ACCESS_TOX
	contains = list(/obj/item/raw_anomaly_core/vortex)
	crate_name = "raw vortex anomaly"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/raw_bluespace_anomaly
	name = "Raw Bluespace Anomaly"
	desc = "Необработанное ядро блюспейс аномалии, готовое к сжатию при взрыве в мощный артефакт."
	cost = 5000
	access = ACCESS_TOX
	contains = list(/obj/item/raw_anomaly_core/bluespace)
	crate_name = "raw bluespace anomaly"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/raw_pyro_anomaly
	name = "Raw Pyro Anomaly"
	desc = "Необработанное ядро пиро анамалии, готовое к сжатию при взрыве в мощный артефакт."
	cost = 5000
	access = ACCESS_TOX
	contains = list(/obj/item/raw_anomaly_core/pyro)
	crate_name = "raw pyro anomaly"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/mod_core
	name = "MOD core Crate"
	desc = "Три ядра, идеально подходящие для вашего MODa!"
	cost = CARGO_CRATE_VALUE * 3
	access = ACCESS_ROBOTICS
	contains = list(/obj/item/mod/construction/core,
		/obj/item/mod/construction/core,
		/obj/item/mod/construction/core)
	crate_name = "MOD core crate"
	crate_type = /obj/structure/closet/crate/secure/science

