#!/usr/bin/env bash
# check-nvidia-fedora.sh
# Diagnóstico integral de NVIDIA en Fedora (probado en portátiles híbridos Intel + NVIDIA)
# La detección de AMD + NVIDIA existe, pero esa configuración aún no ha sido validada.
# No modifica el sistema. Algunas comprobaciones usan sudo cuando está disponible.
# Desarrollado por Víctor Díaz González
# Proyecto independiente: no contiene ni redistribuye software o drivers de NVIDIA.
# NVIDIA conserva todos los derechos sobre sus productos, software y controladores.

set -u
set -o pipefail

SCRIPT_VERSION="1.4.3"
SCRIPT_AUTHOR="Víctor Díaz González"
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
INFO_COUNT=0
SCORE=100
INSTALL_MISSING=0
REPAIR_DRIVER=0
SHOW_MENU=0
ACTION="full"
MISSING_PACKAGES=()

usage() {
    cat <<'EOF'
Uso: check-nvidia-fedora.sh [opciones]

Desarrollado por Víctor Díaz González

Utilidad independiente; no contiene ni redistribuye software o drivers de NVIDIA.

  --menu             Abre el menú interactivo.
  --diagnose         Ejecuta el diagnóstico completo (sin mostrar el menú).
  --quick            Ejecuta un diagnóstico rápido de los componentes esenciales.
  --hdmi-test        Prueba las salidas HDMI/DP, EDID y audio asociado.
  --multimedia-test  Prueba APIs gráficas y codificación NVENC real.
  --stability-test   Ejecuta una carga gráfica vigilada durante 30 segundos.
  --install-missing  Instala con DNF los paquetes de soporte/diagnóstico ausentes.
  --repair-driver    Reconstruye el módulo NVIDIA y el initramfs del kernel activo.
  -h, --help         Muestra esta ayuda.

Sin opciones abre el menú en una terminal; en uso no interactivo ejecuta el diagnóstico.
EOF
}

parse_args() {
    if (( $# == 0 )) && [[ -t 0 && -t 1 ]]; then
        SHOW_MENU=1
        return
    fi
    while (( $# > 0 )); do
        case "$1" in
            --menu) SHOW_MENU=1 ;;
            --diagnose) ACTION="full" ;;
            --quick) ACTION="quick" ;;
            --hdmi-test) ACTION="hdmi" ;;
            --multimedia-test) ACTION="multimedia" ;;
            --stability-test) ACTION="stability" ;;
            --install-missing) INSTALL_MISSING=1 ;;
            --repair-driver) REPAIR_DRIVER=1 ;;
            -h|--help) usage; exit 0 ;;
            *) printf 'Opción desconocida: %s\n' "$1" >&2; usage >&2; exit 2 ;;
        esac
        shift
    done
}

interactive_menu() {
    local choice self
    self="$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")"

    while true; do
        printf '\n%sAsistente NVIDIA para Fedora%s\n' "$C_BOLD" "$C_RESET"
        printf '  1) Diagnóstico rápido\n'
        printf '  2) Diagnóstico completo\n'
        printf '  3) Prueba de HDMI/DisplayPort y audio\n'
        printf '  4) Prueba gráfica y multimedia NVIDIA\n'
        printf '  5) Prueba de estabilidad (30 segundos)\n'
        printf '  6) Instalar paquetes faltantes\n'
        printf '  7) Reparar módulo NVIDIA e initramfs\n'
        printf '  8) Instalar faltantes y reparar NVIDIA\n'
        printf '  9) Mostrar ayuda y comandos disponibles\n'
        printf '  0) Salir\n\n'
        read -r -p 'Selecciona una opción [0-9]: ' choice || return

        case "$choice" in
            1) "$self" --quick ;;
            2) "$self" --diagnose ;;
            3) "$self" --hdmi-test ;;
            4) "$self" --multimedia-test ;;
            5) "$self" --stability-test ;;
            6) "$self" --install-missing ;;
            7) "$self" --repair-driver ;;
            8) "$self" --install-missing --repair-driver ;;
            9) "$self" --help ;;
            0) printf 'Saliendo.\n'; return ;;
            *) printf '%b Opción inválida. Elige un número entre 0 y 9.\n' "$WARN" ;;
        esac

        if [[ "$choice" =~ ^[1-9]$ ]]; then
            printf '\n'
            read -r -p 'Pulsa Enter para volver al menú...' _ || return
        fi
    done
}

# Colores solo si stdout es una terminal.
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    C_RESET="$(tput sgr0 2>/dev/null || true)"
    C_BOLD="$(tput bold 2>/dev/null || true)"
    C_GREEN="$(tput setaf 2 2>/dev/null || true)"
    C_YELLOW="$(tput setaf 3 2>/dev/null || true)"
    C_RED="$(tput setaf 1 2>/dev/null || true)"
    C_BLUE="$(tput setaf 4 2>/dev/null || true)"
else
    C_RESET="" C_BOLD="" C_GREEN="" C_YELLOW="" C_RED="" C_BLUE=""
fi

PASS="${C_GREEN}[OK]${C_RESET}"
WARN="${C_YELLOW}[WARN]${C_RESET}"
FAIL="${C_RED}[FAIL]${C_RESET}"
INFO="${C_BLUE}[INFO]${C_RESET}"

TMP_DIR="$(mktemp -d -t nvidia-check.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

section() {
    printf '\n%s===== %s =====%s\n' "$C_BOLD" "$1" "$C_RESET"
}

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '%b %s\n' "$PASS" "$*"
}

warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    SCORE=$((SCORE - ${2:-2}))
    (( SCORE < 0 )) && SCORE=0
    printf '%b %s\n' "$WARN" "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    SCORE=$((SCORE - ${2:-10}))
    (( SCORE < 0 )) && SCORE=0
    printf '%b %s\n' "$FAIL" "$1"
}

info() {
    INFO_COUNT=$((INFO_COUNT + 1))
    printf '%b %s\n' "$INFO" "$*"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

rpm_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

add_missing_package() {
    local package="$1" item
    rpm_installed "$package" && return
    for item in "${MISSING_PACKAGES[@]}"; do
        [[ "$item" == "$package" ]] && return
    done
    MISSING_PACKAGES+=("$package")
}

refresh_missing_packages() {
    local package
    local remaining=()
    for package in "${MISSING_PACKAGES[@]}"; do
        if [[ "$package" == "ffmpeg-free" ]] && have ffmpeg; then
            continue
        fi
        rpm_installed "$package" || remaining+=("$package")
    done
    MISSING_PACKAGES=("${remaining[@]}")
}

run_privileged() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        "$@"
    elif have sudo && sudo -n true >/dev/null 2>&1; then
        sudo "$@"
    elif have sudo && [[ -t 0 ]]; then
        sudo "$@"
    else
        return 126
    fi
}

read_privileged_file() {
    local path="$1"
    if [[ -r "$path" ]]; then
        cat "$path"
    else
        run_privileged cat "$path"
    fi
}

print_command_output() {
    local label="$1"
    shift
    printf '%s:\n' "$label"
    "$@" 2>&1 | sed 's/^/  /'
}

safe_first_line() {
    "$@" 2>/dev/null | head -n 1 || true
}

NVIDIA_PCI_IDS=()
NVIDIA_GPU_NAMES=()
NVIDIA_PRIMARY_PCI=""

