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

---

### 5. Manejo de Fallos y Resiliencia

El sistema implementa una estrategia de **degradación elegante** (*graceful degradation*) en múltiples niveles. Cada escenario de fallo tiene un mecanismo de recuperación definido:

#### 5.1 Fallos de Conexión WebRTC

La lógica vive en `CallBloc` (`call_bloc.dart`, 525 líneas) y sigue una **state machine de degradación progresiva**:

```
Video OK → Disconnected (espera 3s) → Reconnect (hasta 3 intentos con backoff)
    → Si falla → Ofrece Fallback a Solo Audio
        → Si audio también falla → Error final no recuperable
```

| Estado ICE | Respuesta del sistema | Archivo |
|---|---|---|
| `disconnected` | Timer de 3 segundos — si no se recupera solo, inicia reconexión | `call_bloc.dart:200-224` |
| `failed` | Reconexión inmediata con `CallReconnectRequested` | `call_bloc.dart:215-222` |
| 3 reconexiones fallidas | Emite `CallFailure(canRetry: true)` — UI muestra 3 opciones (Audio/Reintentar/Finalizar) | `call_bloc.dart:244-260` |
| `closed` | Emite `CallEnded` — navegación de vuelta al home | `call_bloc.dart:226-231` |

**Fallback de stream vacío:** Cuando `event.streams` llega vacío en `onTrack` (bug conocido de `flutter_webrtc` en mobile), se crea un `MediaStream` manualmente:
```
onTrack → streams vacío → _createRemoteStreamFromTrack(track)
```
Referencia: `call_bloc.dart:125-139`

#### 5.2 Fallos en Persistencia de Recetas

Patrón de **triple fallback** en `PrescriptionBloc`:

```
Intento online (Firestore) 
    → catch → Guardado offline (Hive) con isSynced: false
        → catch → PrescriptionError (UI muestra SnackBar rojo)
```

Las recetas offline se sincronizan posteriormente con `syncPendingPrescriptions()` cuando la conexión regresa.

Referencia: `prescription_bloc.dart:88-128`, `prescription_service.dart:80-118`

#### 5.3 Fallos de Señalización

| Escenario | Respuesta | Referencia |
|---|---|---|
| ICE candidate llega antes de que el peer esté listo | `.catchError()` silencioso — el candidate se ignora en vez de crashear | `signaling_bridge.dart:103, 186` |
| Room no encontrado | `throw Exception('Room not found')` → capturado por `CallBloc` → `CallFailure` | `signaling_bridge.dart:196` |
| Firestore temporalmente offline | Offline persistence nativa de Firestore encola escrituras localmente | Comportamiento del SDK |

#### 5.4 Fallos de Permisos y Hardware

El `ConnectionAuditService` valida **antes** de la llamada:

```
Internet → Permiso Cámara → Permiso Micrófono → Hardware Disponible
```

La UI (`PreConsultationPage`) muestra un checklist con ✅/❌ y bloquea el botón "Unirse" si algo falla, ofreciendo "Reintentar Verificación".

Referencia: `connection_audit_service.dart:12-56`, `pre_consultation_page.dart:97-121`

#### 5.5 Fallos en Chat

- Error al enviar mensaje → `ChatBloc` emite `ChatError` con mensaje descriptivo. La UI muestra un SnackBar.
- Error al marcar como leído → Se ignora silenciosamente (`catch (_)`) para no interrumpir la lectura de la conversación.

Referencia: `chat_bloc.dart:78-92`

#### 5.6 Manejo de Errores Tipado

La capa de datos utiliza el patrón `Either<Failure, Success>` de `dartz` en el `AuthRepository`:

```dart
Future<Either<Failure, User>> signIn(...) async {
  try {
    return Right(user);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

Los tipos de `Failure` definidos en `core/error/failures.dart`:
- `ServerFailure` — Errores de Firebase/backend
- `CacheFailure` — Errores de almacenamiento local
- `AuthFailure` — Errores de autenticación
- `WebRTCFailure` — Errores de conexión de video

---

### 6. Métricas de Calidad

| Métrica | Valor |
|---|---|
| Tests unitarios | 31 (5 archivos) |
| Features completamente implementadas | 2 (auth, consultation) |
| BLoCs testeados | 4/4 |
| Archivos Dart en `lib/` | ~35 |
| Dependencias directas | 23 |
| Dependencias de desarrollo | 5 |
| Patrón de errores | `Either<Failure, T>` + `Equatable` |

