/*ALL DEFINES RELATED TO CONSTRUCTION, CONSTRUCTING THINGS, OR CONSTRUCTED OBJECTS GO HERE*/

//Defines for construction states

//girder construction states
#define GIRDER_NORMAL 0
#define GIRDER_REINF_STRUTS 1
#define GIRDER_REINF 2
#define GIRDER_DISPLACED 3
#define GIRDER_DISASSEMBLED 4

//rwall construction states
#define INTACT 0
#define SUPPORT_LINES 1
#define COVER 2
#define CUT_COVER 3
#define ANCHOR_BOLTS 4
#define SUPPORT_RODS 5
#define SHEATH 6

//window construction states
#define WINDOW_OUT_OF_FRAME 0
#define WINDOW_IN_FRAME 1
#define WINDOW_SCREWED_TO_FRAME 2

//reinforced plasma window construction states
#define PRWINDOW_FRAME_BOLTED 3
#define PRWINDOW_BARS_CUT 4
#define PRWINDOW_POPPED 5
#define PRWINDOW_BOLTS_OUT 6
#define PRWINDOW_BOLTS_HEATED 7
#define PRWINDOW_SECURE 8

//airlock assembly construction states
#define AIRLOCK_ASSEMBLY_NEEDS_WIRES 0
#define AIRLOCK_ASSEMBLY_NEEDS_ELECTRONICS 1
#define AIRLOCK_ASSEMBLY_NEEDS_SCREWDRIVER 2

//default_unfasten_wrench() return defines
#define CANT_UNFASTEN 0
#define FAILED_UNFASTEN 1
#define SUCCESSFUL_UNFASTEN 2

//ai core defines
#define EMPTY_CORE 0
#define CIRCUIT_CORE 1
#define SCREWED_CORE 2
#define CABLED_CORE 3
#define GLASS_CORE 4
#define AI_READY_CORE 5

//Construction defines for the pinion airlock
#define GEAR_SECURE 1
#define GEAR_LOOSE 2

//floodlights because apparently we use defines now
#define FLOODLIGHT_NEEDS_WIRES 0
#define FLOODLIGHT_NEEDS_LIGHTS 1
#define FLOODLIGHT_NEEDS_SECURING 2
#define FLOODLIGHT_NEEDS_WRENCHING 3

//other construction-related things

//windows affected by Nar'Sie turn this color.
#define NARSIE_WINDOW_COLOUR "#7D1919"

//let's just pretend fulltile windows being children of border windows is fine
#define FULLTILE_WINDOW_DIR NORTHEAST

//The maximum size of a stack object.
#define MAX_STACK_SIZE 50
//maximum amount of cable in a coil
#define MAXCOIL 30

//tablecrafting defines
#define CAT_NONE	""
#define CAT_WEAPONRY	"Оружие"
#define CAT_WEAPON	"Дальнобойное"
#define CAT_MELEE	"Ближний бой"
#define CAT_OTHER	"Прочее"
#define CAT_AMMO	"Боеприпасы"
#define CAT_PARTS	"Части оружия"
#define CAT_ROBOT	"Роботы"
#define CAT_MISCELLANEOUS	"Разное"
#define CAT_TOOL	"Инструменты"
#define CAT_FURNITURE	"Мебель"
#define CAT_PRIMAL  "Племенное"
#define CAT_CLOTHING	"Одежда"
#define CAT_FOOD	"Еда"
#define CAT_BREAD	"Хлеб"
#define CAT_BURGER	"Бургеры"
#define CAT_CAKE	"Торты"
#define CAT_DONUT	"Пончики"
#define CAT_EGG	"Из яиц"
#define CAT_MEAT	"Мясо"
#define CAT_MEXICAN	"Мексиканское"
#define CAT_MISCFOOD	"Разная еда"
#define CAT_PASTRY	"Выпечка"
#define CAT_PIE	"Пироги и сладости"
#define CAT_PIZZA	"Пицца"
#define CAT_SALAD	"Салаты"
#define CAT_SEAFOOD    "Морепродукты"
#define CAT_SANDWICH	"Сэндвичи"
#define CAT_SOUP	"Супы"
#define CAT_SPAGHETTI	"Спагетти"
#define CAT_ICE	"Заморозка"
#define CAT_EAST "Восточная еда"
#define CAT_DRINK "Напитки"
#define CAT_ATMOSPHERIC "Атмосфера"
#define CAT_ATMOSPHERICS "Газовые кристаллы"
#define CAT_STRUCTURES "Структуры"
#define CAT_TILES "Плитка"
#define CAT_WINDOWS "Окна"
#define CAT_DOORS "Двери"
#define CAT_EQUIPMENT "Снаряжение"
#define CAT_CONTAINERS "Контейнеры"
#define CAT_ENTERTAINMENT "Развлечения"
#define CAT_GARDENING "Садоводство"
#define CAT_DECOR "Декор"
#define CAT_CHEMISTRY "Химия"

#define RCD_FLOORWALL 1
#define RCD_AIRLOCK 2
#define RCD_DECONSTRUCT 3
#define RCD_WINDOWGRILLE 4
#define RCD_MACHINE 8
#define RCD_COMPUTER 16

#define RCD_UPGRADE_FRAMES 1
#define RCD_UPGRADE_SIMPLE_CIRCUITS 2

//Electrochromatic window defines.
#define NOT_ELECTROCHROMATIC		0
#define ELECTROCHROMATIC_OFF		1
#define ELECTROCHROMATIC_DIMMED		2

//blast door (de)construction states
#define BLASTDOOR_NEEDS_WIRES 0
#define BLASTDOOR_NEEDS_ELECTRONICS 1
#define BLASTDOOR_FINISHED 2