collect_nvidia_pci() {
    local line slot name
    if ! have lspci; then
        return
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        slot="${line%% *}"
        name="${line#* }"
        NVIDIA_PCI_IDS+=("$slot")
        NVIDIA_GPU_NAMES+=("$name")
    done < <(lspci -Dnn 2>/dev/null | awk 'BEGIN{IGNORECASE=1} /VGA compatible controller|3D controller|Display controller/ && /NVIDIA/ {slot=$1; $1=""; sub(/^ /,""); print slot " " $0}')

    if (( ${#NVIDIA_PCI_IDS[@]} > 0 )); then
        NVIDIA_PRIMARY_PCI="${NVIDIA_PCI_IDS[0]}"
    fi
}

print_header() {
    local host_name
    host_name="$(hostnamectl --static 2>/dev/null || true)"
    [[ -n "$host_name" ]] || host_name="$(hostname 2>/dev/null || printf 'desconocido')"
    printf '%sDiagnóstico NVIDIA para Fedora%s\n' "$C_BOLD" "$C_RESET"
    printf 'Versión del script: %s\n' "$SCRIPT_VERSION"
    printf 'Desarrollado por: %s\n' "$SCRIPT_AUTHOR"
    printf 'Fecha: %s\n' "$(date --iso-8601=seconds 2>/dev/null || date)"
    printf 'Usuario: %s (UID %s)\n' "$(id -un)" "$(id -u)"
    printf 'Host: %s\n' "$host_name"
    printf 'Perfil de prueba: %s\n' "$ACTION"
    if (( REPAIR_DRIVER )); then
        printf 'Modo: diagnóstico y reparación del módulo NVIDIA/initramfs.\n'
    elif (( INSTALL_MISSING )); then
        printf 'Modo: diagnóstico e instalación de paquetes faltantes mediante DNF.\n'
    else
        printf 'Modo: solo lectura; no instala, elimina ni cambia paquetes.\n'
    fi
}

check_system() {
    section "SISTEMA"

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        info "Sistema: ${PRETTY_NAME:-desconocido}"
        if [[ ${ID:-} == "fedora" ]]; then
            pass "Fedora detectado"
        else
            warn "Este script está optimizado para Fedora; se detectó ${ID:-otro sistema}" 1
        fi
    else
        warn "No se pudo leer /etc/os-release" 1
    fi

    info "Kernel: $(uname -r)"
    info "Arquitectura: $(uname -m)"
    info "Sesión: ${XDG_SESSION_TYPE:-desconocida}"
    info "Escritorio: ${XDG_CURRENT_DESKTOP:-desconocido}"

    if have systemd-detect-virt; then
        local virt
        virt="$(systemd-detect-virt 2>/dev/null || true)"
        [[ -n "$virt" && "$virt" != "none" ]] && warn "Entorno virtualizado detectado: $virt" 1 || pass "Sistema físico detectado"
    fi
}

check_gpu_detection() {
    section "DETECCIÓN DE GPU"

    if ! have lspci; then
        fail "lspci no está disponible; instala pciutils" 5
        return
    fi

    local gpu_lines
    gpu_lines="$(lspci -Dnnk 2>/dev/null | grep -A3 -Ei 'VGA compatible controller|3D controller|Display controller' || true)"
    if [[ -n "$gpu_lines" ]]; then
        printf '%s\n' "$gpu_lines" | sed 's/^/  /'
    else
        warn "No se detectaron controladores gráficos mediante lspci" 4
    fi

    if (( ${#NVIDIA_PCI_IDS[@]} > 0 )); then
        pass "GPU NVIDIA detectada (${#NVIDIA_PCI_IDS[@]} dispositivo/s)"
        local i
        for i in "${!NVIDIA_PCI_IDS[@]}"; do
            info "${NVIDIA_PCI_IDS[$i]} ${NVIDIA_GPU_NAMES[$i]}"
        done
    else
        fail "No se detectó ninguna GPU NVIDIA en PCI" 20
    fi

    if lspci -nn 2>/dev/null | grep -Eiq 'Intel.*(VGA|Display)|AMD.*(VGA|Display)|ATI.*(VGA|Display)'; then
        info "También se detectó una GPU integrada; el equipo probablemente utiliza gráficos híbridos"
    fi
}

check_kernel_modules() {
    section "MÓDULOS DEL KERNEL"

    local modules=(nvidia nvidia_modeset nvidia_drm nvidia_uvm)
    local module
    for module in "${modules[@]}"; do
        if lsmod | awk '{print $1}' | grep -qx "$module"; then
            pass "Módulo $module cargado"
        elif modinfo "$module" >/dev/null 2>&1; then
            warn "Módulo $module instalado, pero no cargado" 3
        else
            fail "Módulo $module no encontrado" 8
        fi
    done

    if modinfo nvidia >/dev/null 2>&1; then
        info "Versión del módulo: $(modinfo -F version nvidia 2>/dev/null || echo desconocida)"
        info "Ruta del módulo: $(modinfo -F filename nvidia 2>/dev/null || echo desconocida)"
        info "Licencia: $(modinfo -F license nvidia 2>/dev/null || echo desconocida)"
    fi

    local modeset_path="/sys/module/nvidia_drm/parameters/modeset"
    if [[ -e "$modeset_path" ]]; then
        local modeset
        modeset="$(read_privileged_file "$modeset_path" 2>/dev/null || true)"
        case "$modeset" in
            Y|1) pass "nvidia_drm.modeset está habilitado ($modeset)" ;;
            N|0) warn "nvidia_drm.modeset está deshabilitado; Wayland puede no funcionar correctamente" 5 ;;
            *) warn "No se pudo leer el estado de nvidia_drm.modeset" 1 ;;
        esac
    else
        warn "No existe $modeset_path; nvidia_drm podría no estar cargado" 4
    fi

    local fbdev_path="/sys/module/nvidia_drm/parameters/fbdev"
    if [[ -e "$fbdev_path" ]]; then
        local fbdev
        fbdev="$(read_privileged_file "$fbdev_path" 2>/dev/null || true)"
        info "nvidia_drm.fbdev=${fbdev:-desconocido}"
    fi

    if lsmod | awk '{print $1}' | grep -qx nouveau; then
        fail "El módulo nouveau está cargado junto con NVIDIA; puede causar conflictos" 15
    else
        pass "nouveau no está cargado"
    fi
}

check_nvidia_smi() {
    section "NVIDIA-SMI Y DRIVER"

    if [[ -e /dev/nvidiactl && -e /dev/nvidia0 ]]; then
        pass "Existen los nodos /dev/nvidiactl y /dev/nvidia0"
    else
        fail "Faltan /dev/nvidiactl o /dev/nvidia0; nvidia-smi no podrá comunicarse con la GPU" 15
        if have nvidia-modprobe; then
            info "Prueba temporal: sudo nvidia-modprobe -u -c=0"
        else
            info "Falta nvidia-modprobe; normalmente lo instala el paquete nvidia-modprobe"
            add_missing_package nvidia-modprobe
        fi
    fi

    if ! have nvidia-smi; then
        fail "nvidia-smi no está instalado o no está en PATH" 20
        return
    fi

    local smi_out="$TMP_DIR/nvidia-smi.txt"
    if nvidia-smi >"$smi_out" 2>&1; then
        pass "nvidia-smi funciona correctamente"
        sed 's/^/  /' "$smi_out"
    else
        fail "nvidia-smi no pudo comunicarse con el driver" 25
        sed 's/^/  /' "$smi_out"
        return
    fi

    local driver cuda
    driver="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 || true)"
    cuda="$(nvidia-smi 2>/dev/null | sed -n 's/.*CUDA Version: \([^ ]*\).*/\1/p' | head -n1)"
    [[ -n "$driver" ]] && info "Driver NVIDIA: $driver"
    [[ -n "$cuda" ]] && info "Compatibilidad CUDA anunciada por el driver: $cuda"

    local query='index,name,uuid,pci.bus_id,temperature.gpu,power.draw,power.limit,utilization.gpu,utilization.memory,memory.used,memory.total,clocks.current.graphics,clocks.current.memory,pcie.link.gen.current,pcie.link.gen.max,pcie.link.width.current,pcie.link.width.max'
    info "Telemetría GPU:"
    nvidia-smi --query-gpu="$query" --format=csv 2>/dev/null | sed 's/^/  /' || warn "No fue posible obtener toda la telemetría de nvidia-smi" 1

    info "Procesos que usan la GPU:"
    nvidia-smi pmon -c 1 2>/dev/null | sed 's/^/  /' || info "nvidia-smi pmon no devolvió información"
}

check_version_consistency() {
    section "COHERENCIA DE VERSIONES NVIDIA"

    local module_version="" smi_version="" rpm_version="" kmod_version=""
    module_version="$(modinfo -F version nvidia 2>/dev/null || true)"
    if have nvidia-smi; then
        smi_version="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -n1 || true)"
    fi
    rpm_version="$(rpm -q --qf '%{VERSION}' xorg-x11-drv-nvidia 2>/dev/null || true)"
    kmod_version="$(rpm -q --qf '%{VERSION}' "kmod-nvidia-$(uname -r)" 2>/dev/null || true)"

    info "Módulo cargado: ${module_version:-no disponible}"
    info "nvidia-smi: ${smi_version:-no disponible}"
    info "Paquete de usuario: ${rpm_version:-no disponible}"
    info "KMOD del kernel activo: ${kmod_version:-no disponible}"

    local expected="" value mismatch=0
    for value in "$module_version" "$smi_version" "$rpm_version" "$kmod_version"; do
        [[ -z "$value" ]] && continue
        if [[ -z "$expected" ]]; then
            expected="$value"
        elif [[ "$value" != "$expected" ]]; then
            mismatch=1
        fi
    done
    if [[ -z "$expected" ]]; then
        fail "No fue posible obtener ninguna versión NVIDIA" 10
    elif (( mismatch )); then
        fail "Las versiones del módulo, herramientas o paquetes NVIDIA no coinciden" 15
    else
        pass "Las versiones NVIDIA disponibles coinciden ($expected)"
    fi
}

check_packages_and_build() {
    section "PAQUETES, AKMODS Y COMPILACIÓN"

    local packages=(akmods kmodtool kernel-devel kernel-headers gcc gcc-c++ make elfutils-libelf-devel)
    local p
    for p in "${packages[@]}"; do
        if rpm_installed "$p"; then
            pass "$p instalado"
        else
            case "$p" in
                akmods|kmodtool|kernel-headers|gcc|make|elfutils-libelf-devel)
                    add_missing_package "$p"
                    ;;
            esac
            case "$p" in
                gcc-c++) info "$p no instalado; es opcional y no se requiere para el driver NVIDIA" ;;
                kernel-headers) warn "$p no instalado" 2 ;;
                *) warn "$p no instalado" 3 ;;
            esac
        fi
    done

    if rpm_installed dkms; then
        info "dkms está instalado, aunque Fedora/RPM Fusion normalmente utiliza akmods"
    else
        pass "dkms no instalado: normal cuando se usa akmods en Fedora"
    fi

    local running_kernel
    running_kernel="$(uname -r)"
    if rpm -q "kernel-devel-${running_kernel}" >/dev/null 2>&1; then
        pass "kernel-devel coincide exactamente con el kernel en ejecución ($running_kernel)"
    else
        fail "Falta kernel-devel-${running_kernel}; akmods no podrá recompilar para este kernel" 12
        add_missing_package "kernel-devel-${running_kernel}"
    fi

    if have akmods; then
        pass "akmods está disponible (Fedora 44 ya no ofrece la opción no destructiva --check)"
    fi

    local kmod_pkg
    kmod_pkg="$(rpm -qa | grep -E "^kmod-nvidia-${running_kernel//./\\.}" | head -n1 || true)"
    if [[ -n "$kmod_pkg" ]]; then
        pass "Paquete kmod del kernel actual encontrado: $kmod_pkg"
    elif rpm -qa | grep -q '^akmod-nvidia'; then
        warn "akmod-nvidia está instalado, pero no se encontró un paquete kmod específico para el kernel actual" 5
    else
        fail "No se encontró akmod-nvidia ni kmod-nvidia para el kernel actual" 15
    fi

    if have gcc; then info "$(safe_first_line gcc --version)"; fi
    if have g++; then info "$(safe_first_line g++ --version)"; fi
}

