#!/bin/sh
# Reproducible GD32 build entry point.  Run in the project's T113 WSL.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
JOBS=${JOBS:-$(nproc)}

build_one() {
    name=$1
    config=$2
    out="$ROOT/build-gd32/$name/"
    echo "==> $name ($config)"
    make -C "$ROOT" KCONFIG_CONFIG="$ROOT/$config" OUT="$out" clean
    make -C "$ROOT" KCONFIG_CONFIG="$ROOT/$config" OUT="$out" olddefconfig
    make -C "$ROOT" KCONFIG_CONFIG="$ROOT/$config" OUT="$out" -j"$JOBS"
    arm-none-eabi-size "$out/katapult.elf"
    sha256sum "$out/katapult.bin"
}

arm-none-eabi-gcc --version | head -n 1
make --version | head -n 1

targets=${*:-"f303xb-serial f303xc-serial f303xe-serial f303xc-usb f303xc-can e230-pa23 e230-pa910"}
for target in $targets; do
    case "$target" in
        f303xb-serial) build_one "$target" test/configs/gd32f303xb-f009-serial.config ;;
        f303xc-serial) build_one "$target" test/configs/gd32f303xc-f009-serial.config ;;
        f303xe-serial) build_one "$target" test/configs/gd32f303xe-f009-serial.config ;;
        f303xc-usb) build_one "$target" test/configs/gd32f303xc-usb.config ;;
        f303xc-can) build_one "$target" test/configs/gd32f303xc-canbus.config ;;
        e230-pa23) build_one "$target" test/configs/gd32e230x8-serial-pa2-pa3.config ;;
        e230-pa910) build_one "$target" test/configs/gd32e230x8-serial-pa9-pa10.config ;;
        *) echo "Unknown GD32 build target: $target" >&2; exit 2 ;;
    esac
done
