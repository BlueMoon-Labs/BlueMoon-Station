import { useBackend } from '../../backend';
import { Button, Dropdown, NumberInput, Section, Stack, Tooltip } from '../../components';

type AntagRole = {
  name: string;
  status: number;
};

type AntagData = {
  antag_roles: AntagRole[];
  no_antag: boolean;
  midround_antag: boolean;
  preferred_chaos_level: number;
};

const capitalize = (str: string) =>
  str.charAt(0).toUpperCase() + str.slice(1);

export const AntagsSection = (props) => {
  const { act, data } = useBackend<AntagData>();
  const { antag_roles, no_antag, midround_antag } = data;

  if (!antag_roles) {
    return null;
  }

  const mid = Math.ceil(antag_roles.length / 2);
  const leftCol = antag_roles.slice(0, mid);
  const rightCol = antag_roles.slice(mid);

  const STATUS_OPTIONS = [
    { value: -1, label: 'Отключено' },
    { value: 0, label: 'Высокий' },
    { value: 1, label: 'Низкий' },
  ];

  const renderRole = (role: AntagRole) => {
    const current = STATUS_OPTIONS.find(o => o.value === role.status)
      || STATUS_OPTIONS[0];

    return (
      <Stack.Item key={role.name} className="GamePreferences__row">
        <Stack align="center" fill>
          <Stack.Item grow basis={0} pr={1}>
            <div className="GamePreferences__label">
              {capitalize(role.name)}
            </div>
          </Stack.Item>
          <Stack.Item>
            <Dropdown
              width="150px"
              options={STATUS_OPTIONS.map(o => o.label)}
              selected={current.label}
              onSelected={(value) => {
                const opt = STATUS_OPTIONS.find(o => o.label === value);
                if (opt) act('toggle_antag', { role: role.name, value: opt.value });
              }}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    );
  };

  return (
    <Stack vertical fill>
      <Stack.Item grow basis={0}>
        <Section fill scrollable className="GamePreferences__scroll">
          <Stack fill>
            <Stack.Item basis="50%">
              <Stack vertical>{leftCol.map(renderRole)}</Stack>
            </Stack.Item>
            <Stack.Item basis="50%">
              <Stack vertical>{rightCol.map(renderRole)}</Stack>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row" px={1} py={1}>
          <Stack.Item>
            <Tooltip content="Если включено — вы можете получать любые роли антагонистов. Если выключено — выдача полностью заблокирована">
              <div className="GamePreferences__label">
                Разрешить роли антагонистов
              </div>
            </Tooltip>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon={!no_antag ? 'toggle-on' : 'toggle-off'}
              selected={!no_antag}
              color={!no_antag ? 'green' : 'default'}
              onClick={() => act('toggle_gameplay', { flag: 'no_antag' })}
            >
              {!no_antag ? 'Включено' : 'Отключено'}
            </Button>
          </Stack.Item>
          <Stack.Item pl={2}>
            <Tooltip content="Выдача антага после начала раунда">
              <div className="GamePreferences__label">
                Midround антаги
              </div>
            </Tooltip>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon={midround_antag ? 'toggle-on' : 'toggle-off'}
              selected={midround_antag}
              color={midround_antag ? 'green' : 'default'}
              onClick={() => act('toggle_gameplay', { flag: 'midround_antag' })}
            >
              {midround_antag ? 'Включено' : 'Отключено'}
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" fill className="GamePreferences__row">
          <Stack.Item grow basis={0}>
            <div className="GamePreferences__label">Предпочитаемый уровень хаоса</div>
            <div className="GamePreferences__hint">0 — минимальный, 3 — максимальный хаос</div>
          </Stack.Item>
          <Stack.Item>
            <NumberInput
              width="80px"
              minValue={0}
              maxValue={3}
              step={1}
              value={Number(data.preferred_chaos_level ?? 2)}
              onChange={(e, value) => act('set_gfx_val', { flag: 'preferred_chaos_level', value })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};
