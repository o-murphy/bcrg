import { useEffect, useRef, useState } from 'react'

import { CodeEditor } from './components/CodeEditor'
import { Dropzone } from './components/Dropzone'
import { FlagsForm, parseClickValue, type Flags } from './components/FlagsForm'
import { Preview, type PreviewItem } from './components/Preview'
import { ProgressBar } from './components/ProgressBar'
import { ReticleEngine } from './lua/engine'
import { bmpBytesToObjectUrl } from './lua/bmp'
import { TEMPLATE_LIBRARY } from './lua/templateLibrary'
import { buildZip, downloadBlob, type ZoomResult } from './lua/zip'

const FIXED_ZOOMS = [1, 2, 3, 4, 6]

const DEFAULT_FLAGS: Flags = {
  width: 640,
  height: 640,
  clickX: '1.42',
  clickY: '1.42',
}

// Mirrors the resolution/click grid in batch.sh, so the CLI's batch presets
// are pickable directly from the UI instead of retyping them by hand.
const RESOLUTIONS: Array<{ width: number; height: number }> = [
  { width: 640, height: 480 },
  { width: 640, height: 640 },
  { width: 720, height: 576 },
]
const CLICK_VALUES = [4.26, 3.01, 2.27, 2.13, 2.01, 1.42]

interface ParameterPreset {
  label: string
  width: number
  height: number
  clickX: string
  clickY: string
}

const PARAMETER_PRESETS: ParameterPreset[] = RESOLUTIONS.flatMap(({ width, height }) =>
  CLICK_VALUES.map((click) => ({
    label: `${width}×${height} · ${click}`,
    width,
    height,
    clickX: String(click),
    clickY: String(click),
  })),
)

function stem(fileName: string): string {
  return fileName.replace(/\.lua$/i, '')
}

