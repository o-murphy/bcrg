interface Props {
  done: number
  total: number
}

export function ProgressBar({ done, total }: Props) {
  return (
    <div className="flex items-center gap-2" role="progressbar" aria-valuenow={done} aria-valuemin={0} aria-valuemax={total}>
      <div className="flex flex-1 gap-1">
        {Array.from({ length: total }, (_, i) => (
          <div
            key={i}
            className={`h-1.5 flex-1 rounded-full transition-colors duration-200 ${
              i < done ? 'bg-emerald-400' : 'bg-neutral-700'
            }`}
          />
        ))}
      </div>
      <span className="text-xs tabular-nums text-neutral-400">
        {done}/{total}
      </span>
    </div>
  )
}
