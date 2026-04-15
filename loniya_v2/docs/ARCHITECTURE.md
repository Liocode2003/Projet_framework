# LONIYA V2 — Architecture Globale

> Plateforme éducative offline-first pour le Burkina Faso  
> Flutter 3.x | Clean Architecture | Riverpod | Hive | AES-256

---

## 1. STRUCTURE DU PROJET

```
loniya_v2/
├── lib/
│   ├── main.dart                          # Point d'entrée
│   ├── app.dart                           # App root widget
│   │
│   ├── core/                              # Couche transversale (partagée)
│   │   ├── constants/
│   │   │   ├── app_constants.dart         # Constantes globales
│   │   │   ├── hive_boxes.dart            # Noms des boîtes Hive
│   │   │   └── route_names.dart           # Noms des routes
│   │   │
│   │   ├── errors/
│   │   │   ├── failures.dart              # Types d'échecs (Failure classes)
│   │   │   └── exceptions.dart            # Exceptions custom
│   │   │
│   │   ├── network/
│   │   │   └── network_info.dart          # Vérification connectivité
│   │   │
│   │   ├── router/
│   │   │   └── app_router.dart            # GoRouter configuration
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart             # Material 3 thème
│   │   │   ├── app_colors.dart            # Palette couleurs
│   │   │   └── app_text_styles.dart       # Typographie
│   │   │
│   │   ├── utils/
│   │   │   ├── date_utils.dart            # Helpers date
│   │   │   ├── string_utils.dart          # Helpers string
│   │   │   └── validators.dart            # Validateurs formulaires
│   │   │
│   │   ├── services/
│   │   │   ├── storage/
│   │   │   │   ├── storage_service.dart       # Interface stockage
│   │   │   │   └── hive_storage_service.dart  # Implémentation Hive
│   │   │   │
│   │   │   ├── encryption/
│   │   │   │   ├── encryption_service.dart    # Interface chiffrement
│   │   │   │   └── aes_encryption_service.dart # AES-256 impl
│   │   │   │
│   │   │   ├── connectivity/
│   │   │   │   └── connectivity_service.dart  # Monitoring réseau
│   │   │   │
│   │   │   ├── sync/
│   │   │   │   ├── sync_queue_service.dart    # File d'attente sync
│   │   │   │   └── sync_conflict_resolver.dart # Résolution conflits
│   │   │   │
│   │   │   └── local_network/
│   │   │       ├── local_network_service.dart  # Interface réseau local
│   │   │       ├── mdns_discovery_service.dart # Découverte mDNS
│   │   │       └── local_server_service.dart   # Serveur HTTP local
│   │   │
│   │   └── widgets/
│   │       ├── app_button.dart            # Bouton réutilisable
│   │       ├── app_card.dart              # Carte réutilisable
│   │       ├── offline_banner.dart        # Bandeau mode offline
│   │       ├── loading_overlay.dart       # Overlay chargement
│   │       └── error_widget.dart          # Widget erreur générique
│   │
│   └── features/                          # Modules fonctionnels
│       ├── splash/                        # Écran de démarrage
│       ├── onboarding/                    # Onboarding
│       ├── auth/                          # Authentification
│       ├── home/                          # Dashboard principal
│       ├── marketplace/                   # Marketplace contenus
│       ├── learning/                      # Moteur APC
│       ├── ai_tutor/                      # IA tuteur
│       ├── gamification/                  # XP / badges / streak
│       ├── orientation/                   # Orientation scolaire
│       ├── teacher/                       # Dashboard enseignant
│       └── local_classroom/               # Mode classe locale Wi-Fi
│
├── assets/
│   ├── images/                            # Images PNG/WebP
│   ├── icons/                             # Icônes SVG
│   ├── mock_data/                         # JSON de données mock
│   ├── fonts/                             # Polices personnalisées
│   └── lottie/                            # Animations Lottie
│
├── test/
│   ├── unit/
│   │   ├── core/                          # Tests services core
│   │   └── features/                      # Tests par feature
│   ├── widget/                            # Tests widgets
│   └── integration/                       # Tests d'intégration
│
└── docs/
    ├── ARCHITECTURE.md                    # Ce fichier
    ├── DATA_FLOW.md                       # Flux de données
    └── API_CONTRACTS.md                   # Contrats API
```

---

