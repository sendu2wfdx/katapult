from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONFIG = (ROOT / "test" / "configs" /
          "gd32f303xc-f009-serial.config").read_text(encoding="utf-8")
BUILD_MATRIX = (ROOT / "scripts" / "build-gd32-matrix.sh").read_text(
    encoding="utf-8")


def test_f009_katapult_target_is_rct6_xc_capacity():
    assert 'CONFIG_MCU="gd32f303xc"' in CONFIG
    assert "CONFIG_FLASH_SIZE=0x40000" in CONFIG
    assert "CONFIG_RAM_SIZE=0xc000" in CONFIG
    assert "CONFIG_MACH_GD32F303XC=y" in CONFIG
    assert "CONFIG_MACH_GD32F303XE=y" not in CONFIG


def test_f009_katapult_serial_transport_and_8k_layout():
    assert "CONFIG_FLASH_APPLICATION_ADDRESS=0x08002000" in CONFIG
    assert "CONFIG_LAUNCH_APP_ADDRESS=0x08002000" in CONFIG
    assert "CONFIG_GD32_SERIAL_USART1_PA2_PA3=y" in CONFIG
    assert "CONFIG_SERIAL_BAUD=230400" in CONFIG
    assert (
        'f303xc-serial) build_one "$target" '
        "test/configs/gd32f303xc-f009-serial.config"
        in BUILD_MATRIX
    )
