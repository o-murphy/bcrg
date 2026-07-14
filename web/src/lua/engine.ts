import { LuaFactory, LuaEngine, LuaReturn, LuaThread, LuaType } from 'wasmoon'

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
    try {
      return callAndExtractByteArray(lua.global, 'make_reticle', [
        params.width,
        params.height,
        params.clickX,
        params.clickY,
        params.zoom,
        undefined,
      ])
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

/**
 * Calls a global Lua function and reads its single table return value
 * straight off the Lua stack via lua_rawgeti/lua_tonumberx, instead of
 * going through wasmoon's generic table decoder (LuaThread.call /
 * LuaGlobal.get(...)(...)). That decoder walks the table twice with
 * lua_next (once to detect array-ness, once to read values) and stringifies
 * every numeric key, which dominates runtime for the ~50k-plus-element byte
 * arrays a BMP-sized reticle produces.
 */
function callAndExtractByteArray(thread: LuaThread, name: string, args: unknown[]): Uint8Array {
  const raw = thread.lua
  const state = thread.address

  if (raw.lua_getglobal(state, name) !== LuaType.Function) {
    thread.pop(1)
    throw new LuaTemplateError('No template loaded yet')
  }
  for (const arg of args) thread.pushValue(arg)
  const status = raw.lua_pcallk(state, args.length, 1, 0, 0, null)
  thread.assertOk(status as LuaReturn)

  const tableIndex = thread.getTop()
  if (raw.lua_type(state, tableIndex) !== LuaType.Table) {
    thread.pop(1)
    throw new LuaTemplateError('make_reticle must return fb:to_bmp() or fb:to_bmp_1bit()')
  }

  const length = Number(raw.lua_rawlen(state, tableIndex))
  const bytes = new Uint8Array(length)
  for (let i = 1; i <= length; i++) {
    raw.lua_rawgeti(state, tableIndex, BigInt(i))
    bytes[i - 1] = raw.lua_tonumberx(state, -1, null)
    thread.pop(1)
  }
  thread.pop(1)
  return bytes
}
