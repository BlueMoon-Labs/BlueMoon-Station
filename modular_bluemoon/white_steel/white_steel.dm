//WHITE-STEEL PORT - Агрегатор модуля.
//ПР1: экипировка экспедиторов (снаряжение, контрабанда, вендинг-награды).
//Порядок включений повторяет upstream (modular_bluemoon/white_steel).

#include "_support\tactical.dm"
#include "_support\mre.dm"
#include "_support\feline_chem.dm"

#include "exploration\exploration_explosives.dm"

#include "rangers\proton_cutter.dm"

//ПР2: шаттл экспедиторов (supercruise, орбитальная карта, bg, таксирование).
//Порядок включений повторяет upstream (modular_bluemoon/white_steel).
//ВНИМАНИЕ: при мерже с ПР1 объединить include-блоки обоих лоадеров.

#include "_defines\orbit_defines.dm"
#include "_defines\sound.dm"

#include "_globalvars\_globalvars.dm"

#include "_support\helpers.dm"
#include "_atmos\air_extension.dm"
#include "_support\radio_stuff.dm"
#include "_support\circuits.dm"

#include "_subsystem\orbits.dm"
#include "_subsystem\zclear.dm"

#include "inner\super_cruise\orbital_map_components\orbital_vector.dm"
#include "inner\super_cruise\orbital_map_components\orbital_object.dm"
#include "inner\super_cruise\orbital_map_components\orbital_map.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\z_linked.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\star.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\space_station.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\shuttle.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\habitable.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\lavaland.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\meteor.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\phobos.dm"
#include "inner\super_cruise\orbital_map_components\orbital_objects\beacon.dm"

#include "inner\super_cruise\interface\orbital_map_interface.dm"
#include "inner\super_cruise\shuttle_supercruise.dm"
#include "inner\super_cruise\shuttle_components\shuttle_console.dm"
#include "inner\super_cruise\shuttle_components\shuttle_docking.dm"
#include "inner\super_cruise\bluespace_beacon\bluespace_beacon.dm"

#include "inner\super_cruise\orbital_poi_generator\_orbital_objective.dm"
#include "inner\super_cruise\orbital_poi_generator\objective_types\alien_artifact.dm"
#include "inner\super_cruise\orbital_poi_generator\objective_types\nuke_ruin.dm"
#include "inner\super_cruise\orbital_poi_generator\objective_types\recover_blackbox.dm"
#include "inner\super_cruise\orbital_poi_generator\objective_types\vip_extraction.dm"
#include "inner\super_cruise\orbital_poi_generator\objective_types\headhunt.dm"
#include "inner\super_cruise\orbital_poi_generator\objective_computer.dm"
#include "inner\super_cruise\orbital_poi_generator\loot\alien_artifact.dm"
#include "inner\super_cruise\orbital_poi_generator\loot\artifact_defenses.dm"
#include "inner\super_cruise\orbital_poi_generator\loot\research_disks.dm"

#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_part_template.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_part_loader.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_part_types.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_generator.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\mapping.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\asteroid_generator.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\_generator_settings.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_events\_ruin_event.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_events\asteriod_station.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_events\meteor_storm.dm"

#include "inner\discovery_research\discoverable_component.dm"
#include "inner\discovery_research\discovery_scanner.dm"

#include "exploration\research_locator.dm"
#include "exploration\exploration_shuttle.dm"
