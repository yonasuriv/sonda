# --pretty and line1 Variable Fixes

## Issues Fixed

### 1. **`line1` Unbound Variable Error**
**Problem:** The `line1` variable was used in `stats_cpu_mem_disk()` function without initialization, causing errors with `set -u`.

**Errors:**
```
/usr/share/sonda/lib/includes/logic: line 223: line1: unbound variable
/usr/share/sonda/lib/includes/logic: line 232: line1: unbound variable
```

**Fix:** Added `local line1=""` at the beginning of the `stats_cpu_mem_disk()` function to initialize the variable.

**Location:** `lib/includes/logic` - line 197

### 2. **`--pretty` Not Properly Stripping ANSI Codes**
**Problem:** ANSI escape sequences were being partially stripped, leaving behind `33[2m33[0;37` which contaminated the output.

**Issue:** When escape characters (`\033` or `\x1b`) were stripped, the ASCII representation `33[` was left behind.

**Fix:** Improved ANSI stripping with multiple passes:
1. First remove complete escape sequences (`\e[`, `\033[`, `\x1b[`)
2. Then catch partial sequences (`33[`) that lost the escape character
3. Remove standalone bracket sequences (`[0-9;]*m` or `[0-9;]*[a-zA-Z]`)

**Location:** `bin/sonda` - `pprint` function

## Technical Details

### ANSI Escape Sequence Format
- Complete: `\033[2m` or `\x1b[0;37m` or `\e[0m`
- Partial (after escape char stripped): `33[2m` or `33[0;37m`

### Stripping Strategy
1. **Perl method** (if available):
   - Remove `\e\[[0-9;]*[a-zA-Z]`
   - Remove `\033\[[0-9;]*[a-zA-Z]`
   - Remove `\x1b\[[0-9;]*[a-zA-Z]`
   - Then catch partial sequences: `33\[[0-9;]*[a-zA-Z]`
   - Remove standalone brackets: `\[[0-9;]*m` and `\[[0-9;]*[a-zA-Z]`

2. **Sed method** (fallback):
   - Same pattern matching with sed
   - Multiple passes to ensure all sequences are caught

## Rebuild and Reinstall

After these fixes, rebuild and reinstall:

```bash
# Rebuild the package
make clean
./install_debian.sh build

# Reinstall
./install_debian.sh install

# Or build and install in one step
./install_debian.sh all
```

## Testing

After reinstalling, test the fixes:

```bash
# Test --pretty (should show clean output without color codes or escape sequences)
sonda --pretty -cpu

# Test -sys (should not show line1 unbound variable error)
sonda -sys

# Test any command that uses stats_cpu_mem_disk
sonda --all
```

## Verification

The `--pretty` flag should now produce clean, readable output without:
- Color codes
- ANSI escape sequences
- Partial escape sequences like `33[2m`
- Contaminated text

All variables are now properly initialized to avoid unbound variable errors.
