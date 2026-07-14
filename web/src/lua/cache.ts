import type { PreviewItem } from '../components/Preview'
import type { ZoomResult } from './zip'

interface FlagsLike {
  width: number
  height: number
  clickX: string
  clickY: string
}

function fnv1a(str: string): number {
  let hash = 0x811c9dc5
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i)
    hash = Math.imul(hash, 0x01000193)
  }
  return hash >>> 0
}

/** Fingerprints template source + generation params so identical (source, params)
 * pairs can be served from cache instead of re-running the Lua VM. */
export function cacheKey(source: string, flags: FlagsLike): string {
  const sourceFingerprint = `${fnv1a(source).toString(36)}:${source.length}`
  return `${sourceFingerprint}|${flags.width}x${flags.height}|${flags.clickX}x${flags.clickY}`
}

export interface CacheEntry {
  previews: PreviewItem[]
  zip: ZoomResult[]
}

const MAX_ENTRIES = 8

export class GenerationCache {
  private map = new Map<string, CacheEntry>()

  get(key: string): CacheEntry | undefined {
    const entry = this.map.get(key)
    if (entry) {
      // bump recency for LRU eviction
      this.map.delete(key)
      this.map.set(key, entry)
    }
    return entry
  }

  set(key: string, entry: CacheEntry): void {
    this.map.set(key, entry)
    while (this.map.size > MAX_ENTRIES) {
      const oldestKey = this.map.keys().next().value
      if (oldestKey === undefined) break
      this.map.get(oldestKey)?.previews.forEach((p) => URL.revokeObjectURL(p.objectUrl))
      this.map.delete(oldestKey)
    }
  }

  clear(): void {
    for (const entry of this.map.values()) {
      entry.previews.forEach((p) => URL.revokeObjectURL(p.objectUrl))
    }
    this.map.clear()
  }
}
