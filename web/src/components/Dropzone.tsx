import { useRef, useState, type DragEvent, type ChangeEvent } from 'react'

interface Props {
  fileName: string | null
  onFile: (name: string, source: string) => void
}

async function readLuaFile(file: File): Promise<string> {
  return file.text()
}

export function Dropzone({ fileName, onFile }: Props) {
  const [dragOver, setDragOver] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  async function handleFiles(files: FileList | null) {
    const file = files?.[0]
    if (!file) return
    if (!file.name.toLowerCase().endsWith('.lua')) return
    const source = await readLuaFile(file)
    onFile(file.name, source)
  }

  function onDrop(e: DragEvent<HTMLDivElement>) {
    e.preventDefault()
    setDragOver(false)
    void handleFiles(e.dataTransfer.files)
  }

  function onChange(e: ChangeEvent<HTMLInputElement>) {
    void handleFiles(e.target.files)
    e.target.value = ''
  }

  return (
    <div
      onDragOver={(e) => {
        e.preventDefault()
        setDragOver(true)
      }}
      onDragLeave={() => setDragOver(false)}
      onDrop={onDrop}
      onClick={() => inputRef.current?.click()}
      className={`flex cursor-pointer flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed p-10 text-center transition-colors ${
        dragOver
          ? 'border-emerald-400 bg-emerald-400/10'
          : 'border-neutral-700 bg-neutral-900/50 hover:border-neutral-500'
      }`}
    >
      <input
        ref={inputRef}
        type="file"
        accept=".lua"
        className="hidden"
        onChange={onChange}
      />
      <span className="text-sm text-neutral-400">
        Перетягніть <code className="text-neutral-200">.lua</code> шаблон сюди, або
        натисніть, щоб відкрити файл
      </span>
      {fileName && (
        <span className="rounded-full bg-emerald-400/10 px-3 py-1 text-xs font-medium text-emerald-400">
          {fileName}
        </span>
      )}
    </div>
  )
}
