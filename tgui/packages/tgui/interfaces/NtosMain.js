import { useBackend } from '../backend';
import { Button, Section, Stack } from '../components';
import { NtosWindow } from '../layouts';

export const NtosMain = (props) => {
  const { act, data } = useBackend();
  const {
    device_theme,
    programs = [],
    has_light,
    light_on,
    removable_media = [],
    cardholder,
    login = [],
    has_cartridge,
    cartridge_name,
    battery_percent,
    available_themes = [],
    security_level,
    security_level_color,
  } = data;
  const camera = programs.find(program => program.name === 'Camera');

  return (
    <NtosWindow
      title={device_theme === 'syndicate' ? 'Syndix OS' : 'NtOS'}
      theme={device_theme}
      width={420}
      height={560}>
      <NtosWindow.Content>
        <Stack vertical fill>
          {/* ID Details */}
          {!!cardholder && login.IDName && (
            <Stack.Item>
              <Section
                title="Данные"
                style={{ margin: '8px 10px 0 10px' }}>
                <div style={{ fontSize: '12px', lineHeight: '1.6' }}>
                  <div>
                    <span style={{ color: 'rgba(255,255,255,0.5)' }}>
                      Владелец:{' '}
                    </span>
                    <b>{login.IDName}</b>
                  </div>
                  <div>
                    <span style={{ color: 'rgba(255,255,255,0.5)' }}>
                      Должность:{' '}
                    </span>
                    <b>{login.IDJob || 'Нет'}</b>
                  </div>
                </div>
              </Section>
            </Stack.Item>
          )}

          {/* Cartridge */}
          {!!has_cartridge && (
            <Stack.Item>
              <div style={{
                margin: '4px 10px 0 10px',
                padding: '8px 12px',
                background: 'rgba(255,255,255,0.04)',
                border: '1px solid rgba(255,255,255,0.08)',
                borderRadius: '6px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}>
                <span style={{ fontSize: '13px' }}>
                  <span style={{ color: 'rgba(255,255,255,0.5)' }}>
                    Картридж{' '}
                  </span>
                  <b>{cartridge_name}</b>
                </span>
                <Button
                  icon="eject"
                  color="transparent"
                  onClick={() => act('PDA_ejectDisk')}>
                  Извлечь
                </Button>
              </div>
            </Stack.Item>
          )}

          {/* Removable media */}
          {!!removable_media.length && (
            <Stack.Item>
              <div style={{ margin: '4px 10px 0 10px' }}>
                {removable_media.map(device => (
                  <Button
                    key={device}
                    fluid
                    color="transparent"
                    icon="eject"
                    content={device}
                    onClick={() =>
                      act('PC_Eject_Disk', { name: device })}
                  />
                ))}
              </div>
            </Stack.Item>
          )}

          {/* Applications */}
          <Stack.Item grow minHeight={0} mx="10px" mb="8px">
            <Section
              className="NtosMain__programs"
              title="Приложения"
              fill
              scrollable>
              <Stack vertical>
                {programs.map(program => program !== camera && (
                  <Stack.Item key={program.name}>
                    <Button
                      fluid
                      color={program.alert ? 'yellow' : 'transparent'}
                      icon={program.icon}
                      onClick={() =>
                        act('PC_runprogram', { name: program.name })}>
                      {program.desc}
                      {program.name === 'nt_messenger' && security_level && (
                        <span
                          title={security_level.toUpperCase()}
                          style={{
                            display: 'inline-block',
                            width: '8px',
                            height: '8px',
                            borderRadius: '50%',
                            backgroundColor: security_level_color,
                            marginLeft: '6px',
                            verticalAlign: 'middle',
                          }} />
                      )}
                      {!!program.running && (
                        <span style={{
                          marginLeft: '8px',
                          fontSize: '10px',
                          color: 'rgba(255,255,255,0.4)',
                        }}>
                          (запущено)
                        </span>
                      )}
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>

          {/* Bottom bar */}
          <Stack.Item shrink={0}>
            <div style={{
              borderTop: '1px solid rgba(255,255,255,0.08)',
              padding: '6px 10px',
              display: 'flex',
              gap: '6px',
              alignItems: 'center',
            }}>
              {!!has_light && (
                <>
                  <Button
                    icon="lightbulb"
                    selected={light_on}
                    color="transparent"
                    onClick={() => act('PC_toggle_light')}>
                    {light_on ? 'ВКЛ' : 'ВЫКЛ'}
                  </Button>
                  <Button
                    icon="palette"
                    color="transparent"
                    onClick={() => act('PC_light_color')}>
                    Цвет
                  </Button>
                </>
              )}
              {camera && (
                <Button
                  icon={camera.icon}
                  color={camera.alert ? 'yellow' : 'transparent'}
                  selected={!!camera.running}
                  onClick={() => act('PC_runprogram', { name: camera.name })}>
                  {camera.desc}
                </Button>
              )}
              <Button
                icon="palette"
                color="transparent"
                style={{ marginLeft: 'auto' }}
                onClick={() => {
                  const idx = available_themes.findIndex(
                    t => t.id === device_theme);
                  const next = available_themes[
                    (idx + 1) % available_themes.length];
                  act('set_theme', { theme: next.id });
                }}>
                Тема: {available_themes.find(
                  t => t.id === device_theme)?.name || device_theme}
              </Button>
            </div>
          </Stack.Item>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
