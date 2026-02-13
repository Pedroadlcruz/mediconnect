# Registro de Deuda Técnica — MediConnect

> Inventario de deuda técnica identificada, priorizada y con referencia directa al código fuente. Cada ítem incluye el impacto, la evidencia, y el esfuerzo estimado de resolución.

---

## 🔴 Prioridad Alta — Resolver antes de producción

### DT-1: Firestore Security Rules abiertas

- **Qué:** Las reglas actuales permiten lectura y escritura pública sin autenticación.
- **Impacto:** Cualquier persona con el project ID puede acceder a datos médicos sensibles (recetas, chats, salas de video).
- **Evidencia:** `firestore.rules:6` — `allow read, write: if true;`
- **Resolución propuesta:** Implementar reglas por rol utilizando Custom Claims de Firebase Auth. La infraestructura ya existe: `UserRole.doctor`, `UserRole.patient` en `user.dart`.
- **Esfuerzo:** ~2 horas

### DT-2: Prints de debug en código de producción

- **Qué:** 40+ sentencias `print('DEBUG: [CallBloc]...')` distribuidas en archivos críticos.
- **Impacto:** Exposición de información interna en logs de producción. Ruido en la consola. No se puede filtrar ni desactivar.
- **Evidencia:** `call_bloc.dart`, `signaling_bridge.dart` — múltiples `print('DEBUG: ...')`.
- **Resolución propuesta:** Reemplazar con `debugPrint` envuelto en `assert()` (solo se ejecuta en debug mode) o integrar un logger como `logger` o `firebase_crashlytics`.
- **Esfuerzo:** ~1 hora

### DT-3: Memory leaks en SignalingBridge

- **Qué:** `snapshots().listen(...)` crea `StreamSubscription` que nunca se cancelan. `hangUp()` está vacío.
- **Impacto:** Cada llamada finalizada deja listeners activos de Firestore consumiendo bandwidth y billing. Acumulación de memory leaks en sesiones largas.
- **Evidencia:** `signaling_bridge.dart:88, 170` — `.listen()` sin asignar a variable. Líneas 200-202 — `hangUp()` vacío.
- **Resolución propuesta:** Almacenar las `StreamSubscription` en una lista. Cancelarlas y borrar el documento de Firestore en `hangUp()`.
- **Esfuerzo:** ~1 hora

---

## 🟠 Prioridad Media — Resolver en siguiente iteración

### DT-4: Identidad de usuario hardcoded en flujo de consulta

- **Qué:** La integración de `AuthBloc`/`AuthRepository` con el flujo de consulta está incompleta. Los datos del usuario se generan al vuelo.
- **Impacto:** El chat usa un userId generado por timestamp (`user_${DateTime.now()}`), las recetas usan `doctorId: 'doctor_001'`, `patientName: 'Juan Pérez'`.
- **Evidencia:**
  - `call_screen.dart:45` — `currentUserId: 'user_${DateTime.now().millisecondsSinceEpoch}'`
  - `prescription_page.dart:76-80` — `// TODO: Replace with actual auth data`
- **Resolución propuesta:** Inyectar `AuthRepository.currentUser` en `CallScreen` y `PrescriptionPage` via el BLoC o directamente desde el router.
- **Esfuerzo:** ~2 horas

### DT-5: Duplicación de lógica de PeerConnection en CallBloc

- **Qué:** La configuración de `createPeerConnection` + listeners + manejo de remote tracks se repite en 3 métodos.
- **Impacto:** Si se necesita agregar un TURN server o cambiar la configuración de ICE, hay que actualizar 3 lugares. Riesgo de divergencia.
- **Evidencia:** `call_bloc.dart` — `_initializeCall()` (líneas 54-167), `_onReconnectRequested()` (238-354), `_onFallbackToAudio()` (356-449).
- **Resolución propuesta:** Extraer a un método privado `_createConfiguredPeerConnection({required bool audioOnly})`.
- **Esfuerzo:** ~1.5 horas

### DT-6: Tests de capa Data ausentes

- **Qué:** No hay tests unitarios para `ChatService`, `PrescriptionService`, `SignalingBridge`, ni `ConnectionAuditService`.
- **Impacto:** La lógica de persistencia y señalización no tiene red de seguridad contra regresiones.
- **Evidencia:** Directorio `test/unit/` contiene solo 5 archivos, todos de BLoC/Repository level.
- **Resolución propuesta:** Crear tests con mocks de Firestore y Hive usando `fake_cloud_firestore` y `mocktail`.
- **Esfuerzo:** ~4 horas

### DT-7: UI del Home page inline en app_router.dart

- **Qué:** La pantalla Home (~170 líneas de widgets) está definida inline dentro del `builder` de GoRouter.
- **Impacto:** No se puede testear la pantalla Home de forma aislada. El router mezcla responsabilidades de navegación y UI.
- **Evidencia:** `app_router.dart:12-187` — Scaffold completo dentro de `GoRoute.builder`.
- **Resolución propuesta:** Extraer a `features/dashboard/presentation/pages/home_page.dart`. El router solo haría `builder: (_, __) => const HomePage()`.
- **Esfuerzo:** ~30 minutos

---

## 🟡 Prioridad Baja — Backlog

### DT-8: Carpetas domain vacías en consultation

- **Qué:** `domain/use_cases/` y `domain/repositories/` en el feature `consultation` están vacías.
- **Impacto:** Puramente organizacional. No afecta funcionalidad. Señal de que la arquitectura está *preparada* pero no *completada*.
- **Evidencia:** Carpetas existen pero sin archivos.
- **Resolución propuesta:** Crear Use Cases cuando la lógica de orquestación crezca (ej: `StartConsultation` que valide permisos, cree sala, e inicie stream).
- **Esfuerzo:** ~3 horas

### DT-9: Sin Auth Guards en el router

- **Qué:** No hay protección de navegación. Cualquier ruta es accesible sin autenticación.
- **Impacto:** Un deep link a `/call` o `/prescription` funcionaría sin usuario logueado.
- **Evidencia:** `app_router.dart:7` — `GoRouter(initialLocation: '/')` sin `redirect` ni `refreshListenable`.
- **Resolución propuesta:** Agregar `redirect` en GoRouter que verifique `AuthRepository.currentUser`. Usar `AuthBloc` como `refreshListenable`.
- **Esfuerzo:** ~1.5 horas

### DT-10: Sin timeout para "usuario no disponible"

- **Qué:** Si el caller crea una sala y nadie se une, la pantalla de espera permanece indefinidamente.
- **Impacto:** UX pobre — el doctor no sabe si debe esperar o si el paciente no va a conectarse.
- **Evidencia:** No hay timer de timeout en `CallBloc` después de `createRoom()`.
- **Resolución propuesta:** Agregar un `Timer` de N minutos después de crear la sala, que emita un estado `CallWaitingTimeout` con opciones de esperar más o finalizar.
- **Esfuerzo:** ~1 hora

---

## Resumen

| Prioridad | Items | Esfuerzo total estimado |
|---|---|---|
| 🔴 Alta | 3 (Rules, Prints, Memory Leaks) | ~4 horas |
| 🟠 Media | 4 (Auth, Duplicación, Tests, Router UI) | ~8 horas |
| 🟡 Baja | 3 (Domain vacío, Auth Guards, Timeout) | ~5.5 horas |
| **Total** | **10** | **~17.5 horas** |
