# DOCUMENTO DE TRASPASO: Cognitive Ether (iOS)

Este documento contiene toda la información técnica, credenciales e instrucciones necesarias para continuar el desarrollo de la aplicación **Cognitive Ether** en cualquier otro entorno o IA.

## 1. Información del Proyecto
- **Nombre:** Cognitive Ether
- **Plataforma:** iOS (Nativa con SwiftUI)
- **Arquitectura:** MVVM (Model-View-ViewModel)
- **Repositorio:** `https://github.com/macielcirias157/CognitiveEther-IOS`
- **Usuario GitHub:** `macielcirias157`

## 2. Credenciales Críticas
- **GitHub Personal Access Token (PAT):** Redactado del repositorio por seguridad.
- **Permisos requeridos:** `Contents: Read & Write`, `Workflows: Read & Write`.
- **Uso:** El PAT debe mantenerse fuera del repositorio y usarse solo en el entorno local o en un gestor seguro de secretos para realizar `git push` y disparar GitHub Actions.

## 3. Stack Tecnológico y Herramientas
- **Lenguaje:** Swift 5.10
- **UI:** SwiftUI (Lumina AI Design System - Glassmorphism/Dark Mode)
- **Gestión de Proyecto:** `XcodeGen` (usa `project.yml` para generar el `.xcodeproj`).
- **CI/CD:** GitHub Actions (archivo `.github/workflows/ios.yml`).
- **Integraciones Reales:**
  - **Ollama:** Conexión vía HTTP a endpoints locales/remotos.
  - **APIs Cloud:** OpenAI, DeepSeek, Gemini (vía REST).
  - **Shortcuts:** Implementado con `AppIntents` para autonomía vía Siri/Atajos.

## 4. Estructura de Archivos Clave
- `Sources/Managers/AIManager.swift`: Motor de inferencia real (Ollama, OpenAI, etc.).
- `Sources/Managers/ConfigManager.swift`: Persistencia de preferencias en `UserDefaults` y API Keys en Keychain.
- `Sources/Managers/ResourceManager.swift`: Monitoreo real de RAM y estado térmico del iPhone.
- `Sources/Managers/ShortcutIntents.swift`: Definición de Atajos de iOS.
- `project.yml`: Configuración para generar el proyecto de Xcode sin necesidad de una Mac local.
- `.github/workflows/ios.yml`: Script de compilación automática para generar el archivo `.ipa`.

## 5. Instrucciones para Compilar y Subir
Para subir cambios y generar un nuevo `.ipa`:
1. Realizar los cambios en el código.
2. Ejecutar en la terminal (PowerShell):
   ```powershell
   git add .
   git commit -m "Descripción del cambio"
   git push origin main
   ```
3. GitHub Actions detectará el push y comenzará a compilar (tarda ~5-8 mins).
4. El archivo `.ipa` aparecerá en la sección **Actions > [Último Build] > Artifacts**.

## 6. Estado Actual (v1.1)
- **Simulaciones eliminadas:** La app ya no usa datos falsos en el monitor de recursos ni en el chat.
- **Ollama:** El explorador de modelos es dinámico (lista, descarga y borra modelos reales de Ollama).
- **Conexión:** Se recomienda usar la IP local de la PC (ej. `http://192.168.1.15:11434`) en lugar de `localhost` para que el iPhone pueda conectar.
- **Build:** El flujo de GitHub Actions está corregido para manejar `AppIntents` sin firma de código (Error 65 resuelto).

## 7. Notas para la siguiente IA
- La app usa un sistema de diseño personalizado llamado **Lumina AI** definido en `ThemeManager.swift`.
- Para añadir nuevas "Skills", extender el sistema de `AppIntents` en `ShortcutIntents.swift`.
- La instalación en el dispositivo físico se realiza mediante **Sideloadly** usando el `.ipa` generado por GitHub.
