#!/usr/bin/env bash

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

PASS="[${GREEN}OK${RESET}]"
FAIL="[${RED}FAIL${RESET}]"
WARN="[${YELLOW}WARN${RESET}]"

echo -e "${BLUE}"
echo "=============================================="
echo "      NVIDIA Driver Health Check Fedora"
echo "=============================================="
echo -e "${RESET}"

check() {
    if eval "$2" >/dev/null 2>&1; then
        echo -e "$PASS $1"
    else
        echo -e "$FAIL $1"
    fi
}

echo
echo "===== SISTEMA ====="

echo "Kernel: $(uname -r)"
echo "Arquitectura: $(uname -m)"

echo
echo "===== GPU ====="

lspci | grep -Ei "VGA|3D|Display"

echo
echo "===== DRIVER CARGADO ====="

if lsmod | grep -q "^nvidia"; then
    echo -e "$PASS Módulo NVIDIA cargado"
else
    echo -e "$FAIL El módulo NVIDIA NO está cargado"
fi

echo
echo "===== NVIDIA-SMI ====="

if command -v nvidia-smi &>/dev/null; then
    echo -e "$PASS nvidia-smi encontrado"
    nvidia-smi
else
    echo -e "$FAIL nvidia-smi no encontrado"
fi

echo
echo "===== OPENGL ====="

if command -v glxinfo &>/dev/null; then
    glxinfo -B | grep "OpenGL renderer"
else
    echo -e "$WARN glxinfo no instalado (mesa-demos)"
fi

echo
echo "===== CUDA ====="

if command -v nvcc &>/dev/null; then
    echo -e "$PASS nvcc encontrado"
    nvcc --version
else
    echo -e "$WARN CUDA Toolkit no instalado"
fi

echo
echo "===== COMPILADORES ====="

check "gcc instalado" "command -v gcc"
check "g++ instalado" "command -v g++"
check "make instalado" "command -v make"

if command -v gcc &>/dev/null; then
    echo "gcc version:"
    gcc --version | head -n1
fi

echo
echo "===== KERNEL ====="

check "Kernel headers" "rpm -q kernel-headers"
check "Kernel devel" "rpm -q kernel-devel"

if rpm -q kernel-devel >/dev/null 2>&1; then
    KD=$(rpm -q kernel-devel --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n")
    echo "kernel-devel: $KD"
fi

echo
echo "===== AKMODS / DKMS ====="

if rpm -q akmods >/dev/null 2>&1; then
    echo -e "$PASS akmods instalado"
else
    echo -e "$WARN akmods no instalado"
fi

if rpm -q dkms >/dev/null 2>&1; then
    echo -e "$PASS dkms instalado"
else
    echo -e "$WARN dkms no instalado"
fi

echo
echo "===== PAQUETES NVIDIA ====="

rpm -qa | grep -Ei "nvidia|akmod|cuda"

echo
echo "===== SECURE BOOT ====="

if command -v mokutil >/dev/null; then
    mokutil --sb-state
else
    echo -e "$WARN mokutil no instalado"
fi

echo
echo "===== MODULOS ====="

lsmod | grep nvidia

echo
echo "===== DRM ====="

if [ -e /sys/module/nvidia_drm/parameters/modeset ]; then
    MODE=$(cat /sys/module/nvidia_drm/parameters/modeset)
    echo "nvidia_drm modeset = $MODE"
fi

echo
echo "===== VERSION DRIVER ====="

if [ -f /proc/driver/nvidia/version ]; then
    cat /proc/driver/nvidia/version
fi

echo
echo "===== LIBRERIAS ====="

ldconfig -p | grep -i libcuda

echo
echo "===== TEST FINAL ====="

RESULT=0

command -v nvidia-smi >/dev/null || RESULT=1
lsmod | grep -q nvidia || RESULT=1

if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}"
    echo "=========================================="
    echo "   ✔ NVIDIA parece estar correctamente"
    echo "     instalada y funcionando."
    echo "=========================================="
    echo -e "${RESET}"
else
    echo -e "${RED}"
    echo "=========================================="
    echo "   ✖ Hay problemas con la instalación"
    echo "     del driver NVIDIA."
    echo "=========================================="
    echo -e "${RESET}"
fi
