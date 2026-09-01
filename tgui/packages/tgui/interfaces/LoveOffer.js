import { useBackend } from '../backend';
import { Box, Button, Input, TextArea, Stack } from '../components';
import { Window } from '../layouts';

export const LoveOffer = (props) => {
  const { act, data } = useBackend();

  const {
    proposer_name,
    recipient_name,
    offer_text,
    saved,
  } = data;

  const CHARS_PER_LINE = 47;
  const LINE_HEIGHT = 18;
  const PADDING = 18;
  const LINE_PLUS_AFTER_SAVE = 18;
  const LINE_PLUS_BEFORE_SAVE = 10;

  const linesCount = offer_text
    .split('\n')
    .reduce((height, line) => {
      return height + Math.max(1, Math.ceil(line.length / CHARS_PER_LINE));
    }, 0);

  const textHeight = linesCount * LINE_HEIGHT + PADDING;

  const textAreaHeight = Math.max(20, textHeight);

  const windowHeight = (saved ? 490 : 560) + Math.max(0, textAreaHeight - 20) + linesCount * (saved ? LINE_PLUS_AFTER_SAVE : LINE_PLUS_BEFORE_SAVE);

  const recipientFontSize = Math.max(
    10,
    Math.min(15, 250 / Math.max(recipient_name.length * 0.55, 1)),
  );

  return (
    <Window width="480" height={windowHeight}>
      <Window.Content overflow="auto">
        <Stack fill vertical align="center" justify="center" height="100%">
          <Stack.Item grow={0}>
            <Box
              style={{
                width: '460px',
                background: '#0a0014',
                border: '2px solid #ff0099',
                padding: '40px 35px',
                textAlign: 'center',
                fontFamily: 'Arial, Helvetica, sans-serif',
                boxShadow: '0 0 35px rgba(255,0,153,0.25)',
              }}
            >
              <Box
                style={{
                  background: '#ff0099',
                  color: '#0a0014',
                  fontSize: '10px',
                  display: 'inline-block',
                  padding: '4px 18px',
                  textTransform: 'uppercase',
                  letterSpacing: '5px',
                  fontWeight: 'bold',
                  marginBottom: '16px',
                }}
              >
                Limited
              </Box>

              <Box
                style={{
                  fontSize: '42px',
                  fontWeight: 900,
                  color: '#fff',
                  lineHeight: 1.05,
                  textTransform: 'uppercase',
                  letterSpacing: '2px',
                  textShadow: '0 0 25px rgba(255,0,153,0.6)',
                }}
              >
                ПРОВЕДИ<br />
                ВРЕМЯ<br />
                <span style={{ color: '#ff0099' }}>
                  С {proposer_name}
                </span>
              </Box>

              <Box
                style={{
                  width: '80%',
                  height: '2px',
                  background: 'linear-gradient(90deg,transparent,#ff0099,transparent)',
                  margin: '22px auto',
                  opacity: 0.7,
                }}
              />

              {saved ? (
                <Box
                  style={{
                    fontSize: '14px',
                    color: '#e8e8e8',
                    lineHeight: 1.7,
                    margin: '14px 0 26px',
                    whiteSpace: 'pre-line',
                  }}
                >
                  <i>{offer_text}</i>
                </Box>
              ) : (
                <TextArea
                  value={offer_text}
                  fluid
                  onChange={(e, value) => act('set_offer_text', {
                    offer_text: value,
                  })}
                  style={{
                    minHeight: `${textAreaHeight}px`,
                    height: `${textAreaHeight}px`,
                    background: '#0a0014',
                    color: '#e8e8e8',
                    border: '1px solid rgba(255,0,153,0.5)',
                    borderRadius: '0',
                    padding: '12px',
                    fontSize: '14px',
                    lineHeight: 1.7,
                    textAlign: 'center',
                    fontStyle: 'italic',
                    boxShadow: 'inset 0 0 15px rgba(255,0,153,0.08)',
                  }}
                />
              )}

              <Box
                style={{
                  border: '1px solid rgba(255,0,153,0.5)',
                  padding: '16px 28px',
                  display: 'inline-block',
                  background: 'rgba(255,0,153,0.08)',
                  margin: '10px 0',
                }}
              >
                <Box
                  style={{
                    fontSize: '10px',
                    color: '#ff80c0',
                    letterSpacing: '3px',
                    textTransform: 'uppercase',
                    marginBottom: '6px',
                  }}
                >
                  Только для
                </Box>

                {saved ? (
                  <Box
                    style={{
                      fontSize: `${recipientFontSize}px`,
                      color: '#fff',
                      letterSpacing: '1px',
                    }}
                  >
                    {recipient_name}
                  </Box>
                ) : (
                  <Input
                    value={recipient_name}
                    width="250px"
                    onChange={(e, value) => act('set_recipient_name', {
                      recipient_name: value,
                    })}
                    style={{
                      background: 'transparent',
                      color: '#fff',
                      border: 'none',
                      borderBottom: '1px solid rgba(255,0,153,0.6)',
                      outline: 'none',
                      padding: '0',
                      fontSize: `${recipientFontSize}px`,
                      letterSpacing: '1px',
                      textAlign: 'center',
                    }}
                  />
                )}
              </Box>

              {!saved && (
                <Box style={{ marginTop: '26px' }}>
                  <Button
                    color="pink"
                    onClick={() => act('save', {
                      linesCount: linesCount,
                    })}
                  >
                    Сохранить
                  </Button>
                </Box>
              )}

              <Box
                style={{
                  marginTop: '26px',
                  fontSize: '9px',
                  color: '#555',
                  letterSpacing: '5px',
                  textTransform: 'uppercase',
                }}
              >
                Blue Moon PACT • love offer
              </Box>
            </Box>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window >
  );
};
