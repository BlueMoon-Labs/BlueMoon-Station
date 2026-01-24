import { useBackend } from '../backend';
import { Box, Button, Section } from '../components';
import { Window } from '../layouts';

export const KeycardAuth = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Window
      width={375}
      height={150}>
      <Window.Content>
        <Section>
          <Box>
            {data.waiting === 1 && (
              <span>
                Ожидайте подтверждения запроса
                на втором устройстве...
              </span>
            )}
          </Box>
          <Box>
            {data.waiting === 0 && (
              <>
                {!!data.auth_required && (
                  <Button
                    icon="check-square"
                    color="red"
                    textAlign="center"
                    lineHeight="60px"
                    fluid
                    onClick={() => act('auth_swipe')}
                    content="Авторизовать" />
                )}
                {data.auth_required === 0 && (
                  <>
                    <Button
                      icon="exclamation-triangle"
                      fluid
                      onClick={() => {
                        return act('red_alert');
                      }}
                      content="Красный код" />
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
