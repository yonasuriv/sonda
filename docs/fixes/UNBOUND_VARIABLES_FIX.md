# Unbound Variable Fixes

## Issues Fixed

### 1. **`uptime_days` Unbound Variable in Menu**
**Problem:** The `uptime_days` variable was used in `modules/core/menu` without initialization, causing an error with `set -u`.

**Error:**
```
/usr/share/sonda/modules/core/menu: line 34: uptime_days: unbound variable
```

**Fix:** Added initialization and calculation of `uptime_days` in the menu module if it's not already set. The menu now calculates uptime from `/proc/uptime` if the variable isn't available from `system_info`.

**Location:** `modules/core/menu` - lines 33-40

### 2. **`LAST_UPDATE_DATE` Unbound Variable in Logic**
**Problem:** The `LAST_UPDATE_DATE` variable was used in `calculate_time_since_last_update()` function without initialization.

**Error:**
```
/usr/share/sonda/lib/includes/logic: line 308: LAST_UPDATE_DATE: unbound variable
```

**Fix:** Added initialization of `LAST_UPDATE_DATE` at the beginning of `calculate_time_since_last_update()` function. It now reads from `/var/log/apt/history.log` if not already set.

**Location:** `lib/includes/logic` - lines 307-312

### 3. **`DAYS` Variable in Menu**
**Bonus Fix:** Also fixed `DAYS` variable in menu module by calculating it from `LAST_UPDATE_DATE` if not already set.

**Location:** `modules/core/menu` - lines 42-60

## Technical Details

### Variable Initialization Strategy

1. **`uptime_days` in menu:**
   - Check if variable is already set (from `system_info`)
   - If not, calculate from `/proc/uptime`
   - Use `${uptime_days:-0}` for safe access

2. **`LAST_UPDATE_DATE` in logic:**
   - Check if variable is already set
   - If not, read from `/var/log/apt/history.log`
   - Extract "Start-Date:" from the last entry
   - Default to "Unavailable" if not found

3. **`DAYS` in menu:**
   - Check if variable is already set (from `system_info`)
   - If not, calculate from `LAST_UPDATE_DATE`
   - Use `${DAYS:-0}` for safe access

## Rebuild and Reinstall

After these fixes, rebuild and reinstall:

```bash
# Rebuild the package
make clean
./install.sh source -d debian

# Reinstall
./install.sh release -d debian

# Or build and install in one step
./install.sh source -d debian
```

## Testing

After reinstalling, test the fixes:

```bash
# Test menu (should not show uptime_days error)
sonda -x

# Test system info (should not show LAST_UPDATE_DATE error)
sonda -s

# Test any command that uses calculate_time_since_last_update
sonda --all
```

## Files Modified

- `modules/core/menu` - Added initialization for `uptime_days` and `DAYS`
- `lib/includes/logic` - Added initialization for `LAST_UPDATE_DATE`

All variables are now properly initialized to avoid unbound variable errors with `set -u`.
