# Arquitectura de Señalización: Firebase Firestore como Signaling Server

## ¿Qué se implementó?

El proyecto `mediconnect` utiliza una arquitectura de señalización **Serverless basada en Firebase Cloud Firestore** como canal de señalización para WebRTC. Toda la lógica está encapsulada en la clase `SignalingBridge`.

## Flujo de Señalización Implementado

```mermaid
sequenceDiagram
    participant Caller as Doctor (Caller)
    participant Firestore
    participant Callee as Paciente (Callee)

    Caller->>Firestore: createRoom()
    Note over Caller, Firestore: 1. Genera roomId corto<br/>2. Crea SDP Offer<br/>3. Escribe offer en /rooms/{roomId}
    
    Caller->>Firestore: Escucha cambios en 'calleeCandidates' y 'answer'
    
    Callee->>Firestore: joinRoom(roomId)
    Note over Firestore, Callee: 1. Lee offer de Firestore<br/>2. setRemoteDescription<br/>3. Crea SDP Answer<br/>4. Escribe answer en /rooms/{roomId}<br/>5. Escucha 'callerCandidates'

    Firestore-->>Caller: Notifica nuevo 'answer'
    Caller->>Caller: setRemoteDescription(answer)

    par Intercambio de candidatos ICE
        Caller->>Firestore: Envía ICE Candidates a /callerCandidates
        Firestore-->>Callee: Notifica nuevos candidatos
        Callee->>Callee: addCandidate()
    and
        Callee->>Firestore: Envía ICE Candidates a /calleeCandidates
        Firestore-->>Caller: Notifica nuevos candidatos
        Caller->>Caller: addCandidate()
    end

    Note over Caller, Callee: Conexión P2P Establecida (Media Stream)
```

[Ver diagrama en Mermaid Live Editor](https://mermaid.ai/app/projects/eb8d7b2e-ad81-4f3b-9bbd-84fe4cbd1e41/diagrams/7a82951c-cf42-48fd-85ee-f3a83e97eef9/share/invite/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkb2N1bWVudElEIjoiN2E4Mjk1MWMtY2Y0Mi00OGZkLTg1ZWUtZjNhODNlOTdlZWY5IiwiYWNjZXNzIjoiVmlldyIsImlhdCI6MTc3MDk4NTM4OH0.DoGuWsolBRo19JorHd7EOC7_CXFBOoZCfOHdCFbrtMo)

## Estructura en Firestore

La base de datos NoSQL se estructura para soportar este flujo de la siguiente manera:

```text
rooms/
  └── {shortId}  (6 chars, ej: "A3K7NP")
        ├── offer: { type: 'offer', sdp: '...' }
        ├── answer: { type: 'answer', sdp: '...' }
        ├── callerCandidates/   (subcollection)
        │     └── {auto_id}: { candidate: '...', sdpMid: '...', sdpMLineIndex: 0 }
        └── calleeCandidates/   (subcollection)
              └── {auto_id}: { candidate: '...', sdpMid: '...', sdpMLineIndex: 0 }
```

## Razonamiento de la Elección

Se eligió esta arquitectura basándose en los siguientes factores críticos para el contexto del proyecto (telemedicina en zonas rurales):

| Factor | Justificación |
|---|---|
| **Sin backend propio (Serverless)** | Firestore actúa como servidor de señalización, eliminando la necesidad de mantener un servidor WebSocket dedicado o un backend complejo. Esto reduce drásticamente la complejidad operativa y los costos de mantenimiento. |
| **Tiempo Real Nativo** | Los `snapshots()` de Firestore proporcionan streaming de datos en tiempo real de forma nativa. El sistema reacciona automáticamente a la creación de ofertas, respuestas y candidatos ICE sin necesidad de polling. |
| **Resiliencia a Conectividad Inestable** | Firestore cuenta con **offline persistence** integrada. Si la conexión cae momentáneamente durante el proceso de señalización, las escrituras se encolan localmente y se sincronizan automáticamente cuando regresa la red. Esto es vital para zonas con internet intermitente. |
| **Escalabilidad Automática** | No es necesario gestionar pools de conexiones WebSocket, balanceadores de carga o sesiones "sticky". Firestore escala horizontalmente de forma transparente. |
| **Simplicidad de Implementación** | Una sola clase (`SignalingBridge`) maneja todo el handshake. No se requiere implementar protocolos complejos sobre WebSockets. |
| **Room IDs Legibles** | Se generan IDs cortos de 6 caracteres alfanuméricos (excluyendo caracteres ambiguos como `I`, `O`, `0`, `1`), facilitando que un paciente pueda recibir el código por voz o SMS. |

## Mecanismos de Resiliencia Complementarios

La arquitectura de señalización se ve reforzada por la lógica de negocio en el `CallBloc`:

1.  **Reconexión Automática**: Implementa hasta 3 intentos de reconexión con *backoff* progresivo (`Duration(seconds: _reconnectAttempts)`), crucial para redes inestables.
2.  **Monitoreo de Calidad**: Un enum `ConnectionQuality` (`excellent`, `good`, `poor`, `disconnected`, `reconnecting`) informa al usuario sobre el estado real de la conexión basándose en los estados de ICE.
3.  **Fallback a Solo Audio**: Si la conexión de video es insostenible tras los reintentos, el sistema ofrece una degradación elegante (*graceful degradation*) a modo "solo audio" para mantener la comunicación.
4.  **Verificaciones Previas (Pre-flight checks)**: El servicio `ConnectionAuditService` valida la conectividad, y los permisos de hardware antes de intentar establecer la llamada, previniendo fallos frustrantes.

## Consideraciones y Trade-offs

-   **Latencia**: Firestore puede introducir una latencia de 100-300ms en la señalización comparado con WebSockets puros (<50ms). Esto es aceptable ya que solo afecta el tiempo de establecimiento de la llamada, no la calidad del streaming de medios una vez conectados.
-   **Infraestructura STUN/TURN**: Actualmente se utilizan servidores STUN públicos de Google. Para un entorno de producción robusto en redes corporativas o con NAT estricto (Mobile Data), sería necesario integrar un servidor TURN (e.g., Coturn o Twilio).
-   **Limpieza de Datos**: Se debe asegurar (mediante Cloud Functions o lógica de cliente en `hangUp`) que los documentos de las salas se eliminen o arquiven después de la llamada para evitar costos de almacenamiento innecesarios.
