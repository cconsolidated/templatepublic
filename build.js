import { mkdir } from 'fs/promises'
import { existsSync } from 'fs'
import { resolve } from 'path'

const buildDir = resolve(process.cwd(), 'build/client')

async function ensureBuildDir() {
  if (!existsSync(buildDir)) {
    await mkdir(buildDir, { recursive: true })
  }
}

ensureBuildDir() 