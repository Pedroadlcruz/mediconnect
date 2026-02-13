# Resumen del Patrón Arquitectónico de MediConnect

## Patrón Principal: Clean Architecture "Lite" + BLoC por Feature

El proyecto sigue una estructura de **Clean Architecture simplificada**, organizada verticalmente por **features**, utilizando **BLoC** (Business Logic Component) como patrón de gestión de estado.

### 1. Organización por Features (Feature-First)

La estructura de carpetas sugiere una separación clara por dominios funcionales, donde cada "feature" contiene sus propias capas de responsabilidad:

```
lib/
├── core/           → Infraestructura transversal (DI, config, errores, red)
├── shared/         → Modelos y widgets compartidos
├── features/
│   ├── auth/
│   │   ├── data/           → Data Sources, Models, Repositories (Impl)
│   │   ├── domain/         → Entities, Repositories (Interfaces), Use Cases
│   │   └── presentation/   → Pages, Widgets, BLoCS
│   ├── consultation/
│   │   ├── data/           
│   │   ├── domain/         
│   │   └── presentation/   → Contiene 4 BLoCs especializados
│   └── ... (chat, dashboard, prescription)
```

Cada feature replica la tríada clásica de Clean Architecture: **Data → Domain → Presentation**.

### 2. Gestión de Estado: Múltiples BLoCs (no Cubit global)

El feature principal (`consultation`) divide la lógica en **4 BLoCs independientes**, facilitando la mantenibilidad:

| BLoC | Responsabilidad |
|------|----------------|
| **`CallBloc`** | Gestión compleja de la llamada WebRTC (señalización, candidatos ICE, reconexión, fallback a audio). |
| **`ChatBloc`** | Gestión de mensajería en tiempo real vía Firestore. |
| **`PrescriptionBloc`** | Creación y lectura de recetas médicas. |
| **`PreConsultationBloc`** | Verificación de permisos y conectividad antes de la sesión. |

> **Nota Técnica:** Se utilizan clases `Bloc` (basadas en eventos `Event` -> `State`) y no `Cubit`, lo cual es la decisión correcta dada la naturaleza asíncrona y compleja de los flujos de WebRTC.

### 3. Inyección de Dependencias (DI)

El proyecto utiliza un enfoque robusto para la inversión de control:
- **Herramientas:** `GetIt` (Service Locator) + `Injectable` (Generación de código).
- **Ciclo de Vida:**
  - **Singletons/LazySingletons:** Para Repositorios y Data Sources (se mantienen vivos en memoria).
  - **Factories:** Para los BLoCs (se crea una nueva instancia cada vez que se necesita en la UI).

**Flujo de Dependencias:**
`UI → BLoC → Repository (Interface) → Repository (Impl) → Data Source → External SDK (Firebase)`

### 4. Capas de Datos y Dominio (Análisis Crítico)

- **Data Sources:** Contienen la lógica de implementación "dura" (llamadas directas a Firebase, lógica de WebRTC).
- **Repositories:** En este proyecto, actúan principalmente como **wrappers** que delegan a los data sources, garantizando que el dominio no dependa de librerías externas.
- **Use Cases:** Aunque la estructura de carpetas existe (`domain/use_cases`), se observa una aproximación pragmática donde **muchos BLoCs consumen directamente los Repositorios**, saltándose a veces la capa de Casos de Uso para agilizar el desarrollo (patrón "Clean Architecture Lite").

### Veredicto Técnico

El proyecto está construido sobre una base sólida y escalable:
1.  **Arquitectura:** Clean Architecture Pragmática.
2.  **Estado:** BLoC (Event-driven) segmentado por funcionalidad.
3.  **DI:** Tipada y generada automáticamente.
4.  **Enfoque:** Se prioriza la separación de intereses (Separation of Concerns) sin caer en la sobre-ingeniería ("boilerplate" excesivo de Use Cases para operaciones CRUD simples).