## 2. DIAGRAMME DES MODULES

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐  │
│  │  Splash  │ │Onboarding│ │   Auth   │ │   Home   │ │  ... │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └──┬───┘  │
│       │             │            │             │           │      │
│  ┌────▼─────────────▼────────────▼─────────────▼──────────▼───┐  │
│  │                    RIVERPOD PROVIDERS                        │  │
│  └────────────────────────────┬─────────────────────────────────┘  │
└───────────────────────────────│─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│                         DOMAIN LAYER                             │
│  ┌─────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │  Use Cases  │  │    Entities     │  │  Repository Interfaces│  │
│  └──────┬──────┘  └─────────────────┘  └──────────┬──────────┘  │
└─────────│──────────────────────────────────────────│────────────┘
          │                                          │
┌─────────▼──────────────────────────────────────────▼────────────┐
│                          DATA LAYER                              │
│  ┌──────────────────┐         ┌───────────────────────────────┐  │
│  │   Remote DS      │         │        Local DS               │  │
│  │  (API calls)     │         │  ┌──────────┐ ┌───────────┐  │  │
│  │  [Optionnel]     │         │  │   Hive   │ │JSON Assets│  │  │
│  └────────┬─────────┘         │  └──────────┘ └───────────┘  │  │
│           │                   └───────────────────────────────┘  │
│  ┌────────▼──────────────────────────────────────────────────┐   │
│  │                  REPOSITORY IMPLEMENTATIONS               │   │
│  └───────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
          │
┌─────────▼─────────────────────────────────────────────────────┐
│                       CORE SERVICES                            │
│  ┌────────────┐ ┌─────────────┐ ┌──────────┐ ┌────────────┐  │
│  │  Storage   │ │ Encryption  │ │   Sync   │ │LocalNetwork│  │
│  │  Service   │ │  Service    │ │  Queue   │ │  Service   │  │
│  └────────────┘ └─────────────┘ └──────────┘ └────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

### Modules et leurs interactions

```
┌─────────────────────────────────────────────────────────────────┐
│                       FEATURES MAP                              │
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────────────┐  │
│  │   Auth   │───▶│   Home   │───▶│  Marketplace / Learning  │  │
│  └──────────┘    └──────────┘    └──────────────────────────┘  │
│                       │                       │                 │
│                       ▼                       ▼                 │
│              ┌──────────────┐      ┌───────────────────┐       │
│              │  Gamification│      │    AI Tutor        │       │
│              │  (XP/Badges) │      │  (Offline NLP)     │       │
│              └──────────────┘      └───────────────────┘       │
│                       │                       │                 │
│                       ▼                       ▼                 │
│              ┌──────────────┐      ┌───────────────────┐       │
│              │  Orientation │      │    Teacher Dash    │       │
│              │  Engine      │      │                   │       │
│              └──────────────┘      └─────────┬─────────┘       │
│                                              │                  │
│                                              ▼                  │
│                                   ┌───────────────────┐        │
│                                   │  Local Classroom  │        │
│                                   │  (Wi-Fi Mesh)     │        │
│                                   └───────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. CLEAN ARCHITECTURE — PRINCIPES APPLIQUÉS

### Règle de dépendance
Les dépendances ne vont que **vers l'intérieur** :

```
Presentation → Domain ← Data
                ↑
              Core
```

### Couches par feature

```
feature/
├── data/
│   ├── datasources/     # Sources concrètes (Hive, JSON, HTTP)
│   ├── models/          # DTOs avec méthodes fromJson/toJson + fromEntity/toEntity
│   └── repositories/    # Implémentations des contrats du domain
│
├── domain/
│   ├── entities/        # Objets métier purs (pas de dépendance Flutter)
│   ├── repositories/    # Interfaces (abstraites) — contrats
│   └── usecases/        # Logique métier unitaire (un seul verbe/action)
│
└── presentation/
    ├── providers/        # Riverpod StateNotifierProvider / FutureProvider
    ├── screens/          # Pages complètes (UI)
    └── widgets/          # Widgets réutilisables de la feature