check_secure_boot_and_signatures() {
    section "SECURE BOOT Y FIRMA DEL MÓDULO"

    local sb_state="desconocido"
    if have mokutil; then
        local sb_output
        sb_output="$(mokutil --sb-state 2>&1 || true)"
        printf '  %s\n' "$sb_output"
        if grep -qi 'enabled' <<<"$sb_output"; then
            sb_state="enabled"
            info "Secure Boot está habilitado"
        elif grep -qi 'disabled' <<<"$sb_output"; then
            sb_state="disabled"
            pass "Secure Boot está deshabilitado"
        else
            warn "No se pudo determinar el estado de Secure Boot" 1
        fi
    else
        warn "mokutil no está instalado; no se puede verificar Secure Boot" 2
    fi

    if modinfo nvidia >/dev/null 2>&1; then
        local signer sig_key sig_hash
        signer="$(modinfo -F signer nvidia 2>/dev/null || true)"
        sig_key="$(modinfo -F sig_key nvidia 2>/dev/null || true)"
        sig_hash="$(modinfo -F sig_hashalgo nvidia 2>/dev/null || modinfo -F sig_hash nvidia 2>/dev/null || true)"
        info "Firmante: ${signer:-sin datos}"
        info "Clave: ${sig_key:-sin datos}"
        info "Hash: ${sig_hash:-sin datos}"

        if [[ -n "$signer" ]]; then
            pass "El módulo NVIDIA está firmado"
        elif [[ "$sb_state" == "enabled" ]]; then
            fail "Secure Boot está activo y el módulo NVIDIA no muestra firmante" 20
        else
            warn "El módulo NVIDIA no muestra información de firma" 2
        fi
    fi
}

