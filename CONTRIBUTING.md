# Contribuir / Contributing

## Español

Las correcciones, pruebas y mejoras son bienvenidas. Antes de enviar cambios:

1. Abre un issue para cambios amplios y explica el caso de uso.
2. Conserva los avisos de copyright, `SPDX-License-Identifier` y `NOTICE`.
3. No incluyas controladores, firmware, bibliotecas ni contenido propietario de NVIDIA.
4. Mantén el diagnóstico de solo lectura y protege toda acción privilegiada con
   validación, vista previa y confirmación explícita.
5. Ejecuta `bash -n check-nvidia-fedora.sh` y `shellcheck check-nvidia-fedora.sh`
   si ShellCheck está disponible.
6. Describe hardware y Fedora utilizados, ocultando identificadores personales.

Al contribuir aceptas que tu aportación se licencia bajo Apache-2.0 conforme a
la sección 5 de la licencia. Conservas la autoría de tu contribución; la
atribución original de Víctor Díaz González debe permanecer en el código,
licencia y `NOTICE`.

## English

Fixes, tests, and improvements are welcome. Before submitting changes:

1. Open an issue for broad changes and explain the use case.
2. Preserve copyright notices, `SPDX-License-Identifier`, and `NOTICE`.
3. Do not include proprietary NVIDIA drivers, firmware, libraries, or content.
4. Keep diagnostics read-only and protect privileged actions with validation,
   preview, and explicit confirmation.
5. Run `bash -n check-nvidia-fedora.sh` and `shellcheck check-nvidia-fedora.sh`
   when ShellCheck is available.
6. Describe tested hardware and Fedora while removing personal identifiers.

By contributing, you agree that your contribution is licensed under
Apache-2.0 as described in section 5. You retain authorship of your contribution;
the original Víctor Díaz González attribution must remain in the source,
license, and `NOTICE`.
