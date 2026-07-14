export function bmpBytesToBlob(bytes: Uint8Array): Blob {
  const buffer = bytes.buffer.slice(
    bytes.byteOffset,
    bytes.byteOffset + bytes.byteLength,
  ) as ArrayBuffer
  return new Blob([buffer], { type: 'image/bmp' })
}

export function bmpBytesToObjectUrl(bytes: Uint8Array): string {
  return URL.createObjectURL(bmpBytesToBlob(bytes))
}
