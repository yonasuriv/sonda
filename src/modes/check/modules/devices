# 8. PCI Devices
function pci_devices {
    # lspci shows the list of all PCI devices ${BLUE}(e.g., GPUs, network cards).
    # Always show PCI devices (removed old key check)
    if false; then
        echo -e "${LB}${YELLOW}[!] PCI Devices Information skipped. Only available with -ald or -devices"
    else
        echo -e "${LB}${CYAN}[#] PCI Devices ${BLUE}(lspci)${RT}${LB}"
        pprint "lspci"
    fi
}

# 9. USB Devices
function usb_devices {
    # lsusb shows the list of all connected USB devices.
    # Always show PCI devices (removed old key check)
    if false; then
        echo -e "${LB}${YELLOW}[!] USB Devices Information skipped. Only available with -ald or -devices"
    else
        echo -e "${LB}${CYAN}[#] USB Devices ${BLUE}(lsusb)${RT}${LB}"
        pprint "lsusb"
    fi
}
