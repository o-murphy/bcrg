const modules = import.meta.glob('./templates/*.lua', {
  eager: true,
  query: '?raw',
  import: 'default',
}) as Record<string, string>

export const TEMPLATE_LIBRARY: Record<string, string> = Object.fromEntries(
  Object.entries(modules)
    .map(([path, source]) => [path.replace('./templates/', ''), source])
    .sort(([a], [b]) => a.localeCompare(b)),
)
