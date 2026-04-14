import { Box, Button, Stack } from '../../components';
import { byondListToArray } from './byondPayload';

export const CircuitInfo = (props, context) => {
  const {
    name,
    desc,
    notices,
    ...rest
  } = props;
  const noticeList = byondListToArray(notices).filter(
    (val) => val && typeof val === 'object',
  );
  const nameText = name === null || name === undefined ? '' : String(name);
  const descText = desc === null || desc === undefined ? '' : String(desc);
  return (
    <Box {...rest}>
      <Stack fill vertical justify="space-around">
        {!!nameText && (
          <Stack.Item>
            <Box className="CircuitInfo__name">
              {nameText}
            </Box>
          </Stack.Item>
        )}
        <Stack.Item maxWidth="240px">
          <Box
            className="CircuitInfo__desc"
            style={{ 'white-space': 'pre-wrap' }}>
            {descText}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Stack vertical>
            {noticeList.map((val, index) => (
              <Stack.Item key={index}>
                <Button
                  content={
                    val.content === null || val.content === undefined
                      ? ''
                      : String(val.content)
                  }
                  color={val.color}
                  icon={val.icon}
                  fluid
                />
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
