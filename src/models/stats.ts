/**
 * Stats JSON shape emitted by `todo stats --json`.
 */
export interface StatsOutput {
  total: number;
  completed: number;
  pending: number;
  overdue: number;
  completionRate: number; // 0-100, two-decimal precision allowed
  generated_at: string; // ISO 8601 timestamp
}

export type { StatsOutput as Stats };
