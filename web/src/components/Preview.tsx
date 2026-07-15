import { useEffect, useRef, useState } from 'react'

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

const LOUPE_FACTOR = 2
const LOUPE_SIZE = 260

export function Preview({ items, activeZoom, onSelectZoom }: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const [loupe, setLoupe] = useState<{ x: number; y: number; bgX: number; bgY: number } | null>(
    null,
  )

  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      const target = e.target as HTMLElement | null
      if (target) {
        const tag = target.tagName
        if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || target.isContentEditable) {
          return
        }
      }
      const zoom = Number(e.key)
      if (!items.some((item) => item.zoom === zoom)) return
      onSelectZoom(zoom)
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [items, onSelectZoom])

  if (items.length === 0) return null

  const active = items.find((item) => item.zoom === activeZoom) ?? items[0]

  function updateLoupe(clientX: number, clientY: number) {
    const rect = containerRef.current?.getBoundingClientRect()
    if (!rect) return
    const x = clientX - rect.left
    const y = clientY - rect.top
    setLoupe({
      x,
      y,
      bgX: -(x * LOUPE_FACTOR - LOUPE_SIZE / 2),
      bgY: -(y * LOUPE_FACTOR - LOUPE_SIZE / 2),
    })
  }

  function handlePointerDown(e: React.PointerEvent<HTMLDivElement>) {
    if (e.pointerType === 'mouse' && e.button !== 0) return
    e.currentTarget.setPointerCapture(e.pointerId)
    updateLoupe(e.clientX, e.clientY)
  }

  function handlePointerMove(e: React.PointerEvent<HTMLDivElement>) {
    if (!e.currentTarget.hasPointerCapture(e.pointerId)) return
    updateLoupe(e.clientX, e.clientY)
  }

  function handlePointerUp(e: React.PointerEvent<HTMLDivElement>) {
    if (e.currentTarget.hasPointerCapture(e.pointerId)) {
      e.currentTarget.releasePointerCapture(e.pointerId)
    }
    setLoupe(null)
  }

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
      <div
        ref={containerRef}
        className="relative w-full touch-none overflow-hidden rounded-xl border border-neutral-800 bg-white"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onPointerCancel={handlePointerUp}
      >
        <img
          src={active.objectUrl}
          alt={`zoom ${active.zoom}`}
          className="block h-auto w-full select-none [image-rendering:pixelated]"
          draggable={false}
        />
        {!loupe && (
          <span className="pointer-events-none absolute right-2 top-2 rounded-full bg-neutral-950/70 px-3 py-1.5 text-sm text-neutral-200">
            Hold to zoom
          </span>
        )}
        {loupe && containerRef.current && (
          <div
            className="pointer-events-none absolute rounded-md border-2 border-emerald-400 shadow-lg"
            style={{
              width: LOUPE_SIZE,
              height: LOUPE_SIZE,
              left: loupe.x - LOUPE_SIZE / 2,
              top: loupe.y - LOUPE_SIZE / 2,
              backgroundImage: `url(${active.objectUrl})`,
              backgroundRepeat: 'no-repeat',
              backgroundSize: `${containerRef.current.clientWidth * LOUPE_FACTOR}px ${
                containerRef.current.clientHeight * LOUPE_FACTOR
              }px`,
              backgroundPosition: `${loupe.bgX}px ${loupe.bgY}px`,
              imageRendering: 'pixelated',
            }}
          />
        )}
      </div>
      <p className="text-xs text-neutral-500">
        zoom {active.zoom}× · {(active.sizeBytes / 1024).toFixed(1)} KB
      </p>
    </div>
  )
}
