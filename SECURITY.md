# Política de seguridad / Security Policy

## Español

Se mantiene la versión más reciente publicada. Antes de informar un problema,
actualiza a esa versión y confirma que todavía ocurre.

Para vulnerabilidades, especialmente ejecución de comandos, elevación de
privilegios, archivos temporales, exposición de datos o daños al arranque, usa
de forma privada **Security → Report a vulnerability** en GitHub. No publiques
detalles explotables en un issue antes de que exista una corrección.

Incluye versión, Fedora/kernel, comando usado, resultado esperado y evidencia
redactada. No adjuntes contraseñas, tokens, UUID, nombres de host ni registros
sin revisarlos. El autor acusará recibo y evaluará impacto y solución; no se
garantiza un plazo específico.

Las opciones de diagnóstico son de solo lectura. `--install-missing` y
`--repair-driver` modifican el sistema y requieren confirmación explícita.
Revisa siempre la transacción propuesta y mantén copias de seguridad actuales.

## English

Only the latest published version is supported. Update first and verify that
the issue still occurs.

For vulnerabilities—especially command execution, privilege escalation,
temporary files, information disclosure, or boot damage—privately use
**Security → Report a vulnerability** on GitHub. Do not publish exploitable
details in an issue before a fix is available.

Include the version, Fedora/kernel, command, expected result, and redacted
evidence. Never attach passwords, tokens, UUIDs, hostnames, or unreviewed logs.
The author will acknowledge and assess the report, but no fixed response time
is guaranteed.

Diagnostic options are read-only. `--install-missing` and `--repair-driver`
change the system and require explicit confirmation. Always review proposed
transactions and maintain current backups.
