Use these pnpm aliases when running commands:

```
p='pnpm 2>/dev/null'
pi='pnpm install'
pa='pnpm add'
pad='pnpm add -D'
pf='pnpm --filter'
pfa='pnpm --filter add'
pfad='pnpm --filter add -D'
pp='pnpm publish'
px='pnpm dlx'
```

Never bypass NPM_TOKEN or other env vars with workarounds. If pnpm fails due to env config, ask the user.
