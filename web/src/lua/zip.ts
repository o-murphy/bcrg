import JSZip from 'jszip'

export interface ZoomResult {
  zoom: number
  bytes: Uint8Array
}

export async function buildZip(results: ZoomResult[]): Promise<Blob> {
  const zip = new JSZip()
  for (const { zoom, bytes } of results) {
    zip.file(`${zoom}.bmp`, bytes)
  }
  return zip.generateAsync({ type: 'blob' })
}

export function downloadBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(url)
}
