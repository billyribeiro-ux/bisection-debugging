# Bisection log: SvelteCheck failing after main merge
Date: 2026-06-03  Engineer: you  Predicate: `pnpm exec svelte-check`

Initial suspect range: src/lib/**/*.svelte → 1024 files (sorted alphabetically)

| Round | lo   | hi   | mid  | tested subset    | result | new lo | new hi |
|------:|-----:|-----:|-----:|------------------|:------:|-------:|-------:|
| 1     |    0 | 1023 |  511 | files[0..511]    | BAD    |      0 |    511 |
| 2     |    0 |  511 |  255 | files[0..255]    | GOOD   |    256 |    511 |
| 3     |  256 |  511 |  383 | files[256..383]  | BAD    |    256 |    383 |
| 4     |  256 |  383 |  319 | files[256..319]  | GOOD   |    320 |    383 |
| 5     |  320 |  383 |  351 | files[320..351]  | BAD    |    320 |    351 |
| 6     |  320 |  351 |  335 | files[320..335]  | BAD    |    320 |    335 |
| 7     |  320 |  335 |  327 | files[320..327]  | GOOD   |    328 |    335 |
| 8     |  328 |  335 |  331 | files[328..331]  | BAD    |    328 |    331 |
| 9     |  328 |  331 |  329 | files[328..329]  | GOOD   |    330 |    331 |
| 10    |  330 |  331 |  330 | files[330..330]  | BAD    |    330 |    330 |

→ Culprit: files[330] = src/lib/components/data/HeavyChart.svelte
