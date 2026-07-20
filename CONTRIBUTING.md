# 🤝 Contribuir · Contributing

<p align="center">
  <img src="https://img.shields.io/badge/contribuciones-bienvenidas-76B900?style=for-the-badge" alt="Contribuciones bienvenidas">
  <img src="https://img.shields.io/badge/licencia-Apache--2.0-D22128?style=for-the-badge" alt="Apache 2.0">
  <img src="https://img.shields.io/badge/plataforma-Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white" alt="Fedora">
</p>

<p align="center">
  <a href="#espanol">🇨🇱 Español</a> ·
  <a href="#english">🇬🇧 English</a> ·
  <a href="README.md">🏠 README</a> ·
  <a href="SECURITY.md">🛡️ Seguridad</a>
</p>

---

<a id="espanol"></a>
## 🇨🇱 Español

Las correcciones, nuevas pruebas, documentación y mejoras de compatibilidad son bienvenidas.

### 🧭 Flujo recomendado

1. **Revisa los issues existentes.** Para cambios amplios, abre primero un issue y explica el caso de uso.
2. **Crea un cambio enfocado.** Evita combinar modificaciones no relacionadas.
3. **Protege las operaciones.** Mantén el diagnóstico de solo lectura y toda acción privilegiada detrás de validación, vista previa y confirmación.
4. **Ejecuta las comprobaciones.** Usa los comandos indicados más abajo.
5. **Documenta la prueba.** Describe Fedora, kernel y hardware sin publicar identificadores personales.
6. **Explica el resultado.** Indica qué problema resuelve y qué comportamiento cambia.

### ✅ Lista de comprobación

| Requisito | Verificación |
|---|---|
| 🧹 Sintaxis Bash | `bash -n check-nvidia-fedora.sh` |
| 🔍 Análisis estático | `shellcheck check-nvidia-fedora.sh` |
| 📝 Formato Git | `git diff --check` |
| ⚡ Diagnóstico básico | `./check-nvidia-fedora.sh --quick` |
| 🔒 Privacidad | El resultado no revela identificadores por defecto |
| 📖 Documentación | README/ayuda actualizados si cambia el uso |

> [!IMPORTANT]
> No ejecutes `--install-missing`, `--repair-driver` ni la prueba de estabilidad como parte de una validación automática sobre un equipo ajeno. Esas acciones requieren autorización consciente del propietario.

### 🛡️ Reglas de seguridad

- No incluyas controladores, firmware, bibliotecas ni contenido propietario de NVIDIA.
- No descargues ni ejecutes contenido remoto automáticamente.
- No uses `eval` ni construyas comandos a partir de datos sin validar.
- No elimines archivos fuera del directorio temporal creado por el script.
- No desactives Secure Boot, SELinux ni otras protecciones del sistema.
- No añadas instalación o reparación automática sin confirmación explícita.
- Informa vulnerabilidades mediante la [política de seguridad](SECURITY.md).

### 🧪 Información útil de prueba

Al describir una validación, resulta útil incluir:

- Modelo general del equipo y combinación de GPU, por ejemplo Intel + NVIDIA.
- Versión de Fedora, kernel y driver NVIDIA.
- Wayland o X11 y entorno de escritorio.
- Resultado del perfil utilizado y conectores probados.
- Diferencias observadas respecto del equipo de referencia.

> [!CAUTION]
> Revisa los registros antes de publicarlos. El script oculta varios identificadores por defecto, pero otras herramientas del sistema podrían mostrar UUID, hostname, usuario o rutas personales.

### ⚖️ Licencia y atribución

Al contribuir aceptas que tu aportación se licencia bajo [Apache-2.0](LICENSE), conforme a la sección 5. Conservas la autoría de tu contribución. Deben permanecer:

- Los avisos de copyright aplicables.
- `SPDX-License-Identifier: Apache-2.0` en el script.
- La atribución original a **Víctor Díaz González**.
- El archivo [NOTICE](NOTICE).

---

<a id="english"></a>
## 🇬🇧 English

Bug fixes, new tests, documentation, and compatibility improvements are welcome.

### 🧭 Recommended workflow

1. **Review existing issues.** For broad changes, open an issue first and explain the use case.
2. **Create a focused change.** Avoid combining unrelated modifications.
3. **Protect operations.** Keep diagnostics read-only and place privileged actions behind validation, preview, and confirmation.
4. **Run the checks.** Use the commands listed below.
5. **Document testing.** Describe Fedora, kernel, and hardware without publishing personal identifiers.
6. **Explain the result.** State which problem is solved and which behavior changes.

### ✅ Checklist

| Requirement | Verification |
|---|---|
| 🧹 Bash syntax | `bash -n check-nvidia-fedora.sh` |
| 🔍 Static analysis | `shellcheck check-nvidia-fedora.sh` |
| 📝 Git formatting | `git diff --check` |
| ⚡ Basic diagnostic | `./check-nvidia-fedora.sh --quick` |
| 🔒 Privacy | Output does not expose identifiers by default |
| 📖 Documentation | README/help updated when usage changes |

> [!IMPORTANT]
> Do not run `--install-missing`, `--repair-driver`, or the stability test as part of automated validation on someone else's computer. Those actions require the owner's informed authorization.

### 🛡️ Security rules

- Do not include proprietary NVIDIA drivers, firmware, libraries, or content.
- Do not automatically download or execute remote content.
- Do not use `eval` or build commands from unvalidated data.
- Do not remove files outside the temporary directory created by the script.
- Do not disable Secure Boot, SELinux, or other system protections.
- Do not add automatic installation or repair without explicit confirmation.
- Report vulnerabilities through the [security policy](SECURITY.md).

### 🧪 Useful testing information

When describing validation, it is useful to include:

- General computer model and GPU combination, such as Intel + NVIDIA.
- Fedora, kernel, and NVIDIA driver versions.
- Wayland or X11 and the desktop environment.
- Results from the selected profile and tested connectors.
- Differences from the reference hardware.

> [!CAUTION]
> Review logs before publishing them. The script hides several identifiers by default, but other system tools may expose UUIDs, hostnames, usernames, or personal paths.

### ⚖️ License and attribution

By contributing, you agree that your contribution is licensed under [Apache-2.0](LICENSE), as described in section 5. You retain authorship of your contribution. The following must remain:

- Applicable copyright notices.
- `SPDX-License-Identifier: Apache-2.0` in the script.
- Original attribution to **Víctor Díaz González**.
- The [NOTICE](NOTICE) file.
