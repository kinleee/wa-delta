export type WaLevel = 'off' | 'notify' | 'draft' | 'auto'

/** The part of the settings a contact can override: sections 1-3 of the panel. */
export type WaProfile = {
  flags: string[]
  customPrompt: string
  model: string
  idleSec: number
  jitter: [number, number]
  readDelay: [number, number]
  typing: 'type' | 'paste'
  cps: [number, number]
  escalateRisky: boolean
  dailyCap: number
  activeHours: string
}

export type WaTelegram = { on: boolean; token: string; chatId: string; bot: string }

export type WaSettings = WaProfile & {
  enabled: boolean
  defaultLevel: WaLevel
  tg: WaTelegram
}

export type WaContact = { name: string; level: WaLevel; over?: Partial<WaProfile> }

export type WaPending = { sender: string; texts: string[]; firstAt: number; extra: number }

export type WaLogRow = { at: number; text: string }

export type WaStatus = { watcher: 'off' | 'on' | 'error'; idle: number; busy: string }

declare module 'claude-code' {
  interface PluginState {
    'wa-delta': {
      settings: Shaped<WaSettings>
      contacts: Shaped<WaContact[]>
      pending: Shaped<WaPending[]>
      log: Shaped<WaLogRow[]>
      status: WaStatus
      /** whose template the panel edits: '' is the default one */
      editing: string
    }
  }
}
