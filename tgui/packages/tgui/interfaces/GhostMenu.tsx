import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  LabeledList,
  Section,
  Stack,
  Tooltip,
} from '../components';
import { Window } from '../layouts';

type NotificationEntry = {
  key: string;
  enabled: BooleanLike;
  desc: string;
};

type Data = {
  can_reenter: BooleanLike;
  body_name: string | null;
  ghost_vision: BooleanLike;
  current_darkness: string | null;
  data_huds_on: BooleanLike;
  health_scan: BooleanLike;
  reagent_scan: BooleanLike;
  gas_scan: BooleanLike;
  t_ray: BooleanLike;
  notification_entries: NotificationEntry[];
  // static
  darkness_levels: string[];
};

export function GhostMenu(props) {
  const { act, data } = useBackend<Data>();
  const { can_reenter, body_name } = data;

  return (
    <Window title="Ghost Menu" width={460} height={700}>
      <Window.Content scrollable>
        <Stack fill vertical>
          {!!body_name && (
            <Stack.Item>
              <Section title="Body">
                <Box mb={1}>
                  You can re-enter <b>{body_name}</b>.
                </Box>
                <Stack wrap>
                  <Stack.Item>
                    <Button color="good" onClick={() => act('return_to_body')}>
                      Re-enter Corpse
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button.Confirm
                      color="bad"
                      tooltip="Permanently prevent (almost) all means of resuscitation. Cannot be undone."
                      onClick={() => act('DNR')}
                    >
                      Do Not Resuscitate
                    </Button.Confirm>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          )}
          {!body_name && can_reenter === 0 && (
            <Stack.Item>
              <Section title="Body">
                <Button
                  color="bad"
                  tooltip="Permanently prevent (almost) all means of resuscitation. Cannot be undone."
                  onClick={() => act('DNR')}
                >
                  Do Not Resuscitate
                </Button>
              </Section>
            </Stack.Item>
          )}

          <Stack.Item>
            <Section title="Crew">
              <Stack wrap>
                <Stack.Item>
                  <Button icon="users" onClick={() => act('manifest')}>
                    Show Station Manifest
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button icon="robot" onClick={() => act('signup_pai')}>
                    Sign up as pAI
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Vision">
              <LabeledList>
                <LabeledList.Item label="Darkness">
                  <Dropdown
                    options={data.darkness_levels}
                    selected={data.current_darkness}
                    onSelected={(value) =>
                      act('darkness', { darkness_level: value })
                    }
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Ghost Vision">
                  <BooleanButton
                    value={data.ghost_vision}
                    onToggle={() => act('toggle_ghost_vision')}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Scanners">
              <LabeledList>
                <LabeledList.Item
                  label={
                    <Tooltip content="Scan living beings on click for health and wounds.">
                      Health Scan
                    </Tooltip>
                  }
                >
                  <BooleanButton
                    value={data.health_scan}
                    onToggle={() => act('toggle_health_scan')}
                  />
                </LabeledList.Item>
                <LabeledList.Item
                  label={
                    <Tooltip content="Scan living beings on click for their reagents.">
                      Reagent Scan
                    </Tooltip>
                  }
                >
                  <BooleanButton
                    value={data.reagent_scan}
                    onToggle={() => act('toggle_reagent_scan')}
                  />
                </LabeledList.Item>
                <LabeledList.Item
                  label={
                    <Tooltip content="Scan floor tiles on click for their air contents.">
                      Gas Scan
                    </Tooltip>
                  }
                >
                  <BooleanButton
                    value={data.gas_scan}
                    onToggle={() => act('toggle_gas_scan')}
                  />
                </LabeledList.Item>
                <LabeledList.Item
                  label={
                    <Tooltip content="Show Security, Medical and Diagnostic HUDs for nearby beings.">
                      Data HUDs
                    </Tooltip>
                  }
                >
                  <BooleanButton
                    value={data.data_huds_on}
                    onToggle={() => act('toggle_data_huds')}
                  />
                </LabeledList.Item>
                <LabeledList.Item
                  label={
                    <Tooltip content="Expose items hidden under the floor near you.">
                      T-Ray
                    </Tooltip>
                  }
                >
                  <BooleanButton
                    value={data.t_ray}
                    onToggle={() => act('toggle_t_ray')}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          <Stack.Item>
            <Section title="Notifications">
              {(!data.notification_entries ||
                data.notification_entries.length === 0) && (
                <Box color="label">No ghost roles to choose from.</Box>
              )}
              <Stack wrap>
                {data.notification_entries.map((entry) => (
                  <Stack.Item key={entry.key}>
                    <Button
                      icon={entry.enabled ? 'bell' : 'bell-slash'}
                      color={entry.enabled ? 'good' : 'bad'}
                      tooltip={entry.desc}
                      onClick={() =>
                        act('toggle_notification', { key: entry.key })
                      }
                    >
                      {entry.desc}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}

function BooleanButton(props: {
  value: BooleanLike;
  onToggle: () => void;
}) {
  const { value, onToggle } = props;
  return (
    <Button
      icon={value ? 'check' : 'times'}
      color={value ? 'good' : 'bad'}
      onClick={onToggle}
    >
      {value ? 'Enabled' : 'Disabled'}
    </Button>
  );
}