export default function App() {
  const engineRef = useRef<ReticleEngine | null>(null)
  if (!engineRef.current) engineRef.current = new ReticleEngine()

  const [engineReady, setEngineReady] = useState(false)
  const [fileName, setFileName] = useState<string | null>(null)
  const [editorSource, setEditorSource] = useState('')
  const [flags, setFlags] = useState<Flags>(DEFAULT_FLAGS)
  const [previews, setPreviews] = useState<PreviewItem[]>([])
  const [activeZoom, setActiveZoom] = useState<number>(FIXED_ZOOMS[0])
  const [zipResults, setZipResults] = useState<ZoomResult[]>([])
  const [isCompiling, setIsCompiling] = useState(false)
  const [progress, setProgress] = useState<{ done: number; total: number } | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [compileError, setCompileError] = useState<string | null>(null)
  const [sourceOpen, setSourceOpen] = useState(false)

  const runIdRef = useRef(0)
  const skipDebounceRef = useRef(false)
  const flagsRef = useRef(flags)
  flagsRef.current = flags
  const fileNameRef = useRef(fileName)
  fileNameRef.current = fileName

  useEffect(() => {
    const engine = engineRef.current!
    engine
      .init()
      .then(() => setEngineReady(true))
      .catch((e) => setError(`Failed to initialize Lua VM: ${String(e)}`))
    return () => engine.close()
  }, [])

  useEffect(() => {
    return () => {
      previews.forEach((p) => URL.revokeObjectURL(p.objectUrl))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  async function runCompileAndGenerate(source: string) {
    const runId = ++runIdRef.current
    setIsCompiling(true)
    try {
      const engine = engineRef.current!
      await engine.loadTemplate(source, fileNameRef.current ?? 'template.lua')
      if (runIdRef.current !== runId) return

      const flagsNow = flagsRef.current
      const clickX = parseClickValue(flagsNow.clickX)
      const clickY = parseClickValue(flagsNow.clickY)

      const nextPreviews: PreviewItem[] = []
      const nextZip: ZoomResult[] = []
      setProgress({ done: 0, total: FIXED_ZOOMS.length })

      for (const [index, zoom] of FIXED_ZOOMS.entries()) {
        const bytes = engine.generate({
          width: flagsNow.width,
          height: flagsNow.height,
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
        if (runIdRef.current !== runId) return
      }

      if (runIdRef.current !== runId) return
      setPreviews((old) => {
        old.forEach((p) => URL.revokeObjectURL(p.objectUrl))
        return nextPreviews
      })
      setActiveZoom(FIXED_ZOOMS[0])
      setZipResults(nextZip)
      setCompileError(null)
    } catch (e) {
      // Deliberately does not touch previews/zipResults: the last good
      // render stays on screen, only the error banner updates.
      if (runIdRef.current === runId) {
        setCompileError(e instanceof Error ? e.message : String(e))
      }
    } finally {
      if (runIdRef.current === runId) {
        setIsCompiling(false)
        setProgress(null)
      }
    }
  }

  function handleTemplate(name: string, source: string) {
    setError(null)
    setFileName(name)
    skipDebounceRef.current = true
    setEditorSource(source)
  }

  // Live preview: recompile + regenerate whenever the edited source settles.
  // Programmatic loads (dropzone / picker) skip the debounce for snappier feedback.
  useEffect(() => {
    if (!engineReady || !editorSource) return
    const immediate = skipDebounceRef.current
    skipDebounceRef.current = false
    const timer = setTimeout(() => void runCompileAndGenerate(editorSource), immediate ? 0 : 500)
    return () => clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editorSource, engineReady])

  async function handleDownloadZip() {
    if (zipResults.length === 0 || !fileName) return
    const clickX = parseClickValue(flags.clickX)
    const clickY = parseClickValue(flags.clickY)
    const blob = await buildZip(zipResults)
    downloadBlob(blob, `${stem(fileName)}_${clickX}x${clickY}.zip`)
  }

  return (
    <div className="mx-auto min-h-svh max-w-5xl px-4 py-10 text-neutral-100">
      <header className="mb-8">
        <h1 className="text-2xl font-semibold tracking-tight">BCRG Reticle Generator</h1>
        <p className="mt-1 text-sm text-neutral-400">
          Ballistic reticle generator from .lua templates — everything runs locally in the
          browser via the built-in Lua runtime.
        </p>
        {!engineReady && <p className="mt-2 text-xs text-amber-400">Loading Lua VM…</p>}
      </header>

      <section className="mb-6 space-y-3">
        <Dropzone fileName={fileName} onFile={handleTemplate} />
        <div className="flex flex-wrap items-center gap-2 text-xs text-neutral-500">
          <span>Built-in templates:</span>
          <select
            className="rounded-lg border border-neutral-700 bg-neutral-900 px-2 py-1 text-neutral-300 outline-none focus:border-emerald-400 disabled:opacity-50"
            disabled={!engineReady}
            value=""
            onChange={(e) => {
              const name = e.target.value
              if (name) handleTemplate(name, TEMPLATE_LIBRARY[name])
            }}
          >
            <option value="" disabled>
              Choose a template…
            </option>
            {Object.keys(TEMPLATE_LIBRARY).map((name) => (
              <option key={name} value={name}>
                {name}
              </option>
            ))}
          </select>
        </div>
      </section>

      {editorSource && (
        <details
          className="group mb-6"
          open={sourceOpen}
          onToggle={(e) => setSourceOpen(e.currentTarget.open)}
        >
          <summary className="mb-2 flex cursor-pointer list-none items-center justify-between text-sm font-medium text-neutral-200">
            <span className="flex items-center gap-2">
              <svg
                viewBox="0 0 20 20"
                fill="currentColor"
                className="h-3 w-3 text-neutral-500 transition-transform group-open:rotate-90"
              >
                <path d="M6 4l8 6-8 6V4z" />
              </svg>
              Template source
            </span>
            {isCompiling && <span className="text-xs text-amber-400">Compiling…</span>}
          </summary>
          {sourceOpen && <CodeEditor value={editorSource} onChange={setEditorSource} />}
        </details>
      )}

      <section className="mb-6 rounded-xl border border-neutral-800 bg-neutral-900/30 p-4">
        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
          <h2 className="text-sm font-medium text-neutral-200">Parameters</h2>
          <div className="flex items-center gap-2 text-xs text-neutral-500">
            <span>Presets:</span>
            <select
              className="rounded-lg border border-neutral-700 bg-neutral-900 px-2 py-1 text-neutral-300 outline-none focus:border-emerald-400"
              value=""
              onChange={(e) => {
                const preset = PARAMETER_PRESETS.find((p) => p.label === e.target.value)
                if (preset) {
                  setFlags({
                    width: preset.width,
                    height: preset.height,
                    clickX: preset.clickX,
                    clickY: preset.clickY,
                  })
                }
              }}
            >
              <option value="" disabled>
                Choose a preset…
              </option>
              {PARAMETER_PRESETS.map((preset) => (
                <option key={preset.label} value={preset.label}>
                  {preset.label}
                </option>
              ))}
            </select>
          </div>
        </div>
        <FlagsForm flags={flags} onChange={setFlags} />
        <button
          type="button"
          disabled={!editorSource || !engineReady}
          onClick={() => void runCompileAndGenerate(editorSource)}
          className="mt-4 rounded-lg bg-emerald-500 px-4 py-2 text-sm font-semibold text-neutral-950 transition-colors hover:bg-emerald-400 disabled:cursor-not-allowed disabled:opacity-40"
        >
          {isCompiling ? 'Generating…' : 'Generate'}
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

      {compileError && (
        <div className="mb-6 whitespace-pre-wrap rounded-lg border border-red-500/40 bg-red-500/10 px-4 py-3 font-mono text-xs text-red-300">
          {compileError}
        </div>
      )}

      {previews.length > 0 && (
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-medium text-neutral-200">Preview</h2>
            <button
              type="button"
              onClick={() => void handleDownloadZip()}
              className="rounded-lg border border-neutral-700 px-3 py-1.5 text-xs font-medium text-neutral-200 hover:border-emerald-400 hover:text-emerald-400"
            >
              Download .zip
            </button>
          </div>
          <Preview items={previews} activeZoom={activeZoom} onSelectZoom={setActiveZoom} />
        </section>
      )}
    </div>
  )
}
