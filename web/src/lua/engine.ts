import { LuaFactory, LuaEngine } from 'wasmoon'

import fontSrc from './vendor/font.lua?raw'
import framebufSrc from './vendor/framebuf.lua?raw'
import reticledrawSrc from './vendor/reticledraw.lua?raw'

export interface ReticleParams {
  width: number
  height: number
  clickX: number
  clickY: number
  zoom: number
}

export class LuaTemplateError extends Error {}

/**
 * One persistent Lua VM for the app's lifetime. The vendor modules
 * (font/framebuf/reticledraw) are registered as package.preload loaders so
 * templates can `require("reticledraw")` exactly like the CLI does, without
 * any filesystem access.
 */
export class ReticleEngine {
  private lua: LuaEngine | null = null
  private ready: Promise<void> | null = null

  init(): Promise<void> {
    if (!this.ready) {
      this.ready = this.setup()
    }
    return this.ready
  }

  private async setup(): Promise<void> {
    const factory = new LuaFactory(`${import.meta.env.BASE_URL}glue.wasm`)
    const lua = await factory.createEngine()

    lua.global.set('__FONT_SRC', fontSrc)
    lua.global.set('__FRAMEBUF_SRC', framebufSrc)
    lua.global.set('__RETICLEDRAW_SRC', reticledrawSrc)

    await lua.doString(`
      package.preload["font"] = assert(load(__FONT_SRC, "font.lua"))
      package.preload["framebuf"] = assert(load(__FRAMEBUF_SRC, "framebuf.lua"))
      package.preload["reticledraw"] = assert(load(__RETICLEDRAW_SRC, "reticledraw.lua"))
      __FONT_SRC = nil
      __FRAMEBUF_SRC = nil
      __RETICLEDRAW_SRC = nil
    `)

    this.lua = lua
  }

  /** Executes the template source, defining/overwriting the global make_reticle function. */
  async loadTemplate(source: string, chunkName = 'template.lua'): Promise<void> {
    await this.init()
    const lua = this.assertEngine()

    lua.global.set('__TEMPLATE_SRC', source)
    lua.global.set('__TEMPLATE_NAME', chunkName)
    try {
      await lua.doString(`
        make_reticle = nil
        local chunk, err = load(__TEMPLATE_SRC, __TEMPLATE_NAME)
        if not chunk then
          error(err, 0)
        end
        chunk()
        if type(make_reticle) ~= "function" then
          error(__TEMPLATE_NAME .. " does not define a make_reticle(width, height, click_x, click_y, zoom, adjustment) function", 0)
        end
      `)
    } catch (e) {
      throw new LuaTemplateError(extractLuaMessage(e))
    } finally {
      // wasmoon's Promise type extension crashes on a literal JS `null`
      // (it calls `.then` on it without a null-check); `undefined` is safe,
      // it's special-cased to push a Lua nil before reaching that code.
      lua.global.set('__TEMPLATE_SRC', undefined)
    }
  }

  /** Calls make_reticle and returns the raw BMP bytes it produced. */
  generate(params: ReticleParams): Uint8Array {
    const lua = this.assertEngine()
    const makeReticle = lua.global.get('make_reticle')
    if (typeof makeReticle !== 'function') {
      throw new LuaTemplateError('No template loaded yet')
    }
    try {
      const result = makeReticle(
        params.width,
        params.height,
        params.clickX,
        params.clickY,
        params.zoom,
        undefined,
      )
      if (!Array.isArray(result)) {
        throw new LuaTemplateError(
          'make_reticle must return fb:to_bmp() or fb:to_bmp_1bit()',
        )
      }
      return Uint8Array.from(result)
    } catch (e) {
      if (e instanceof LuaTemplateError) throw e
      throw new LuaTemplateError(extractLuaMessage(e))
    }
  }

  close(): void {
    this.lua?.global.close()
    this.lua = null
    this.ready = null
  }

  private assertEngine(): LuaEngine {
    if (!this.lua) throw new Error('Lua engine not initialized, call init() first')
    return this.lua
  }
}

function extractLuaMessage(e: unknown): string {
  if (e instanceof Error) return e.message
  return String(e)
}