```

### Règles de code strictes

| Règle | Détail |
|-------|--------|
| Entities | Pas d'import Flutter, pas de JSON |
| Use Cases | 1 classe = 1 action = 1 méthode `call()` |
| Repository Impl | Toujours local-first, remote si connecté |
| Provider | Jamais de logique métier — délègue aux Use Cases |
| Screens | Jamais d'accès direct aux datasources |

---

## 4. SERVICES CORE

### StorageService (Hive)
```
StorageService
├── init()                  # Initialise Hive + ouvre les boîtes
├── put(box, key, value)    # Stocke une valeur chiffrée
├── get(box, key)           # Récupère une valeur
├── delete(box, key)        # Supprime une entrée
├── getAll(box)             # Récupère toutes les entrées
├── clear(box)              # Vide une boîte
└── close()                 # Ferme proprement
```

### EncryptionService (AES-256)
```
EncryptionService
├── generateKey()           # Génère une clé AES-256 unique
├── encrypt(data, key)      # Chiffre les données
├── decrypt(data, key)      # Déchiffre les données
├── hashPin(pin)            # Hash PIN SHA-256 + sel
└── verifyPin(pin, hash)    # Vérifie PIN
```

### ConnectivityService
```
ConnectivityService
├── isConnected             # Stream<bool> état réseau
├── connectionType          # Enum: wifi / mobile / none
├── checkConnectivity()     # Vérification ponctuelle
└── onConnectivityChanged   # Stream événements changement
```

### SyncQueueService
```
SyncQueueService
├── enqueue(action)         # Ajoute une action à synchroniser
├── processQueue()          # Traite la file (max 3 retry)
├── retryFailed()           # Re-tente les actions échouées
├── clearCompleted()        # Nettoie les actions réussies
└── getSyncStatus()         # État de la file (pending/failed/done)
```

### LocalNetworkService (Wi-Fi Mesh)
```
LocalNetworkService
├── startServer()           # Démarrage serveur (enseignant)
├── stopServer()            # Arrêt serveur
├── discoverPeers()         # Découverte appareils voisins
├── connectToPeer(host)     # Connexion à un pair
├── shareContent(data)      # Partage contenu local
├── receiveContent()        # Réception contenu
└── getConnectedPeers()     # Liste des pairs connectés
```

### AiTutorService (Offline)
```
AiTutorService
├── processQuery(question, context)  # Analyse question
├── buildHint(step, keywords)        # Génère un indice
├── matchCurriculum(tags)            # Lie au curriculum
└── formatResponse(text)             # Format max 3 phrases
```

---

## 5. DATA FLOW — OFFLINE-FIRST

### Stratégie de données locale

```
┌─────────────────────────────────────────────────────────────────┐
│                    OFFLINE-FIRST STRATEGY                       │
│                                                                 │
│  User Action                                                    │
│      │                                                          │
│      ▼                                                          │
│  Repository.getData()                                           │
│      │                                                          │
│      ├──[1]──▶ Lire Hive DB (TOUJOURS en premier)              │
│      │              │                                           │
│      │              ▼                                           │
│      │         Data trouvée? ──YES──▶ Retourner immédiatement  │
│      │              │                                           │
│      │             NO                                           │
│      │              │                                           │
│      ├──[2]──▶ Vérifier connexion internet                     │
│      │              │                                           │
│      │    CONNECTED──┤       NOT CONNECTED                      │
│      │              │           │                               │
│      │              ▼           ▼                               │
│      │         Appel API   Retourner                            │
│      │              │      données vides                        │
│      │              ▼      ou erreur offline                    │
│      │         Sauvegarder                                      │
│      │         dans Hive                                        │
│      │              │                                           │
│      └──────────────▶ Retourner données fraîches               │
│                                                                 │
│  Write Action (formulaire, progression, etc.)                  │
│      │                                                          │
│      ├──[1]──▶ Écrire dans Hive IMMÉDIATEMENT                 │
│      │                                                          │
│      ├──[2]──▶ Ajouter à SyncQueue                            │
│      │                                                          │
│      └──[3]──▶ Sync quand internet disponible                  │
└─────────────────────────────────────────────────────────────────┘
```

### Boîtes Hive définies

| Boîte (Box) | Contenu | Chiffrée |
|---|---|---|
| `users` | Profils utilisateurs locaux | ✅ OUI |
| `sessions` | Sessions actives | ✅ OUI |
| `contents` | Contenus marketplace téléchargés | ✅ OUI |
| `progress` | Progression élève par leçon | ✅ OUI |
| `gamification` | XP, badges, streaks | Non |
| `sync_queue` | Actions en attente de sync | Non |
| `ai_cache` | Cache réponses IA | Non |
| `settings` | Paramètres app | Non |
| `orientation` | Résultats orientation | Non |
| `classroom` | Données classe locale | Non |

---

## 6. DATA FLOW — RÉSEAU LOCAL (Wi-Fi Mesh)

```
┌────────────────────────────────────────────────────────────────┐
│                   LOCAL CLASSROOM MODE                         │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │               TEACHER DEVICE (Serveur)                  │  │
│  │                                                         │  │
│  │  LocalNetworkService.startServer()                      │  │
│  │      │                                                  │  │
│  │      ▼                                                  │  │
│  │  HTTP Server sur port 8080                              │  │
│  │  mDNS broadcast: "_loniya._tcp"                         │  │
│  │      │                                                  │  │
│  │      ▼                                                  │  │
│  │  Endpoints disponibles:                                 │  │
│  │  GET  /contents      → liste des contenus              │  │
│  │  GET  /content/{id}  → téléchargement contenu          │  │
│  │  POST /progress      → recevoir progression élèves     │  │
│  │  GET  /classroom     → état de la classe               │  │
│  └─────────────────────────────────────────────────────────┘  │
│                        │ Wi-Fi AP                              │
│                        │ (même réseau)                         │
│  ┌─────────────────────▼───────────────────────────────────┐  │
│  │               STUDENT DEVICES (Clients)                 │  │
│  │                                                         │  │
│  │  LocalNetworkService.discoverPeers()                    │  │
│  │      │                                                  │  │
│  │      ▼                                                  │  │
│  │  Scan mDNS "_loniya._tcp"                               │  │
│  │      │                                                  │  │
│  │      ▼                                                  │  │
│  │  Connexion TCP → teacher IP:8080                        │  │
│  │      │                                                  │  │
│  │      ▼                                                  │  │
│  │  Téléchargement contenus                                │  │
│  │  → Déchiffrement                                        │  │
│  │  → Stockage Hive local                                  │  │
│  └─────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

