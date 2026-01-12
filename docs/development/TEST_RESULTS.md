# Sonda Argument Testing Results

**Test Date:** 2026-01-12
**Test Environment:** Ubuntu 24.04.3 LTS, Linux 6.14.0-37-generic
**Sonda Version:** 1.8.2

## Test Plan

Testing all arguments from `sonda -h` output to verify functionality.

---

## Test Results

### Basic Commands

#### ✅ `-h | --help`
- **Status:** WORKING
- **Output:** Shows help menu correctly with ASCII art logo
- **Notes:** Help text is displayed properly

#### ✅ `-v | --version`
- **Status:** WORKING
- **Output:** Shows version correctly: "sonda version 1.8.2 (running the latest version)"
- **Notes:** Works as expected

#### ⚠️ `--check-update`
- **Status:** ISSUE - No output
- **Output:** Silent (no output, exit code 0)
- **Expected:** Should show version comparison and update availability
- **Issue:** Function executes but produces no visible output

#### ✅ `-u | --update`
- **Status:** WORKING
- **Output:** Shows "you are running the latest version" message
- **Notes:** Works correctly when up to date

#### ❌ `-r | --recommends`
- **Status:** BROKEN - No output
- **Output:** Completely silent (no output at all)
- **Expected:** Should show system recommendations
- **Issue:** Function may not exist or module not loading properly

### System Information Commands

#### ✅ `-s | -sys`
- **Status:** WORKING
- **Output:** Shows comprehensive system information
- **Notes:** Displays uptime, OS, kernel, hardware, etc. correctly

#### ✅ `-n | -net`
- **Status:** WORKING
- **Output:** Shows network information (interfaces, IPs, MACs)
- **Notes:** Python module executes correctly

#### ✅ `-G | -sysnet`
- **Status:** WORKING
- **Output:** Shows both system and network information
- **Notes:** Combines -s and -n correctly

#### ✅ `-x`
- **Status:** WORKING
- **Output:** Shows interactive menu with system status
- **Notes:** Displays menu correctly

### Verbosity

#### ⚠️ `-v <LEVEL>` (1-8)
- **Status:** ISSUE - Conflicts with --version
- **Output:** When run as `sonda -v 1`, it shows version instead of verbosity
- **Expected:** Should set verbosity level and show detailed system info
- **Issue:** Argument parsing conflict - `-v` is matched to `--version` before checking for numeric value
- **Workaround:** Need to use different syntax or fix argument parsing order

### Detailed Information Commands

#### ✅ `--all | --ald`
- **Status:** WORKING
- **Output:** Shows comprehensive system information using inxi
- **Notes:** Produces long output as expected

#### ✅ `-battery`
- **Status:** WORKING
- **Output:** Shows detailed battery information via upower
- **Notes:** Works correctly, shows charge, capacity, etc.

#### ✅ `-cpu`
- **Status:** WORKING
- **Output:** Shows detailed CPU information via lscpu
- **Notes:** Comprehensive CPU details displayed

#### ✅ `-devices`
- **Status:** WORKING
- **Output:** Shows PCI and USB device information
- **Notes:** lspci output displayed correctly

#### ✅ `-disks`
- **Status:** WORKING
- **Output:** Shows disk and storage information
- **Notes:** df and lsblk output displayed

#### ✅ `-gpu`
- **Status:** WORKING
- **Output:** Shows GPU information and OpenGL details
- **Notes:** Works correctly with glxinfo

#### ✅ `-kernel`
- **Status:** WORKING
- **Output:** Shows kernel boot parameters and loaded modules
- **Notes:** /proc/cmdline and lsmod output displayed

#### ✅ `-memory | -memmory`
- **Status:** WORKING (with note)
- **Output:** Shows memory information via free -h
- **Notes:** Both spellings work. Shows warning for detailed info requiring sudo (expected behavior)

#### ✅ `-networks`
- **Status:** WORKING
- **Output:** Shows network interface details via ip addr
- **Notes:** Displays interface information correctly

#### ✅ `-packages`
- **Status:** WORKING
- **Output:** Shows installed packages list via dpkg -l
- **Notes:** Displays package list (truncated in test, but working)

### Output Options

#### ⚠️ `--save | --SAVE`
- **Status:** ISSUE - Missing log file path
- **Output:** Shows "System information gathered successfully. Check  for details."
- **Expected:** Should show full log file path
- **Issue:** Log file path variable not being displayed in success message
- **Note:** Log file is actually created (tested separately), but path not shown

#### ✅ `--pretty`
- **Status:** WORKING
- **Output:** Strips color codes and dims output
- **Notes:** Works as expected when combined with other commands

### Default Behavior

#### ✅ No Arguments
- **Status:** WORKING
- **Output:** Shows default system information menu
- **Notes:** Displays logo and basic system info correctly

### Error Handling

#### ⚠️ Invalid Arguments
- **Status:** ISSUE - Silent failure
- **Output:** No error message, silently ignores invalid arguments
- **Expected:** Should show error message or help
- **Issue:** Unknown arguments are silently ignored instead of showing error

---

## Issues Summary

### Critical Issues

1. **`-r | --recommends` - No Output**
   - Command produces no output at all
   - May be missing function or module not loading
   - **Priority:** HIGH

2. **`-v <LEVEL>` - Argument Parsing Conflict**
   - Verbosity level cannot be set because `-v` matches `--version` first
   - **Priority:** HIGH

### Warnings

3. **`--check-update` - Silent Execution**
   - Function runs but produces no visible output
   - Exit code is 0, suggesting it thinks it worked
   - **Priority:** MEDIUM

4. **`--save` - Missing Log Path in Output**
   - Log file is created but path not shown in success message
   - Message shows "Check  for details" with empty path
   - **Priority:** LOW

5. **Invalid Arguments - Silent Failure**
   - Unknown arguments are silently ignored
   - Should show error message or help
   - **Priority:** LOW

---

## Working Features

✅ All system information commands work correctly:
- `-s`, `-n`, `-G`, `-x`
- `-cpu`, `-battery`, `-gpu`, `-devices`, `-disks`, `-kernel`, `-memory`, `-networks`, `-packages`
- `--all`, `--version`, `--update` (when up to date)
- `--pretty`, default behavior

---

## Recommendations

1. **Fix `-r | --recommends`**
   - Check if `system_recommended` function exists
   - Verify `modules/core/syscheck` is loading correctly
   - Add error handling if module/function missing

2. **Fix `-v <LEVEL>` verbosity**
   - Reorder argument parsing to check for numeric value before `--version`
   - Or use different flag for verbosity (e.g., `--verbose <LEVEL>`)
   - Ensure verbosity level is actually applied to output

3. **Fix `--check-update` output**
   - Ensure function produces visible output
   - Add proper error messages if check fails
   - Show version comparison clearly

4. **Fix `--save` log path display**
   - Ensure `$LOGFILE` variable is properly set and displayed
   - Show full path in success message

5. **Improve error handling**
   - Show error message for unknown arguments
   - Suggest `--help` when invalid arguments are used

---

## Test Coverage

- **Total Arguments Tested:** 20+
- **Working:** 17
- **Issues Found:** 5
- **Critical Issues:** 2
- **Warnings:** 3

---

## Next Steps

1. Address critical issues first (`-r` and `-v <LEVEL>`)
2. Fix `--check-update` output
3. Improve error handling for invalid arguments
4. Fix log path display in `--save`
