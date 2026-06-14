import { capitalize } from 'common/string';
import { useBackend } from '../backend';
import { Box, Button, Section } from '../components';
import { Window } from '../layouts';

const HIGH_ALERT_LABELS = {
  lambda: 'Код Лямбда',
  gamma: 'Код Гамма',
  epsilon: 'Код Эпсилон',
  delta: 'Код Дельта',
};

export const KeycardAuth = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    waiting,
    auth_required,
    security_level,
    can_set_red_alert,
    can_clear_red_alert,
    can_clear_high_alert,
    high_alert_levels = [],
  } = data;

  return (
    <Window
      width={375}
      height={340}>
      <Window.Content scrollable>
        <Section>
          <Box>
            {waiting === 1 && (
              <span>
                Ожидайте подтверждения запроса
                на втором устройстве...
              </span>
            )}
          </Box>
          <Box>
            {waiting === 0 && (
              <>
                {!!auth_required && (
                  <Button
                    icon="check-square"
                    color="red"
                    textAlign="center"
                    lineHeight="60px"
                    fluid
                    onClick={() => act('auth_swipe')}
                    content="Авторизовать" />
                )}
                {auth_required === 0 && (
                  <>
                    {!!can_set_red_alert && (
                      <Button
                        icon="exclamation-triangle"
                        fluid
                        onClick={() => act('red_alert')}
                        content="Красный код" />
                    )}
                    {!!can_clear_red_alert && (
                      <Button
                        icon="check"
                        fluid
                        onClick={() => act('clear_red_alert')}
                        content="Снять красный код" />
                    )}
                    {!!can_clear_high_alert && (
                      <Button
                        icon="check"
                        fluid
                        onClick={() => act('clear_high_alert')}
                        content="Снизить код (до красного)" />
                    )}
                    {high_alert_levels.map(level => (
                      <Button
                        key={level}
                        icon="radiation"
                        fluid
                        disabled={security_level === level}
                        onClick={() => act('set_high_alert', { level })}
                        content={HIGH_ALERT_LABELS[level] || capitalize(level)} />
                    ))}
                    <Button
                      icon="wrench"
                      fluid
                      onClick={() => act('emergency_maint')}
                      content="Аварийный доступ в тоннели" />
                    <Button
                      icon="meteor"
                      fluid
                      onClick={() => act('bsa_unlock')}
                      content="Протоколы Блюспейс-Артиллерии" />
                    <Button
                      icon="database"
                      fluid
                      onClick={() => act('bs_miner_protocols')}
                      content="Протоколы Блюспейс майнеров" />
                    <Button
                      icon="key"
                      fluid
                      onClick={() => act('give_janitor_access')}
                      content="Выдать доступ уборщику" />
                  </>
                )}
              </>
            )}
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};