check_graphics_apis() {
    section "OPENGL, EGL, VULKAN Y OPENCL"

    if have glxinfo; then
        local glx
        glx="$(glxinfo -B 2>&1 || true)"
        if grep -q 'OpenGL renderer string' <<<"$glx"; then
            pass "OpenGL responde correctamente"
            grep -E 'OpenGL vendor string|OpenGL renderer string|OpenGL core profile version string|OpenGL version string' <<<"$glx" | sed 's/^/  /'
            if grep -qi 'NVIDIA' <<<"$(grep 'OpenGL renderer string' <<<"$glx")"; then
                info "La sesión actual renderiza OpenGL con NVIDIA"
            else
                info "La sesión actual no renderiza OpenGL con NVIDIA; esto es normal en modo híbrido/Optimus"
            fi
        else
            warn "glxinfo no pudo obtener el renderer OpenGL" 4
            printf '%s\n' "$glx" | tail -n 10 | sed 's/^/  /'
        fi
    else
        warn "glxinfo no instalado; instala glx-utils" 2
    fi

    if have eglinfo; then
        local egl_file="$TMP_DIR/eglinfo.txt" egl_rc
        # Limitar la prueba a la plataforma de la sesión evita que eglinfo recorra
        # backends no usados (por ejemplo GBM) que pueden fallar en sistemas híbridos.
        local egl_platform="${XDG_SESSION_TYPE:-surfaceless}"
        [[ "$egl_platform" == "wayland" || "$egl_platform" == "x11" ]] || egl_platform="surfaceless"
        { timeout 20 eglinfo -B -p "$egl_platform"; } >"$egl_file" 2>&1
        egl_rc=$?
        if [[ $egl_rc -eq 0 ]] && grep -Eiq 'EGL vendor|EGL version' "$egl_file"; then
            pass "EGL responde correctamente"
            grep -Ei 'EGL vendor|EGL version|Device platform' "$egl_file" | head -n 12 | sed 's/^/  /'
        elif [[ $egl_rc -eq 124 ]]; then
            warn "eglinfo excedió 20 segundos" 2
        elif [[ $egl_rc -eq 139 ]]; then
            warn "eglinfo terminó con SIGSEGV; revisa egl-gbm y las bibliotecas NVIDIA" 5
            tail -n 12 "$egl_file" | sed 's/^/  /'
        elif grep -Eiq 'EGL vendor|EGL version' "$egl_file"; then
            warn "eglinfo devolvió datos EGL, pero terminó con código $egl_rc" 3
            grep -Ei 'EGL vendor|EGL version|Device platform' "$egl_file" | head -n 12 | sed 's/^/  /'
        else
            warn "eglinfo no devolvió información útil (código $egl_rc)" 2
        fi

        if journalctl -b --no-pager -k 2>/dev/null | grep -Ei 'eglinfo.*segfault.*libnvidia-egl-gbm' >/dev/null; then
            info "Este arranque contiene un fallo histórico de eglinfo en libnvidia-egl-gbm; la prueba EGL actual terminó correctamente"
        fi
    else
        warn "eglinfo no instalado; normalmente lo proporciona egl-utils" 1
    fi

    if have vulkaninfo; then
        local vk="$TMP_DIR/vulkan.txt"
        if timeout 20 vulkaninfo --summary >"$vk" 2>&1; then
            pass "Vulkan responde correctamente"
            grep -E 'GPU[0-9]|deviceName|driverName|driverInfo|apiVersion' "$vk" | head -n 30 | sed 's/^/  /'
            if grep -qi NVIDIA "$vk"; then
                pass "Vulkan detecta la GPU NVIDIA"
            else
                warn "Vulkan no mostró una GPU NVIDIA" 4
            fi
        else
            warn "vulkaninfo falló o excedió 20 segundos" 4
            tail -n 15 "$vk" | sed 's/^/  /'
        fi
    else
        warn "vulkaninfo no instalado; instala vulkan-tools" 2
    fi

    if have clinfo; then
        local cl="$TMP_DIR/opencl.txt"
        if timeout 20 clinfo >"$cl" 2>&1; then
            if grep -q 'Device Name' "$cl"; then
                pass "OpenCL detecta uno o más dispositivos"
                grep -E 'Platform Name|Device Name|Device Vendor|Device Version' "$cl" | head -n 30 | sed 's/^/  /'
                grep -qi NVIDIA "$cl" && pass "OpenCL detecta NVIDIA" || warn "OpenCL no mostró un dispositivo NVIDIA" 2
            else
                warn "clinfo se ejecutó, pero no detectó dispositivos OpenCL" 3
            fi
        else
            warn "clinfo falló o excedió 20 segundos" 2
        fi
    else
        warn "clinfo no instalado; solo es necesario para comprobar OpenCL" 1
    fi
}

check_prime() {
    section "PRIME / GPU HÍBRIDA"

    if have switcherooctl; then
        info "Dispositivos informados por switcheroo-control:"
        switcherooctl list 2>/dev/null | sed 's/^/  /' || warn "switcherooctl no pudo listar las GPU" 1
    elif systemctl list-unit-files switcheroo-control.service >/dev/null 2>&1; then
        info "switcheroo-control está disponible, pero switcherooctl no está en PATH"
    else
        warn "switcheroo-control no parece estar instalado; GNOME puede seguir usando PRIME mediante otras rutas" 1
    fi

    if have xrandr && [[ ${XDG_SESSION_TYPE:-} == "x11" ]]; then
        info "Proveedores XRandR:"
        xrandr --listproviders 2>/dev/null | sed 's/^/  /' || warn "xrandr no pudo listar proveedores" 1
    elif [[ ${XDG_SESSION_TYPE:-} == "wayland" ]]; then
        info "En Wayland, xrandr --listproviders no es una prueba fiable; se omite"
    fi

    if have glxinfo; then
        local offload="$TMP_DIR/prime-offload.txt"
        if __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo -B >"$offload" 2>&1; then
            local renderer
            renderer="$(grep 'OpenGL renderer string' "$offload" | head -n1 || true)"
            if grep -qi NVIDIA <<<"$renderer"; then
                pass "PRIME Render Offload funciona: $renderer"
            else
                warn "PRIME se ejecutó, pero el renderer no fue NVIDIA: ${renderer:-sin renderer}" 5
            fi
        else
            warn "PRIME Render Offload mediante GLX falló" 6
            tail -n 12 "$offload" | sed 's/^/  /'
        fi
    fi

    if have vulkaninfo; then
        local vkoff="$TMP_DIR/vulkan-offload.txt"
        if __NV_PRIME_RENDER_OFFLOAD=1 timeout 20 vulkaninfo --summary >"$vkoff" 2>&1 && grep -qi NVIDIA "$vkoff"; then
            pass "PRIME Render Offload para Vulkan detecta NVIDIA"
        else
            warn "No se pudo confirmar PRIME Offload para Vulkan" 3
        fi
    fi
}

