import { Button, Dropdown, Input, NumberInput, Stack } from '../../components';
import { BasicInput } from './BasicInput';
import { formatPortLiveValue } from './portValueFormat';

/** BYOND dirs (integrated_io/dir) */
const IE_DIR_OPTIONS = [
  [1, 'N (1)'],
  [2, 'S (2)'],
  [4, 'E (4)'],
  [8, 'W (8)'],
  [5, 'NE (5)'],
  [9, 'NW (9)'],
  [6, 'SE (6)'],
  [10, 'SW (10)'],
];

export const FUNDAMENTAL_DATA_TYPES = {
  'string': (props, context) => {
    const { name, value, setValue, color } = props;
    return (
      <BasicInput name={name} setValue={setValue} value={value} defaultValue="">
        <Input
          placeholder={name}
          value={value ?? ''}
          onChange={(e, val) => setValue(val)}
          width="96px"
        />
      </BasicInput>
    );
  },
  'number': (props, context) => {
    const { name, value, setValue, color } = props;
    const hasNumber = typeof value === 'number' && Number.isFinite(value);
    return (
      <BasicInput
        name={name}
        setValue={setValue}
        value={value}
        defaultValue={0}>
        <NumberInput
          value={hasNumber ? value : 0}
          format={hasNumber ? undefined : () => '—'}
          color={color}
          onChange={(e, val) => setValue(val)}
          unit={name}
          showBar={false}
        />
      </BasicInput>
    );
  },
  'index': (props, context) => {
    return FUNDAMENTAL_DATA_TYPES.number(props, context);
  },
  'boolean': (props, context) => {
    const { name, value, setValue } = props;
    const on = value === true || value === 1 || value === '1' || value === 'true';
    return (
      <Button
        compact
        color={on ? 'good' : 'transparent'}
        icon={on ? 'toggle-on' : 'toggle-off'}
        content={`${name}: ${on ? 'Да' : 'Нет'}`}
        onClick={() => setValue(on ? 0 : 1)}
      />
    );
  },
  'char': (props, context) => {
    const { name, value, setValue } = props;
    const s = value === null || value === undefined ? '' : String(value);
    return (
      <BasicInput name={name} setValue={setValue} value={value} defaultValue="">
        <Input
          placeholder={name}
          value={s.slice(0, 1)}
          maxLength={1}
          width="2.2rem"
          onChange={(e, val) => setValue((val || '').slice(0, 1))}
        />
      </BasicInput>
    );
  },
  'color': (props, context) => {
    const { name, value, setValue } = props;
    const hex = typeof value === 'string' && /^#[0-9A-Fa-f]{6}$/.test(value)
      ? value
      : '#FFFFFF';
    return (
      <BasicInput name={name} setValue={setValue} value={value} defaultValue="#FFFFFF">
        <Stack>
          <Stack.Item>
            <input
              type="color"
              value={hex}
              title={name}
              onChange={(e) => setValue(e.target.value.toUpperCase())}
              style={{
                width: '28px',
                height: '22px',
                padding: 0,
                border: 'none',
                cursor: 'pointer',
                verticalAlign: 'middle',
              }}
            />
          </Stack.Item>
          <Stack.Item>
            <Input
              placeholder="#RRGGBB"
              value={typeof value === 'string' ? value : ''}
              width="76px"
              onChange={(e, val) => setValue(val)}
            />
          </Stack.Item>
        </Stack>
      </BasicInput>
    );
  },
  'dir': (props, context) => {
    const { value, setValue, name } = props;
    const labels = IE_DIR_OPTIONS.map(([, label]) => label);
    const match = IE_DIR_OPTIONS.find(([v]) => v === value);
    const displayText = match ? match[1] : (value === null || value === undefined ? '—' : String(value));
    return (
      <Dropdown
        width="9rem"
        noscroll
        color="transparent"
        displayText={`${name}: ${displayText}`}
        options={labels}
        onSelected={(sel) => {
          const found = IE_DIR_OPTIONS.find(([, label]) => label === sel);
          if (found) {
            setValue(found[0]);
          }
        }}
      />
    );
  },
  'list': (props, context) => {
    const { act, componentId, portId, name, isOutput, ieCircuit } = props;
    if (!act || componentId === null || componentId === undefined
      || portId === null || portId === undefined) {
      return null;
    }
    if (!ieCircuit) {
      return name;
    }
    return (
      <Stack align="center">
        <Stack.Item>
          <Button
            icon="list-ul"
            content={name}
            compact
            color="transparent"
            tooltip="Редактор / просмотр списка"
            onClick={() => act('ie_open_list_editor', {
              component_id: componentId,
              port_id: portId,
              is_output: !!isOutput,
            })}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="upload"
            compact
            color="transparent"
            tooltip="Debugger: вставить/скопировать список (режим Copy — забрать текущий список в память)"
            onClick={() => act('set_component_input', {
              component_id: componentId,
              port_id: portId,
              marked_atom: true,
            })}
          />
        </Stack.Item>
      </Stack>
    );
  },
  'entity': (props, context) => {
    const { name, setValue, value } = props;
    const hasRef = value !== null && value !== undefined && value !== '';
    const label = hasRef
      ? `${name}: ${formatPortLiveValue(value, 'entity')}`
      : name;
    return (
      <Button
        content={label}
        color="transparent"
        icon="upload"
        compact
        tooltip="Сначала предмет в активной руке (как ref); иначе память debugger в любой руке (ref/null); иначе marked"
        onClick={() => setValue(null, { marked_atom: true })}
      />
    );
  },
  'signal': (props, context) => {
    const { name, setValue } = props;
    const fire = (e) => {
      e?.stopPropagation?.();
      setValue();
    };
    return (
      <Stack align="center">
        <Stack.Item>
          <Button
            icon="bolt"
            color="transparent"
            compact
            tooltip="Вручную подать импульс на вход"
            onMouseDown={(e) => e.stopPropagation()}
            onClick={fire}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            content={name}
            color="transparent"
            compact
            tooltip="Вручную подать импульс на вход"
            onMouseDown={(e) => e.stopPropagation()}
            onClick={fire}
          />
        </Stack.Item>
      </Stack>
    );
  },
  'option': (props, context) => {
    const { value, setValue, extraData } = props;
    return (
      <Dropdown
        className="Datatype__Option"
        color={"transparent"}
        options={Array.isArray(extraData)
          ? extraData
          : Object.keys(extraData)}
        onSelected={setValue}
        displayText={value}
        noscroll
      />
    );
  },
  'any': (props, context) => {
    const { name, value, setValue, color, act, componentId, portId, isOutput, ieCircuit } = props;
    const complex = value !== null && value !== undefined
      && typeof value === 'object';
    const displayStr = complex
      ? formatPortLiveValue(value, Array.isArray(value) ? 'list' : 'any')
      : (value ?? '');
    return (
      <BasicInput
        name={name}
        setValue={setValue}
        value={value}
        defaultValue={''}>
        <Stack>
          <Stack.Item>
            <Button
              color={color}
              icon="upload"
              tooltip="Сначала предмет в активной руке; иначе память debugger (строка/число/ref/null); иначе marked"
              onClick={() => setValue(null, { marked_atom: true })}
            />
          </Stack.Item>
          {!!(complex && act && ieCircuit) && (
            <Stack.Item>
              <Button
                icon="search-plus"
                compact
                color="transparent"
                tooltip="Открыть данные (список / объект)"
                onClick={() => act('ie_open_data_inspector', {
                  component_id: componentId,
                  port_id: portId,
                  is_output: !!isOutput,
                })}
              />
            </Stack.Item>
          )}
          <Stack.Item>
            <Input
              placeholder={name}
              value={complex ? displayStr : (value ?? '')}
              onChange={(e, val) => !complex && setValue(val)}
              width="64px"
              disabled={complex}
            />
          </Stack.Item>
        </Stack>
      </BasicInput>
    );
  },
};

export const DATATYPE_DISPLAY_HANDLERS = {
  'option': (port) => {
    return port.name.toLowerCase();
  },
};
