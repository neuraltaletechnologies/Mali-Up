'use client'

import { DURATION_UNITS, DURATION_UNIT_LABELS, type DurationUnit } from '@/lib/duration'

interface DurationPickerProps {
  value: number
  unit: DurationUnit
  onValueChange: (value: number) => void
  onUnitChange: (unit: DurationUnit) => void
  disabled?: boolean
  inputClassName?: string
  selectClassName?: string
}

const DEFAULT_INPUT_CLS =
  'w-20 rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]'
const DEFAULT_SELECT_CLS =
  'flex-1 rounded-md border border-[var(--line)] bg-[var(--canvas)] px-3 py-2 text-[13px] text-[var(--ink)] focus:outline-none focus:ring-1 focus:ring-[var(--accent)]'

/** Quantity + unit pair for admin-side plan assignment ("2 weeks", "6
 *  months", "1 year", "30 days"…) — replaces a bare "duration in months"
 *  number field so an admin can grant exactly the length of time intended. */
export function DurationPicker({
  value, unit, onValueChange, onUnitChange, disabled,
  inputClassName, selectClassName,
}: DurationPickerProps) {
  return (
    <div className="flex gap-2">
      <input
        type="number"
        min={1}
        max={3650}
        value={value}
        disabled={disabled}
        onChange={(e) => onValueChange(Math.max(1, Number(e.target.value) || 1))}
        className={inputClassName ?? DEFAULT_INPUT_CLS}
      />
      <select
        value={unit}
        disabled={disabled}
        onChange={(e) => onUnitChange(e.target.value as DurationUnit)}
        className={selectClassName ?? DEFAULT_SELECT_CLS}
      >
        {DURATION_UNITS.map((u) => (
          <option key={u} value={u}>{DURATION_UNIT_LABELS[u]}</option>
        ))}
      </select>
    </div>
  )
}
