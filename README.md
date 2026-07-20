# Diagnóstico NVIDIA para Fedora

**Versión actual: 1.3.5**

[Español](#español) · [English](#english)

## Español

Script interactivo para comprobar la instalación y el funcionamiento del driver NVIDIA en Fedora, con atención especial a portátiles con gráficos híbridos Intel/AMD + NVIDIA y salidas HDMI/DisplayPort.

Desarrollado por **Víctor Díaz González**.

## Funciones principales

El script verifica, entre otros elementos:

- GPU NVIDIA e integrada detectadas mediante PCI.
- Módulos `nvidia`, `nvidia_modeset`, `nvidia_drm` y `nvidia_uvm`.
- Funcionamiento y telemetría de `nvidia-smi`.
- Correspondencia entre el kernel activo, `kernel-devel`, AKMOD y KMOD.
- Secure Boot y firma del módulo NVIDIA.
- KMS (`nvidia_drm.modeset`) y framebuffer (`nvidia_drm.fbdev`).
- OpenGL, EGL, Vulkan, OpenCL y PRIME Render Offload.
- Conectores HDMI/DisplayPort, GPU responsable y modos disponibles.
- Audio HDMI/DisplayPort mediante ALSA y PipeWire/WirePlumber.
- CUDA, NVENC, NVDEC, VA-API y VDPAU.
- Firmware GSP, enlace PCIe, energía y servicios relacionados.
- Errores NVIDIA relevantes del arranque actual.
- Bibliotecas NVIDIA, incluido `libnvidia-egl-gbm.so.1`.
- Paquetes de diagnóstico ausentes y actualizaciones en la caché local.

## Requisitos

- Fedora; desarrollado y probado principalmente con Fedora 44.
- Bash, RPM, DNF, systemd y las herramientas habituales del sistema.
- Hardware NVIDIA para las comprobaciones específicas del driver.
- `sudo` para instalar paquetes, reconstruir módulos o leer determinados parámetros protegidos.

El diagnóstico básico es de solo lectura. Las operaciones que modifican el sistema se ejecutan únicamente al elegirlas en el menú o mediante sus opciones explícitas.

## Uso rápido

Otorga permiso de ejecución si fuera necesario:

```bash
chmod +x check-nvidia-fedora.sh
```

Abre el menú interactivo:

```bash
./check-nvidia-fedora.sh
```

El menú permite:

1. Ejecutar el diagnóstico completo en modo de solo lectura.
2. Instalar paquetes de soporte y diagnóstico ausentes.
3. Reparar el módulo NVIDIA y reconstruir el initramfs.
4. Instalar paquetes faltantes y realizar la reparación.
5. Mostrar la ayuda.
0. Salir.

## Opciones de línea de comandos

```text
--menu             Abre el menú interactivo.
--diagnose         Ejecuta únicamente el diagnóstico.
--install-missing  Instala mediante DNF los paquetes detectados como ausentes.
--repair-driver    Reconstruye NVIDIA para el kernel activo y el initramfs.
-h, --help         Muestra la ayuda.
```

Ejemplos:

```bash
./check-nvidia-fedora.sh --diagnose
./check-nvidia-fedora.sh --menu
./check-nvidia-fedora.sh --install-missing
./check-nvidia-fedora.sh --repair-driver
./check-nvidia-fedora.sh --install-missing --repair-driver
```

El script solicita `sudo` cuando una operación lo necesita. No es necesario iniciar todo el menú como `root`.

## Reparación del driver e HDMI

La opción `--repair-driver` automatiza la solución que suele ser necesaria cuando el módulo está instalado, pero NVIDIA DRM no registra las salidas externas:

```bash
sudo akmods --force --kernels "$(uname -r)"
sudo dracut --force
```

Primero ejecuta AKMODS. Solo si termina correctamente reconstruye el initramfs con Dracut. El script no reinicia automáticamente; al finalizar indicará que se debe ejecutar:

```bash
sudo reboot
```

Un HDMI NVIDIA operativo debería aparecer como `connected` en un conector similar a:

```text
/sys/class/drm/card0-HDMI-A-2/status
```

La numeración de la tarjeta y el conector puede cambiar entre equipos o arranques.

## Paquetes NVIDIA y EGL/GBM

Una instalación habitual del driver desde RPM Fusion puede incluir:

```bash
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia egl-gbm libva-nvidia-driver
```

El paquete `xorg-x11-drv-nvidia-cuda` añade herramientas y componentes de CUDA/NVIDIA, pero CUDA Toolkit no es necesario para utilizar HDMI.

En Fedora, el archivo `libnvidia-egl-gbm.so.1` pertenece al paquete `egl-gbm`; el nombre del paquete no coincide exactamente con el de la biblioteca:

```bash
rpm -q egl-gbm
rpm -qf /usr/lib64/libnvidia-egl-gbm.so.1
```

No se recomienda mezclar paquetes de Fedora estable con Rawhide para resolver una biblioteca ausente.

## Interpretación del resultado

- `[OK]`: comprobación satisfactoria.
- `[WARN]`: elemento opcional, información incompleta o condición que merece revisión.
- `[FAIL]`: fallo que puede impedir el funcionamiento del driver o de una característica esencial.
- `[INFO]`: dato informativo que no reduce la evaluación.

La puntuación final es orientativa. La evidencia concreta de cada sección es más importante que la cifra total.

## Seguridad y alcance

- El diagnóstico no elimina paquetes ni modifica la configuración.
- La instalación usa DNF y muestra la transacción antes de confirmarla.
- La reparación modifica módulos generados e initramfs, pero no reinicia automáticamente.
- El script no instala CUDA Toolkit automáticamente.
- Antes de reparar, conviene guardar el trabajo y cerrar aplicaciones importantes.

## Archivos

- `check-nvidia-fedora.sh`: versión completa e interactiva recomendada.
- `check-nvidia.sh`: diagnóstico básico anterior, conservado como referencia.

---

## English

# NVIDIA Diagnostics for Fedora

Interactive script for checking NVIDIA driver installation and operation on Fedora, with special attention to Intel/AMD + NVIDIA hybrid laptops and HDMI/DisplayPort outputs.

Developed by **Víctor Díaz González**.

## Main features

The script checks, among other components:

- NVIDIA and integrated GPUs detected through PCI.
- The `nvidia`, `nvidia_modeset`, `nvidia_drm`, and `nvidia_uvm` modules.
- `nvidia-smi` operation and telemetry.
- Matching active kernel, `kernel-devel`, AKMOD, and KMOD packages.
- Secure Boot status and NVIDIA module signature.
- KMS (`nvidia_drm.modeset`) and framebuffer (`nvidia_drm.fbdev`).
- OpenGL, EGL, Vulkan, OpenCL, and PRIME Render Offload.
- HDMI/DisplayPort connectors, controlling GPU, and available modes.
- HDMI/DisplayPort audio through ALSA and PipeWire/WirePlumber.
- CUDA, NVENC, NVDEC, VA-API, and VDPAU.
- GSP firmware, PCIe link, power status, and related services.
- Relevant NVIDIA errors from the current boot.
- NVIDIA libraries, including `libnvidia-egl-gbm.so.1`.
- Missing diagnostic packages and cached updates.

## Requirements

- Fedora; primarily developed and tested on Fedora 44.
- Bash, RPM, DNF, systemd, and standard system utilities.
- NVIDIA hardware for driver-specific checks.
- `sudo` for package installation, module rebuilding, and protected parameters.

The basic diagnostic mode is read-only. System-changing operations only run when explicitly selected from the menu or requested through a command-line option.

## Quick start

Make the script executable if necessary:

```bash
chmod +x check-nvidia-fedora.sh
```

Open the interactive menu:

```bash
./check-nvidia-fedora.sh
```

The menu provides these actions:

1. Run the complete read-only diagnostic.
2. Install missing support and diagnostic packages.
3. Repair the NVIDIA module and rebuild the initramfs.
4. Install missing packages and perform the repair.
5. Display help.
0. Exit.

## Command-line options

```text
--menu             Open the interactive menu.
--diagnose         Run only the diagnostic.
--install-missing  Install packages detected as missing through DNF.
--repair-driver    Rebuild NVIDIA for the active kernel and rebuild initramfs.
-h, --help         Display help.
```

Examples:

```bash
./check-nvidia-fedora.sh --diagnose
./check-nvidia-fedora.sh --menu
./check-nvidia-fedora.sh --install-missing
./check-nvidia-fedora.sh --repair-driver
./check-nvidia-fedora.sh --install-missing --repair-driver
```

The script requests `sudo` only when required. The complete menu does not need to be started as `root`.

## Driver and HDMI repair

The `--repair-driver` option automates the usual recovery procedure when the module is installed but NVIDIA DRM does not register external outputs:

```bash
sudo akmods --force --kernels "$(uname -r)"
sudo dracut --force
```

AKMODS runs first. The initramfs is rebuilt only when AKMODS completes successfully. The script does not reboot automatically; when finished, it instructs the user to run:

```bash
sudo reboot
```

An operational NVIDIA HDMI output should report `connected` in a connector similar to:

```text
/sys/class/drm/card0-HDMI-A-2/status
```

Card and connector numbering can differ between computers and boots.

## NVIDIA and EGL/GBM packages

A typical RPM Fusion driver installation may include:

```bash
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia egl-gbm libva-nvidia-driver
```

The `xorg-x11-drv-nvidia-cuda` package adds NVIDIA/CUDA tools and components, but the CUDA Toolkit is not required for HDMI operation.

On Fedora, `libnvidia-egl-gbm.so.1` is supplied by the `egl-gbm` package:

```bash
rpm -q egl-gbm
rpm -qf /usr/lib64/libnvidia-egl-gbm.so.1
```

Mixing stable Fedora packages with Rawhide packages to resolve a missing library is not recommended.

## Understanding the results

- `[OK]`: the check passed.
- `[WARN]`: optional component, incomplete information, or a condition worth reviewing.
- `[FAIL]`: a problem that may prevent the driver or an essential feature from working.
- `[INFO]`: informational data that does not lower the score.

The final score is only a guideline. The concrete evidence in each section is more important than the numeric score.

## Safety and scope

- Diagnostic mode does not remove packages or modify configuration.
- Installation uses DNF and displays the transaction before confirmation.
- Repair mode changes generated modules and initramfs but does not reboot automatically.
- The script never installs the CUDA Toolkit automatically.
- Save your work and close important applications before running a repair.

## Files

- `check-nvidia-fedora.sh`: recommended complete interactive version.
- `check-nvidia.sh`: earlier basic diagnostic retained for reference.
