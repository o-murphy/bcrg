export interface Flags {
  width: number
  height: number
  clickX: string
  clickY: string
}

interface Props {
  flags: Flags
  onChange: (flags: Flags) => void
  disabled?: boolean
}

const fieldClass =
  'w-full rounded-lg border border-neutral-700 bg-neutral-900 px-3 py-2 text-sm text-neutral-100 outline-none focus:border-emerald-400 disabled:opacity-50'
const labelClass = 'mb-1 block text-xs font-medium text-neutral-400'

export function FlagsForm({ flags, onChange, disabled }: Props) {
  function set<K extends keyof Flags>(key: K, value: Flags[K]) {
    onChange({ ...flags, [key]: value })
  }

  return (
    <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
      <div>
        <label className={labelClass}>Ширина (px)</label>
        <input
          type="number"
          min={1}
          className={fieldClass}
          value={flags.width}
          disabled={disabled}
          onChange={(e) => set('width', Number(e.target.value))}
        />
      </div>
      <div>
        <label className={labelClass}>Висота (px)</label>
        <input
          type="number"
          min={1}
          className={fieldClass}
          value={flags.height}
          disabled={disabled}
          onChange={(e) => set('height', Number(e.target.value))}
        />
      </div>
      <div>
        <label className={labelClass}>Клік X (см/100м)</label>
        <input
          type="text"
          inputMode="decimal"
          className={fieldClass}
          value={flags.clickX}
          disabled={disabled}
          placeholder="0.5"
          onChange={(e) => set('clickX', e.target.value)}
        />
      </div>
      <div>
        <label className={labelClass}>Клік Y (см/100м)</label>
        <input
          type="text"
          inputMode="decimal"
          className={fieldClass}
          value={flags.clickY}
          disabled={disabled}
          placeholder="0.5"
          onChange={(e) => set('clickY', e.target.value)}
        />
      </div>
    </div>
  )
}

export function parseClickValue(text: string, fallback = 0.5): number {
  const n = Number.parseFloat(text.trim().replace(',', '.'))
  return Number.isFinite(n) && n > 0 ? n : fallback
}