check_hdmi_outputs() {
    section "SALIDAS HDMI / DISPLAYPORT Y AUDIO"

    local connector status found=0 connected=0 driver card device
    shopt -s nullglob
    for connector in /sys/class/drm/card*-HDMI-A-* /sys/class/drm/card*-DP-*; do
        [[ -e "$connector/status" ]] || continue
        found=$((found + 1))
        status="$(<"$connector/status")"
        card="$(basename "$connector")"
        card="${card%%-*}"
        device="$(readlink -f "/sys/class/drm/$card/device" 2>/dev/null || true)"
        driver="$(basename "$(readlink -f "$device/driver" 2>/dev/null)" 2>/dev/null || true)"
        info "$(basename "$connector"): estado=$status, DRM=$card, driver=${driver:-desconocido}"
        if [[ "$status" == "connected" ]]; then
            connected=$((connected + 1))
            pass "$(basename "$connector") detecta un monitor conectado"
            if [[ -r "$connector/modes" ]]; then
                sed 's/^/    modo: /' "$connector/modes" | head -n 8
            fi
        fi
    done
    shopt -u nullglob

    if (( found == 0 )); then
        fail "El kernel no expone conectores HDMI/DP en /sys/class/drm" 12
    elif (( connected == 0 )); then
        warn "Hay $found conector(es) HDMI/DP, pero ninguno informa connected. Conecta el cable antes de ejecutar de nuevo." 5
    else
        pass "$connected de $found conector(es) HDMI/DP está(n) conectado(s)"
    fi

    if have lspci && lspci -Dnn 2>/dev/null | grep -Eiq 'NVIDIA.*Audio'; then
        pass "Se detectó el controlador de audio HDMI/DP de NVIDIA en PCI"
        lspci -Dnnk 2>/dev/null | grep -A3 -Ei 'NVIDIA.*Audio' | sed 's/^/  /'
        if lsmod | awk '{print $1}' | grep -qx snd_hda_intel; then
            pass "snd_hda_intel está cargado para audio HDMI/DP"
        else
            warn "snd_hda_intel no está cargado; el vídeo puede funcionar sin audio HDMI" 3
        fi
    else
        info "No se detectó una función PCI de audio NVIDIA; algunos equipos enrutan el audio por la GPU integrada"
    fi

    if have wpctl; then
        local wp="$TMP_DIR/wpctl-status.txt"
        wpctl status >"$wp" 2>&1 || true
        if grep -Eiq 'HDMI|DisplayPort|NVIDIA' "$wp"; then
            pass "PipeWire/WirePlumber muestra una salida relacionada con HDMI/DisplayPort"
            grep -Ei 'HDMI|DisplayPort|NVIDIA' "$wp" | head -n 15 | sed 's/^/  /'
        else
            warn "PipeWire no muestra una salida HDMI/DisplayPort activa" 2
        fi
    elif have pactl; then
        pactl list short sinks 2>/dev/null | grep -Ei 'hdmi|displayport|nvidia' | sed 's/^/  /' || \
            warn "PulseAudio/PipeWire no muestra un sink HDMI/DisplayPort" 2
    else
        info "wpctl/pactl no está disponible; no se pudo comprobar la salida de audio"
    fi

    local cmdline
    cmdline="$(< /proc/cmdline)"
    if grep -Eq '(^|[[:space:]])nomodeset([[:space:]]|$)' <<<"$cmdline"; then
        fail "El kernel arrancó con nomodeset; esto deshabilita KMS y puede impedir las salidas externas" 20
    else
        pass "El kernel no arrancó con nomodeset"
    fi
    if grep -Eq '(^|[[:space:]])(rd\.)?driver\.blacklist=nvidia([[:space:]]|$)' <<<"$cmdline"; then
        fail "La línea del kernel bloquea explícitamente el módulo nvidia" 20
    fi

    if [[ -n "$NVIDIA_PRIMARY_PCI" ]]; then
        local boot_vga="/sys/bus/pci/devices/${NVIDIA_PRIMARY_PCI}/boot_vga"
        [[ -r "$boot_vga" ]] && info "NVIDIA boot_vga=$(<"$boot_vga") (0 es normal en portátiles híbridos)"
    fi
}

check_hdmi_details() {
    section "EDID, ENLACE Y AUDIO ELD"

    local connector status name value edid_file edid_copy eld found_edid=0 found_eld=0 connected_count=0
    shopt -s nullglob
    for connector in /sys/class/drm/card*-HDMI-A-* /sys/class/drm/card*-DP-*; do
        [[ -r "$connector/status" ]] || continue
        status="$(<"$connector/status")"
        [[ "$status" == "connected" ]] || continue
        connected_count=$((connected_count + 1))
        name="$(basename "$connector")"
        info "$name:"
        for value in enabled dpms link_status; do
            if [[ -r "$connector/$value" ]]; then
                printf '  %s=%s\n' "$value" "$(<"$connector/$value")"
            fi
        done
        edid_file="$connector/edid"
        edid_copy="$TMP_DIR/${name}.edid"
        if dd if="$edid_file" of="$edid_copy" status=none 2>/dev/null && [[ -s "$edid_copy" ]]; then
            found_edid=$((found_edid + 1))
            pass "$name expone un EDID válido ($(wc -c <"$edid_copy") bytes)"
            info "Huella EDID: $(sha256sum "$edid_copy" 2>/dev/null | awk '{print $1}')"
            if have edid-decode; then
                edid-decode "$edid_copy" 2>/dev/null | grep -E 'Manufacturer:|Model:|Display Product Name|DTD 1:|Maximum image size' | head -n 12 | sed 's/^/  /' || true
            else
                info "Instala v4l-utils (proporciona edid-decode) para mostrar fabricante, modelo y resolución preferida"
                add_missing_package v4l-utils
            fi
        else
            warn "$name está conectado, pero no entrega EDID" 4
        fi
    done

    for eld in /proc/asound/card*/eld*; do
        [[ -r "$eld" ]] || continue
        if grep -Eq 'monitor_present[[:space:]]+1|eld_valid[[:space:]]+1' "$eld"; then
            found_eld=$((found_eld + 1))
            pass "ALSA expone audio ELD para el monitor"
            grep -E 'monitor_name|connection_type|sad_count|eld_valid|monitor_present' "$eld" | sed 's/^/  /'
        fi
    done
    shopt -u nullglob

    if (( connected_count > 0 && found_edid == 0 )); then
        warn "No se obtuvo EDID de ninguna salida conectada" 3
    fi
    if (( found_eld == 0 )); then
        info "El monitor conectado no anuncia audio mediante ELD; es normal si no incorpora altavoces/audio HDMI"
    fi
}

check_cuda() {
    section "CUDA"

    if ldconfig -p 2>/dev/null | grep 'libcuda\.so' >/dev/null; then
        pass "libcuda.so está registrada en el enlazador dinámico"
        ldconfig -p 2>/dev/null | grep 'libcuda\.so' | head -n 5 | sed 's/^/  /'
    else
        fail "libcuda.so no aparece en ldconfig" 10
    fi

    if ldconfig -p 2>/dev/null | grep -E 'libcudart\.so' >/dev/null; then
        pass "CUDA Runtime (libcudart) instalado"
        ldconfig -p 2>/dev/null | grep 'libcudart\.so' | head -n 5 | sed 's/^/  /'
    else
        info "CUDA Runtime de desarrollo (libcudart) no está instalado; no es necesario para usar el driver"
    fi

    if have nvcc; then
        pass "CUDA Toolkit instalado (nvcc disponible)"
        nvcc --version 2>/dev/null | tail -n 4 | sed 's/^/  /'
    else
        info "CUDA Toolkit no instalado (nvcc ausente); no es necesario para usar el driver ni HDMI"
    fi
}

check_video_acceleration() {
    section "NVENC, NVDEC, VA-API Y VDPAU"

    if have ffmpeg; then
        local encoders decoders
        encoders="$(ffmpeg -hide_banner -encoders 2>/dev/null || true)"
        decoders="$(ffmpeg -hide_banner -decoders 2>/dev/null || true)"
        if grep -qE 'h264_nvenc|hevc_nvenc|av1_nvenc' <<<"$encoders"; then
            pass "FFmpeg incluye codificadores NVENC"
            grep -E 'h264_nvenc|hevc_nvenc|av1_nvenc' <<<"$encoders" | sed 's/^/  /'
        else
            warn "FFmpeg no muestra codificadores NVENC" 3
        fi
        if grep -qE 'cuvid|_cuvid' <<<"$decoders"; then
            pass "FFmpeg incluye decodificadores NVIDIA/CUVID"
        else
            info "FFmpeg no muestra decodificadores CUVID; puede usar NVDEC mediante hwaccel sin decodificador dedicado"
        fi
    else
        warn "ffmpeg no instalado; no se puede verificar NVENC/NVDEC desde FFmpeg" 1
    fi

    if have vainfo; then
        info "Resumen VA-API:"
        timeout 15 vainfo 2>&1 | head -n 25 | sed 's/^/  /' || warn "vainfo falló" 1
    else
        info "vainfo no instalado"
    fi

    if have vdpauinfo; then
        local vd="$TMP_DIR/vdpau.txt"
        if timeout 15 vdpauinfo >"$vd" 2>&1; then
            pass "VDPAU responde correctamente"
            head -n 25 "$vd" | sed 's/^/  /'
        else
            warn "vdpauinfo no pudo inicializar VDPAU" 2
        fi
    else
        info "vdpauinfo no instalado"
    fi
}

