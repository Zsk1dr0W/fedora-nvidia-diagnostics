# 🛡️ Política de seguridad · Security Policy

<p align="center">
  <img src="https://img.shields.io/badge/versión_soportada-más_reciente-51A2DA?style=for-the-badge" alt="Última versión compatible">
  <img src="https://img.shields.io/badge/reporte-privado-D22128?style=for-the-badge&logo=github" alt="Reporte privado">
  <img src="https://img.shields.io/badge/datos-redactados-76B900?style=for-the-badge" alt="Datos redactados">
</p>

<p align="center">
  <a href="#espanol">🇨🇱 Español</a> ·
  <a href="#english">🇬🇧 English</a> ·
  <a href="README.md">🏠 README</a>
</p>

---

<a id="espanol"></a>
## 🇨🇱 Español

### 📌 Versiones compatibles

| Versión | Estado |
|:---:|:---:|
| Última versión publicada | ✅ Compatible |
| Versiones anteriores | ⚠️ Sin soporte activo |

Antes de informar un problema, actualiza a la versión más reciente y confirma que todavía ocurre.

### 🔐 Informar una vulnerabilidad

> [!IMPORTANT]
> Informa las vulnerabilidades de forma privada mediante **[Security → Report a vulnerability](https://github.com/Zsk1dr0W/fedora-nvidia-diagnostics/security/advisories/new)**. No publiques detalles explotables en un issue antes de que exista una corrección.

Este canal debe utilizarse especialmente para problemas relacionados con:

- Ejecución inesperada de comandos o elevación de privilegios.
- Manipulación insegura de archivos temporales.
- Exposición de identificadores o información privada.
- Instalación de paquetes distintos de los anunciados.
- Daños potenciales al kernel, módulos o proceso de arranque.
- Pruebas de estabilidad que no se detengan de forma segura.

### 📋 Información que debe incluir el reporte

| Dato | Ejemplo o recomendación |
|---|---|
| 🏷️ Versión | Salida de `./check-nvidia-fedora.sh --help` |
| 🐧 Entorno | Versión de Fedora y kernel |
| ⌨️ Comando | Opción exacta que provocó el problema |
| 🎯 Resultado esperado | Qué debía haber sucedido |
| 🧾 Evidencia | Mensajes o registros mínimos y redactados |

> [!CAUTION]
> No adjuntes contraseñas, tokens, UUID, hostname, nombre de usuario ni registros completos sin revisarlos. Usa `--include-identifiers` solamente cuando sea imprescindible y entiendas qué datos mostrará.

### ⏱️ Proceso de respuesta

1. El autor confirmará la recepción del reporte.
2. Se evaluarán reproducibilidad, impacto y alcance.
3. Se preparará una corrección o mitigación cuando corresponda.
4. La divulgación pública se coordinará después de disponer de una solución.

No se garantiza un plazo específico de respuesta o corrección.

### ⚙️ Límites operativos

| Tipo de acción | Comportamiento |
|---|---|
| 🔎 Diagnóstico | Solo lectura y sin `sudo` por defecto |
| 📦 `--install-missing` | Modifica paquetes y exige confirmación explícita |
| 🔧 `--repair-driver` | Reconstruye módulos/initramfs y conserva una copia previa |
| 🌡️ `--stability-test` | Genera carga y se detiene ante temperatura crítica o Xid |

> [!WARNING]
> Revisa siempre la operación propuesta y conserva copias de seguridad actuales. La política de seguridad no sustituye las condiciones y limitaciones de responsabilidad de la [licencia Apache-2.0](LICENSE).

---

<a id="english"></a>
## 🇬🇧 English

### 📌 Supported versions

| Version | Status |
|:---:|:---:|
| Latest published release | ✅ Supported |
| Previous releases | ⚠️ Not actively supported |

Before reporting an issue, update to the latest release and verify that it still occurs.

### 🔐 Reporting a vulnerability

> [!IMPORTANT]
> Report vulnerabilities privately through **[Security → Report a vulnerability](https://github.com/Zsk1dr0W/fedora-nvidia-diagnostics/security/advisories/new)**. Do not publish exploitable details in an issue before a fix is available.

Use this channel especially for issues involving:

- Unexpected command execution or privilege escalation.
- Unsafe temporary-file handling.
- Disclosure of identifiers or private information.
- Installation of packages other than those displayed.
- Potential damage to the kernel, modules, or boot process.
- Stability tests that fail to stop safely.

### 📋 What to include

| Item | Example or recommendation |
|---|---|
| 🏷️ Version | Output from `./check-nvidia-fedora.sh --help` |
| 🐧 Environment | Fedora and kernel versions |
| ⌨️ Command | Exact option that triggered the issue |
| 🎯 Expected result | What should have happened |
| 🧾 Evidence | Minimal, reviewed, and redacted logs |

> [!CAUTION]
> Never attach passwords, tokens, UUIDs, hostnames, usernames, or complete unreviewed logs. Use `--include-identifiers` only when essential and when you understand which data it exposes.

### ⏱️ Response process

1. The author will acknowledge the report.
2. Reproducibility, impact, and scope will be assessed.
3. A fix or mitigation will be prepared when appropriate.
4. Public disclosure will be coordinated after a solution is available.

No fixed response or remediation time is guaranteed.

### ⚙️ Operational boundaries

| Action type | Behavior |
|---|---|
| 🔎 Diagnostics | Read-only and no `sudo` by default |
| 📦 `--install-missing` | Changes packages and requires explicit confirmation |
| 🔧 `--repair-driver` | Rebuilds modules/initramfs and keeps a prior backup |
| 🌡️ `--stability-test` | Generates load and stops on critical temperature or Xid |

> [!WARNING]
> Always review the proposed operation and maintain current backups. This policy does not replace the warranty and liability limitations in the [Apache-2.0 license](LICENSE).
