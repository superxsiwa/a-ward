import { BedCasePayload, StagePayload } from './beds/types';
import { BED_01 } from './beds/bed1';
import { BED_02 } from './beds/bed2';
import { BED_03 } from './beds/bed3';
import { BED_04 } from './beds/bed4';
import { BED_05 } from './beds/bed5';
import { BED_06 } from './beds/bed6';
import { BED_07 } from './beds/bed7';
import { BED_08 } from './beds/bed8';

export type { BedCasePayload, StagePayload };

export const DEFAULT_CCU_BEDS: BedCasePayload[] = [
  BED_01,
  BED_02,
  BED_03,
  BED_04,
  BED_05,
  BED_06,
  BED_07,
  BED_08,
];

