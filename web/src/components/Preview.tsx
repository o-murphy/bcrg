export interface PreviewItem {
  zoom: number
  objectUrl: string
  sizeBytes: number
}

interface Props {
  items: PreviewItem[]
  activeZoom: number
  onSelectZoom: (zoom: number) => void
}

export function Preview({ items, activeZoom, onSelectZoom }: Props) {
  if (items.length === 0) return null

  const active = items.find((item) => item.zoom === activeZoom) ?? items[0]

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-2">
        {items.map((item) => (
          <button
            key={item.zoom}
            type="button"
            onClick={() => onSelectZoom(item.zoom)}
            className={`rounded-full px-3 py-1 text-xs font-medium transition-colors ${
              item.zoom === active.zoom
                ? 'bg-emerald-500 text-neutral-950'
                : 'border border-neutral-700 text-neutral-300 hover:border-neutral-500'
            }`}
          >
            {item.zoom}×
          </button>
        ))}
      </div>
      <div className="w-full overflow-hidden rounded-xl border border-neutral-800 bg-white">
        <img
          src={active.objectUrl}
          alt={`zoom ${active.zoom}`}
          className="block h-auto w-full [image-rendering:pixelated]"
        />
      </div>
      <p className="text-xs text-neutral-500">
        zoom {active.zoom}× · {(active.sizeBytes / 1024).toFixed(1)} KB
      </p>
    </div>
  )
}