---

## 7. DÉPENDANCES FLUTTER (pubspec.yaml prévu)

```yaml
dependencies:
  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^13.2.0

  # Local storage
  hive_flutter: ^1.1.0

  # Encryption
  encrypt: ^5.0.3
  flutter_secure_storage: ^9.0.0
  crypto: ^3.0.3

  # Network
  connectivity_plus: ^5.0.2
  http: ^1.2.1
  shelf: ^1.4.1          # Pour le serveur HTTP local (teacher mode)
  shelf_router: ^1.1.4

  # mDNS pour découverte réseau local
  multicast_dns: ^0.3.2+1

  # TTS
  flutter_tts: ^3.8.5

  # PDF export
  pdf: ^3.10.8
  printing: ^5.12.0

  # Compression
  archive: ^3.4.10

  # UI / UX
  lottie: ^3.1.0
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0

dev_dependencies:
  # Code generation
  build_runner: ^2.4.8
  riverpod_generator: ^2.4.0
  hive_generator: ^2.0.1

  # Tests
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.3
```

---

## 8. SÉCURITÉ

```
┌──────────────────────────────────────────────────────────────┐
│                    SÉCURITÉ MULTICOUCHE                      │
│                                                              │
│  Couche 1: Génération de clé                                 │
│    • Clé AES-256 générée à l'installation                    │
│    • Stockée dans flutter_secure_storage (Android Keystore)  │
│                                                              │
│  Couche 2: Chiffrement données                               │
│    • Toutes données sensibles → AES-256-CBC                  │
│    • IV aléatoire par entrée                                 │
│                                                              │
│  Couche 3: Authentification                                  │
│    • PIN hashé SHA-256 + sel unique                          │
│    • Session token JWT local                                 │
│                                                              │
│  Couche 4: Réseau local                                      │
│    • Contenus transmis chiffrés                              │
│    • Token de session requis pour rejoindre une classe       │
└──────────────────────────────────────────────────────────────┘
```

---

## 9. OPTIMISATION APPAREILS LOW-END

| Contrainte | Solution |
|---|---|
| RAM < 120MB | Lazy loading des features, dispose agressif |
| APK < 50MB | Split APK, assets WebP, tree-shaking |
| CPU limité | Pas d'animations complexes, listes virtuelles |
| Stockage limité | Compression GZIP des contenus Hive |
| Écran petit | Layout responsive, Material 3 compact |

---

## 10. ROADMAP PHASES

| Phase | Module | Priorité |
|---|---|---|
| 1 | Architecture (ce doc) | ✅ DONE |
| 2 | Initial Setup Flutter | 🔜 |
| 3 | Offline Core System | 🔜 |
| 4 | Auth System | 🔜 |
| 5 | Marketplace | 🔜 |
| 6 | Learning Engine APC | 🔜 |
| 7 | AI Tutor Offline | 🔜 |
| 8 | Gamification | 🔜 |
| 9 | Orientation Engine | 🔜 |
| 10 | Local Network Mode | 🔜 |
| 11 | Sync System | 🔜 |
| 12 | UI Screens | 🔜 |
| 13 | Optimization | 🔜 |
