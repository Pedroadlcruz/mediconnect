# Trade-offs Técnicos — MediConnect

> Este documento analiza las decisiones de ingeniería donde se aceptó un compromiso explícito entre dos o más alternativas válidas. Cada trade-off incluye evidencia directa del código fuente.

---

## 1. Firestore como Signaling Server vs. WebSocket dedicado

| | Elegido ✅ | Alternativa descartada |
|---|---|---|
| **Qué** | Firestore `snapshots()` para intercambio de SDP y candidatos ICE | WebSocket Server (Node.js + Socket.io) |
| **Ganancia** | Zero-ops (serverless), offline persistence nativa, escalabilidad automática, sin infraestructura adicional |
| **Costo** | Latencia de señalización ~100-300ms vs ~50ms de WebSockets |
| **Resolución** | Aceptable porque la latencia solo afecta el *setup* de la llamada (una sola vez), no el streaming de medios P2P que es directo entre peers |

**Evidencia:** `signaling_bridge.dart` — `roomRef.snapshots().listen(...)` para reaccionar en tiempo real a cambios en la sala.

---

## 2. Solo STUN (Google) vs. TURN Server propio

| | Elegido ✅ | Alternativa |
|---|---|---|
| **Qué** | Servidores STUN públicos (`stun1/stun2.l.google.com:19302`) | TURN Server (Coturn/Twilio) |
| **Ganancia** | Cero costo, sin infraestructura adicional que mantener |
| **Costo** | No funciona en redes con NAT simétrico (algunos operadores móviles rurales, redes corporativas con firewall estricto) |
| **Resolución** | Decisión pragmática para MVP. La configuración de ICE servers está centralizada en un solo punto del código (`call_bloc.dart:82-88`), lo que permite agregar TURN servers con un cambio de una línea. Se compensó con el mecanismo de **fallback a audio** que cubre muchos de los mismos escenarios |

**Evidencia:** `call_bloc.dart:82-88` — `'iceServers': [{'urls': 'stun:stun1.l.google.com:19302'}]`

---

## 3. Clean Architecture "Lite" (sin Use Cases) vs. Clean Architecture estricta

| | Elegido ✅ | Alternativa |
|---|---|---|
| **Qué** | BLoCs inyectan directamente Services/Repositories | BLoCs → Use Cases → Repositories → DataSources |
| **Ganancia** | Menos boilerplate, desarrollo más rápido, menos archivos para un MVP |
| **Costo** | Acoplamiento ligero entre Presentation y Data. Ejemplo: `PrescriptionBloc` importa directamente `PrescriptionService` y `PrescriptionModel` (clase de la capa Data) |
| **Resolución** | Las carpetas `use_cases/` existen vacías en la estructura — preparadas para escalar cuando la lógica de orquestación lo justifique. Se preservó la separación Entity/Model y la inyección mediante interfaces abstractas |

**Evidencia:** `prescription_bloc.dart:4` — `import ...data/data_sources/prescription_service.dart` (import cruzando capas).

---

## 4. Persistencia offline selectiva (solo Recetas) vs. Offline-first global

| | Elegido ✅ | Alternativa |
|---|---|---|
| **Qué** | Offline con Hive solo en prescripciones | Offline-first completo (chat, auth, llamadas, todo) |
| **Ganancia** | El dato más crítico (receta médica) nunca se pierde, incluso sin red |
| **Costo** | Chat y señalización dependen de conectividad a Firestore |
| **Resolución** | Priorización por **criticidad clínica**: una receta perdida tiene impacto médico-legal directo; un mensaje de chat perdido no. El `PrescriptionBloc` tiene fallback automático a guardado local si falla Firestore, con flag `isSynced: false` para sincronización posterior |

**Evidencia:** `prescription_bloc.dart:88-128` (fallback offline) y `prescription_service.dart:80-118` (`syncPendingPrescriptions`).

---

## 5. Firestore Security Rules abiertas vs. Reglas por rol

| | Elegido ✅ | Alternativa |
|---|---|---|
| **Qué** | `allow read, write: if true;` | Reglas granulares: `auth.token.role == 'doctor'` para escritura, `auth.uid == resource.data.patientId` para lectura |
| **Ganancia** | Velocidad de desarrollo, testing sin fricción, onboarding inmediato |
| **Costo** | Cualquiera con el project ID puede leer/escribir datos de cualquier sala |
| **Resolución** | Trade-off **consciente y temporal** para la fase de MVP. El sistema de roles ya existe en la entidad `User` (`UserRole.doctor`, `UserRole.patient`) y el `AuthRepository` implementa el patrón `Either<Failure, Success>` con `Failure` tipado, por lo que la migración a reglas estrictas es directa cuando se requiera |

**Evidencia:** `firestore.rules:6` — `allow read, write: if true;` vs `user.dart:3` — `enum UserRole { doctor, patient, unknown }`

---

## 6. Degradación elegante (Graceful Degradation) vs. Fail-fast

| | Elegido ✅ | Alternativa |
|---|---|---|
| **Qué** | Video → Reconexión (3 intentos con backoff) → Fallback a solo audio → Error final | Fallo inmediato si la conexión de video cae |
| **Ganancia** | Máxima resiliencia en redes inestables. La consulta médica continúa aunque el video falle |
| **Costo** | Complejidad significativa en `CallBloc` (525 líneas). Duplicación de lógica de `createPeerConnection` y configuración de listeners en 3 métodos: `_initializeCall`, `_onReconnectRequested`, `_onFallbackToAudio` |
| **Resolución** | Se priorizó la **fiabilidad de la consulta médica** sobre la elegancia del código. En un contexto donde una consulta perdida puede significar que un paciente rural no reciba atención, la redundancia del código es aceptable |

**Evidencia:** `call_bloc.dart` — `_maxReconnectAttempts = 3`, estados `CallReconnecting`, `CallFailure(canRetry: true)`, evento `CallFallbackToAudio`.

---

## 7. Room IDs cortos legibles vs. UUIDs estándar

| | Elegido ✅ | Alternativa |
|---|---|---|
| **Qué** | IDs de 6 caracteres alfanuméricos (charset sin ambigüedades: sin `I`, `O`, `0`, `1`) | UUIDs estándar (`550e8400-e29b-41d4-a716-446655440000`) |
| **Ganancia** | Un paciente rural puede recibirlo por SMS o dictado telefónico (ej: `A3K7NP`). Reduce errores de transcripción |
| **Costo** | Riesgo de colisión (30^6 ≈ 729 millones de combinaciones). Sin validación de unicidad contra Firestore antes de crear la sala |
| **Resolución** | Para el volumen esperado de un MVP de telemedicina (decenas de salas diarias), la probabilidad de colisión es despreciable (~1 en millones). Se excluyeron caracteres ambiguos para minimizar errores en comunicación verbal |

**Evidencia:** `signaling_bridge.dart:18-25` — `_generateShortId()` con charset `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`

---

## Resumen de prioridades del MVP

```
┌─────────────────────────────────────────────────────┐
│             Filosofía de Trade-offs                  │
├─────────────────────────────────────────────────────┤
│ ✅ Resiliencia de la consulta  >  Código DRY         │
│ ✅ Datos clínicos offline      >  Offline-first total │
│ ✅ Zero-ops (Serverless)       >  Latencia óptima     │
│ ✅ UX accesible (Room IDs)     >  Unicidad garantizada│
│ ✅ Velocidad de desarrollo     >  Purismo arquitect.  │
│ ⚠️ Seguridad (rules)          =  Pendiente para prod │
└─────────────────────────────────────────────────────┘
```
