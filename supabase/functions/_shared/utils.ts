export function countWords(input: string): number {
  return input.trim().length === 0 ? 0 : input.trim().split(/\s+/).length;
}

export function toIsoOrNull(epochMillis?: number | null): string | null {
  if (!epochMillis) {
    return null;
  }

  return new Date(epochMillis).toISOString();
}
