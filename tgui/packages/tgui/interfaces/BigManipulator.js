import { useBackend } from '../backend';
import { Box, Button, NoticeBox, NumberInput, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

const TASK_TYPE_LABELS = {
  pickup: 'Pickup',
  drop: 'Drop',
  throw: 'Throw',
  wait: 'Wait',
};

const ROWS = [
  [
    { key: 'northwest', icon: 'arrow-up', iconRotation: -45, button: 1 },
    { key: 'north', icon: 'arrow-up', iconRotation: 0, button: 2 },
    { key: 'northeast', icon: 'arrow-up', iconRotation: 45, button: 3 },
  ],
  [
    { key: 'west', icon: 'arrow-left', iconRotation: 0, button: 4 },
    null,
    { key: 'east', icon: 'arrow-right', iconRotation: 0, button: 6 },
  ],
  [
    { key: 'southwest', icon: 'arrow-down', iconRotation: 45, button: 7 },
    { key: 'south', icon: 'arrow-down', iconRotation: 0, button: 8 },
    { key: 'southeast', icon: 'arrow-down', iconRotation: -45, button: 9 },
  ],
];

export const BigManipulator = (props) => {
  const { act, data } = useBackend();
  const {
    active,
    stopping,
    manipulator_position,
    tasking_strategy,
    disk_inserted,
    disk_read_only,
    disk_task_count = 0,
    tasks_data = [],
  } = data;

  return (
    <Window width={540} height={700} resizable>
      <Window.Content scrollable>
        {(!!stopping && (
          <NoticeBox>Stopping in progress...</NoticeBox>
        )) || null}
        <Section
          title="Status"
          buttons={
            <>
              <Button
                icon="power-off"
                content={active ? 'Stop' : 'Start'}
                color={active ? 'bad' : 'good'}
                disabled={!!stopping}
                onClick={() => act('run_cycle')}
              />
              <Button
                icon="eject"
                tooltip="Drop whatever the claw is holding right now"
                onClick={() => act('drop_held_atom')}
              >
                Drop held
              </Button>
            </>
          }
        >
          <Box mb={1}>
            Position: {manipulator_position} | Strategy:{' '}
            <Button
              inline
              compact
              content={tasking_strategy}
              onClick={() =>
                act('cycle_tasking_strategy', {
                  new_strategy:
                    tasking_strategy === 'Sequential'
                      ? 'Strict order'
                      : 'Sequential',
                })
              }
            />
            <Button
              inline
              compact
              icon="rotate-left"
              tooltip="Restart task iteration from the first task"
              onClick={() => act('reset_tasking_index')}
            >
              Reset index
            </Button>
          </Box>
        </Section>

        <Section title="Create task">
          <Stack wrap>
            <Button
              icon="hand-paper"
              onClick={() => act('create_task', { task_type: 'pickup' })}
            >
              Pickup
            </Button>
            <Button
              icon="box-open"
              onClick={() => act('create_task', { task_type: 'drop' })}
            >
              Drop
            </Button>
            <Button
              icon="paper-plane"
              onClick={() => act('create_task', { task_type: 'throw' })}
            >
              Throw
            </Button>
            <Button
              icon="clock"
              onClick={() => act('create_task', { task_type: 'wait' })}
            >
              Wait
            </Button>
          </Stack>
          <Box mt={1} color="label" fontSize="12px">
            Cargo tasks are placed on a free adjacent tile. Use the number pad
            buttons on each task to move its point around the machine.
          </Box>
        </Section>

        <Section title={`Tasks (${tasks_data.length})`}>
          {tasks_data.length === 0 && (
            <Box color="label">No tasks yet. Create some above.</Box>
          )}
          <Table>
            {tasks_data.map((task) => (
              <Table.Row key={task.id} className="candystripe">
                <Table.Cell collapsing>
                  <Box bold>{task.name}</Box>
                  <Box color="label" fontSize="11px">
                    {TASK_TYPE_LABELS[task.task_type] || task.task_type}
                    {task.turf ? ` @ ${task.turf}` : ''}
                  </Box>
                </Table.Cell>
                <Table.Cell>
                  {task.task_type === 'pickup' && (
                    <Button
                      compact
                      content={task.pickup_eagerness}
                      tooltip="Eager pickups grab any item immediately; otherwise they wait until a dropoff point can accept it"
                      onClick={() =>
                        act('adjust_task_param', {
                          taskId: task.id,
                          param: 'cycle_pickup_eagerness',
                        })
                      }
                    />
                  )}
                  {task.task_type === 'drop' && (
                    <>
                      <Button
                        compact
                        content={task.overflow_status}
                        tooltip="Allow: always drop here; TO HELD: no same-type item already there; FORBID: no items at all there"
                        onClick={() =>
                          act('adjust_task_param', {
                            taskId: task.id,
                            param: 'cycle_overflow_status',
                          })
                        }
                      />
                    </>
                  )}
                  {task.task_type === 'throw' && (
                    <Box inline>
                      Range{' '}
                      <Button
                        compact
                        content={task.throw_range}
                        onClick={() =>
                          act('adjust_task_param', {
                            taskId: task.id,
                            param: 'cycle_throw_range',
                          })
                        }
                      />
                    </Box>
                  )}
                  {task.task_type === 'wait' && (
                    <Box inline>
                      Seconds{' '}
                      <NumberInput
                        width="50px"
                        step={1}
                        minValue={1}
                        maxValue={60}
                        value={task.time || 1}
                        onDrag={(value) =>
                          act('adjust_task_param', {
                            taskId: task.id,
                            param: 'set_wait_time',
                            value: value,
                          })
                        }
                      />
                    </Box>
                  )}
                  {task.turf && (
                    <Box mt={0.5}>
                      {ROWS.map((row, rowIndex) => (
                        <Stack key={rowIndex} mb={rowIndex < ROWS.length - 1 ? 1 : 0}>
                          {row.map((direction, cellIndex) => (
                            <Stack.Item mx={0.5} key={direction ? direction.key : `stop-${cellIndex}`}>
                              {direction && (
                                <Button
                                  compact
                                  icon={direction.icon}
                                  iconRotation={direction.iconRotation}
                                  tooltip={`Move point (${((direction.button - 1) % 3) - 1}, ${1 - Math.round((direction.button - 1) / 3)})`}
                                  onClick={() =>
                                    act('adjust_task_param', {
                                      taskId: task.id,
                                      param: 'move_to',
                                      value: direction.button,
                                    })
                                  }
                                />
                              )}
                            </Stack.Item>
                          ))}
                        </Stack>
                      ))}
                    </Box>
                  )}
                </Table.Cell>
                <Table.Cell collapsing>
                  <Stack vertical>
                    <Button
                      compact
                      icon="arrow-up"
                      tooltip="Move task up"
                      onClick={() =>
                        act('adjust_task_param', {
                          taskId: task.id,
                          param: 'move_up',
                        })
                      }
                    />
                    <Button
                      compact
                      icon="arrow-down"
                      tooltip="Move task down"
                      onClick={() =>
                        act('adjust_task_param', {
                          taskId: task.id,
                          param: 'move_down',
                        })
                      }
                    />
                    <Button
                      compact
                      color="bad"
                      icon="times"
                      tooltip="Delete task"
                      onClick={() =>
                        act('adjust_task_param', {
                          taskId: task.id,
                          param: 'remove_task',
                        })
                      }
                    />
                  </Stack>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>

        <Section
          title="Task disk"
          buttons={
            <>
              <Button
                icon="download"
                disabled={!disk_inserted || active || stopping}
                tooltip="Write current tasks to disk"
                onClick={() => act('disk_write')}
              >
                Write
              </Button>
              <Button
                icon="upload"
                disabled={!disk_inserted || active || stopping}
                tooltip="Load tasks from disk"
                onClick={() => act('disk_read')}
              >
                Read
              </Button>
              <Button
                icon="eraser"
                disabled={!disk_inserted || active || stopping || disk_read_only}
                onClick={() => act('disk_clear')}
              >
                Clear
              </Button>
              <Button
                icon="eject"
                disabled={!disk_inserted || active || stopping}
                onClick={() => act('disk_eject')}
              >
                Eject
              </Button>
            </>
          }
        >
          {!disk_inserted ? (
            <Box color="label">No disk inserted.</Box>
          ) : (
            <Box>
              Disk inserted: {disk_task_count} task(s)
              {!!disk_read_only && (
                <Box inline color="yellow">
                  {' '}
                  [READ-ONLY]
                </Box>
              )}
            </Box>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
