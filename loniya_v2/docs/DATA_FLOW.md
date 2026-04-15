# LONIYA V2 — Data Flow Documentation

## 1. Offline-First Read Flow

```
UI Widget
    │ watch(provider)
    ▼
Riverpod Provider
    │ useCase.execute()
    ▼
Domain UseCase
    │ repository.getData()
    ▼
Repository Implementation
    │
    ├─── [STEP 1] LocalDataSource.fetch()
    │         │
    │         ▼
    │    HiveStorageService.get(box, key)
    │         │
    │    ┌────▴────────────────────────────┐
    │    │ Data found in Hive?              │
    │    │   YES → return cached data       │
    │    │   NO  → continue to STEP 2       │
    │    └─────────────────────────────────┘
    │
    ├─── [STEP 2] ConnectivityService.isConnected
    │         │
    │    ┌────▴────────────────────────────┐
    │    │ Connected to internet?           │
    │    │   YES → fetch from Remote DS    │
    │    │   NO  → return OfflineFailure   │
    │    └─────────────────────────────────┘
    │
    └─── [STEP 3] RemoteDataSource.fetch()
              │ http.get(endpoint)
              ▼
         Parse response
              │
              ▼
         LocalDataSource.store() ← save to Hive
              │
              ▼
         return fresh data
```

## 2. Offline-First Write Flow

```
User Action (form submit, progress update, etc.)
    │
    ▼
Repository.save(entity)
    │
    ├─── [STEP 1] LocalDataSource.store() → Hive
    │         Retourne succès immédiatement à l'UI
    │
    └─── [STEP 2] SyncQueueService.enqueue(action)
              │ Ajoute {type, payload, timestamp, retries: 0}
              │
              ▼
         Connectivity changed to CONNECTED?
              │ YES
              ▼
         SyncQueueService.processQueue()
              │
              ├── action.retries < 3?
              │       YES → RemoteDataSource.post()
              │                 │
              │            Success? → mark as done, remove
              │            Failure? → retries++, backoff
              │
              └── action.retries >= 3? → mark as FAILED, alert user
```

## 3. Local Classroom Data Flow

```
TEACHER DEVICE                          STUDENT DEVICES
      │                                        │
      │ teacherProvider.startClassroom()       │
      ▼                                        │
LocalServerService.start(port: 8080)           │
      │                                        │
      │ mDNS broadcast                         │
      │ "_loniya._tcp.local"                   │
      │ ─────────────────────────────────────▶ │
      │                                        │ localNetworkService.discover()
      │                                        │ mDNS scan "_loniya._tcp"
      │                                        │
      │◀──────────────────────────────────────  │ connectToPeer(teacherIP:8080)
      │                                        │
      │ GET /classroom → ClassroomInfo         │
      │ ─────────────────────────────────────▶ │
      │                                        │ Display classroom info
      │                                        │
      │ GET /contents → ContentList            │
      │ ─────────────────────────────────────▶ │
      │                                        │ Download selected contents
      │                                        │ → Decrypt
      │                                        │ → Store in Hive
      │                                        │
      │ POST /progress ← StudentProgress       │
      │◀─────────────────────────────────────  │ Submit progress
      │                                        │
      │ Teacher sees live dashboard            │
      │ of all students' progress              │
```

## 4. AI Tutor Query Flow

```
Student types question
    │
    ▼
AiTutorService.processQuery(question, currentStep)
    │
    ├─── Tokenize question → keywords
    │
    ├─── Match keywords against curriculum tags (local JSON)
    │
    ├─── Find matching step/concept
    │
    ├─── Select hint template (never give direct answer)
    │
    ├─── Format response (max 3 sentences)
    │
    └─── Cache response in Hive ai_cache box
         (key = hash(question + stepId))
```

## 5. Sync Conflict Resolution

```
Strategy: LAST-WRITE-WINS with version counter

Local version: {data, timestamp: T1, version: 5}
Remote version: {data, timestamp: T2, version: 7}

T2 > T1 AND version_remote > version_local
    → Remote wins → overwrite local
    → Update local version counter

T2 < T1 AND version_local > version_remote
    → Local wins → push local to remote
    → Update remote version counter

Special cases:
- Progress data: MERGE (take max values, never regress)
- Gamification: MERGE (sum XP, union badges)
- User profile: LAST-WRITE-WINS
```
