import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Section, Box, Button, Stack, Icon, Grid } from '../components';

export const MalfunctionModulePicker = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    processing_time = 0,
    large_modules = [],
    small_modules = [],
  } = data;

  const ModuleCard = ({ module, typeColor }) => (
    <Box
      key={module.ref}
      style={{
        background: 'linear-gradient(135deg, rgba(10, 10, 10, 0.95) 0%, rgba(25, 25, 25, 0.7) 100%)',
        borderLeft: `3px solid ${typeColor}`,
        boxShadow: `0 4px 15px rgba(0, 0, 0, 0.6)`,
        padding: '12px',
        marginBottom: '10px',
        borderRadius: '2px',
        backdropFilter: 'blur(2px)',
      }}
    >
      <Box className="display-flex" style={{ alignItems: 'center', marginBottom: '6px' }}>
        <Icon name="microchip" color={typeColor} size={1.2} style={{
          marginRight: '10px',
          textShadow: `0 0 10px ${typeColor}`
        }} />
        <Box fluid bold fontSize="14px" color={typeColor} style={{ textShadow: `0 0 5px ${typeColor}88` }}>
          {module.name.toUpperCase()}
        </Box>
        <Box color="cyan" bold fontSize="14px" fontFamily="monospace" style={{ textShadow: '0 0 10px #00ffff66' }}>
          {module.cost} PT
        </Box>
      </Box>

      <Box color="label" fontSize="11px" italic mb={1.5} style={{ lineHeight: '1.4', minHeight: '30px' }}>
        {module.desc}
      </Box>

      <Button
        fluid
        disabled={processing_time < module.cost}
        color="transparent"
        style={{
          border: `1px solid ${processing_time < module.cost ? '#333' : typeColor}`,
          color: processing_time < module.cost ? '#555' : '#fff',
          backgroundColor: 'rgba(0,0,0,0.4)',
          boxShadow: processing_time >= module.cost ? `inset 0 0 8px ${typeColor}44` : 'none',
          textShadow: processing_time >= module.cost ? `0 0 5px #fff` : 'none',
        }}
        onClick={() => act('buy', { ref: module.ref })}
      >
        {processing_time < module.cost ? 'НЕДОСТАТОЧНО ПАМЯТИ' : 'УСТАНОВИТЬ МОДУЛЬ'}
      </Button>
    </Box>
  );

  return (
    <Window width={750} height={650} theme="malfunction">
      <Window.Content
        scrollable
        style={{
          background: '#020202',
          backgroundImage: `
            radial-gradient(circle at 50% 30%, #1a1a2e 0%, #020202 100%),
            linear-gradient(rgba(28, 97, 213, 0.03) 1px, transparent 1px),
            linear-gradient(90deg, rgba(28, 97, 213, 0.03) 1px, transparent 1px)
          `,
          backgroundSize: '100% 100%, 25px 25px, 25px 25px',
          padding: '15px'
        }}
      >
        <Grid>
          <Grid.Column size={3}>
            <Box style={{
              borderBottom: '2px solid #1c61d5',
              paddingBottom: '12px',
              marginBottom: '20px',
              boxShadow: '0 8px 15px -10px #1c61d5',
              background: 'rgba(0, 0, 0, 0.4)',
              padding: '10px',
              borderRadius: '2px'
            }}>
              <Box color="#1c61d5" bold fontSize="18px" style={{ letterSpacing: '2px', textShadow: '0 0 12px #1c61d5' }}>
                MALFUNCTION SYSTEM
              </Box>
              <Box color="label" fontSize="10px" style={{ opacity: 0.6 }}>INTERFACE // BUILD 2.77</Box>
            </Box>

            <Box
              p={2}
              style={{
                background: 'linear-gradient(to bottom, rgba(28, 97, 213, 0.15), rgba(0, 0, 0, 0.6))',
                border: '1px solid #1c61d533',
                borderRadius: '4px',
                textAlign: 'center',
                boxShadow: '0 4px 15px rgba(0, 0, 0, 0.5)'
              }}
            >
              <Box color="label" fontSize="10px" mb={0.5} bold uppercase>Available Flops</Box>
              <Box color="cyan" fontSize="36px" bold fontFamily="monospace" style={{ textShadow: '0 0 20px #00ffff' }}>
                {processing_time}
              </Box>
              <Box color="cyan" fontSize="10px" style={{ opacity: 0.8, letterSpacing: '1px' }}>SYS_RESOURCES_OK</Box>
            </Box>

            <Box mt={5} p={1.5} style={{
              borderLeft: '2px solid #1c61d5',
              background: 'rgba(0, 0, 0, 0.5)',
              backdropFilter: 'blur(1px)'
            }}>
              <Box color="#1c61d5" fontSize="11px" bold mb={1}>DIRECTIVE_LOG:</Box>
              <Box color="label" fontSize="10px" italic style={{ lineHeight: '1.3' }}>
                Ядро ожидает выбора модулей. Все модификации выполняются в приоритетном режиме доступа.
              </Box>
            </Box>
          </Grid.Column>

          <Grid.Column size={7}>
            <Box pr={1}>
              <Section
                title={<Box color="#ff2a2a" style={{ textShadow: '0 0 10px #ff2a2a' }}>ТЯЖЕЛЫЕ СИСТЕМЫ</Box>}
                style={{ marginBottom: '30px' }}
              >
                {large_modules.map(module => (
                  <ModuleCard key={module.ref} module={module} typeColor="#ff2a2a" />
                ))}
              </Section>

              <Section
                title={<Box color="#ff9d00" style={{ textShadow: '0 0 10px #ff9d00' }}>ЛЕГКИЕ СКРИПТЫ</Box>}
              >
                {small_modules.map(module => (
                  <ModuleCard key={module.ref} module={module} typeColor="#ff9d00" />
                ))}
              </Section>
            </Box>
          </Grid.Column>
        </Grid>
      </Window.Content>
    </Window>
  );
};
