//WHITE-STEEL PORT - Агрегатор модуля
//Порядок имеет значение для логики компиляции; типы разрешаются глобально.

// ===== Defines =====
#include "_defines\access.dm"
#include "_defines\orbit_defines.dm"
#include "_defines\sound.dm"

// ===== Глобальные списки =====
#include "_globalvars\_globalvars.dm"

// ===== Хелперы совместимости =====
#include "_support\helpers.dm"

// ===== Атмосферная обвязка z-уровней =====
#include "_atmos\air_extension.dm"

// ===== Поддержка контента =====
#include "_support\radio_stuff.dm"
#include "_support\circuits.dm"
#include "_support\tactical.dm"
#include "_support\duffel.dm"
#include "_support\mre.dm"
#include "_support\feline_chem.dm"
#include "_support\ruin_stubs.dm"

// ===== Подсистемы =====
#include "_subsystem\orbits.dm"
#include "_subsystem\zclear.dm"

// ===== Система орбитальной карты =====
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

// ===== Генератор руин и объективы =====
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
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_objects.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_generator.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\mapping.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\asteroid_generator.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\exoplanets\exoplanet_generator.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\exoplanets\biomes\_biome.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\exoplanets\biomes\lavaland.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\exoplanets\biomes\lush.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\_generator_settings.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\generator_abandoned.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\generator_blob.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\generator_city.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\generator_netherworld.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\generator_ratvar.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\generator_inteq.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\generator_settings\generator_xeno.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_events\_ruin_event.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_events\asteriod_station.dm"
#include "inner\super_cruise\orbital_poi_generator\ruin_generator\ruin_events\meteor_storm.dm"

// ===== Исследования и основной контент =====
#include "inner\discovery_research\discoverable_component.dm"
#include "inner\discovery_research\discovery_scanner.dm"
#include "exploration\exploration_explosives.dm"
#include "exploration\research_locator.dm"
#include "exploration\exploration_shuttle.dm"

// ===== Рейнджеры =====
#include "rangers\proton_cutter.dm"
