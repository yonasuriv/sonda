# 11. Kernel Boot Parameters
function kernel_boot_params {
    # /proc/cmdline contains the boot parameters passed to the kernel.
    echo -e "${LB}${CYAN}[#] Kernel Boot Parameters ${BLUE}(cat /proc/cmdline)${RT}${LB}"
    pprint "cat /proc/cmdline"
}

# 12. Kernel Modules
function kernel_modules {
    # lsmod shows the currently loaded kernel modules.
    echo -e "${LB}${CYAN}[#] Loaded Kernel Modules ${BLUE}(lsmod)${RT}${LB}"
    pprint "lsmod"
}

# TODO: Kernel errors and warnings
#sudo dmesg -T --level=err,crit,alert,emerg
#sudo dmesg -T --level=warn