import { MachineWindow } from './types';

export type RemoteParameter = NonNullable<NonNullable<MachineWindow['remote']>['actions'][number]['params']>[number];

export const remoteParameterValue = (param: RemoteParameter, drafts: Record<string, string>) => {
  const value = drafts[param.id] ?? String(param.value ?? param.options?.[0]?.value ?? (param.type === 'number' ? param.min ?? 1 : ''));
  return param.options && !param.options.some((option) => option.value === value) ? '' : value;
};

/** Validate the same values shown in the form. Never send NaN/null or silently clamp a request. */
export const remoteArguments = (params: RemoteParameter[], drafts: Record<string, string>) => {
  const args: Record<string, string | number> = {};
  for (const param of params) {
    const value = remoteParameterValue(param, drafts);
    if (param.options && !param.options.some((option) => option.value === value)) {
      return { args, error: `${param.name}: выберите доступный вариант.` };
    }
    if (param.type !== 'number') { args[param.id] = value; continue; }
    const decimal = value.trim().replace(',', '.');
    const number = Number(decimal);
    if (!/^[-+]?(?:\d+\.?\d*|\.\d+)(?:e[-+]?\d+)?$/i.test(decimal) || !Number.isFinite(number)) {
      return { args, error: `${param.name}: введите число.` };
    }
    if (param.min !== undefined && number < param.min) {
      return { args, error: `${param.name}: минимум ${param.min}.` };
    }
    if (param.max !== undefined && number > param.max) {
      return { args, error: `${param.name}: максимум ${param.max}.` };
    }
    args[param.id] = number;
  }
  return { args, error: null };
};
