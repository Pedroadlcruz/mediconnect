# MediConnect

Implementación de una solución de asistencia remota para cerrar la brecha de salud entre zonas urbanas y rurales. El núcleo del problema técnico es la orquestación de señalización y flujo de medios en condiciones de conectividad inestable, priorizando la estabilidad del enlace, el manejo profesional de permisos y la seguridad de los datos sensibles del paciente mediante una arquitectura escalable y resiliente.

## 🎥 Demo

- **MVP actual:** [Ver Demo del MVP](https://docs.google.com/videos/d/1NF1cT0SC4udx1FGRa3llg1IiLmlEVgLwVpOQqE9j8WQ/edit?usp=sharing)
- **🧭 Visión del producto (Prototipo Stitch):** [Ver hacia dónde se dirige la app](https://docs.google.com/videos/d/1dYsySLo16Nj8d2MIZOGyy893_BlAnCcv9T5B6zGCC-M/edit?usp=sharing)

---

## 📡 Tipos de Comunicación Implementados

Se implementaron **tres canales de comunicación complementarios**, seleccionados específicamente para el contexto de telemedicina rural:

| Canal | Tecnología | Propósito Clínico |
|---|---|---|
| **Video + Audio en tiempo real** | WebRTC (P2P) via `flutter_webrtc` | Consulta médica visual: el doctor necesita observar al paciente (síntomas visibles, estado general, heridas). El audio es indispensable para la anamnesis. |
| **Chat de texto en tiempo real** | Firebase Firestore `snapshots()` | Canal secundario durante la llamada: permite enviar instrucciones escritas (nombres de medicamentos, direcciones de farmacias), útil cuando la calidad de audio es baja o el paciente necesita anotar algo. Incluye **read receipts** automáticos. |
| **Datos clínicos estructurados** | Formulario + Firma digital + Firestore/Hive | Receta médica digital con firma touch del doctor, capturada como imagen Base64. Persistencia dual online/offline para zonas sin cobertura. |

### ¿Por qué esta combinación?

- **Video+Audio** es el canal primario porque una consulta médica requiere observación visual del paciente y comunicación verbal con el doctor.
- **Texto** complementa al audio porque en zonas rurales la conexión puede degradar la calidad de voz, y los nombres de medicamentos deben comunicarse sin ambigüedad.
- **Datos estructurados (recetas)** porque el output legal de una consulta médica es la prescripción, y esta debe sobrevivir a pérdidas de conexión.

### ¿Por qué no screen sharing?

- El caso de uso es doctor-paciente, no soporte técnico. No existe necesidad clínica de compartir pantalla en una consulta médica remota.
- Añadiría complejidad al stream WebRTC y consumo de ancho de banda, contraproducente en zonas con internet limitado.

---

## 🚀 Cómo correr el proyecto

1.  **Clonar el repositorio**:
    ```bash
    git clone <repo_url>
    cd mediconnect
    ```

2.  **Instalar dependencias**:
    ```bash
    flutter pub get
    ```

3.  **Generar código (Clean Architecture + DI)**:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Configuración de Firebase**:
    -   Coloca `google-services.json` en `android/app/`.
    -   Coloca `GoogleService-Info.plist` en `ios/Runner/`.

5.  **Ejecutar**:
    ```bash
    flutter run
    ```

---

## 🏗 Arquitectura

El proyecto sigue **Clean Architecture** con patrón **BLoC**.

📄 **[Ver Resumen Detallado de Arquitectura](./ARCHITECTURE_SUMMARY.md)**

-   **Presentation**: UI (Widgets, Pages) y BLoC (State Management).
-   **Domain**: Entidades, Casos de Uso y Contratos de Repositorio (Puro Dart).
-   **Data**: Modelos, Data Sources (API, DB) e Implementación de Repositorios.

📄 **[Trade-offs Técnicos](./TRADEOFFS.md)** · **[Deuda Técnica](./TECHNICAL_DEBT.md)**

## 🛠 Tecnologías Principales

-   **Flutter WebRTC**: Videollamada P2P.
-   **Firebase Firestore**: Señalización WebRTC y Chat.
    -   Consulta el detalle en: [Arquitectura de Señalización](./SIGNALING_ARCHITECTURE.md)
    -   📊 **[Ver Diagrama de Flujo (Mermaid Chart)](https://mermaid.ai/app/projects/eb8d7b2e-ad81-4f3b-9bbd-84fe4cbd1e41/diagrams/7a82951c-cf42-48fd-85ee-f3a83e97eef9/share/invite/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkb2N1bWVudElEIjoiN2E4Mjk1MWMtY2Y0Mi00OGZkLTg1ZWUtZjNhODNlOTdlZWY5IiwiYWNjZXNzIjoiVmlldyIsImlhdCI6MTc3MDk4NTM4OH0.DoGuWsolBRo19JorHd7EOC7_CXFBOoZCfOHdCFbrtMo)**
-   **Firebase Auth**: Autenticación con roles (Doctor/Paciente).
-   **Hive**: Persistencia local offline para recetas médicas.
-   **Shorebird**: Actualizaciones OTA (Over-The-Air).

---

## 🎨 Decisiones de UX/UI

Se priorizó una experiencia **profesional, accesible y resiliente**, considerando que los usuarios (pacientes rurales y doctores) pueden tener distintos niveles de familiaridad con la tecnología.

### Design System

- **Paleta médica profesional**: `Medical Blue #0077B6` como color primario, con acentos en `#00B4D8` y `#2A9D8F` (éxito). Colores seleccionados por su asociación con confianza y salud.
- **Tipografía**: Google Fonts `Inter` — sans-serif moderna, altamente legible en pantallas móviles.
- **Material 3**: Componentes con bordes redondeados (`12px`), elevaciones sutiles, y `ColorScheme.fromSeed()` para consistencia.
- **Archivo**: [`core/config/theme/app_theme.dart`](./lib/core/config/theme/app_theme.dart)

### UX durante la llamada

| Decisión | Implementación | Razón |
|---|---|---|
| **Indicador de calidad de conexión** | Badge en tiempo real con 5 estados: `Excelente` (verde) → `Buena` → `Débil` (naranja) → `Sin conexión` (rojo) → `Reconectando` (ámbar) | El paciente rural necesita saber si el problema es su internet, no la app. Reduce frustración y llamadas de soporte. |
| **Vista de reconexión con progreso** | "Intento 2 de 3" con spinner y opción de finalizar | Transparencia: el usuario sabe que el sistema está trabajando, no colgado. |
| **Pantalla de fallo con 3 opciones** | "Continuar con Solo Audio" / "Reintentar Video" / "Finalizar" | Empodera al usuario a elegir según su contexto (prisa, calidad de red). |
| **Modo Solo Audio con mensaje explicativo** | Vista dedicada con icono de teléfono y texto "Se cambió a audio por problemas de conexión" | Evita la pantalla negra que genera confusión. El usuario entiende qué pasó. |
| **Room ID copiable al clipboard** | Tap en el ID → copia + SnackBar de confirmación con el ID completo | El doctor necesita compartir el ID rápidamente. Un tap es más rápido que seleccionar texto. |
| **Controles reactivos** | Botones mute/cámara cambian color (blanco→rojo) e icono según estado | Feedback visual inmediato sin necesidad de leer texto. |

### UX de Pre-Consulta

- **Checklist visual** con ✅/❌ por cada requisito (Internet, Cámara, Micrófono, Permisos) antes de permitir ingresar a la llamada.
- **Botón contextual**: Si todo está OK → "Unirse a la Llamada" (verde). Si algo falla → "Reintentar Verificación" (naranja).
- **Propósito**: Prevenir el escenario frustrante de entrar a una llamada y descubrir que la cámara no funciona.

### UX de Recetas

- **Flujo guiado en 3 pasos**: Formulario → Firma digital touch → Confirmación de guardado.
- **Diferenciación visual online/offline**: Guardado exitoso online = SnackBar verde ("✅ Receta guardada exitosamente"). Guardado offline = SnackBar naranja ("✅ Guardada localmente, se sincronizará cuando haya conexión").
- **Medicamentos dinámicos**: Botón "+Agregar" para múltiples medicamentos, con validación de que al menos uno exista.

### Room IDs legibles

Se generan IDs de sala de **6 caracteres alfanuméricos** (charset: `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, excluyendo `I`, `O`, `0`, `1`) para que un paciente rural pueda recibirlo por SMS o dictado telefónico sin confusión.

---

## 🧪 Testing

31 tests unitarios cubriendo los 4 BLoCs, entidades de dominio y el repositorio de autenticación.

```bash
# Tests unitarios
flutter test test/unit/

# Tests de widgets
flutter test test/widget/
```

| Archivo | Tests | Cobertura |
|---|---|---|
| `call_bloc_test.dart` | 7 | Estados, enums, ConnectionQuality |
| `chat_bloc_test.dart` | 5 | Inicio, recepción, auto-read, error |
| `pre_consultation_bloc_test.dart` | 7 | Check pass/parcial, error, isReady |
| `prescription_bloc_test.dart` | 10 | Form, firma, save online/offline, sync |
| `auth_repository_impl_test.dart` | 2 | signIn success, ServerException |
