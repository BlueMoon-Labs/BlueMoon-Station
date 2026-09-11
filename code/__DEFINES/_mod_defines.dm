/// Default value for the max_complexity var on MODsuits
#define DEFAULT_MAX_COMPLEXITY 18
#define STATION_COMBAT_MAX_COMPLEXITY 13
#define COMMAND_MAX_COMPLEXITY 23
#define ANTAG_MAX_COMPLEXITY 23
#define CENTCOMM_MAX_COMPLEXITY 28
#define DEBUG_COMPLEXITY 100

/// Default cell drain per process on MODsuits
#define DEFAULT_CHARGE_DRAIN 2
#define CIVILIAN_LOW_CHARGE_DRAIN 1
#define VERY_HIGHT_CHARGE_DRAIN 6
#define DEBUG_LOW_CHARGE_DRAIN 0.5
/// Default time for a part to seal
#define MOD_ACTIVATION_STEP_TIME (0.9 SECONDS)

/// Passive module, just acts when put in naturally.
#define MODULE_PASSIVE 0
/// Usable module, does something when you press a button.
#define MODULE_USABLE 1
/// Toggle module, you turn it on/off and it does stuff.
#define MODULE_TOGGLE 2
/// Actively usable module, you may only have one selected at a time.
#define MODULE_ACTIVE 3
//Почти как пассивный модуль, но их не может быть больше чем max_armor_module_count
#define MODULE_ARMOR  4

//Defines used by the theme for clothing flags and similar
#define CONTROL_LAYER "control_layer"
#define HELMET_FLAGS "helmet_flags"
#define CHESTPLATE_FLAGS "chestplate_flags"
#define GAUNTLETS_FLAGS "gauntlets_flags"
#define BOOTS_FLAGS "boots_flags"

#define UNSEALED_LAYER "unsealed_layer"
#define UNSEALED_CLOTHING "unsealed_clothing"
#define SEALED_CLOTHING "sealed_clothing"
#define UNSEALED_INVISIBILITY "unsealed_invisibility"
#define SEALED_INVISIBILITY "sealed_invisibility"
#define UNSEALED_COVER "unsealed_cover"
#define SEALED_COVER "sealed_cover"
#define CAN_OVERSLOT "can_overslot"

//Defines used to override MOD clothing's icon and worn icon files in the skin.
#define MOD_ICON_OVERRIDE "mod_icon_override"
#define MOD_WORN_ICON_OVERRIDE "mod_worn_icon_override"

/// Global list of all /datum/mod_theme
GLOBAL_LIST_INIT(mod_themes, setup_mod_themes())

#define MOD_PART_HEAD		1
#define MOD_PART_CHEST		2
#define MOD_PART_GLOVES		3
#define MOD_PART_FEET		4
// #define MOD_PART_CORE		5
#define MOD_PART_CELL 		5

#define MODPART_DEPLOYED  "deployed"
#define MODPART_CONSEALED "consealed"

#define MOD_HELMET mod_parts[MOD_PART_HEAD]
#define MOD_CHESTPLATE mod_parts[MOD_PART_CHEST]
#define MOD_GLOVES mod_parts[MOD_PART_GLOVES]
#define MOD_BOOTS mod_parts[MOD_PART_FEET]
// #define MOD_CORE   mod_parts[MOD_PART_CORE]
#define MOD_CELL mod_parts[MOD_PART_CELL]

//ЕМП
#define MOD_EMP_CHARGE_LOOSE_MODIFICATOR 8
#define MOD_EMP_SEVERITY_MAX 100
#define MOD_CELL_BLOOW_UP_CHANCE 5

//Модули щитов
#define MOD_ANTAG_SHIELD_CELL_DRAIN_MODIFICATOR 20
#define MOD_ERT_SHIELD_CELL_DRAIN_MODIFICATOR 25
#define MOD_DEFAULT_SHIELD_CELL_DRAIN_MODIFICATOR 40

//Минимальные заряды батареи для модулей
#define MOD_MINIMUM_CELL_CHARGE_SHIELD 50
#define MOD_MINIMUM_CELL_CHARGE_SHIELD_ERT 30
#define MOD_MINIMUM_CELL_CHARGE_SHIELD_ANTAG 25

#define MOD_ACTIVE      (1<<0)
#define MOD_ACTIVATING  (1<<1)
#define MOD_MALFUNCTION (1<<2)
#define MOD_OPEN        (1<<3)
#define MOD_WELDED		(1<<4)
#define MOD_DNA_LOCKED	(1<<5)

#define MOD_WELD_FUEL_COST 5
#define MOD_WELD_TIME 5 SECONDS

#define MOD_STANDART_COLOR          rgb(26, 209, 255, 255)
#define MOD_COMMAND_COLOR           rgb(26, 118, 255, 255)
#define MOD_MEDBAY_COLOR            rgb(26, 255, 179, 255)
#define MOD_CARGO_COLOR             rgb(255, 118, 26, 255)
#define MOD_CARGO_BLUE              rgb(26, 209, 255, 255)
#define MOD_SEC_COLOR               rgb(255, 26, 26, 255)
#define MOD_RESEARCH_COLOR 		    rgb(133, 26, 255, 255)

#define MOD_LUSTWISH_COLOR 			rgb(255, 102, 204)

#define MOD_SYNDICATE_COLOR         rgb(255, 60, 26, 255)
#define MOD_INTEQ_COLOR             rgb(255, 129, 26, 255)
#define MOD_NINJA_COLOR 			rgb(102, 255, 102)
#define MOD_MAGE_FEDERATION_COLOR   rgb(134, 60, 243)

//для трейта QUICK_BUILD, который даётся специальными перчатками, а так же модулем.
#define QUIICK_BUILD_SPEED 0.25 //там время умножается на это число. Чем меньше - тем меньше. Но лучше ниже 0.5 не делать.