test_nvenc_functional() {
    section "PRUEBA FUNCIONAL NVENC"

    if ! have ffmpeg; then
        warn "FFmpeg no está instalado; no se puede ejecutar una codificación NVENC real" 2
        return
    fi
    if ! ffmpeg -hide_banner -encoders 2>/dev/null | grep 'h264_nvenc' >/dev/null; then
        warn "Este FFmpeg no ofrece el codificador h264_nvenc" 3
        return
    fi

    local out="$TMP_DIR/nvenc-functional.txt" rc
    if timeout 20 ffmpeg -nostdin -hide_banner -loglevel warning \
        -f lavfi -i 'testsrc2=size=1280x720:rate=30' \
        -frames:v 60 -c:v h264_nvenc -gpu 0 -preset p1 \
        -f null /dev/null >"$out" 2>&1; then
        pass "NVENC codificó correctamente 60 fotogramas (2 segundos) de vídeo sintético 720p"
    else
        rc=$?
        warn "La prueba funcional de NVENC falló (código $rc)" 5
        if [[ -s "$out" ]]; then
            tail -n 20 "$out" | sed 's/^/  /'
        else
            info "FFmpeg no produjo diagnóstico; repite con: ffmpeg -nostdin -loglevel verbose -f lavfi -i 'testsrc2=size=1280x720:rate=30' -frames:v 60 -c:v h264_nvenc -gpu 0 -f null /dev/null"
        fi
    fi
}

test_stability() {
    section "PRUEBA OPCIONAL DE ESTABILIDAD (30 SEGUNDOS)"

    if ! have nvidia-smi || ! nvidia-smi >/dev/null 2>&1; then
        fail "nvidia-smi debe funcionar antes de iniciar la prueba de estabilidad" 10
        return
    fi
    if ! have glxgears || [[ -z "${DISPLAY:-}" ]]; then
        warn "Se necesita glxgears y una sesión gráfica para generar carga" 4
        return
    fi

    local before_xid after_xid render_pid rc sample temp max_temp=0 samples=0
    local render_out="$TMP_DIR/stability-render.txt"
    before_xid="$(journalctl -b --no-pager -k 2>/dev/null | grep -Ec 'NVRM: Xid' || true)"
    info "Iniciando carga PRIME vigilada; puedes interrumpirla con Ctrl+C"

    timeout 30 env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
        glxgears -info >"$render_out" 2>&1 &
    render_pid=$!
    for sample in {1..10}; do
        temp="$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 || true)"
        if [[ "$temp" =~ ^[0-9]+$ ]]; then
            samples=$((samples + 1))
            (( temp > max_temp )) && max_temp=$temp
            info "Muestra $sample/10: ${temp} °C"
        else
            warn "No se pudo leer la temperatura en la muestra $sample" 1
        fi
        sleep 3
    done
    wait "$render_pid"
    rc=$?
    after_xid="$(journalctl -b --no-pager -k 2>/dev/null | grep -Ec 'NVRM: Xid' || true)"

    if [[ $rc -eq 0 || $rc -eq 124 ]]; then
        pass "La carga gráfica permaneció activa durante la prueba"
    else
        fail "La carga gráfica terminó inesperadamente (código $rc)" 10
        tail -n 15 "$render_out" | sed 's/^/  /'
    fi
    (( samples > 0 )) && info "Temperatura máxima observada: ${max_temp} °C"
    if (( after_xid > before_xid )); then
        fail "Aparecieron $((after_xid - before_xid)) errores Xid nuevos durante la prueba" 20
    else
        pass "No aparecieron errores Xid nuevos durante la prueba"
    fi
    if (( max_temp >= 90 )); then
        warn "La temperatura alcanzó ${max_temp} °C; revisa ventilación y perfil térmico" 5
    elif (( max_temp > 0 )); then
        pass "La temperatura se mantuvo por debajo de 90 °C"
    fi
}

check_gsp_and_pcie() {
    section "GSP, PCIe Y ESTADO DE ENERGÍA"

    if have nvidia-smi && nvidia-smi >/dev/null 2>&1; then
        local q="$TMP_DIR/nvidia-q.txt"
        nvidia-smi -q >"$q" 2>/dev/null || true

        info "Firmware GSP:"
        grep -A3 -i 'GSP Firmware' "$q" | sed 's/^/  /' || info "nvidia-smi no informó firmware GSP"

        info "Modo de persistencia y energía:"
        grep -E 'Persistence Mode|Power State|Performance State|Power Draw|Power Limit' "$q" | head -n 20 | sed 's/^/  /'

        info "Enlace PCIe:"
        nvidia-smi --query-gpu=pci.bus_id,pcie.link.gen.current,pcie.link.gen.max,pcie.link.width.current,pcie.link.width.max --format=csv 2>/dev/null | sed 's/^/  /' || true
        info "En reposo, una generación o ancho PCIe reducido puede ser normal por ahorro de energía."
    fi

    if [[ -n "$NVIDIA_PRIMARY_PCI" ]] && have lspci; then
        info "Detalles PCI del dispositivo $NVIDIA_PRIMARY_PCI:"
        lspci -s "$NVIDIA_PRIMARY_PCI" -vv 2>/dev/null | grep -E 'LnkCap:|LnkSta:|Kernel driver in use|Kernel modules' | sed 's/^/  /' || true

        local runtime_path="/sys/bus/pci/devices/${NVIDIA_PRIMARY_PCI}/power/runtime_status"
        if [[ -r "$runtime_path" ]]; then
            info "Estado runtime PM: $(cat "$runtime_path")"
        fi
    fi
}

check_services() {
    section "SERVICIOS"

    local services=(nvidia-persistenced.service nvidia-powerd.service switcheroo-control.service)
    local s
    for s in "${services[@]}"; do
        if systemctl list-unit-files "$s" >/dev/null 2>&1; then
            local enabled active
            enabled="$(systemctl is-enabled "$s" 2>/dev/null || true)"
            active="$(systemctl is-active "$s" 2>/dev/null || true)"
            info "$s: habilitado=${enabled:-desconocido}, activo=${active:-desconocido}"
            if [[ "$s" == "nvidia-persistenced.service" ]]; then
                if [[ "$active" == "active" ]]; then
                    pass "nvidia-persistenced está activo"
                else
                    info "nvidia-persistenced no está activo; en portátiles no siempre es necesario"
                fi
            fi
        else
            info "$s no está instalado"
        fi
    done
}

