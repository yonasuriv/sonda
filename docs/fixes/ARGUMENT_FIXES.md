# Argument Fixes

## Issues Fixed

### 1. **`-gpu` - Unsafe Command Error**
**Problem:** The `safe_exec` function was blocking pipes (`|`) in commands like `lspci | grep -i vga`.

**Error:**
```
[ERROR] Unsafe command detected: lspci | grep -i vga
Error: Unsafe command detected
```

**Fix:** Updated `safe_exec` to allow pipes (`|`) while still blocking dangerous constructs like:
- Backticks for command substitution
- Semicolons for command chaining
- Background processes
- Dangerous variable expansion patterns

**Location:** `bin/sonda` - `safe_exec` function

### 2. **`-sys` - Unbound Variable Error**
**Problem:** Variable `DAYS` was used before being initialized, causing an error with `set -u`.

**Error:**
```
/usr/share/sonda/lib/includes/logic: line 387: DAYS: unbound variable
```

**Fix:** Added initialization check for `DAYS` variable before use. If `calculate_time_since_last_update` wasn't called, `DAYS` is now calculated or defaulted to 0.

**Location:** `lib/includes/logic` - lines 386-393

### 3. **`-packages` - Unsafe Command Error**
**Problem:** Same as `-gpu` - pipes were being blocked in `dpkg -l | cat`.

**Error:**
```
[ERROR] Unsafe command detected: dpkg -l | cat
Error: Unsafe command detected
```

**Fix:** Same as `-gpu` - pipes are now allowed in `safe_exec`.

**Location:** `bin/sonda` - `safe_exec` function

### 4. **`--pretty` - Color Codes Not Stripped**
**Problem:** ANSI color codes were not being properly stripped, showing escape sequences like `33[2m` instead of clean text.

**Error:**
```
33[2m33[0;37mArchitecture:                            x86_64 33[0m
```

**Fix:** Improved ANSI code stripping with multiple methods:
- Use `perl` if available for better regex handling
- Multiple `sed` patterns to catch all ANSI escape sequences
- Handles both `\x1b`, `\033`, and `\e` escape sequences
- Removes both color codes (`m`) and other control sequences

**Location:** `bin/sonda` - `pprint` function

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

After reinstalling, test all fixed arguments:

```bash
sonda -gpu        # Should work now
sonda -sys        # Should work now
sonda -packages   # Should work now
sonda --pretty -cpu  # Should show clean output without color codes
```

## Security Note

The `safe_exec` function still maintains security by blocking:
- Command substitution with backticks
- Semicolon command chaining
- Background processes
- Dangerous variable expansion patterns

But now allows:
- Pipes (`|`) - needed for many legitimate commands
- Basic command execution

All arguments should now work correctly!
