# Show every change to the function `calculateTax` in src/tax.mjs
git log -L :calculateTax:src/tax.mjs

# Same idea by line range — useful when the function name has multiple
# matches or for non-function constructs (config blocks, etc.)
git log -L 45,67:src/config.ts

# Combined with -p (already implied by -L): each commit shows the patch
# specifically for that function's lines, not the whole file.
