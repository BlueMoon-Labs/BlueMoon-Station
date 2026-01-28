import { AnimatedNumber, Box } from '../../components';

export const BeakerContents = props => {
  const { beakerLoaded, beakerContents } = props;
  return (
    <Box>
      {!beakerLoaded && (
        <Box color="label">
          Реагенты отсутствуют.
        </Box>
      ) || beakerContents.length === 0 && (
        <Box color="label">
          Ёмкость пустая.
        </Box>
      )}
      {beakerContents.map(chemical => (
        <Box key={chemical.name} color="label">
          <AnimatedNumber
            initial={0} a
            value={chemical.volume} />
          {"u "+chemical.name}
          {chemical.purity < 1 && "(Purity: "+chemical.purity+")"}
        </Box>
      ))}
    </Box>
  );
};
