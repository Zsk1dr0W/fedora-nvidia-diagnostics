# Diagnóstico NVIDIA para Fedora

<p align="center">
  <a href="https://fedoraproject.org/" title="Fedora Project">
    <img src="https://cdn.simpleicons.org/fedora/51A2DA" alt="Fedora" width="110" height="110">
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://www.nvidia.com/" title="NVIDIA">
    <img src="https://cdn.simpleicons.org/nvidia/76B900" alt="NVIDIA" width="110" height="110">
  </a>
</p>

<p align="center"><strong>Fedora + NVIDIA</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/versión-1.5.1-51A2DA?style=for-the-badge" alt="Versión 1.5.1">
  <img src="https://img.shields.io/badge/Fedora-44-51A2DA?style=for-the-badge&logo=fedora&logoColor=white" alt="Fedora 44">
  <img src="https://img.shields.io/badge/NVIDIA-compatible-76B900?style=for-the-badge&logo=nvidia&logoColor=white" alt="NVIDIA compatible">
  <img src="https://img.shields.io/badge/Bash-script-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/licencia-Apache--2.0-D22128?style=for-the-badge" alt="Licencia Apache 2.0">
</p>

<p align="center">
  <a href="#espanol">🇨🇱 Español</a> ·
  <a href="#english">🇬🇧 English</a>
</p>

---

<a id="espanol"></a>
## 🇨🇱 Español

Script interactivo para comprobar la instalación y el funcionamiento del driver NVIDIA en Fedora, incluidas las salidas HDMI/DisplayPort. Ha sido desarrollado y probado en un portátil con gráficos híbridos **Intel + NVIDIA**.

> [!NOTE]
> El script puede detectar configuraciones **AMD + NVIDIA**, pero ese tipo de equipo aún no ha sido probado ni validado. No se garantiza que todas las comprobaciones o acciones de reparación se comporten igual que en Intel + NVIDIA.

### 🧪 Hardware de referencia probado

Esta es la configuración utilizada durante el desarrollo y las pruebas. No representa un requisito mínimo.

| Componente | Configuración validada |
|---|---|
| 💻 Equipo | HP ENVY Laptop 16-h1xxx |
| 🧠 Procesador | Intel Core i9-13900H de 13.ª generación |
| 🎨 GPU integrada | Intel Iris Xe Graphics (Raptor Lake-P), driver `i915` |
| 🎮 GPU dedicada | NVIDIA GeForce RTX 4060 Laptop GPU / AD107M, driver `nvidia` |
| 🧩 Driver NVIDIA probado | `610.43.03` desde RPM Fusion |
| 🧮 Memoria | 32 GB de RAM |
| 🐧 Sistema | Fedora Linux 44 Workstation, arquitectura `x86_64` |
| ⚙️ Kernel probado | `7.1.3-201.fc44.x86_64` |
| 🪟 Escritorio | GNOME sobre Wayland |
| 💻 Pantalla interna | eDP conectado a Intel `i915` |
| 🖥️ Salida externa | HDMI conectado directamente a NVIDIA |
| 🖥️ Monitor HDMI probado | HP Z24n G3, 1920×1200 a 60 Hz |

> [!NOTE]
> El kernel y el driver NVIDIA evolucionan con las actualizaciones de Fedora. La tabla documenta la configuración en la que se validó esta versión, no limita el script exclusivamente a esas versiones.

### ✅ Estado de validación de v1.5.1

La versión actual obtuvo **100/100** en el diagnóstico completo del equipo de referencia:

- HDMI NVIDIA conectado, con EDID válido e identificación del monitor.
- OpenGL y Vulkan mediante PRIME Render Offload.
- EGL, OpenCL, VA-API y VDPAU operativos.
- NVENC validado codificando 60 fotogramas H.264 a 720p.
- Secure Boot activo y módulo NVIDIA correctamente firmado.
- Versiones coincidentes entre módulo, `nvidia-smi`, paquete de usuario y KMOD.
- Sin errores NVIDIA Xid ni fallos DRM graves durante el arranque validado.

Desarrollado por **Víctor Díaz González**.

