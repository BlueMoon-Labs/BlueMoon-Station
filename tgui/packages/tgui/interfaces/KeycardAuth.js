import { useBackend } from '../backend';
import { Box, Button, Section } from '../components';
import { Window } from '../layouts';

export const KeycardAuth = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    waiting,
    auth_required,
    can_set_red_alert,
    can_clear_red_alert,
    can_clear_high_alert,
  } = data;

  return (
    <Window
      width={375}
      height={165}>
      <Window.Content>
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
