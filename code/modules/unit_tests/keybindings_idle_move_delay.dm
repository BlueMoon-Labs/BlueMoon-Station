/// Regression test for a double-step bug introduced by the SSinput early-out.
///
/// /client/Move() used to be called on every tick for every client, even with no
/// keys held. Its prologue runs before the `!direction` bail-out:
///
///     if(world.time < move_delay)
///         return FALSE
///     else
///         next_move_dir_add = next_move_dir_sub = NONE
///     var/old_move_delay = move_delay
///     move_delay = world.time + world.tick_lag
///     if(!n || !direction || !mob?.loc)
///         return FALSE
///
/// so standing still kept move_delay pinned just ahead of world.time. Skipping the
/// call for an idle client left move_delay wherever the last real step put it —
/// in the past. /client/Move()'s catch-up buffer then reused that stale value as
/// its baseline:
///
///     if(old_move_delay + (add_delay*MOVEMENT_DELAY_BUFFER_DELTA) + MOVEMENT_DELAY_BUFFER > world.time)
///         move_delay = old_move_delay
///
/// With add_delay around 2ds the buffer window is ~3.25ds, so stopping and
/// pressing again within about half a second left move_delay + add_delay already
/// in the past — and the next tick of the same keypress took a second step for
/// free. One press, two tiles.
///
/// The idle path now keeps the baseline current without walking the Move() chain.

/datum/unit_test/idle_input_keeps_move_delay_current

/datum/unit_test/idle_input_keeps_move_delay_current/Run()
	var/now = 1000
	var/tick_lag = 0.5

	// The bug: a baseline left behind world.time hands out a free step.
	var/refreshed = keybindings_idle_move_delay(940, now, tick_lag)
	TEST_ASSERT(refreshed > now, "An idle tick must not leave move_delay in the past (got [refreshed] against now=[now])")
	TEST_ASSERT_EQUAL(refreshed, now + tick_lag, "An idle tick must re-pin move_delay one tick ahead, exactly as /client/Move() did")

	// A cooldown that is still running belongs to a real move and must be left be —
	// /client/Move() returns before touching move_delay in that case.
	TEST_ASSERT_EQUAL(keybindings_idle_move_delay(now + 3, now, tick_lag), now + 3, "An idle tick must not shorten a cooldown that is still running")

	// Expired exactly now counts as expired, matching `world.time < move_delay`.
	TEST_ASSERT_EQUAL(keybindings_idle_move_delay(now, now, tick_lag), now + tick_lag, "A cooldown that expired exactly now must be re-pinned")

	// A fresh client starts at 0, which is behind any real world.time.
	TEST_ASSERT_EQUAL(keybindings_idle_move_delay(0, now, tick_lag), now + tick_lag, "A never-moved client must also get a current baseline")