check_wayland() {
    section "WAYLAND / X11"

    local session_type="${XDG_SESSION_TYPE:-}"
    if [[ -z "$session_type" && -n "${XDG_SESSION_ID:-}" ]] && have loginctl; then
        session_type="$(loginctl show-session "$XDG_SESSION_ID" -p Type --value 2>/dev/null || true)"
    fi

    case "$session_type" in
        wayland)
            pass "Sesión Wayland activa"
            ;;
        x11)
            pass "Sesión X11 activa"
            ;;
        *)
            warn "No se pudo identificar el tipo de sesión gráfica" 1
            ;;
    esac

    if [[ "$session_type" == "wayland" ]]; then
        if [[ -e /sys/module/nvidia_drm/parameters/modeset ]]; then
            local m
            m="$(read_privileged_file /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || true)"
            if [[ "$m" == "Y" || "$m" == "1" ]]; then
                pass "KMS de NVIDIA habilitado para Wayland"
            elif [[ -n "$m" ]]; then
                fail "Wayland activo sin nvidia_drm.modeset=1" 10
            else
                warn "No se pudo leer nvidia_drm.modeset; ejecuta el script con sudo para confirmarlo" 3
            fi
        fi
    fi

    info "Variables relevantes:"
    printf '  XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-desconocido}"
    printf '  WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY:-no definido}"
    printf '  DISPLAY=%s\n' "${DISPLAY:-no definido}"
    printf '  __NV_PRIME_RENDER_OFFLOAD=%s\n' "${__NV_PRIME_RENDER_OFFLOAD:-no definido}"
}

check_journal() {
    section "REGISTROS DEL KERNEL Y JOURNAL"

    local log="$TMP_DIR/nvidia-journal.txt"
    if journalctl -b --no-pager -k >"$log" 2>/dev/null; then
        local errors warnings
        errors="$(grep -Ei 'NVRM: Xid|nvidia.*(failed|error|timeout|cannot find any crtc|assertion failed)|nouveau.*(failed|error)|GPU has fallen off the bus' "$log" || true)"
        warnings="$(grep -Ei 'nvidia|NVRM|nouveau' "$log" | tail -n 40 || true)"

        if [[ -n "$errors" ]]; then
            fail "Se detectaron errores relevantes de NVIDIA en el arranque actual" 20
            printf '%s\n' "$errors" | tail -n 30 | sed 's/^/  /'
        else
            pass "No se detectaron Xid ni errores graves de NVIDIA en el kernel del arranque actual"
        fi

        info "Últimas líneas relacionadas con NVIDIA:"
        if [[ -n "$warnings" ]]; then
            printf '%s\n' "$warnings" | sed 's/^/  /'
        else
            printf '  Sin entradas relacionadas.\n'
        fi
    else
        warn "No se pudo leer journalctl -k; el usuario puede no pertenecer al grupo systemd-journal" 2
    fi
}

check_libraries() {
    section "BIBLIOTECAS NVIDIA"

    local libs=(libcuda.so libGLX_nvidia.so libEGL_nvidia.so libnvidia-egl-gbm.so.1 libnvidia-encode.so libnvcuvid.so)
    local lib
    for lib in "${libs[@]}"; do
        if ldconfig -p 2>/dev/null | grep -F "$lib" >/dev/null; then
            pass "$lib encontrada"
        else
            case "$lib" in
                libcuda.so|libGLX_nvidia.so|libEGL_nvidia.so) fail "$lib no encontrada" 6 ;;
                libnvidia-egl-gbm.so.1) warn "$lib no encontrada; instala el paquete Fedora egl-gbm (no CUDA Toolkit)" 3 ;;
                *) warn "$lib no encontrada" 2 ;;
            esac
        fi
    done

    if have alternatives; then
        info "El sistema dispone de alternatives"
    fi
}

check_updates() {
    section "ACTUALIZACIONES PENDIENTES"

    if ! have dnf; then
        warn "dnf no está disponible" 1
        return
    fi

    local out="$TMP_DIR/dnf-updates.txt"
    if timeout 45 dnf -q -C check-upgrade >"$out" 2>&1; then
        pass "No hay actualizaciones pendientes según la caché local"
    else
        local rc=$?
        if [[ $rc -eq 100 ]]; then
            local nvidia_updates
            nvidia_updates="$(grep -Ei '(^|[[:space:]])(akmod-nvidia|xorg-x11-drv-nvidia|nvidia-|kernel|kernel-core|kernel-devel)' "$out" || true)"
            if [[ -n "$nvidia_updates" ]]; then
                warn "Hay actualizaciones relacionadas con kernel/NVIDIA pendientes" 3
                printf '%s\n' "$nvidia_updates" | sed 's/^/  /'
            else
                info "Hay actualizaciones pendientes, pero no se detectaron paquetes NVIDIA/kernel en la salida"
            fi
        elif [[ $rc -eq 124 ]]; then
            warn "La comprobación de actualizaciones excedió 45 segundos" 1
        else
            warn "dnf check-upgrade no pudo completarse (código $rc)" 1
            tail -n 10 "$out" | sed 's/^/  /'
        fi
    fi
}

check_benchmark() {
    section "PRUEBA RÁPIDA DE RENDERIZADO"

    if ! have glxgears; then
        warn "glxgears no instalado; instala glx-utils para una prueba rápida" 1
        return
    fi

    if [[ -z "${DISPLAY:-}" ]]; then
        warn "DISPLAY no está definido; se omite glxgears" 1
        return
    fi

    local out="$TMP_DIR/glxgears.txt"
    timeout 6 glxgears -info >"$out" 2>&1
    local rc=$?
    if [[ $rc -eq 124 || $rc -eq 0 ]]; then
        pass "glxgears se inició correctamente durante la prueba"
        grep -E 'GL_RENDERER|GL_VERSION|frames in' "$out" | head -n 10 | sed 's/^/  /' || true
    else
        warn "glxgears no pudo iniciarse (código $rc)" 3
        tail -n 15 "$out" | sed 's/^/  /'
    fi

    local off="$TMP_DIR/glxgears-nvidia.txt"
    timeout 6 env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxgears -info >"$off" 2>&1
    rc=$?
    if [[ $rc -eq 124 || $rc -eq 0 ]]; then
        if grep -qi NVIDIA "$off"; then
            pass "glxgears mediante PRIME Offload se inició con NVIDIA"
        else
            warn "glxgears con PRIME se inició, pero no confirmó renderer NVIDIA" 2
        fi
    else
        warn "glxgears mediante PRIME Offload falló (código $rc)" 4
    fi
}

check_recommended_packages() {
    section "PAQUETES DE DIAGNÓSTICO RECOMENDADOS"

    local packages=(pciutils glx-utils vulkan-tools egl-utils egl-gbm clinfo libva-utils vdpauinfo v4l-utils mokutil switcheroo-control)
    local p
    for p in "${packages[@]}"; do
        if rpm_installed "$p"; then
            if [[ "$p" == "v4l-utils" ]]; then
                pass "$p instalado (proporciona edid-decode)"
            else
                pass "$p instalado"
            fi
        else
            info "$p no instalado"
            add_missing_package "$p"
        fi
    done
    if have ffmpeg; then
        pass "ffmpeg instalado"
    else
        info "ffmpeg no instalado (opcional; ffmpeg-free está disponible en Fedora)"
        add_missing_package "ffmpeg-free"
    fi
}

