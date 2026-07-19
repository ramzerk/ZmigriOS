cmake_minimum_required(VERSION 3.20)

# The kernel is compiled by `zig` for freestanding i386, so CMake needs no
# C/C++/ASM toolchain of its own. NONE disables compiler detection; CMake here
# is purely an orchestrator (like the Makefile it replaces).
project(ZmigriOS VERSION 0.1.0 LANGUAGES NONE)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
set(KERNEL_NAME  ZmigriOS)
set(ISO_NAME     ${KERNEL_NAME}.iso)

set(KERNEL_BIN   ${CMAKE_SOURCE_DIR}/zig-out/bin/${KERNEL_NAME})
set(GRUB_CFG     ${CMAKE_SOURCE_DIR}/grub.cfg)

# ISO staging tree lives under the build dir. Standard GRUB layout:
#   isodir/boot/${KERNEL_NAME}      <- the kernel (grub.cfg expects /boot/ZmigriOS)
#   isodir/boot/grub/grub.cfg
set(ISO_DIR      ${CMAKE_BINARY_DIR}/isodir)
set(ISO_PATH     ${CMAKE_BINARY_DIR}/${ISO_NAME})

# Docker image used to run the GRUB tools on macOS (Debian has grub-pc-bin).
set(DOCKER_IMAGE debian:stable-slim)

find_program(ZIG_EXECUTABLE zig REQUIRED)

# ---------------------------------------------------------------------------
# 1. Compile the kernel with zig
# ---------------------------------------------------------------------------
add_custom_target(compile
    COMMAND ${ZIG_EXECUTABLE} build -Dcpu=i386 -Dtarget=x86-freestanding
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Compiling kernel with zig (freestanding i386)"
    VERBATIM
)

# ---------------------------------------------------------------------------
# 2. Stage the ISO tree (kernel -> /boot, grub.cfg -> /boot/grub)
# ---------------------------------------------------------------------------
add_custom_target(stage
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ISO_DIR}/boot/grub
    COMMAND ${CMAKE_COMMAND} -E copy ${KERNEL_BIN} ${ISO_DIR}/boot/${KERNEL_NAME}
    COMMAND ${CMAKE_COMMAND} -E copy ${GRUB_CFG}   ${ISO_DIR}/boot/grub/grub.cfg
    COMMENT "Staging ISO tree at ${ISO_DIR}"
    VERBATIM
)
add_dependencies(stage compile)

# ---------------------------------------------------------------------------
# 3. Build the bootable ISO
#      Linux (x64): run grub-mkrescue natively
#      macOS (arm64): run the GRUB tools inside Docker, mounting the build dir
# ---------------------------------------------------------------------------
if(APPLE)
    add_custom_target(iso
        COMMAND docker run --rm
                -v "${CMAKE_BINARY_DIR}:/build" -w /build
                ${DOCKER_IMAGE}
                bash -c "apt-get update && apt-get install -y grub-pc-bin grub-common xorriso && grub-file --is-x86-multiboot isodir/boot/${KERNEL_NAME} && grub-mkrescue -o ${ISO_NAME} isodir"
        COMMENT "Building ISO via Docker (${DOCKER_IMAGE}) -> ${ISO_PATH}"
        VERBATIM
    )
else()
    add_custom_target(iso
        COMMAND grub-file --is-x86-multiboot ${ISO_DIR}/boot/${KERNEL_NAME}
        COMMAND grub-mkrescue -o ${ISO_PATH} ${ISO_DIR}
        COMMENT "Building ISO natively (grub-mkrescue) -> ${ISO_PATH}"
        VERBATIM
    )
endif()
add_dependencies(iso stage)

# ---------------------------------------------------------------------------
# 4. Boot the ISO in QEMU:  cmake --build build --target run
# ---------------------------------------------------------------------------
add_custom_target(run
    COMMAND qemu-system-i386 -cdrom ${ISO_PATH}
    COMMENT "Booting ${ISO_NAME} in QEMU"
    VERBATIM
)
add_dependencies(run iso)
