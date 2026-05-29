import { useBackend } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';

export const MetadollarShop = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    balance = 0,
    inteqMode = false,
    legit = [],
    smuggle = [],
    onlinePlayers = 0,
  } = data;
  const theme = inteqMode ? 'inteq' : 'ntos';
  const catalog = inteqMode ? smuggle : legit;
  return (
    <Window
      width={520}
      height={480}
      theme={theme}
      title="Метамагазин">
      <Window.Content scrollable fitted>
        <Box m={1}>
          <Section
            title="Баланс"
            buttons={(
              <Stack direction="row" align="center">
                <Stack.Item>
                  <Box color="label">
                    {balance} M$
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="wallet"
                    onClick={() => act('topup')}>
                    ПОПОЛНИТЬ СЧЁТ
                  </Button>
                </Stack.Item>
              </Stack>
            )}>
            {inteqMode ? (
              <Box>
                Подпольный каталог: особые заказы для следующей смены.
              </Box>
            ) : (
              <Box>
                Официальный каталог: снаряжение в рюкзак при появлении на станции.
              </Box>
            )}
          </Section>
          <Section title="Товары">
            <Stack vertical>
              {catalog.map(entry => {
                const minP = entry.minPlayers || 0;
                const lowPop = minP > 0 && onlinePlayers < minP;
                const cantAfford = balance < entry.cost;
                return (
                  <Stack.Item key={entry.id}>
                    <Box
                      p={1.2}
                      mb={1}
                      className="MetadollarShop__card"
                      style={{
                        border: '1px solid rgba(120, 180, 255, 0.35)',
                        borderRadius: '4px',
                        backgroundColor: 'rgba(15, 25, 45, 0.55)',
                        boxShadow: 'inset 0 0 0 1px rgba(0, 0, 0, 0.35)',
                      }}>
                      <Box mb={1}>
                        <Box bold>{entry.name}</Box>
                        <Box color="label" fontSize={0.9}>
                          {entry.desc}
                        </Box>
                        {minP > 0 && (
                          <Box color={lowPop ? 'bad' : 'label'} fontSize={0.85} mt={0.5}>
                            Игроков онлайн: {onlinePlayers} / нужно ≥{minP}
                          </Box>
                        )}
                      </Box>
                      <Button
                        fluid
                        icon="cart-plus"
                        color={inteqMode ? 'bad' : 'good'}
                        disabled={cantAfford || lowPop}
                        tooltip={lowPop
                          ? `Нужно минимум ${minP} игроков на сервере (сейчас ${onlinePlayers})`
                          : cantAfford
                            ? 'Недостаточно метадолларов'
                            : null}
                        content={`Купить за ${entry.cost} M$`}
                        onClick={() => act('buy', { id: entry.id })} />
                    </Box>
                  </Stack.Item>
                );
              })}
            </Stack>
          </Section>
          <Box mt={1}>
            <Button
              compact
              tooltip={inteqMode
                ? 'Вернуться к официальному каталогу'
                : 'Подпольный вход (другой каталог)'}
              icon={inteqMode ? 'building' : 'skull'}
              color={inteqMode ? 'average' : 'bad'}
              onClick={() => act('toggle_smuggle')} />
          </Box>
        </Box>
      </Window.Content>
    </Window>
  );
};