Fedora y el logotipo de Fedora son marcas del Fedora Project. NVIDIA y el logotipo de NVIDIA son marcas de NVIDIA Corporation. Este proyecto comunitario no está afiliado ni respaldado oficialmente por dichas organizaciones.

> [!IMPORTANT]
> **Aviso sobre NVIDIA:** los controladores, CUDA, bibliotecas, firmware, marcas y demás software de NVIDIA pertenecen a NVIDIA Corporation y se distribuyen bajo sus propios términos. Este repositorio no contiene ni redistribuye software de NVIDIA. Es una utilidad comunitaria e independiente que únicamente ayuda a diagnosticar, instalar mediante los repositorios configurados y comprobar el funcionamiento del driver NVIDIA en Fedora.

> [!TIP]
> Ejecuta `./check-nvidia-fedora.sh`, elige una opción y deja que el asistente haga el resto.

### ✨ Vista rápida

| Área | Comprobaciones |
|---|---|
| 🧩 Driver | Módulos, versiones, AKMOD/KMOD y `nvidia-smi` |
| 🖥️ Pantallas | HDMI, DisplayPort, DRM, KMS y framebuffer |
| 🚀 Aceleración | OpenGL, EGL, Vulkan, OpenCL y PRIME |
| 🔊 Multimedia | Audio HDMI, PipeWire, NVENC, NVDEC, VA-API y VDPAU |
| 🔐 Seguridad | Secure Boot, firma del módulo y conflictos con Nouveau |
| 🛠️ Reparación | Paquetes faltantes, AKMODS y reconstrucción del initramfs |

### 🧭 Perfiles de prueba

| Perfil | Alcance | Duración aproximada |
|---|---|:---:|
| ⚡ Rápido | Driver, versiones, PRIME, HDMI, KMS y errores | Segundos |
| 🔎 Completo | Todas las comprobaciones disponibles | Menos de 2 minutos |
| 🖥️ HDMI/audio | Conectores, EDID, enlace DRM, PipeWire y ALSA ELD | Segundos |
| 🎞️ Multimedia | APIs gráficas, vídeo y codificación NVENC real | Segundos |
| 🌡️ Estabilidad | Carga PRIME, temperatura y errores Xid nuevos | 30 segundos |

> [!CAUTION]
> La prueba de estabilidad aumenta temporalmente el uso, consumo y temperatura de la GPU. Solo se ejecuta al elegirla explícitamente.

### 📋 Contenido

