// Append to domain/ports/{{port}}.port.ts

export const {{port}}ExpectedErrors = {
  networkTimeout: 'Service unavailable — network timeout',
  unauthorized: 'Authentication failed',
  rateLimited: 'Too many requests',
} as const

export type {{Port}}Error = keyof typeof {{port}}ExpectedErrors
