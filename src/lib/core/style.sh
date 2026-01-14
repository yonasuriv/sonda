#!/bin/bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# ANSI color codes and styles
sonda_styles() {
    LB='\n'
    NC='\n'
    RT='\033[0m'
    DIM="\033[2m"
    CURSIVE="\033[2m"
    HIDDEN="\033[8m"
    BOLD="\033[1m"
    UNDERLINE="\033[4m"
    BLINK="\033[5m"
    NEGATIVE="\033[7m"
    STRIKETHROUGH="\033[9m"
    GREY="\033[0;30m"
    WHITE="\033[0;37m"
    WHITE2="\033[1;37m"
    RED="\033[0;31m"
    RED2="\033[1;31m"
    GREEN="\033[0;32m"
    GREEN2="\033[1;32m"
    YELLOW="\033[0;33m"
    YELLOW2="\033[1;33m"
    BLUE="\033[0;34m"
    BLUE2="\033[1;34m"
    MAGENTA="\033[0;35m"
    MAGENTA2="\033[1;35m"
    CYAN="\033[0;36m"
    CYAN2="\033[1;36m"
    REDBG="\033[1;37;41m"
    GREENBG="\033[1;37;42m"
    YELLOWBG="\033[1;37;43m"
    BLUEBG="\033[1;37;44m"
    MAGENTABG="\033[1;37;45m"
    CYANBG="\033[1;37;46m"
    WHITEBG="\033[1;37;47m"
    GREYBGRED="\033[1;31;40m"
    GREYBGGREEN="\033[1;32;40m"
    GREYBGYELLOW="\033[1;33;40m"
    GREYBGBLUE="\033[1;34;40m"
    GREYBGMAGENTA="\033[1;35;40m"
    GREYBGCYAN="\033[1;36;40m"
    GREYBGWHITE="\033[1;37;40m"

    NKBLACK='\033[30m'
    NKRED='\033[31m'
    NKGREEN='\033[32m'
    NKYELLOW='\033[33m'
    NKBLUE='\033[34m'
    NKMAGENTA='\033[35m'
    NKCYAN='\033[36m'
    NKWHITE='\033[37m'

    NKBRBLACK='\033[90m'
    NKBRRED='\033[91m'
    NKBRGREEN='\033[92m'
    NKBRYELLOW='\033[93m'
    NKBRBLUE='\033[94m'
    NKBRMAGENTA='\033[95m'
    NKBRCYAN='\033[96m'
    NKBRWHITE='\033[97m'

    NKBGBLACK='\033[40m'
    NKBGRED='\033[41m'
    NKBGGREEN='\033[42m'
    NKBGYELLOW='\033[43m'
    NKBGBLUE='\033[44m'
    NKBGMAGENTA='\033[45m'
    NKBGCYAN='\033[46m'
    NKBGWHITE='\033[47m'

    NKBGBRBLACK='\033[100m'
    NKBGBRRED='\033[101m'
    NKBGBRGREEN='\033[102m'
    NKBGBRYELLOW='\033[103m'
    NKBGBRBLUE='\033[104m'
    NKBGBRMAGENTA='\033[105m'
    NKBGBRCYAN='\033[106m'
    NKBGBRWHITE='\033[107m'

    # Custom Styles
    E="${NKBRRED} E ${RT}"
    W="${NKBRYELLOW} ! ${RT}"
    S="${NKBRGREEN} ✔ ${RT}"

    # Export all variables automatically using set -a
    # This ensures all variables defined above are exported
    set -a
    # All variables are now exported
    set +a
}

# Call the function to initialize all color variables
sonda_styles

# Banner functions (aliases for backward compatibility)
# These will use banner.sh functions if available, otherwise provide fallbacks
logo_sonda_script() {
    # Alias for banner_logo_small for backward compatibility
    if type banner_logo_small &>/dev/null 2>&1; then
        banner_logo_small
    else
        local version_text="SONDA v$(cat ${VERSION_FILE:-VERSION} 2>/dev/null || echo "unknown")"
        if command -v lolcat >/dev/null 2>&1; then
            echo -e "${LB}    $version_text" | lolcat 2>/dev/null || echo -e "${LB}${CYAN}    $version_text${RT}"
        else
            echo -e "${LB}${CYAN}    $version_text${RT}"
        fi
    fi
}

logo_sonda_sysnet() {
    # Alias for banner_logo_big for backward compatibility
    if type banner_logo_big &>/dev/null 2>&1; then
        banner_logo_big
    else
        local assets_dir="${ASSETS_DIR:-${ASSETS:-}}"
        if command -v lolcat >/dev/null 2>&1; then
            if [[ -n "$assets_dir" ]] && [[ -f "$assets_dir/art/sonda_sysnet_1" ]]; then
                bash "$assets_dir/art/sonda_sysnet_1" | lolcat 2>/dev/null || bash "$assets_dir/art/sonda_sysnet_1"
            fi
        else
            if [[ -n "$assets_dir" ]] && [[ -f "$assets_dir/art/sonda_sysnet_1" ]]; then
                bash "$assets_dir/art/sonda_sysnet_1"
            fi
        fi
    fi
}