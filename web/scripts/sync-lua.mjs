import { cpSync, mkdirSync, readdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const webRoot = dirname(dirname(fileURLToPath(import.meta.url)))
const repoRoot = dirname(webRoot)

function syncLuaFiles(srcDir, destDir) {
  mkdirSync(destDir, { recursive: true })
  for (const name of readdirSync(srcDir)) {
    if (name.endsWith('.lua')) {
      cpSync(join(srcDir, name), join(destDir, name))
    }
  }
}

syncLuaFiles(join(repoRoot, 'templates'), join(webRoot, 'src/lua/templates'))
syncLuaFiles(join(repoRoot, 'bcrg'), join(webRoot, 'src/lua/vendor'))
