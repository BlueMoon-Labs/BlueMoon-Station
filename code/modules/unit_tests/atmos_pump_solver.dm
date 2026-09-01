// ===== Exact pressure solver for pumps (tg gas_pressure_calculate port) =====
//
// The legacy pump formula (pressure_delta * V_out / (T_in * R)) ignores that
// the transferred gas changes the output's temperature. With a hot input and a
// cold output it badly overshoots the target, so the pump chased the setpoint
// for many cycles, rewaking itself and the pipenet every time. The solver
// treats moles and temperature of the merged output as coupled unknowns
// (quadratic in n) and lands the target in ONE step.

#define PUMP_SOLVER_TARGET_KPA 300

/datum/unit_test/atmos_pump_solver/Run()
	// --- Hot input, cold output: the case the legacy formula gets wrong ---
	var/datum/gas_mixture/input_hot = new
	input_hot.set_volume(1000)
	input_hot.set_moles(GAS_N2, 500)
	input_hot.set_temperature(600)

	var/datum/gas_mixture/output_cold = new
	output_cold.set_volume(200)
	output_cold.set_moles(GAS_O2, 5)
	output_cold.set_temperature(100)

	var/moles_before = input_hot.total_moles() + output_cold.total_moles()
	var/energy_before = input_hot.thermal_energy() + output_cold.thermal_energy()

	// Legacy estimate, for the accuracy comparison
	var/legacy_moles = (PUMP_SOLVER_TARGET_KPA - output_cold.return_pressure()) * output_cold.return_volume() / (input_hot.return_temperature() * R_IDEAL_GAS_EQUATION)
	var/datum/gas_mixture/legacy_input = input_hot.copy()
	var/datum/gas_mixture/legacy_output = output_cold.copy()
	legacy_input.transfer_to(legacy_output, legacy_moles)
	var/legacy_error = abs(legacy_output.return_pressure() - PUMP_SOLVER_TARGET_KPA)

	// Solver
	var/solved_moles = input_hot.gas_pressure_calculate(output_cold, PUMP_SOLVER_TARGET_KPA)
	TEST_ASSERT(solved_moles > 0, "Solver must return a positive transfer for a reachable target")
	input_hot.transfer_to(output_cold, solved_moles)
	var/solver_error = abs(output_cold.return_pressure() - PUMP_SOLVER_TARGET_KPA)

	TEST_ASSERT(solver_error < 1, "Solver must land within 1 kPa of the target in one step (missed by [solver_error] kPa)")
	TEST_ASSERT(solver_error < legacy_error, "Solver must beat the legacy formula on a hot->cold transfer (solver [solver_error] vs legacy [legacy_error] kPa)")
	TEST_ASSERT(legacy_error > 30, "Fixture sanity: legacy formula should miss this case badly (got [legacy_error] kPa error)")

	// Conservation
	var/moles_after = input_hot.total_moles() + output_cold.total_moles()
	var/energy_after = input_hot.thermal_energy() + output_cold.thermal_energy()
	TEST_ASSERT(abs(moles_before - moles_after) < 0.01, "Solver transfer must conserve moles ([moles_before] -> [moles_after])")
	TEST_ASSERT(abs(energy_before - energy_after) < energy_before * 0.001, "Solver transfer must conserve thermal energy ([energy_before] -> [energy_after])")

	// --- Equal temperatures: cheap path must also land the target ---
	var/datum/gas_mixture/input_warm = new
	input_warm.set_volume(1000)
	input_warm.set_moles(GAS_N2, 200)
	input_warm.set_temperature(T20C)

	var/datum/gas_mixture/output_warm = new
	output_warm.set_volume(200)
	output_warm.set_moles(GAS_O2, 2)
	output_warm.set_temperature(T20C)

	var/warm_moles = input_warm.gas_pressure_calculate(output_warm, PUMP_SOLVER_TARGET_KPA, ignore_temperature = TRUE)
	TEST_ASSERT(warm_moles > 0, "Cheap path must return a positive transfer")
	input_warm.transfer_to(output_warm, warm_moles)
	var/warm_error = abs(output_warm.return_pressure() - PUMP_SOLVER_TARGET_KPA)
	TEST_ASSERT(warm_error < 1, "Cheap path must land within 1 kPa at equal temperatures (missed by [warm_error] kPa)")

	// --- Already at/above target: no transfer ---
	TEST_ASSERT(!output_warm.gas_pressure_calculate(input_warm, 1), "Target below current pressure must return FALSE")

	// --- Cold input into hot output (reverse skew) must also converge ---
	var/datum/gas_mixture/input_cold = new
	input_cold.set_volume(1000)
	input_cold.set_moles(GAS_N2, 800)
	input_cold.set_temperature(80)

	var/datum/gas_mixture/output_hot = new
	output_hot.set_volume(200)
	output_hot.set_moles(GAS_O2, 3)
	output_hot.set_temperature(900)

	var/reverse_moles = input_cold.gas_pressure_calculate(output_hot, PUMP_SOLVER_TARGET_KPA)
	TEST_ASSERT(reverse_moles > 0, "Reverse-skew solve must return a positive transfer")
	input_cold.transfer_to(output_hot, reverse_moles)
	var/reverse_error = abs(output_hot.return_pressure() - PUMP_SOLVER_TARGET_KPA)
	TEST_ASSERT(reverse_error < 1, "Reverse-skew solve must land within 1 kPa (missed by [reverse_error] kPa)")

#undef PUMP_SOLVER_TARGET_KPA
