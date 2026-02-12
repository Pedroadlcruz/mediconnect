# MediConnect

App de Telemedicina WebRTC resiliente para zonas rurales.

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

## 🏗 Arquitectura

El proyecto sigue **Clean Architecture** con patrón **BLoC**.

-   **Presentation**: UI (Widgets, Pages) y BLoC (State Management).
-   **Domain**: Entidades, Casos de Uso y Contratos de Repositorio (Puro Dart).
-   **Data**: Modelos, Data Sources (API, DB) e Implementación de Repositorios.

## 🛠 Tecnologías Principales

-   **Flutter WebRTC**: Videollamada P2P.
-   **Firebase Firestore**: Señalización WebRTC y Chat.
-   **Firebase Auth**: Autenticación con roles (Doctor/Paciente).
-   **Shorebird**: Actualizaciones OTA (Over-The-Air).

## 🧪 Testing

Ejecutar tests unitarios:
```bash
flutter test test/unit/
```

Ejecutar tests de widgets:
```bash
flutter test test/widget/
```