install_missing_packages() {
    (( INSTALL_MISSING )) || return 0
    section "INSTALACIÓN DE PAQUETES FALTANTES"

    if (( ${#MISSING_PACKAGES[@]} == 0 )); then
        pass "No hay paquetes de soporte o diagnóstico pendientes"
        return
    fi
    if ! have dnf; then
        fail "DNF no está disponible; no se puede instalar: ${MISSING_PACKAGES[*]}" 5
        return
    fi

    info "DNF instalará: ${MISSING_PACKAGES[*]}"
    if run_privileged dnf install "${MISSING_PACKAGES[@]}"; then
        pass "Paquetes faltantes instalados correctamente"
        refresh_missing_packages
    else
        local rc=$?
        if [[ $rc -eq 126 ]]; then
            fail "Se necesita ejecutar con sudo o disponer de sudo autenticado" 5
            printf '  Ejecuta: sudo %q --install-missing\n' "$0"
        else
            fail "DNF no pudo instalar todos los paquetes (código $rc)" 5
        fi
    fi
}

repair_driver() {
    (( REPAIR_DRIVER )) || return 0
    section "REPARACIÓN DEL DRIVER NVIDIA"

    local running_kernel
    running_kernel="$(uname -r)"

    if ! have akmods; then
        fail "akmods no está instalado. Ejecuta primero: sudo dnf install akmods akmod-nvidia" 10
        return
    fi
    if ! have dracut; then
        fail "dracut no está instalado; no se puede reconstruir el initramfs" 10
        return
    fi

    info "Reconstruyendo/verificando el módulo NVIDIA para $running_kernel"
    run_privileged akmods --force --kernels "$running_kernel"
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        if [[ $rc -eq 126 ]]; then
            fail "La reparación necesita privilegios. Ejecuta: sudo $0 --repair-driver" 10
        else
            fail "akmods falló (código $rc); no se modificará el initramfs" 15
        fi
        return
    fi
    pass "akmods completó la verificación/reconstrucción para $running_kernel"

    info "Reconstruyendo el initramfs con dracut"
    run_privileged dracut --force
    rc=$?
    if [[ $rc -eq 0 ]]; then
        pass "dracut reconstruyó el initramfs correctamente"
        warn "La reparación está preparada. Reinicia para aplicarla: sudo reboot" 0
    else
        if [[ $rc -eq 126 ]]; then
            fail "dracut necesita privilegios. Ejecuta: sudo dracut --force" 10
        else
            fail "dracut falló (código $rc)" 15
        fi
    fi
}

print_recommendations() {
    section "RECOMENDACIONES"

    local recs=()
    have glxinfo || recs+=("Para probar OpenGL/PRIME, instala: sudo dnf install glx-utils")
    have vulkaninfo || recs+=("Para diagnosticar Vulkan, instala: sudo dnf install vulkan-tools")
    have eglinfo || recs+=("Para diagnosticar EGL, instala: sudo dnf install egl-utils")
    have clinfo || recs+=("Para diagnosticar OpenCL, instala: sudo dnf install clinfo")
    rpm -q "kernel-devel-$(uname -r)" >/dev/null 2>&1 || recs+=("Instala el desarrollo del kernel actual: sudo dnf install kernel-devel-$(uname -r)")

    if (( ${#MISSING_PACKAGES[@]} > 0 )); then
        recs+=("Paquetes de soporte/diagnóstico ausentes: sudo dnf install ${MISSING_PACKAGES[*]}")
        recs+=("También puedes ejecutar este script con: sudo $0 --install-missing")
    fi

    if [[ ! -e /dev/nvidiactl || ! -e /dev/nvidia0 ]]; then
        recs+=("Faltan los dispositivos NVIDIA. Prueba: sudo nvidia-modprobe -u -c=0; luego ejecuta nvidia-smi. Si funciona, reinicia y revisa udev si vuelven a faltar.")
    elif have nvidia-smi && ! nvidia-smi >/dev/null 2>&1; then
        recs+=("Los módulos cargan, pero nvidia-smi falla. Ejecuta: sudo $0 --repair-driver; después reinicia.")
    fi

    if journalctl -b --no-pager -k 2>/dev/null | grep -Eqi 'nvidia.*cannot find any crtc'; then
        recs+=("El kernel informó 'Cannot find any crtc or sizes': la GPU NVIDIA no pudo registrar sus salidas. Confirma KMS con: sudo cat /sys/module/nvidia_drm/parameters/modeset (debe mostrar Y).")
        recs+=("Si muestra N: sudo grubby --update-kernel=ALL --args='nvidia-drm.modeset=1' y reinicia.")
    fi

    if (( ${#recs[@]} == 0 )); then
        pass "No hay recomendaciones adicionales derivadas de las herramientas disponibles"
    else
        local r
        for r in "${recs[@]}"; do
            printf '  - %s\n' "$r"
        done
    fi
}

print_summary() {
    section "RESUMEN FINAL"

    local grade
    if (( SCORE >= 95 )); then
        grade="Excelente"
    elif (( SCORE >= 85 )); then
        grade="Muy bueno"
    elif (( SCORE >= 70 )); then
        grade="Aceptable"
    elif (( SCORE >= 50 )); then
        grade="Requiere atención"
    else
        grade="Crítico"
    fi

    printf 'Puntuación: %s%d/100%s — %s\n' "$C_BOLD" "$SCORE" "$C_RESET" "$grade"
    printf 'Correcto: %d | Advertencias: %d | Fallos: %d | Información: %d\n' "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT" "$INFO_COUNT"

    if (( FAIL_COUNT > 0 )); then
        printf '%b Se detectaron %d fallos. Revisa primero los elementos marcados como FAIL.\n' "$FAIL" "$FAIL_COUNT"
    elif (( WARN_COUNT > 0 )); then
        printf '%b El driver parece funcional, con advertencias o componentes opcionales pendientes.\n' "$WARN"
    else
        printf '%b No se detectaron problemas en las comprobaciones ejecutadas.\n' "$PASS"
    fi

    printf '\nNota: la puntuación es orientativa. Una advertencia por herramientas opcionales no implica un fallo del driver.\n'
}

main() {
    parse_args "$@"
    if (( SHOW_MENU )); then
        interactive_menu
        return
    fi
    print_header
    collect_nvidia_pci
    check_system
    check_gpu_detection
    check_kernel_modules
    check_nvidia_smi
    check_version_consistency

    case "$ACTION" in
        quick)
            check_secure_boot_and_signatures
            check_prime
            check_hdmi_outputs
            check_wayland
            check_journal
            check_libraries
            ;;
        hdmi)
            check_secure_boot_and_signatures
            check_hdmi_outputs
            check_hdmi_details
            check_wayland
            check_journal
            ;;
        multimedia)
            check_graphics_apis
            check_prime
            check_cuda
            check_video_acceleration
            test_nvenc_functional
            check_libraries
            check_journal
            ;;
        stability)
            check_prime
            test_stability
            check_gsp_and_pcie
            check_journal
            ;;
        full)
            check_packages_and_build
            check_secure_boot_and_signatures
            check_graphics_apis
            check_prime
            check_hdmi_outputs
            check_hdmi_details
            check_cuda
            check_video_acceleration
            test_nvenc_functional
            check_gsp_and_pcie
            check_services
            check_wayland
            check_journal
            check_libraries
            check_updates
            check_benchmark
            check_recommended_packages
            ;;
        *)
            fail "Perfil de diagnóstico desconocido: $ACTION" 10
            ;;
    esac

    install_missing_packages
    repair_driver
    print_recommendations
    print_summary
}

main "$@"