- [Funciones principales](#es-funciones)
- [Requisitos](#es-requisitos)
- [Uso rápido](#es-uso)
- [Opciones](#es-opciones)
- [Reparación de HDMI](#es-reparacion)
- [Paquetes EGL/GBM](#es-paquetes)
- [Interpretación](#es-resultados)
- [Seguridad](#es-seguridad)
- [Licencia](#es-licencia)

<a id="es-funciones"></a>
### 🔍 Funciones principales

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

<a id="es-requisitos"></a>
### 📦 Requisitos

- Fedora; desarrollado y probado principalmente con Fedora 44.
- Configuración validada: portátil con GPU integrada Intel y GPU dedicada NVIDIA.
- AMD + NVIDIA: detección disponible, pero sin validación práctica por el momento.
- Bash, RPM, DNF, systemd y las herramientas habituales del sistema.
- Hardware NVIDIA para las comprobaciones específicas del driver.
- `sudo` solo para instalar, reparar o cuando se autorice expresamente `--allow-sudo-read`.

El diagnóstico básico es de solo lectura. Las operaciones que modifican el sistema se ejecutan únicamente al elegirlas en el menú o mediante sus opciones explícitas.

<a id="es-uso"></a>
### 🚀 Uso rápido

Otorga permiso de ejecución si fuera necesario:

```bash
chmod +x check-nvidia-fedora.sh
```

Abre el menú interactivo:

```bash
./check-nvidia-fedora.sh
```

#### Menú interactivo

| Opción | Acción | ¿Modifica el sistema? |
|:---:|---|:---:|
| `1` | Diagnóstico rápido | No |
| `2` | Diagnóstico completo | No |
| `3` | Prueba HDMI/DisplayPort y audio | No |
| `4` | Prueba gráfica y multimedia NVIDIA | No |
| `5` | Prueba de estabilidad de 30 segundos | No¹ |
| `6` | Instalar paquetes faltantes | Sí |
| `7` | Reparar módulo NVIDIA e initramfs | Sí |
| `8` | Instalar faltantes y reparar | Sí |
| `9` | Mostrar ayuda | No |
| `0` | Salir | No |

¹ No cambia la configuración, pero genera carga temporal en la GPU.

<a id="es-opciones"></a>
### ⌨️ Opciones de línea de comandos

```text
--menu             Abre el menú interactivo.
--diagnose         Ejecuta el diagnóstico completo.
--quick            Ejecuta el diagnóstico rápido.
--hdmi-test        Prueba HDMI/DP, EDID y audio.
--multimedia-test  Prueba APIs gráficas y codificación NVENC real.
--stability-test   Ejecuta una carga vigilada durante 30 segundos.
--install-missing  Instala mediante DNF los paquetes detectados como ausentes.
--repair-driver    Reconstruye NVIDIA para el kernel activo y el initramfs.
--yes              Autoriza una acción mutable sin confirmación interactiva.
--include-identifiers
                   Incluye usuario, host, UUID de GPU y huella EDID.
--allow-sudo-read  Autoriza sudo para leer parámetros protegidos.
-h, --help         Muestra la ayuda.
```

Ejemplos:

```bash
./check-nvidia-fedora.sh --diagnose
./check-nvidia-fedora.sh --quick
./check-nvidia-fedora.sh --hdmi-test
./check-nvidia-fedora.sh --multimedia-test
./check-nvidia-fedora.sh --stability-test
./check-nvidia-fedora.sh --menu
./check-nvidia-fedora.sh --install-missing
./check-nvidia-fedora.sh --repair-driver
./check-nvidia-fedora.sh --install-missing --repair-driver
```

El diagnóstico no solicita `sudo` por defecto. Instalar o reparar requiere escribir `INSTALAR` o `REPARAR`; `--yes` está destinado exclusivamente a automatización consciente.

<a id="es-reparacion"></a>
### 🔧 Reparación del driver e HDMI

> [!IMPORTANT]
> Guarda tu trabajo antes de reparar. El script no reinicia el equipo automáticamente.

La opción `--repair-driver` automatiza la solución que suele ser necesaria cuando el módulo está instalado, pero NVIDIA DRM no registra las salidas externas:

```bash
sudo akmods --force --kernels "$(uname -r)"
sudo dracut --force --kver "$(uname -r)"
```

Primero valida Fedora, NVIDIA, `kernel-devel`, espacio libre y herramientas. Después guarda una copia fechada del initramfs, ejecuta AKMODS y solo si termina correctamente reconstruye el initramfs del kernel activo. La copia se conserva para recuperación y el script nunca reinicia automáticamente.

```bash
sudo reboot
```

Un HDMI NVIDIA operativo debería aparecer como `connected` en un conector similar a:

```text
/sys/class/drm/card0-HDMI-A-2/status
```

La numeración de la tarjeta y el conector puede cambiar entre equipos o arranques.

<a id="es-paquetes"></a>
### 🧱 Paquetes NVIDIA y EGL/GBM

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

En Fedora 44, `edid-decode` pertenece al paquete `v4l-utils`:

```bash
sudo dnf install v4l-utils
rpm -qf "$(command -v edid-decode)"
```

No se recomienda mezclar paquetes de Fedora estable con Rawhide para resolver una biblioteca ausente.

<a id="es-resultados"></a>
### 🚦 Interpretación del resultado

| Estado | Significado |
|:---:|---|
| ✅ `[OK]` | Comprobación satisfactoria |
| ⚠️ `[WARN]` | Elemento opcional o condición que merece revisión |
| ❌ `[FAIL]` | Fallo que puede impedir una característica esencial |
| ℹ️ `[INFO]` | Información que no reduce la evaluación |

La puntuación final es orientativa. La evidencia concreta de cada sección es más importante que la cifra total.

<a id="es-seguridad"></a>
### 🛡️ Seguridad y alcance

> [!CAUTION]
> El software se entrega **sin garantías**, conforme a Apache-2.0. Ningún script puede eliminar todo riesgo derivado de fallos de energía, firmware, repositorios de terceros o diferencias entre equipos. Revisa la vista previa, conserva copias de seguridad y no ejecutes las acciones mutables si no comprendes su alcance.

- El diagnóstico no elimina paquetes ni modifica la configuración.
- Los identificadores se ocultan por defecto; `--include-identifiers` permite incluirlos conscientemente.
- El diagnóstico no eleva privilegios salvo con `--allow-sudo-read`.
- Los parámetros KMS protegidos se muestran como información, no como fallos del driver.
- La instalación muestra paquetes/proveedores y exige confirmación explícita antes de DNF.
- La reparación valida el entorno, comprueba espacio y conserva una copia del initramfs.
- La prueba de estabilidad se detiene ante un Xid nuevo o al alcanzar 95 °C.
- El script no instala CUDA Toolkit automáticamente.
- Antes de reparar, conviene guardar el trabajo y cerrar aplicaciones importantes.

Consulta la [política de seguridad](SECURITY.md) y las [reglas de contribución](CONTRIBUTING.md).

### 📁 Archivos

- `check-nvidia-fedora.sh`: versión completa e interactiva recomendada.

<a id="es-licencia"></a>
### ⚖️ Licencia

Código publicado bajo [Apache License 2.0](LICENSE). Deben conservarse los avisos de copyright, licencia y el archivo [NOTICE](NOTICE). NVIDIA conserva todos los derechos sobre sus productos; este repositorio no contiene ni redistribuye sus controladores o software.

---

<a id="english"></a>
## 🇬🇧 English

### NVIDIA Diagnostics for Fedora

Interactive script for checking NVIDIA driver installation and operation on Fedora, including HDMI/DisplayPort outputs. It was developed and tested on a laptop with **Intel + NVIDIA** hybrid graphics.

> [!NOTE]
> The script can detect **AMD + NVIDIA** configurations, but that type of system has not yet been tested or validated. Not every check or repair action is guaranteed to behave exactly as it does on Intel + NVIDIA systems.

### 🧪 Tested reference hardware

This is the configuration used during development and testing. It is not a minimum requirement.

| Component | Validated configuration |
|---|---|
| 💻 Computer | HP ENVY Laptop 16-h1xxx |
| 🧠 Processor | 13th Gen Intel Core i9-13900H |
| 🎨 Integrated GPU | Intel Iris Xe Graphics (Raptor Lake-P), `i915` driver |
| 🎮 Dedicated GPU | NVIDIA GeForce RTX 4060 Laptop GPU / AD107M, `nvidia` driver |
| 🧩 Tested NVIDIA driver | `610.43.03` from RPM Fusion |
| 🧮 Memory | 32 GB RAM |
| 🐧 System | Fedora Linux 44 Workstation, `x86_64` architecture |
| ⚙️ Tested kernel | `7.1.3-201.fc44.x86_64` |
| 🪟 Desktop | GNOME on Wayland |
| 💻 Internal display | eDP connected to Intel `i915` |
| 🖥️ External output | HDMI directly connected to NVIDIA |
| 🖥️ Tested HDMI monitor | HP Z24n G3, 1920×1200 at 60 Hz |

> [!NOTE]
> Fedora updates continuously change the kernel and NVIDIA driver. This table records the configuration used to validate this version; it does not restrict the script to those exact versions.

### ✅ v1.5.1 validation status

The current version scored **100/100** in the complete diagnostic on the reference system:

- NVIDIA HDMI connected with valid EDID and monitor identification.
- OpenGL and Vulkan through PRIME Render Offload.
- Working EGL, OpenCL, VA-API, and VDPAU.
- NVENC validated by encoding 60 H.264 frames at 720p.
- Secure Boot enabled with a correctly signed NVIDIA module.
- Matching module, `nvidia-smi`, user-space package, and KMOD versions.
- No NVIDIA Xid errors or serious DRM failures during the validated boot.

Developed by **Víctor Díaz González**.

Fedora and the Fedora logo are trademarks of the Fedora Project. NVIDIA and the NVIDIA logo are trademarks of NVIDIA Corporation. This community project is not officially affiliated with or endorsed by either organization.

> [!IMPORTANT]
> **NVIDIA notice:** NVIDIA drivers, CUDA, libraries, firmware, trademarks, and other NVIDIA software belong to NVIDIA Corporation and are distributed under their own terms. This repository does not contain or redistribute NVIDIA software. It is an independent community utility that only helps diagnose, install through configured repositories, and verify NVIDIA driver operation on Fedora.

> [!TIP]
> Run `./check-nvidia-fedora.sh`, select an option, and let the assistant handle the rest.

### ✨ At a glance

| Area | Checks |
|---|---|
| 🧩 Driver | Modules, versions, AKMOD/KMOD, and `nvidia-smi` |
| 🖥️ Displays | HDMI, DisplayPort, DRM, KMS, and framebuffer |
| 🚀 Acceleration | OpenGL, EGL, Vulkan, OpenCL, and PRIME |
| 🔊 Multimedia | HDMI audio, PipeWire, NVENC, NVDEC, VA-API, and VDPAU |
| 🔐 Security | Secure Boot, module signature, and Nouveau conflicts |
| 🛠️ Repair | Missing packages, AKMODS, and initramfs rebuilding |

### 🧭 Test profiles

| Profile | Scope | Approximate duration |
|---|---|:---:|
| ⚡ Quick | Driver, versions, PRIME, HDMI, KMS, and errors | Seconds |
| 🔎 Complete | Every available check | Under 2 minutes |
| 🖥️ HDMI/audio | Connectors, EDID, DRM link, PipeWire, and ALSA ELD | Seconds |
| 🎞️ Multimedia | Graphics APIs, video, and real NVENC encoding | Seconds |
| 🌡️ Stability | PRIME load, temperature, and new Xid errors | 30 seconds |

> [!CAUTION]
> The stability test temporarily increases GPU utilization, power usage, and temperature. It only runs when explicitly selected.

### 📋 Contents

- [Main features](#en-features)
- [Requirements](#en-requirements)
- [Quick start](#en-quick-start)
- [Options](#en-options)
- [HDMI repair](#en-repair)
- [EGL/GBM packages](#en-packages)
- [Understanding results](#en-results)
- [Safety](#en-safety)
- [License](#en-license)

<a id="en-features"></a>
### 🔍 Main features

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

<a id="en-requirements"></a>
### 📦 Requirements

- Fedora; primarily developed and tested on Fedora 44.
- Validated configuration: laptop with an integrated Intel GPU and a dedicated NVIDIA GPU.
- AMD + NVIDIA: detection is available, but practical validation has not yet been performed.
- Bash, RPM, DNF, systemd, and standard system utilities.
- NVIDIA hardware for driver-specific checks.
- `sudo` only for installation, repair, or explicitly authorized `--allow-sudo-read` checks.

The basic diagnostic mode is read-only. System-changing operations only run when explicitly selected from the menu or requested through a command-line option.

<a id="en-quick-start"></a>
### 🚀 Quick start

Make the script executable if necessary:

```bash
chmod +x check-nvidia-fedora.sh
```

Open the interactive menu:

```bash
./check-nvidia-fedora.sh
```

#### Interactive menu

| Option | Action | Changes the system? |
|:---:|---|:---:|
| `1` | Quick diagnostic | No |
| `2` | Complete diagnostic | No |
| `3` | HDMI/DisplayPort and audio test | No |
| `4` | NVIDIA graphics and multimedia test | No |
| `5` | 30-second stability test | No¹ |
| `6` | Install missing packages | Yes |
| `7` | Repair NVIDIA module and initramfs | Yes |
| `8` | Install missing packages and repair | Yes |
| `9` | Display help | No |
| `0` | Exit | No |

¹ It does not change configuration, but it temporarily loads the GPU.

<a id="en-options"></a>
### ⌨️ Command-line options

```text
--menu             Open the interactive menu.
--diagnose         Run the complete diagnostic.
--quick            Run the quick diagnostic.
--hdmi-test        Test HDMI/DP, EDID, and audio.
--multimedia-test  Test graphics APIs and real NVENC encoding.
--stability-test   Run a monitored load for 30 seconds.
--install-missing  Install packages detected as missing through DNF.
--repair-driver    Rebuild NVIDIA for the active kernel and rebuild initramfs.
--yes              Authorize a mutating action without an interactive prompt.
--include-identifiers
                   Include user, host, GPU UUID, and EDID fingerprint.
--allow-sudo-read  Authorize sudo for reading protected parameters.
-h, --help         Display help.
```

Examples:

```bash
./check-nvidia-fedora.sh --diagnose
./check-nvidia-fedora.sh --quick
./check-nvidia-fedora.sh --hdmi-test
./check-nvidia-fedora.sh --multimedia-test
./check-nvidia-fedora.sh --stability-test
./check-nvidia-fedora.sh --menu
./check-nvidia-fedora.sh --install-missing
./check-nvidia-fedora.sh --repair-driver
./check-nvidia-fedora.sh --install-missing --repair-driver
```

Diagnostics do not request `sudo` by default. Installation and repair require typing `INSTALAR` or `REPARAR`; `--yes` is intended only for deliberate automation.

<a id="en-repair"></a>
### 🔧 Driver and HDMI repair

> [!IMPORTANT]
> Save your work before running a repair. The script never reboots automatically.

The `--repair-driver` option automates the usual recovery procedure when the module is installed but NVIDIA DRM does not register external outputs:

```bash
sudo akmods --force --kernels "$(uname -r)"
sudo dracut --force --kver "$(uname -r)"
```

The script first validates Fedora, NVIDIA hardware, `kernel-devel`, free space, and required tools. It then keeps a timestamped initramfs backup, runs AKMODS, and rebuilds only the active kernel initramfs after AKMODS succeeds. The backup remains available for recovery, and the script never reboots automatically.

```bash
sudo reboot
```

An operational NVIDIA HDMI output should report `connected` in a connector similar to:

```text
/sys/class/drm/card0-HDMI-A-2/status
```

Card and connector numbering can differ between computers and boots.

<a id="en-packages"></a>
### 🧱 NVIDIA and EGL/GBM packages

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

On Fedora 44, `edid-decode` is provided by the `v4l-utils` package:

```bash
sudo dnf install v4l-utils
rpm -qf "$(command -v edid-decode)"
```

Mixing stable Fedora packages with Rawhide packages to resolve a missing library is not recommended.

<a id="en-results"></a>
### 🚦 Understanding the results

| Status | Meaning |
|:---:|---|
| ✅ `[OK]` | The check passed |
| ⚠️ `[WARN]` | Optional component or a condition worth reviewing |
| ❌ `[FAIL]` | A problem that may prevent an essential feature from working |
| ℹ️ `[INFO]` | Information that does not lower the score |

The final score is only a guideline. The concrete evidence in each section is more important than the numeric score.

<a id="en-safety"></a>
### 🛡️ Safety and scope

> [!CAUTION]
> This software is provided **without warranties** under Apache-2.0. No script can remove every risk arising from power loss, firmware, third-party repositories, or hardware differences. Review the preview, keep current backups, and do not run mutating actions unless you understand their scope.

- Diagnostic mode does not remove packages or modify configuration.
- Identifiers are hidden by default and require `--include-identifiers` to be printed.
- Diagnostics do not elevate privileges unless `--allow-sudo-read` is supplied.
- Protected KMS parameters are reported as information, not as driver failures.
- Installation previews packages/providers and requires explicit confirmation before DNF.
- Repair validates its environment, checks free space, and preserves an initramfs backup.
- The stability test stops on a new Xid or at 95 °C.
- The script never installs the CUDA Toolkit automatically.
- Save your work and close important applications before running a repair.

See the [security policy](SECURITY.md) and [contribution guide](CONTRIBUTING.md).

### 📁 Files

- `check-nvidia-fedora.sh`: recommended complete interactive version.

<a id="en-license"></a>
### ⚖️ License

Code released under the [Apache License 2.0](LICENSE). Copyright, license notices, and [NOTICE](NOTICE) must be preserved. NVIDIA retains all rights to its products; this repository does not contain or redistribute NVIDIA drivers or software.
