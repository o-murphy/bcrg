import { useEffect, useRef, useState } from 'react'

import { Dropzone } from './components/Dropzone'
import { FlagsForm, parseClickValue, type Flags } from './components/FlagsForm'
import { Preview, type PreviewItem } from './components/Preview'
import { ProgressBar } from './components/ProgressBar'
import { ReticleEngine } from './lua/engine'
import { bmpBytesToObjectUrl } from './lua/bmp'
import { buildZip, downloadBlob, type ZoomResult } from './lua/zip'

import mradExample from './lua/examples/mrad.lua?raw'
import thsExample from './lua/examples/ths.lua?raw'

const EXAMPLES: Record<string, string> = {
  'mrad.lua': mradExample,
  'ths.lua': thsExample,
}

const FIXED_ZOOMS = [1, 2, 3, 4, 6]

const DEFAULT_FLAGS: Flags = {
  width: 640,
  height: 640,
  clickX: '1.42',
  clickY: '1.42',
}

function stem(fileName: string): string {
  return fileName.replace(/\.lua$/i, '')
}

export default function App() {
  const engineRef = useRef<ReticleEngine | null>(null)
  if (!engineRef.current) engineRef.current = new ReticleEngine()

  const [engineReady, setEngineReady] = useState(false)
  const [fileName, setFileName] = useState<string | null>(null)
  const [templateLoaded, setTemplateLoaded] = useState(false)
  const [flags, setFlags] = useState<Flags>(DEFAULT_FLAGS)
  const [previews, setPreviews] = useState<PreviewItem[]>([])
  const [activeZoom, setActiveZoom] = useState<number>(FIXED_ZOOMS[0])
  const [zipResults, setZipResults] = useState<ZoomResult[]>([])
  const [isLoadingTemplate, setIsLoadingTemplate] = useState(false)
  const [isGenerating, setIsGenerating] = useState(false)
  const [progress, setProgress] = useState<{ done: number; total: number } | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const engine = engineRef.current!
    engine
      .init()
      .then(() => setEngineReady(true))
      .catch((e) => setError(`Не вдалося ініціалізувати Lua VM: ${String(e)}`))
    return () => engine.close()
  }, [])

  useEffect(() => {
    return () => {
      previews.forEach((p) => URL.revokeObjectURL(p.objectUrl))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  async function handleTemplate(name: string, source: string) {
    setError(null)
    setTemplateLoaded(false)
    setPreviews((old) => {
      old.forEach((p) => URL.revokeObjectURL(p.objectUrl))
      return []
    })
    setZipResults([])
    setFileName(name)
    setIsLoadingTemplate(true)
    try {
      await engineRef.current!.loadTemplate(source, name)
      setTemplateLoaded(true)
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setIsLoadingTemplate(false)
    }
  }

  async function handleGenerate() {
    if (!templateLoaded) return

    setError(null)
    setIsGenerating(true)
    setProgress({ done: 0, total: FIXED_ZOOMS.length })
    setPreviews((old) => {
      old.forEach((p) => URL.revokeObjectURL(p.objectUrl))
      return []
    })
    setZipResults([])

    try {
      const engine = engineRef.current!
      const clickX = parseClickValue(flags.clickX)
      const clickY = parseClickValue(flags.clickY)

      const nextPreviews: PreviewItem[] = []
      const nextZip: ZoomResult[] = []

      for (const [index, zoom] of FIXED_ZOOMS.entries()) {
        const bytes = engine.generate({
          width: flags.width,
          height: flags.height,
          clickX,
          clickY,
          zoom,
        })
        nextPreviews.push({ zoom, objectUrl: bmpBytesToObjectUrl(bytes), sizeBytes: bytes.length })
        nextZip.push({ zoom, bytes })

        setProgress({ done: index + 1, total: FIXED_ZOOMS.length })
        // yield to the browser so the progress update actually paints
        // between synchronous (and fairly heavy) wasm calls
        await new Promise((resolve) => requestAnimationFrame(resolve))
      }

      setPreviews(nextPreviews)
      setActiveZoom(FIXED_ZOOMS[0])
      setZipResults(nextZip)
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e))
    } finally {
      setIsGenerating(false)
      setProgress(null)
    }
  }

  async function handleDownloadZip() {
    if (zipResults.length === 0 || !fileName) return
    const clickX = parseClickValue(flags.clickX)
    const clickY = parseClickValue(flags.clickY)
    const blob = await buildZip(zipResults)
    downloadBlob(blob, `${stem(fileName)}_${clickX}x${clickY}.zip`)
  }

  const busy = isLoadingTemplate || isGenerating

  return (
    <div className="mx-auto min-h-svh max-w-5xl px-4 py-10 text-neutral-100">
      <header className="mb-8">
        <h1 className="text-2xl font-semibold tracking-tight">BCRG Reticle Generator</h1>
        <p className="mt-1 text-sm text-neutral-400">
          Генератор балістичних сіток з .lua шаблонів — все виконується локально у
          браузері через вбудований Lua-рантайм.
        </p>
        {!engineReady && (
          <p className="mt-2 text-xs text-amber-400">Завантаження Lua VM…</p>
        )}
      </header>

      <section className="mb-6 space-y-3">
        <Dropzone fileName={fileName} onFile={handleTemplate} />
        <div className="flex flex-wrap items-center gap-2 text-xs text-neutral-500">
          <span>Приклади:</span>
          {Object.keys(EXAMPLES).map((name) => (
            <button
              key={name}
              type="button"
              disabled={!engineReady || busy}
              className="rounded-full border border-neutral-700 px-3 py-1 text-neutral-300 hover:border-neutral-500 disabled:opacity-50"
              onClick={() => void handleTemplate(name, EXAMPLES[name])}
            >
              {name}
            </button>
          ))}
        </div>
      </section>

      <section className="mb-6 rounded-xl border border-neutral-800 bg-neutral-900/30 p-4">
        <h2 className="mb-3 text-sm font-medium text-neutral-200">Параметри</h2>
        <FlagsForm flags={flags} onChange={setFlags} disabled={busy} />
        <button
          type="button"
          disabled={!templateLoaded || !engineReady || busy}
          onClick={() => void handleGenerate()}
          className="mt-4 rounded-lg bg-emerald-500 px-4 py-2 text-sm font-semibold text-neutral-950 transition-colors hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-40"
        >
          {isGenerating ? 'Генерація…' : 'Згенерувати'}
        </button>
        {progress && (
          <div className="mt-3">
            <ProgressBar done={progress.done} total={progress.total} />
          </div>
        )}
      </section>

      {error && (
        <div className="mb-6 rounded-lg border border-red-500/40 bg-red-500/10 px-4 py-3 text-sm text-red-300">
          {error}
        </div>
      )}

      {previews.length > 0 && (
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-medium text-neutral-200">Прев'ю</h2>
            <button
              type="button"
              onClick={() => void handleDownloadZip()}
              className="rounded-lg border border-neutral-700 px-3 py-1.5 text-xs font-medium text-neutral-200 hover:border-emerald-400 hover:text-emerald-400"
            >
              Завантажити .zip
            </button>
          </div>
          <Preview items={previews} activeZoom={activeZoom} onSelectZoom={setActiveZoom} />
        </section>
      )}
    </div>
  )
}
