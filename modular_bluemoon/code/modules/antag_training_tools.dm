GLOBAL_LIST_INIT(antag_training_equipment, list(
	"baton" = list("name" = "Электродубинка", "category" = "Ближний бой", "type" = /obj/item/melee/baton/loaded),
	"knife" = list("name" = "Боевой нож", "category" = "Ближний бой", "type" = /obj/item/kitchen/knife/combat),
	"sword" = list("name" = "Энергетический меч", "category" = "Ближний бой", "type" = /obj/item/melee/transforming/energy/sword),
	"shield" = list("name" = "Щит ОМОНа", "category" = "Ближний бой", "type" = /obj/item/shield/riot),
	"flash" = list("name" = "Вспышка", "category" = "Ближний бой", "type" = /obj/item/assembly/flash/handheld),
	"cuffs" = list("name" = "Наручники", "category" = "Ближний бой", "type" = /obj/item/restraints/handcuffs),
	"laser" = list("name" = "Лазерный карабин", "category" = "Стрельба", "type" = /obj/item/gun/energy/laser),
	"egun" = list("name" = "Энергетическая винтовка", "category" = "Стрельба", "type" = /obj/item/gun/energy/e_gun),
	"disabler" = list("name" = "Дизейблер", "category" = "Стрельба", "type" = /obj/item/gun/energy/disabler),
	"pistol" = list("name" = "Пистолет 10 мм", "category" = "Стрельба", "type" = /obj/item/gun/ballistic/automatic/pistol),
	"magazine" = list("name" = "Магазин 10 мм", "category" = "Стрельба", "type" = /obj/item/ammo_box/magazine/m10mm),
	"shotgun" = list("name" = "Дробовик", "category" = "Стрельба", "type" = /obj/item/gun/ballistic/shotgun),
	"shells" = list("name" = "Коробка картечи", "category" = "Стрельба", "type" = /obj/item/ammo_box/shotgun/loaded/buckshot),
	"vest" = list("name" = "Бронежилет", "category" = "Защита", "type" = /obj/item/clothing/suit/armor/vest),
	"helmet" = list("name" = "Шлем", "category" = "Защита", "type" = /obj/item/clothing/head/helmet),
	"riot" = list("name" = "Костюм ОМОНа", "category" = "Защита", "type" = /obj/item/clothing/suit/armor/riot),
	"riot_helmet" = list("name" = "Шлем ОМОНа", "category" = "Защита", "type" = /obj/item/clothing/head/helmet/riot),
	"tools" = list("name" = "Пояс с инструментами", "category" = "Инструменты", "type" = /obj/item/storage/belt/utility/full),
	"welder" = list("name" = "Сварочный аппарат", "category" = "Инструменты", "type" = /obj/item/weldingtool/largetank),
	"multitool" = list("name" = "Мультитул", "category" = "Инструменты", "type" = /obj/item/multitool),
	"rcd" = list("name" = "RCD", "category" = "Инструменты", "type" = /obj/item/construction/rcd),
	"rcd_ammo" = list("name" = "Картридж RCD", "category" = "Инструменты", "type" = /obj/item/rcd_ammo),
	"firstaid" = list("name" = "Аптечка", "category" = "Медицина", "type" = /obj/item/storage/firstaid/regular),
	"health" = list("name" = "Медицинский анализатор", "category" = "Медицина", "type" = /obj/item/healthanalyzer/advanced),
	"surgery" = list("name" = "Хирургические инструменты", "category" = "Медицина", "type" = /obj/item/storage/backpack/duffelbag/med/surgery),
	"syringe" = list("name" = "Шприц", "category" = "Медицина", "type" = /obj/item/reagent_containers/syringe),
	"beaker" = list("name" = "Большой стакан", "category" = "Медицина", "type" = /obj/item/reagent_containers/glass/beaker/large),
	"steel" = list("name" = "Металл — 50 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/metal, "amount" = 50),
	"glass" = list("name" = "Стекло — 50 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/glass, "amount" = 50),
	"plasteel" = list("name" = "Пласталь — 50 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/plasteel, "amount" = 50),
	"wood" = list("name" = "Дерево — 50 досок", "category" = "Материалы", "type" = /obj/item/stack/sheet/mineral/wood, "amount" = 50),
	"cable" = list("name" = "Кабель — 30 отрезков", "category" = "Материалы", "type" = /obj/item/stack/cable_coil, "amount" = 30),
	"cloth" = list("name" = "Ткань — 10 отрезков", "category" = "Материалы", "type" = /obj/item/stack/sheet/cloth, "amount" = 10),
	"silver" = list("name" = "Серебро — 10 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/mineral/silver, "amount" = 10),
	"candle" = list("name" = "Свеча", "category" = "Инструменты", "type" = /obj/item/candle),
	"matches" = list("name" = "Спички", "category" = "Инструменты", "type" = /obj/item/storage/box/matches),
	"forensic_scanner" = list("name" = "Криминалистический сканер", "category" = "Инструменты", "desc" = "Снимает отпечатки, волокна и следы крови.", "type" = /obj/item/detective_scanner),
	"rods" = list("name" = "Прутья — 50 штук", "category" = "Материалы", "type" = /obj/item/stack/rods, "amount" = 50),
	"rglass" = list("name" = "Армированное стекло — 50 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/rglass, "amount" = 50),
	"plastic" = list("name" = "Пластик — 50 листов", "category" = "Материалы", "type" = /obj/item/stack/sheet/plastic, "amount" = 50),
	"defibrillator" = list("name" = "Дефибриллятор с батареей", "category" = "Медицина", "desc" = "Для практики реанимации. Медицинский анализатор поможет проверить состояние тела.", "type" = /obj/item/defibrillator/loaded),
	"burn_kit" = list("name" = "Аптечка от ожогов", "category" = "Медицина", "type" = /obj/item/storage/firstaid/fire),
	"toxin_kit" = list("name" = "Аптечка от отравления", "category" = "Медицина", "type" = /obj/item/storage/firstaid/toxin),
	"oxygen_kit" = list("name" = "Аптечка от кислородного голодания", "category" = "Медицина", "type" = /obj/item/storage/firstaid/o2),
	"dropper" = list("name" = "Пипетка", "category" = "Химия", "desc" = "Перенос небольших доз реагентов между ёмкостями.", "type" = /obj/item/reagent_containers/dropper),
	"bottle" = list("name" = "Бутылочка", "category" = "Химия", "type" = /obj/item/reagent_containers/glass/bottle),
	"spray" = list("name" = "Распылитель", "category" = "Химия", "desc" = "Пустой: залейте свою смесь.", "type" = /obj/item/reagent_containers/spray),
	"science_goggles" = list("name" = "Научные очки", "category" = "Химия", "desc" = "Показывают состав реагентов в ёмкостях.", "type" = /obj/item/clothing/glasses/science),
	"grenade_casing" = list("name" = "Корпус химической гранаты", "category" = "Химия", "desc" = "Вставьте запал из воспламенителя и таймера, затем стаканы со смесью, и закрутите отвёрткой.", "type" = /obj/item/grenade/chem_grenade),
	"igniter" = list("name" = "Воспламенитель", "category" = "Химия", "desc" = "Вместе с таймером - запал гранаты.", "type" = /obj/item/assembly/igniter),
	"timer" = list("name" = "Таймер", "category" = "Химия", "type" = /obj/item/assembly/timer),
	"dispenser_board" = list("name" = "Плата химраздатчика", "category" = "Сборка машин", "desc" = "Установите в каркас машины. Каркас подскажет, каких деталей не хватает.", "type" = /obj/item/circuitboard/machine/chem_dispenser),
	"chemmaster_board" = list("name" = "Плата ChemMaster", "category" = "Сборка машин", "type" = /obj/item/circuitboard/machine/chem_master),
	"recharger_board" = list("name" = "Плата зарядной станции", "category" = "Сборка машин", "type" = /obj/item/circuitboard/machine/recharger),
	"capacitor" = list("name" = "Конденсатор", "category" = "Сборка машин", "type" = /obj/item/stock_parts/capacitor),
	"manipulator" = list("name" = "Манипулятор", "category" = "Сборка машин", "type" = /obj/item/stock_parts/manipulator),
	"matter_bin" = list("name" = "Ёмкость материи", "category" = "Сборка машин", "type" = /obj/item/stock_parts/matter_bin),
	"micro_laser" = list("name" = "Микролазер", "category" = "Сборка машин", "type" = /obj/item/stock_parts/micro_laser),
	"cell" = list("name" = "Батарея высокой ёмкости", "category" = "Сборка машин", "type" = /obj/item/stock_parts/cell/high),
	"telebaton" = list("name" = "Телескопическая дубинка", "category" = "Ближний бой", "type" = /obj/item/melee/classic_baton/telescopic),
	"bola" = list("name" = "Бола", "category" = "Ближний бой", "desc" = "Бросок опутывает ноги и валит бегущую цель.", "type" = /obj/item/restraints/legcuffs/bola),
	"pepper" = list("name" = "Перцовый баллончик", "category" = "Ближний бой", "type" = /obj/item/reagent_containers/spray/pepper),
	"zipties" = list("name" = "Стяжки", "category" = "Ближний бой", "desc" = "Одноразовые наручники: снятые рвутся.", "type" = /obj/item/restraints/handcuffs/cable/zipties),
	"security_belt" = list("name" = "Пояс СБ", "category" = "Ближний бой", "desc" = "Перцовый баллончик, наручники, светошумовая граната, вспышка и электродубинка.", "type" = /obj/item/storage/belt/security/full),
	"contractor_baton" = list("name" = "Дубинка контрактника", "category" = "Ближний бой", "type" = /obj/item/melee/classic_baton/telescopic/contractor_baton),
	"fireaxe" = list("name" = "Пожарный топор", "category" = "Ближний бой", "desc" = "Держите двумя руками, чтобы бить в полную силу.", "type" = /obj/item/fireaxe),
	"taser" = list("name" = "Гибридный тазер", "category" = "Стрельба", "type" = /obj/item/gun/energy/e_gun/advtaser),
	"beanbag" = list("name" = "Коробка резиновых патронов", "category" = "Стрельба", "desc" = "Нелетальные патроны для дробовика.", "type" = /obj/item/storage/box/beanbag),
	"teargas" = list("name" = "Граната со слезоточивым газом", "category" = "Стрельба", "type" = /obj/item/grenade/chem_grenade/teargas),
	"revolver" = list("name" = "Револьвер .357", "category" = "Стрельба", "type" = /obj/item/gun/ballistic/revolver),
	"speedloader" = list("name" = "Спидлоадер .357", "category" = "Стрельба", "type" = /obj/item/ammo_box/a357),
	"detective_revolver" = list("name" = "Револьвер детектива .38", "category" = "Стрельба", "type" = /obj/item/gun/ballistic/revolver/detective),
	"speedloader_38" = list("name" = "Спидлоадер .38", "category" = "Стрельба", "type" = /obj/item/ammo_box/c38),
	"wt550" = list("name" = "Пистолет-пулемёт WT-550", "category" = "Стрельба", "type" = /obj/item/gun/ballistic/automatic/wt550/standart),
	"wt550_magazine" = list("name" = "Магазин WT-550", "category" = "Стрельба", "type" = /obj/item/ammo_box/magazine/wt550m9),
	"c20r" = list("name" = "Пистолет-пулемёт C-20r", "category" = "Стрельба", "type" = /obj/item/gun/ballistic/automatic/c20r/unrestricted),
	"c20r_magazine" = list("name" = "Магазин .45 для C-20r", "category" = "Стрельба", "type" = /obj/item/ammo_box/magazine/smgm45),
	"crossbow" = list("name" = "Мини энергетический арбалет", "category" = "Стрельба", "desc" = "Бесшумный, заряд восстанавливается сам.", "type" = /obj/item/gun/energy/kinetic_accelerator/crossbow),
	"ionrifle" = list("name" = "Ионная винтовка", "category" = "Стрельба", "desc" = "Бьёт по электронике, киборгам и синтетикам.", "type" = /obj/item/gun/energy/ionrifle),
	"smoke" = list("name" = "Дымовая граната", "category" = "Стрельба", "desc" = "Дымовая завеса закрывает обзор.", "type" = /obj/item/grenade/smokebomb),
	"emp" = list("name" = "ЭМИ-граната", "category" = "Стрельба", "desc" = "Разряжает энергооружие и бьёт по электронике и киборгам рядом.", "type" = /obj/item/grenade/empgrenade),
	"bulletproof" = list("name" = "Пуленепробиваемый жилет", "category" = "Защита", "type" = /obj/item/clothing/suit/armor/bulletproof),
	"sunglasses" = list("name" = "Солнцезащитные очки", "category" = "Защита", "desc" = "Защищают глаза от вспышек.", "type" = /obj/item/clothing/glasses/sunglasses),
	"bulletproof_helmet" = list("name" = "Пуленепробиваемый шлем", "category" = "Защита", "type" = /obj/item/clothing/head/helmet/alt),
	"combat_gloves" = list("name" = "Боевые перчатки", "category" = "Защита", "desc" = "Изолированные: защищают и от удара током.", "type" = /obj/item/clothing/gloves/combat),
	"holobarrier" = list("name" = "Проектор голобарьеров СБ", "category" = "Защита", "desc" = "Голографические барьеры для оцепления.", "type" = /obj/item/holosign_creator/security),
	"emag" = list("name" = "Криптографический секвенсор", "category" = "Скрытность", "desc" = "Емаг: взламывает шлюзы, шкафы и машины.", "type" = /obj/item/card/emag),
	"chameleon_mask" = list("name" = "Маска-хамелеон", "category" = "Скрытность", "desc" = "Меняет облик и подменяет голос.", "type" = /obj/item/clothing/mask/chameleon),
	"noslip" = list("name" = "Нескользящие ботинки-хамелеон", "category" = "Скрытность", "desc" = "Не дают поскользнуться на мокром полу и мыле.", "type" = /obj/item/clothing/shoes/chameleon/noslip),
	"thermals" = list("name" = "Термальные очки", "category" = "Скрытность", "desc" = "Показывают живых сквозь стены.", "type" = /obj/item/clothing/glasses/thermal/syndi),
	"sleepy_pen" = list("name" = "Снотворная ручка", "category" = "Скрытность", "desc" = "Укол усыпляет цель и лишает её голоса.", "type" = /obj/item/pen/sleepy),
	"edagger" = list("name" = "Энергокинжал", "category" = "Скрытность", "desc" = "Ручка, которая включается в энергетический клинок.", "type" = /obj/item/pen/edagger),
	"gauze" = list("name" = "Марля", "category" = "Медицина", "desc" = "Останавливает кровотечение.", "type" = /obj/item/stack/medical/gauze),
	"suture" = list("name" = "Швы", "category" = "Медицина", "type" = /obj/item/stack/medical/suture),
	"medipen" = list("name" = "Медипен с эпинефрином", "category" = "Медицина", "type" = /obj/item/reagent_containers/hypospray/medipen),
	"bruise_pack" = list("name" = "Бинты от ушибов", "category" = "Медицина", "type" = /obj/item/stack/medical/bruise_pack),
	"ointment" = list("name" = "Мазь от ожогов", "category" = "Медицина", "type" = /obj/item/stack/medical/ointment),
	"charcoal" = list("name" = "Таблетки угля", "category" = "Медицина", "desc" = "Выводят токсины.", "type" = /obj/item/storage/pill_bottle/charcoal),
	"tactical_kit" = list("name" = "Тактическая аптечка", "category" = "Медицина", "desc" = "Боевой дефибриллятор и гипоспреи.", "type" = /obj/item/storage/firstaid/tactical),
	"roller" = list("name" = "Каталка", "category" = "Медицина", "desc" = "Перевозка лежачего пациента.", "type" = /obj/item/roller),
	"bodybag" = list("name" = "Мешок для тела", "category" = "Медицина", "type" = /obj/item/bodybag),
	"nullrod" = list("name" = "Нуль-жезл", "category" = "Контрмеры", "desc" = "Защищает владельца от магии.", "type" = /obj/item/nullrod),
	"holywater" = list("name" = "Святая вода", "category" = "Контрмеры", "desc" = "Выпитая смывает мелодию Пляски и выводит из стазиса Песка.", "type" = /obj/item/reagent_containers/food/drinks/bottle/holywater),
	"foilhat" = list("name" = "Шапочка из фольги", "category" = "Контрмеры", "desc" = "Держит только ментальные чары.", "type" = /obj/item/clothing/head/foilhat),
	"earmuffs" = list("name" = "Наушники-заглушки", "category" = "Контрмеры", "desc" = "Глушат такт Пляски.", "type" = /obj/item/clothing/ears/earmuffs),
	"flashbang" = list("name" = "Светошумовая граната", "category" = "Контрмеры", "desc" = "Ослепляет и оглушает. В Болеро - фальшивая нота, сбивающая ступень.", "type" = /obj/item/grenade/flashbang),
	"bikehorn" = list("name" = "Клаксон", "category" = "Контрмеры", "desc" = "Гудок в Болеро - фальшивая нота, сбивающая ступень.", "type" = /obj/item/bikehorn),
	"bible" = list("name" = "Библия", "category" = "Контрмеры", "type" = /obj/item/storage/book/bible),
	"insulated_gloves" = list("name" = "Изолированные перчатки", "category" = "Инженерия", "desc" = "Защищают от удара током при работе с проводами и щитками.", "type" = /obj/item/clothing/gloves/color/yellow),
	"plasma" = list("name" = "Плазма — 20 листов", "category" = "Инженерия", "desc" = "Топливо генератора P.A.C.M.A.N. От горячего инструмента вспыхивает горящим газом.", "type" = /obj/item/stack/sheet/mineral/plasma, "amount" = 20),
	"apc_frame" = list("name" = "Каркас APC", "category" = "Инженерия", "desc" = "Вешается на стену сектора с питанием, если в нём нет другого APC: прежний щиток сначала разберите.", "type" = /obj/item/wallframe/apc),
	"apc_board" = list("name" = "Плата APC", "category" = "Инженерия", "desc" = "Ставится в открытый каркас APC и закрепляется отвёрткой, без этого батарею не вставить. Затем снимите плитку под щитком, проложите 10 отрезков кабеля и вставьте батарею.", "type" = /obj/item/electronics/apc),
	"welding_helmet" = list("name" = "Сварочная маска", "category" = "Инженерия", "desc" = "Защищает глаза при сварке.", "type" = /obj/item/clothing/head/welding),
	"mesons" = list("name" = "Мезонные очки", "category" = "Инженерия", "desc" = "Показывают стены и пол сквозь темноту.", "type" = /obj/item/clothing/glasses/meson),
	"t_scanner" = list("name" = "Т-сканер", "category" = "Инженерия", "desc" = "Показывает кабели и трубы под полом.", "type" = /obj/item/t_scanner),
	"floor_tiles" = list("name" = "Плитка пола — 20 штук", "category" = "Инженерия", "type" = /obj/item/stack/tile/plasteel, "amount" = 20),
	"airlock_electronics" = list("name" = "Электроника шлюза", "category" = "Инженерия", "desc" = "Ставится в каркас шлюза и задаёт ему доступ.", "type" = /obj/item/electronics/airlock),
	"mask" = list("name" = "Противогаз", "category" = "Атмос", "type" = /obj/item/clothing/mask/gas),
	"oxygen" = list("name" = "Кислородный баллон", "category" = "Атмос", "type" = /obj/item/tank/internals/oxygen),
	"analyzer" = list("name" = "Газоанализатор", "category" = "Атмос", "type" = /obj/item/analyzer),
	"extinguisher" = list("name" = "Огнетушитель", "category" = "Атмос", "type" = /obj/item/extinguisher),
	"breath_mask" = list("name" = "Дыхательная маска", "category" = "Атмос", "type" = /obj/item/clothing/mask/breath),
	"emergency_oxygen" = list("name" = "Аварийный баллон с кислородом", "category" = "Атмос", "type" = /obj/item/tank/internals/emergency_oxygen),
	"plasma_tank" = list("name" = "Поясной баллон с плазмой", "category" = "Атмос", "desc" = "Дыхание для плазмолюдов.", "type" = /obj/item/tank/internals/plasmaman/belt/full),
	"firesuit" = list("name" = "Пожарный костюм", "category" = "Атмос", "type" = /obj/item/clothing/suit/fire/firefighter),
	"fire_helmet" = list("name" = "Пожарная каска", "category" = "Атмос", "type" = /obj/item/clothing/head/hardhat/red),
	"holofan" = list("name" = "Проектор атмосферных голобарьеров", "category" = "Атмос", "desc" = "Барьер не пропускает газ, а люди проходят.", "type" = /obj/item/holosign_creator/atmos),
	"suit" = list("name" = "Скафандр", "category" = "Космос", "type" = /obj/item/clothing/suit/space),
	"space_helmet" = list("name" = "Шлем скафандра", "category" = "Космос", "desc" = "Держит подачу воздуха из баллона или джетпака без маски.", "type" = /obj/item/clothing/head/helmet/space),
	"jetpack" = list("name" = "Кислородный джетпак", "category" = "Космос", "desc" = "Включается кнопкой действия, стабилизатор гасит дрейф. Газ тратится и на полёт, и на дыхание.", "type" = /obj/item/tank/jetpack/oxygen),
	"magboots" = list("name" = "Магнитные ботинки", "category" = "Космос", "desc" = "Включённые держат на полу без гравитации, но замедляют шаг.", "type" = /obj/item/clothing/shoes/magboots),
	"gps" = list("name" = "GPS", "category" = "Космос", "desc" = "Выдаётся выключенным: включите его, чтобы видеть координаты, область и другие учебные GPS. Станционные GPS его сигнала не видят, а он - их.", "type" = /obj/item/gps/antag_training),
	"mmi" = list("name" = "MMI", "category" = "Робототехника", "desc" = "Вместилище для мозга учебной цели. MMI с мозгом вставляется в учебную раму киборга.", "type" = /obj/item/mmi),
	"flashlight" = list("name" = "Фонарик", "category" = "Разное", "type" = /obj/item/flashlight),
	"radio" = list("name" = "Рация", "category" = "Разное", "desc" = "Слышна только на полигоне: станция её не принимает.", "type" = /obj/item/radio),
	"duffelbag" = list("name" = "Вещмешок", "category" = "Разное", "type" = /obj/item/storage/backpack/duffelbag),
	"pen" = list("name" = "Ручка", "category" = "Разное", "type" = /obj/item/pen)
))

GLOBAL_LIST_INIT(antag_training_structures, list(
	"table" = list("name" = "Стол", "category" = "Обстановка", "desc" = "Разместить инструменты, проверить укрытие и взаимодействие с предметами.", "type" = /obj/structure/table),
	"rack" = list("name" = "Стеллаж", "category" = "Обстановка", "desc" = "Хранение предметов и практика разборки.", "type" = /obj/structure/rack),
	"closet" = list("name" = "Шкаф", "category" = "Обстановка", "desc" = "Проверка укрытия, захватов и взаимодействия с содержимым.", "type" = /obj/structure/closet),
	"bed" = list("name" = "Кровать", "category" = "Обстановка", "desc" = "Пристёгивание, перенос пациентов и осмотр лежащего персонажа.", "type" = /obj/structure/bed),
	"chair" = list("name" = "Стул", "category" = "Обстановка", "desc" = "Пристёгивание, перемещение и ближний бой.", "type" = /obj/structure/chair),
	"window" = list("name" = "Полноразмерное окно", "category" = "Преграды", "desc" = "Проверка ударов, стрельбы, ремонта и демонтажа.", "type" = /obj/structure/window/fulltile),
	"grille" = list("name" = "Решётка", "category" = "Преграды", "desc" = "Преграда для проверки инструментов и снарядов.", "type" = /obj/structure/grille),
	"airlock" = list("name" = "Шлюз", "category" = "Преграды", "desc" = "Практика работы с проводами, взлома и разборки шлюза.", "type" = /obj/machinery/door/airlock),
	"frame" = list("name" = "Каркас машины", "category" = "Оборудование", "desc" = "Соберите машину сами: кабель, платы и детали есть в снаряжении.", "type" = /obj/structure/frame),
	"recharger" = list("name" = "Зарядная станция", "category" = "Оборудование", "desc" = "Зарядка энергетического оружия и электродубинок.", "type" = /obj/machinery/recharger),
	"operating_table" = list("name" = "Операционный стол", "category" = "Медицина и химия", "desc" = "Для операций: перетащите пациента на стол и возьмите хирургические инструменты.", "type" = /obj/structure/table/optable),
	"sleeper" = list("name" = "Слипер", "category" = "Медицина и химия", "desc" = "Помощь пациенту и проверка медицинских препаратов.", "type" = /obj/machinery/sleeper),
	"chem_dispenser" = list("name" = "Химраздатчик", "category" = "Медицина и химия", "desc" = "Смешивание реагентов по рецептам. Стаканы и пипетки есть в снаряжении.", "type" = /obj/machinery/chem_dispenser),
	"chem_master" = list("name" = "ChemMaster", "category" = "Медицина и химия", "desc" = "Разделение смесей и изготовление таблеток и бутылочек.", "type" = /obj/machinery/chem_master),
	"crate" = list("name" = "Ящик", "category" = "Обстановка", "desc" = "Укрытие для тела или предметов.", "type" = /obj/structure/closet/crate),
	"secure_closet" = list("name" = "Запираемый шкаф", "category" = "Обстановка", "desc" = "Проверка замков и взлома запертых шкафов.", "type" = /obj/structure/closet/secure_closet),
	"glass_table" = list("name" = "Стеклянный стол", "category" = "Обстановка", "desc" = "Разбивается, если на него бросить человека.", "type" = /obj/structure/table/glass),
	"barricade" = list("name" = "Деревянная баррикада", "category" = "Преграды", "desc" = "Укрытие от выстрелов, ломается ударами.", "type" = /obj/structure/barricade/wooden)
))

GLOBAL_LIST_INIT(antag_training_injuries, list(
	"brute" = list("name" = "Ушибы: +40", "type" = BRUTE, "amount" = 40),
	"burn" = list("name" = "Ожоги: +40", "type" = BURN, "amount" = 40),
	"toxin" = list("name" = "Токсины: +30", "type" = TOX, "amount" = 30),
	"oxygen" = list("name" = "Кислородный урон: +40", "type" = OXY, "amount" = 40)
))

GLOBAL_LIST_INIT(antag_training_conditions, list(
	"knockdown" = "Сбить с ног на 10 с",
	"exhaust" = "Обессилить",
	"cuffs" = "Надеть или снять наручники"
))

GLOBAL_LIST_INIT(antag_training_creatures, list(
	"human" = list("name" = "Человек без брони", "type" = /mob/living/carbon/human),
	"runner" = list("name" = "Бегущий человек", "type" = /mob/living/carbon/human, "runner" = TRUE),
	"armored" = list("name" = "Человек в бронежилете", "type" = /mob/living/carbon/human, "armored" = TRUE),
	"corpse" = list("name" = "Тело для ритуала", "type" = /mob/living/carbon/human, "dead" = TRUE),
	"carp" = list("name" = "Космический карп", "type" = /mob/living/simple_animal/hostile/carp),
	"bear" = list("name" = "Медведь", "type" = /mob/living/simple_animal/hostile/bear),
	"operative" = list("name" = "Оперативник с ножом", "type" = /mob/living/simple_animal/hostile/syndicate),
	"gunner" = list("name" = "Оперативник со стрельбой", "type" = /mob/living/simple_animal/hostile/syndicate/ranged),
	"goliath" = list("name" = "Голиаф", "type" = /mob/living/simple_animal/hostile/asteroid/goliath),
	"spider" = list("name" = "Паук-охотник", "type" = /mob/living/simple_animal/hostile/poison/giant_spider/hunter),
	"xeno" = list("name" = "Ксеноморф-охотник", "type" = /mob/living/simple_animal/hostile/alien),
	"hivebot" = list("name" = "Хайвбот-стрелок", "type" = /mob/living/simple_animal/hostile/hivebot/range)
))

/datum/antag_training_arena/proc/build_zones()
	zones = list(
		"hub" = list("name" = "Безопасный центр", "desc" = "Восстановление, снаряжение и переходы.", "bounds" = list(25, 31, 25, 31), "spawn" = locate(28, 28, private_level.z_value), "target" = locate(28, 28, private_level.z_value)),
		"melee" = list("name" = "Ближний бой", "desc" = "Открытая площадка для дистанции, ударов и контроля.", "bounds" = list(3, 24, 3, 24), "spawn" = locate(20, 13, private_level.z_value), "target" = locate(10, 13, private_level.z_value)),
		"range" = list("name" = "Тир", "desc" = "Длинная дистанция, линии стрельбы и зарядная станция.", "bounds" = list(32, 53, 3, 24), "spawn" = locate(36, 13, private_level.z_value), "target" = locate(49, 13, private_level.z_value)),
		"pve" = list("name" = "Арена противников", "desc" = "Активные враги и укрытия для боевых сценариев.", "bounds" = list(32, 53, 32, 53), "spawn" = locate(36, 42, private_level.z_value), "target" = locate(48, 42, private_level.z_value)),
		"laboratory" = list("name" = "Лаборатория", "desc" = "Ритуалы, медицина и девять рабочих мест для дел пути. Каждый ряд кроватей, столов и приборов — отдельная учебная локация.", "bounds" = list(3, 24, 32, 53), "spawn" = locate(20, 42, private_level.z_value), "target" = locate(13, 42, private_level.z_value))
	)
	for(var/datum/antag_training_sector/sector_type as anything in subtypesof(/datum/antag_training_sector))
		if(!initial(sector_type.id))
			continue
		var/datum/antag_training_sector/sector = new sector_type(src)
		sectors[sector.id] = sector

/datum/antag_training_arena/proc/build_ground(zone_id)
	var/list/reset_bounds = zones[zone_id]?["bounds"]
	var/list/work_tiles = reset_bounds ? block(locate(reset_bounds[1], reset_bounds[3], private_level.z_value), locate(reset_bounds[2], reset_bounds[4], private_level.z_value)) : reservation.reserved_turfs
	for(var/turf/tile as anything in work_tiles)
		yield_work()
		if(finished)
			return
		if(reset_bounds && !inside_bounds(tile, reset_bounds))
			continue
		var/is_wall = tile.x <= 2 || tile.x >= 54 || tile.y <= 2 || tile.y >= 54
		var/is_door = FALSE
		var/tile_zone = inside_bounds(tile, zones["hub"]["bounds"]) ? "hub" : null
		for(var/other_zone in zones)
			if(other_zone == "hub")
				continue
			var/list/bounds = zones[other_zone]["bounds"]
			if(!inside_bounds(tile, bounds))
				continue
			tile_zone = other_zone
			is_wall = tile.x == bounds[1] || tile.x == bounds[2] || tile.y == bounds[3] || tile.y == bounds[4]
			var/door_x = bounds[1] < 25 ? bounds[2] : bounds[1]
			var/door_y = round((bounds[3] + bounds[4]) / 2)
			is_door = tile.x == door_x && abs(tile.y - door_y) <= 1
			break
		var/ground_type = GLOB.antag_training_core_floors[tile_zone] || /turf/open/floor/holofloor/antag_training
		if(is_door)
			ground_type = /turf/open/floor/holofloor/antag_training
		else if(is_wall)
			ground_type = /turf/closed/indestructible/antag_training
		else if(tile_zone == "laboratory")
			ground_type = /turf/open/floor/plating
		tile = tile.ChangeTurf(ground_type, null, CHANGETURF_INHERIT_AIR)
		tile.color = initial(tile.color)
		if(is_door)
			new /obj/structure/antag_training_barrier(tile, src)
	if(!zone_id || zone_id == "pve")
		for(var/column in list(40, 45))
			for(var/row in list(37, 38, 46, 47))
				var/turf/cover = locate(column, row, private_level.z_value)
				cover.ChangeTurf(/turf/closed/indestructible/antag_training)
	if(!zone_id || zone_id == "range")
		new /obj/machinery/recharger(locate(36, 7, private_level.z_value))
		for(var/column in list(40, 45, 50))
			for(var/row in 8 to 18)
				var/turf/line = locate(column, row, private_level.z_value)
				line.color = "#dce6f4"
	if(!zone_id || zone_id == "laboratory")
		for(var/column in list(5, 11, 17))
			for(var/row in list(33, 39, 45))
				yield_work()
				if(finished)
					return
				new /obj/structure/bed(locate(column, row, private_level.z_value))
				new /obj/structure/table(locate(column + 1, row, private_level.z_value))
				new /obj/machinery/light(locate(column + 2, row, private_level.z_value))
				new /obj/structure/sink(locate(column, row + 2, private_level.z_value))
				new /obj/machinery/vending/antag_training(locate(column + 1, row + 2, private_level.z_value))
				new /obj/item/radio/intercom(locate(column + 2, row + 2, private_level.z_value))
				new /obj/structure/window(locate(column + 3, row + 2, private_level.z_value))
				new /obj/machinery/door/airlock(locate(column + 4, row + 2, private_level.z_value))
				var/turf/marker = locate(column + 1, row + 1, private_level.z_value)
				marker.color = "#63858f"
	place_zone_boards(zone_id)
	// Полы строятся пустыми и заполняются за один тик: заполненная клетка рядом с пустой или космосом гонит ветер.
	for(var/turf/open/floor in work_tiles)
		floor.air.copy_from_turf(floor)
	for(var/turf/open/floor in work_tiles)
		floor.air_update_turf(FALSE, FALSE)
		yield_work()
		if(finished)
			return

GLOBAL_LIST_INIT(antag_training_core_floors, list(
	"hub" = /turf/open/floor/holofloor/antag_training/hub,
	"melee" = /turf/open/floor/holofloor/antag_training/melee,
	"range" = /turf/open/floor/holofloor/antag_training/range,
	"pve" = /turf/open/floor/holofloor/antag_training/pve
))

/turf/open/floor/holofloor/antag_training
	name = "holographic floor"
	desc = "Голографический пол полигона: инструментами его не разобрать, а сброс зоны проецирует его заново."
	color = "#b8ccd0"
	heretic_rustable = TRUE

/turf/open/floor/holofloor/antag_training/hub
	color = "#87b6a4"

/turf/open/floor/holofloor/antag_training/melee
	color = "#e8b4a4"

/turf/open/floor/holofloor/antag_training/range
	color = "#a8c4ec"

/turf/open/floor/holofloor/antag_training/pve
	color = "#c4b4e8"

/turf/closed/indestructible/antag_training
	name = "holographic wall"
	desc = "Голографическая стена полигона. Её не пробить и не разобрать."
	icon_state = "riveted"
	color = "#8fd8ff"

/obj/machinery/vending/antag_training
	name = "training vending machine"
	desc = "Учебный автомат для проверки взаимодействий. Выдавайте предметы через пульт полигона."
	icon_state = "snack"
	products = list()
	contraband = list()
	premium = list()

/obj/item/gps/antag_training
	desc = "Учебный GPS полигона. Показывает координаты, область и другие учебные GPS полигона, а станционные приёмники его сигнала не видят."
	gpstag = "TRN0"
	starton = FALSE
	gps_component = /datum/component/gps/item/antag_training
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'

GLOBAL_LIST_EMPTY(antag_training_gps)

/// Свой список сигналов вместо станционного: только учебные GPS того же уровня.
/datum/component/gps/item/antag_training
	global_mode = FALSE

/datum/component/gps/item/antag_training/join_signal_lists()
	GLOB.antag_training_gps += src

/datum/component/gps/item/antag_training/leave_signal_lists()
	GLOB.antag_training_gps -= src

/datum/component/gps/item/antag_training/signal_sources()
	return GLOB.antag_training_gps

/datum/component/gps/item/antag_training/ui_act(action, params)
	if(action == "globalmode")
		var/atom/holder = parent
		if(ismob(usr))
			holder.balloon_alert(usr, "ловит только сигналы полигона")
		return FALSE
	return ..()

/datum/antag_training_arena/proc/inside_bounds(turf/tile, list/bounds)
	return tile?.z == private_level.z_value && tile.x >= bounds[1] && tile.x <= bounds[2] && tile.y >= bounds[3] && tile.y <= bounds[4]

/datum/antag_training_arena/proc/reset_zone(zone_id)
	var/list/zone = zone_id == "all" ? list("bounds" = list(1, ANTAG_TRAINING_SIZE, 1, ANTAG_TRAINING_SIZE)) : zones[zone_id]
	if(!zone || zone_id == "hub" || finished || resetting || world.time < next_reset_at)
		return FALSE
	next_reset_at = world.time + 5 SECONDS
	resetting = TRUE
	reset_zone_id = zone_id
	stop_zone_exercises(zone_id)
	var/datum/antag_training_sector/reset_sector = sectors[zone_id]
	if(reset_sector)
		reset_sector.unload()
		. = reset_sector.load()
		prune_targets()
		resetting = FALSE
		reset_zone_id = null
		return
	duel?.finish("Дуэль завершена: выполняется общий сброс.")
	if(zone_id == "all")
		for(var/sector_id in sectors)
			var/datum/antag_training_sector/sector = sectors[sector_id]
			sector.unload()
	for(var/datum/antag_training_session/member as anything in members)
		if(inside_bounds(get_turf(member.current_body), zone["bounds"]))
			member.current_body.forceMove(entry_turf)
	var/list/bounds = zone["bounds"]
	for(var/turf/tile as anything in block(locate(bounds[1], bounds[3], private_level.z_value), locate(bounds[2], bounds[4], private_level.z_value)))
		clear_tile(tile, TRUE)
		yield_work()
	build_ground(zone_id == "all" ? null : zone_id)
	prune_targets()
	resetting = FALSE
	reset_zone_id = null
	return TRUE

/// override_scenario: проверку слота партии уже сделал вызывающий (смена должности, решение админа стенда).
/datum/antag_training_session/proc/restart(program_type, override_scenario = FALSE)
	if(!override_scenario && scenario_role_locked())
		return FALSE
	if(finished || resetting || arena?.resetting || world.time < next_restart_at || !antag_training_program_selectable(program_type))
		return FALSE
	if(!antag_training_role_compatible(program_type, role))
		to_chat(current_body, span_warning("Эта программа не работает с синтетиком. Выберите должность человека или программу «Снаряжение и бой»."))
		return FALSE
	next_restart_at = world.time + ANTAG_TRAINING_RESTART_DELAY
	if(arena.duel?.includes(src))
		arena.duel.finish("Дуэль завершена: участник сменил программу.")
	stop_practice()
	stop_exercise()
	recipe_cache = null
	recipe_cache_size = -1
	resetting = TRUE
	deltimer(recovery_timer)
	recovery_timer = null
	var/mob/previous_body = current_body
	var/datum/mind/previous_mind = avatar_mind
	var/mob/living/carbon/human/previous_avatar = avatar
	UnregisterSignal(previous_body, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING, COMSIG_MOB_GHOSTIZE, COMSIG_MOVABLE_MOVED, COMSIG_MOB_PRE_PLAYER_CHANGE))
	UnregisterSignal(previous_mind, COMSIG_MIND_TRANSFER)
	QDEL_NULL(controls)
	QDEL_NULL(exit_action)
	QDEL_NULL(program)
	program = new program_type
	current_body = null
	if(!create_avatar())
		var/mob/fallback = avatar || avatar_mind?.current
		if(fallback)
			previous_body.transfer_ckey(fallback, FALSE)
		current_body = fallback
		finish()
	else
		previous_body.transfer_ckey(current_body, FALSE)
	qdel(previous_mind)
	discard_body(previous_body)
	if(previous_avatar != previous_body)
		discard_body(previous_avatar)
	resetting = FALSE
	return !finished

/datum/antag_training_arena/proc/prune_targets()
	for(var/mob/living/target as anything in targets.Copy())
		if(QDELETED(target))
			targets -= target
	for(var/datum/mind/soul as anything in target_minds.Copy())
		if(QDELETED(soul) || QDELETED(soul.current))
			target_minds -= soul
			for(var/datum/antag_training_session/member as anything in members)
				var/datum/antagonist/heretic/heretic = IS_HERETIC(member.current_body)
				if(heretic)
					heretic.sacrificed_minds -= soul
			qdel(soul)

/datum/antag_training_arena/proc/spawn_target(armored = FALSE, dead = FALSE)
	return spawn_creature(dead ? "corpse" : armored ? "armored" : "human", "laboratory", FALSE)

/// Ближайшая к center свободная клетка пола внутри bounds, чтобы цели не вставали стопкой.
/datum/antag_training_arena/proc/free_spot(turf/center, list/bounds)
	if(!inside_bounds(center, bounds))
		return null
	for(var/radius in 0 to ANTAG_TRAINING_SPAWN_RADIUS)
		for(var/turf/open/spot in (radius ? orange(radius, center) : list(center)))
			if(max(get_dist(spot, center), 0) == radius && inside_bounds(spot, bounds) && !spot.is_blocked_turf(exclude_mobs = FALSE) && !(locate(/mob/living) in spot))
				return spot
	return null

/datum/antag_training_arena/proc/spawn_creature(template_id, zone_id, active = FALSE, datum/antag_training_session/creator, turf/near)
	var/list/template = GLOB.antag_training_creatures[template_id]
	var/list/zone = zones[zone_id] || hub?.pad_zone(zone_id, creator)
	prune_targets()
	if(!template || !zone || zone_id == "hub" || finished || resetting || length(targets) >= limit_for(ANTAG_TRAINING_TARGET_LIMIT, creator))
		return null
	if(zone_id == "melee" && duel && duel.phase != "invite")
		return null
	var/booked_refusal = booked_zone_refusal(zone_id, creator)
	if(booked_refusal)
		creator.practice_message(booked_refusal)
		return null
	var/turf/location = free_spot(near, zone["bounds"]) || free_spot(zone["target"], zone["bounds"]) || zone["target"]
	var/mob_type = template["type"]
	var/mob/living/target = new mob_type(location)
	if(ishuman(target))
		var/mob/living/carbon/human/human = target
		human.real_name = "Учебная цель [++next_target_id]"
		human.name = human.real_name
		human.mind_initialize()
		human.mind.add_antag_datum(/datum/antagonist/ghost_role/antag_training)
		target_minds += human.mind
		human.equipOutfit(/datum/outfit/antag_training)
		if(template["armored"])
			human.equip_to_slot_or_del(new /obj/item/clothing/suit/armor/vest, ITEM_SLOT_OCLOTHING)
			human.equip_to_slot_or_del(new /obj/item/clothing/head/helmet, ITEM_SLOT_HEAD)
		if(template["dead"])
			human.death()
		if(template["runner"])
			new /datum/antag_training_runner(human, src, zone["bounds"])
	else if(isanimal(target))
		var/mob/living/simple_animal/animal = target
		animal.toggle_ai(active ? AI_ON : AI_OFF)
	if(!claim_target(target, creator, TRUE))
		QDEL_NULL(target.mind)
		qdel(target)
		return null
	return target

/// Ставит созданное ролью (потомство, яйца, оболочки) в общий лимит целей: метит сеансом и снимает с учёта при удалении. FALSE - лимит исчерпан или вещь не на этом полигоне.
/datum/antag_training_arena/proc/claim_target(atom/movable/thing, datum/antag_training_session/owner, silent = FALSE)
	if(QDELETED(thing) || finished)
		return FALSE
	if(thing in targets)
		return TRUE
	thing.register_training_atom()
	if(thing.training_origin?.resolve() != src)
		return FALSE
	if(!has_target_room(1, owner))
		if(!silent && owner)
			to_chat(owner.current_body, span_warning(target_limit_refusal()))
		return FALSE
	if(owner)
		thing.training_owner = WEAKREF(owner)
	if(isliving(thing))
		ADD_TRAIT(thing, TRAIT_NO_MIDROUND_ANTAG, REF(src))
		ADD_TRAIT(thing, TRAIT_EXEMPT_HEALTH_EVENTS, REF(src))
	targets += thing
	RegisterSignal(thing, COMSIG_PARENT_QDELETING, PROC_REF(on_target_deleted))
	return TRUE

/datum/antag_training_arena/proc/has_target_room(count = 1, datum/antag_training_session/session)
	prune_targets()
	return length(targets) + count <= limit_for(ANTAG_TRAINING_TARGET_LIMIT, session)

/datum/antag_training_arena/proc/target_limit_refusal()
	return "На полигоне уже [ANTAG_TRAINING_TARGET_LIMIT] целей - это предел. Удалите лишние в разделе «Цели» пульта или очистите свои объекты."

/datum/antag_training_arena/proc/on_target_deleted(atom/movable/source)
	SIGNAL_HANDLER
	targets -= source

/// Бегущая мишень ходит челноком поперёк сектора и замирает, пока её держат, сковали или сбили с ног.
/datum/antag_training_runner
	var/mob/living/carbon/human/runner
	var/datum/antag_training_arena/arena
	var/list/bounds
	var/heading = NORTH
	var/next_step_at = 0

/datum/antag_training_runner/New(mob/living/carbon/human/target, datum/antag_training_arena/training, list/zone_bounds)
	runner = target
	arena = training
	bounds = zone_bounds
	RegisterSignal(runner, COMSIG_PARENT_QDELETING, PROC_REF(on_runner_deleted))
	START_PROCESSING(SSfastprocess, src)

/datum/antag_training_runner/proc/on_runner_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/antag_training_runner/proc/can_run()
	return !runner.client && runner.stat == CONSCIOUS && (runner.mobility_flags & MOBILITY_MOVE) && (runner.mobility_flags & MOBILITY_STAND) && !runner.resting && !runner.handcuffed && !runner.buckled && !runner.pulledby && !arena.resetting && isturf(runner.loc) && arena.inside_bounds(runner.loc, bounds)

/datum/antag_training_runner/process()
	if(world.time < next_step_at || !can_run())
		return
	next_step_at = world.time + ANTAG_TRAINING_RUNNER_STEP
	for(var/attempt in 1 to 2)
		var/turf/next = get_step(runner, heading)
		if(next && next.y > bounds[3] && next.y < bounds[4])
			runner.set_glide_size(DELAY_TO_GLIDE_SIZE(ANTAG_TRAINING_RUNNER_STEP))
			if(runner.Move(next, heading))
				return
		heading = turn(heading, 180)

/datum/antag_training_runner/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	if(runner)
		UnregisterSignal(runner, COMSIG_PARENT_QDELETING)
	runner = null
	arena = null
	return ..()

/// once_per_tick - для окон пульта: все пульты в одном проходе SStgui видят один и тот же счёт.
/datum/antag_training_arena/proc/prune_supplies(once_per_tick = FALSE)
	if(once_per_tick && last_supply_prune == world.time)
		return
	last_supply_prune = world.time
	for(var/datum/weakref/item_ref as anything in issued_items.Copy())
		if(!item_ref?.resolve())
			issued_items -= item_ref
	supply_count = length(issued_items)
	for(var/datum/weakref/structure_ref as anything in placed_structures.Copy())
		if(!structure_ref?.resolve())
			placed_structures -= structure_ref

/datum/antag_training_arena/proc/issue_item(item_type, turf/destination, amount = 1, datum/antag_training_session/creator)
	prune_supplies()
	if(finished || resetting || !owns_area(get_area(destination)) || supply_count >= limit_for(ANTAG_TRAINING_SUPPLY_LIMIT, creator))
		return null
	var/obj/item
	if(ispath(item_type, /obj/item/stack))
		item = new item_type(destination, amount)
	else
		item = new item_type(destination)
	track_supply(item, creator)
	return item

/// Выдача предмета участнику в руки с общим кулдауном выдачи и сообщениями об отказе.
/datum/antag_training_session/proc/issue_to_hands(item_type, mob/living/user)
	if(world.time < next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return null
	next_supply_at = world.time + 1 SECONDS
	var/obj/item/supply = arena.issue_item(item_type, get_turf(user), 1, src)
	if(!supply)
		to_chat(user, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return null
	user.put_in_hands(supply)
	return supply

/datum/antag_training_arena/proc/track_supply(obj/supply, datum/antag_training_session/creator)
	if(creator)
		for(var/atom/movable/content as anything in supply.GetAllContents())
			content.training_owner = WEAKREF(creator)
	issued_items += WEAKREF(supply)
	supply_count = length(issued_items)

/datum/antag_training_arena/proc/construction_error(turf/destination, datum/antag_training_session/builder)
	if(finished || resetting)
		return "Дождитесь окончания сброса полигона."
	if(supply_count >= limit_for(ANTAG_TRAINING_SUPPLY_LIMIT, builder) || length(placed_structures) >= limit_for(ANTAG_TRAINING_STRUCTURE_LIMIT, builder))
		return "Достигнут лимит объектов. Уберите ненужное или очистите свои объекты."
	var/zone_id = match_zone(destination)
	if(!isfloorturf(destination) || !owns_area(get_area(destination)) || !zone_id || zone_id == "hub")
		return "Встаньте в секторе лицом к свободной клетке пола. В центре и переходах установка недоступна."
	for(var/atom/movable/obstacle in destination)
		if(obstacle.density || isliving(obstacle) || isstructure(obstacle) || ismachinery(obstacle))
			return "Клетка перед вами занята. Повернитесь к свободному месту."
	return null

/datum/antag_training_session/proc/build_structure(structure_id, mob/user)
	var/list/template = GLOB.antag_training_structures[structure_id]
	if(!can_control(user) || !template || world.time < next_supply_at)
		return null
	arena.prune_supplies()
	var/turf/destination = get_step(user, user.dir)
	var/problem = arena.construction_error(destination, src)
	if(problem)
		to_chat(user, span_warning(problem))
		return null
	next_supply_at = world.time + 1 SECONDS
	var/structure_type = template["type"]
	var/obj/placed = new structure_type(destination)
	placed.setDir(user.dir)
	arena.track_supply(placed, src)
	arena.placed_structures += WEAKREF(placed)
	to_chat(user, span_notice("Установлено: [template["name"]]."))
	return placed

/datum/antag_training_session/proc/injure_target(mob/living/target, injury_id)
	var/list/injury = GLOB.antag_training_injuries[injury_id]
	if(!injury || !can_manage_target(target) || !ishuman(target) || target.stat == DEAD || !arena.owns_area(get_area(target)) || arena.resetting || finished)
		return FALSE
	switch(injury["type"])
		if(TOX)
			target.setToxLoss(min(target.getToxLoss() + injury["amount"], target.maxHealth * 2), forced = TRUE)
		if(OXY)
			target.setOxyLoss(min(target.getOxyLoss() + injury["amount"], target.maxHealth * 2), forced = TRUE)
		else
			target.apply_damage(injury["amount"], injury["type"], BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
	return TRUE

/datum/antag_training_session/proc/can_condition_target(mob/living/carbon/human/target)
	if(!can_manage_target(target) || !ishuman(target) || target.stat == DEAD || !arena.owns_area(get_area(target)) || arena.resetting || finished)
		return FALSE
	return !exercise_holds_target(target)

/datum/antag_training_session/proc/condition_target(mob/living/carbon/human/target, condition_id)
	if(!(condition_id in GLOB.antag_training_conditions) || !can_condition_target(target))
		return FALSE
	switch(condition_id)
		if("knockdown")
			target.Knockdown(ANTAG_TRAINING_KNOCKDOWN, ignore_canstun = TRUE)
		if("exhaust")
			target.adjustStaminaLoss(STAMINA_CRIT, forced = TRUE)
		if("cuffs")
			if(target.handcuffed)
				QDEL_NULL(target.handcuffed)
			else
				target.handcuffed = new /obj/item/restraints/handcuffs(target)
			target.update_handcuffed()
	return TRUE

/// Состояния цели, от которых зависят захваты и обряды.
/proc/antag_training_target_states(mob/living/target)
	var/list/states = list()
	if(!ishuman(target) || target.stat == DEAD)
		return states
	var/mob/living/carbon/human/human = target
	if(human.IsKnockdown() || human.IsParalyzed())
		states += "сбита с ног"
	if(IS_STAMCRIT(human))
		states += "обессилена"
	if(human.handcuffed)
		states += "в наручниках"
	if(human.stat != CONSCIOUS)
		states += "без сознания"
	return states

/datum/antag_training_session/proc/issue_equipment(equipment_id, mob/user)
	var/list/equipment = GLOB.antag_training_equipment[equipment_id]
	if(!can_control(user) || !equipment || world.time < next_supply_at)
		return FALSE
	next_supply_at = world.time + 1 SECONDS
	return !!arena.issue_item(equipment["type"], get_turf(user), equipment["amount"] || 1, src)

/obj/structure/antag_training_barrier
	name = "training barrier"
	desc = "Граница сектора пропускает участников тренировки. Цели и снаряды остаются внутри."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield1"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF
	var/datum/antag_training_arena/arena

/obj/structure/antag_training_barrier/Initialize(mapload, datum/antag_training_arena/training)
	. = ..()
	arena = training

/obj/structure/antag_training_barrier/CanPass(atom/movable/mover, turf/target)
	for(var/datum/antag_training_session/member as anything in arena?.members)
		if(mover == member.current_body)
			return TRUE
	return FALSE

/obj/structure/antag_training_barrier/Destroy()
	arena = null
	return ..()

/datum/antag_training_program/free
	name = "Снаряжение и бой"
	desc = "Оружие, броня, медицина, химия, строительство и бой с противниками. Можно взять любую должность станции: её снаряжение, ID с доступом и гарнитуру отдела, которая работает между участниками полигона. Должностям службы безопасности открыты упражнения «Задержание» и «Обыск и конфискация» в станционном макете."
	icon = "dumbbell"
	color = "teal"
	learn = "Оружие ближнего боя и стрельба по мишеням|Броня, наручники и захват цели|Первая помощь, лечение пациента и реанимация|Бой с противниками на арене|Задержание и обыск для службы безопасности"
	difficulty = 1
	order = 1

/datum/antag_training_program/free/setup(datum/antag_training_session/session)
	return TRUE


/datum/antag_training_arena/proc/participant_minds()
	var/list/souls = list()
	for(var/datum/antag_training_session/member as anything in members)
		if(!QDELETED(member.avatar_mind))
			souls += member.avatar_mind
	return souls

/datum/antag_training_arena/proc/match_zone(atom/target)
	var/turf/tile = get_turf(target)
	for(var/zone_id in zones)
		if(inside_bounds(tile, zones[zone_id]["bounds"]))
			return zone_id
	// Вестибюль хаба - та же безопасная зона, что центр.
	if(hub?.lobby_turf(tile))
		return "hub"
	return "corridor"

/datum/antag_training_arena/proc/request_reset(datum/antag_training_session/requester, zone_id)
	if(!(requester in members) || (!zones[zone_id] && zone_id != "all") || zone_id == "hub" || !ready || finished || resetting || pending_reset_zone || world.time < next_reset_request_at || world.time < next_reset_at)
		return FALSE
	var/refusal = reset_refusal(requester, zone_id)
	if(refusal)
		requester.practice_message(refusal)
		return FALSE
	next_reset_request_at = world.time + 5 SECONDS
	pending_reset_zone = zone_id
	for(var/datum/antag_training_session/member as anything in reset_voters(zone_id))
		reset_votes[member] = member == requester
		to_chat(member.current_body, span_notice("Запрошен сброс сектора «[zone_id == "all" ? "Весь полигон" : zones[zone_id]["name"]]». Подтвердите или отмените его в пульте полигона. Нужно согласие [reset_voters(zone_id) == members ? "всех участников" : "всей группы"] за 45 секунд."))
	reset_vote_deadline = world.time + ANTAG_TRAINING_VOTE_TIME
	reset_vote_timer = addtimer(CALLBACK(src, PROC_REF(cancel_reset)), ANTAG_TRAINING_VOTE_TIME, TIMER_STOPPABLE)
	check_reset_votes()
	return TRUE

/datum/antag_training_arena/proc/approve_reset(datum/antag_training_session/member)
	if(!pending_reset_zone || !(member in reset_votes) || world.time >= reset_vote_deadline)
		return FALSE
	reset_votes[member] = TRUE
	check_reset_votes()
	return TRUE

/datum/antag_training_arena/proc/cancel_reset()
	deltimer(reset_vote_timer)
	reset_vote_timer = null
	pending_reset_zone = null
	reset_vote_deadline = 0
	reset_votes.Cut()

/datum/antag_training_arena/proc/member_left(datum/antag_training_session/member)
	forget_squad_member(member)
	reset_votes -= member
	if(!length(members))
		cancel_reset()
	else
		check_reset_votes()

/// Состав голосующих за идущий сброс сменился: новичок голосует, ушедший не держит.
/datum/antag_training_arena/proc/sync_reset_votes()
	if(!pending_reset_zone)
		return
	var/list/voters = reset_voters(pending_reset_zone)
	for(var/datum/antag_training_session/voter as anything in reset_votes.Copy())
		if(!(voter in voters))
			reset_votes -= voter
	for(var/datum/antag_training_session/voter as anything in voters)
		if(!(voter in reset_votes))
			reset_votes[voter] = FALSE
	check_reset_votes()

/datum/antag_training_arena/proc/check_reset_votes()
	if(!pending_reset_zone || finished || world.time >= reset_vote_deadline)
		return
	var/list/voters = reset_voters(pending_reset_zone)
	// Голосовать некому (группа брони разошлась): согласия нет, сброс отменяется.
	if(!length(voters))
		cancel_reset()
		return
	for(var/datum/antag_training_session/member as anything in voters)
		if(!reset_votes[member])
			return
	var/zone_id = pending_reset_zone
	cancel_reset()
	INVOKE_ASYNC(src, PROC_REF(reset_zone), zone_id)

/// Цель идущего упражнения пульт не сбивает с ног, не сковывает и не лечит: иначе он выполнит упражнение за участника.
/datum/antag_training_session/proc/exercise_holds_target(mob/living/target)
	for(var/datum/antag_training_session/member as anything in arena.members)
		var/datum/antag_training_exercise_run/run = member.exercise_run
		if(run && !run.ended && (target in run.props))
			practice_message("[target.name] - цель упражнения «[run.exercise.name]», пульт её не сбивает с ног, не сковывает и не лечит. Прекратите упражнение, чтобы управлять ею из пульта.")
			return TRUE
	return FALSE

/// Тело или оставленная кукла участника полигона, а не учебная цель.
/proc/antag_training_member_body(mob/living/body)
	var/datum/antag_training_arena/arena = body?.training_origin?.resolve()
	if(!arena)
		return FALSE
	if(arena.session_of(body))
		return TRUE
	for(var/datum/antag_training_session/member as anything in arena.members)
		if(member.avatar == body)
			return TRUE
	return FALSE

/datum/antag_training_session/proc/can_manage_target(mob/living/target)
	if(QDELETED(target) || !(target in arena.targets) || arena.session_of(target))
		return FALSE
	var/datum/antag_training_session/creator = target.training_owner?.resolve()
	return !creator || same_squad(creator)

/datum/antag_training_session/proc/clear_personal_entities()
	if(finished || cleaning_personal || arena.finished || arena.resetting)
		return FALSE
	cleaning_personal = TRUE
	stop_practice()
	stop_exercise()
	. = arena.cleanup_owner(WEAKREF(src), src)
	cleaning_personal = FALSE

/datum/antag_training_arena/proc/cleanup_owner(datum/weakref/owner_ref, datum/antag_training_session/active_owner)
	if(!owner_ref)
		return FALSE
	for(var/datum/weakref/entity_ref as anything in created_atoms.Copy())
		yield_work()
		if(finished || (active_owner && QDELETED(active_owner)))
			return FALSE
		var/atom/movable/entity = entity_ref?.resolve()
		if(!entity || entity.training_owner != owner_ref)
			continue
		var/protected = FALSE
		for(var/datum/antag_training_session/member as anything in members)
			if(entity.contains_atom(member.current_body) || member.current_body?.buckled == entity || (member != active_owner && member.current_body.contains_atom(entity)))
				if(!active_owner)
					entity.training_owner = WEAKREF(member)
				protected = TRUE
				break
		if(protected)
			continue
		for(var/atom/movable/content as anything in entity.GetAllContents())
			var/datum/antag_training_session/creator = content.training_owner?.resolve()
			if(creator && content.training_owner != owner_ref)
				if(!active_owner)
					entity.training_owner = content.training_owner
				protected = TRUE
				break
		if(protected)
			continue
		if(isliving(entity))
			var/mob/living/body = entity
			QDEL_NULL(body.mind)
		qdel(entity)
	prune_targets()
	prune_supplies()
	return TRUE
