

**FUNCTIONAL SPECIFICATION DOCUMENT**

AI Robot Assistant — Car Companion Feature

Android Headunit Integration via HP Internet Bridge

| Document Version | 2.0.0 |
| :---- | :---- |
| Status | Draft — For Developer Review |
| Supersedes | FSD v1.0.0 (Cloud Relay Architecture) |
| Date | June 2025 |
| Author | Business Analyst |
| Target Platform | Android Headunit (menengah ke bawah) \+ Android Phone (Testing) |
| Internet Source | HP User via USB Tethering / WiFi Hotspot |

# **1\. Overview**

## **1.1 Background**

AI Robot Assistant adalah perangkat fisik berukuran kecil (P=10cm, L=5cm, T=8cm) yang ditenagai ESP32-S3, dengan kemampuan percakapan dua arah melalui platform xiaozhi.ai, dan telah terintegrasi dengan MCP Server untuk Email dan Telegram.

| CATATAN  | Mayoritas Android headunit menengah ke bawah tidak memiliki slot SIM card atau koneksi internet mandiri. Arsitektur ini dirancang agar kompatibel dengan headunit tersebut tanpa modifikasi hardware. |
| :---: | :---- |

## **1.2 Objectives**

* Memungkinkan robot mengirimkan perintah ke Android headunit melalui alur suara end-to-end.

* Flutter app berjalan di headunit, mendapat internet dari HP via USB Tethering atau WiFi Hotspot.

* Setup semudah mungkin untuk user awam — cukup aktifkan USB Tethering di HP dan colok ke headunit atau menggunakan Hotspot.

* Memberikan acknowledgement verbal kepada user setelah perintah dieksekusi.

* Menangani kondisi app tidak terinstall, internet tidak tersedia, dan koneksi headunit terputus.

## **1.3 Scope**

**In Scope:**

* Flutter app di Android headunit sebagai command receiver dan executor.

* HP sebagai internet bridge (USB Tethering / WiFi Hotspot) — konfigurasi ada di sisi user, bukan di app.

* MCP Server di cloud xiaozhi.me untuk menerima tool call dari AI dan push command ke headunit.

* Intent-based launcher untuk Google Maps, Spotify, YouTube Music, WhatsApp, Dialer, dan generic app.

* Acknowledgement verbal dari headunit ke robot ke user.

* Error handling: app tidak terinstall, internet tidak tersedia, timeout.

* User setup guide yang sederhana (termuat dalam dokumen ini sebagai lampiran).

**Out of Scope:**

* Koneksi internet mandiri di headunit (SIM card / built-in WiFi ke router).

* UI/dashboard visual di headunit — app berjalan di background.

* Aplikasi di HP (HP hanya sebagai internet bridge, tidak install app apapun).

# **2\. Stakeholders & Roles**

| Role | Pihak | Tanggung Jawab |
| ----- | ----- | ----- |
| Product Owner | Internal (Aji) | Menentukan requirement, validasi FSD, sign-off UAT |
| Business Analyst | Internal (Aji) | Menulis FSD, mediasi ke developer |
| Mobile Developer | Internal (Alief) | Membangun Flutter app untuk Android headunit |
| Backend / MCP Dev | Internal (Alief) | Membangun MCP Server baru di cloud xiaozhi.me |
| QA Engineer | Internal (Aji/Alief) | Integration test, UAT di Android phone dan headunit (jika ada) |

# **3\. System Architecture**

## **3.1 High-Level Architecture**

Diagram berikut menggambarkan alur sistem end-to-end pada arsitektur v2.0:

| 👤 USER Bicara ke robot | ▶ | 🤖 ROBOT ESP32-S3 \+ WiFi | ▶ | ☁ XIAOZHI AI \+ MCP Orchestrator | ▶ | ⚙ MCP SERVER cloud xiaozhi.me |  |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |

| ↓  USB Tethering / WiFi Hotspot  ↓ |
| :---: |

| 📺  ANDROID HEADUNIT  —  Flutter App Menerima command via internet → eksekusi Android Intent lokal |
| :---: |

Acknowledgement berjalan balik: **Headunit → MCP Server → xiaozhi.ai → Robot Speaker → User.**

## **3.2 Peran HP dalam Arsitektur**

| PENTING | HP tidak menginstall aplikasi apapun. HP hanya berfungsi sebagai internet gateway untuk headunit. Seluruh logic app ada di headunit. |
| :---: | :---- |

| Komponen | Peran | Catatan |
| ----- | ----- | ----- |
| HP User | Internet bridge — menyediakan koneksi internet ke headunit via USB Tethering atau WiFi Hotspot | Tidak ada app yang diinstall di HP |
| Android Headunit | Menjalankan Flutter app, menerima command dari MCP Server, mengeksekusi Android Intent | Internet masuk via HP, bukan SIM card headunit |
| Kabel USB | Menghubungkan HP ke headunit untuk USB Tethering (primary method) | Sambil charge HP jika headunit punya output power |
| WiFi Hotspot | Alternatif jika port USB headunit sudah dipakai atau untuk headunit yang support WiFi client | HP dijadikan hotspot, headunit konek ke hotspot HP |

## **3.3 Detail Alur End-to-End**

| \# | Layer | Deskripsi |
| ----- | ----- | ----- |
| 1 | User → Robot | User mengucapkan perintah ke robot. Contoh: 'buka Google Maps, navigasi ke SPBU terdekat'. |
| 2 | Robot → xiaozhi.ai | Robot streaming audio ke xiaozhi.ai via WiFi untuk diproses (STT \+ NLU \+ AI inference). |
| 3 | xiaozhi.ai → MCP Server | AI mengidentifikasi intent dan memanggil tool yang sesuai di MCP Server Android (di-host di cloud xiaozhi.me). |
| 4 | MCP Server → Headunit | MCP Server push command payload JSON ke Flutter app yang berjalan di headunit via SSE. Koneksi internet ke headunit berasal dari HP (USB Tethering/Hotspot). |
| 5 | Headunit: Eksekusi | Flutter app menerima dan mem-parsing command, lalu mengeksekusi Android Intent secara lokal di headunit (buka Google Maps, Spotify, dll.). |
| 6 | Headunit → MCP Server | Flutter app mengirim HTTP POST acknowledgement (status success/error \+ pesan verbal) ke MCP Server via internet HP. |
| 7 | MCP → xiaozhi.ai → Robot | xiaozhi.ai menerima status, men-generate respons TTS, dan robot memutarnya via speaker. Contoh: 'Google Maps sudah dibuka, navigasi dimulai.' |

## **3.4 Tech Stack**

| Layer | Teknologi | Keterangan |
| ----- | ----- | ----- |
| **Robot Hardware** | ESP32-S3, Mic, Speaker, OLED, Baterai | Existing — tidak ada perubahan |
| **Robot Firmware** | xiaozhi.ai SDK \+ Arduino C++ | Existing — kemungkinan perlu modifikasi program (firmware) yg ada di ESP32 sekarang |
| **AI Platform** | xiaozhi.ai (cloud) | STT, NLU, TTS, MCP orchestration |
| **MCP Server (NEW)** | Node.js / Python \+ MCP SDK | Deploy di cloud xiaozhi.me. Menerima tool call AI, push command ke headunit via SSE. |
| **Internet Bridge** | Android Phone — USB Tethering / WiFi Hotspot | Bukan app baru. Fitur native Android di HP user. Zero development effort. |
| **Android App (NEW)** | Flutter (Dart) \+ Android Intent API | Berjalan di headunit. Koneksi internet via HP. Eksekusi intent lokal. |
| **Transport Protocol** | SSE (push command) \+ HTTP POST (acknowledgement) | Semua traffic lewat internet HP. HTTPS wajib. |

# **4\. Internet Bridge — HP ke Headunit**

## **4.1 Metode Koneksi**

| Metode | Prioritas | Cara Kerja | Catatan |
| ----- | ----- | ----- | ----- |
| USB Tethering | ⭐ Primary | HP colok ke headunit via kabel USB. Di HP: Settings → Hotspot & Tethering → USB Tethering → ON. | Paling stabil. Sekaligus charge HP jika headunit ada output USB power. Support hampir semua headunit Android. |
| WiFi Hotspot | Fallback | HP dijadikan hotspot. Di HP: Settings → Hotspot → Personal Hotspot → ON. Headunit konek ke SSID HP. | Gunakan jika port USB headunit sudah dipakai atau headunit tidak support USB tethering. |

| ZERO DEV EFFORT | Kedua metode ini adalah fitur native Android yang tidak membutuhkan pengembangan apapun. Developer hanya perlu mendokumentasikan cara setup di user guide. |
| :---: | :---- |

## **4.2 Deteksi Status Internet di Flutter App**

Flutter app harus mendeteksi ketersediaan internet saat startup dan secara periodik:

* Gunakan package connectivity\_plus untuk monitor status koneksi network di headunit.

* Jika internet tidak tersedia: tampilkan notifikasi persistent 'Hubungkan HP via USB Tethering atau Hotspot untuk mengaktifkan Car Companion Mode'.

* Saat internet kembali tersedia: otomatis reconnect ke MCP Server tanpa user action.

* Jika robot mengirim perintah saat headunit offline: MCP Server queue command selama 60 detik. Jika headunit online dalam 60 detik, command dieksekusi. Jika tidak, robot mendapat acknowledgement error 'Headunit tidak terhubung ke internet'.

## **4.3 User Setup Guide (Ringkasan)**

**Setup Awal (hanya sekali):**

1. Install Flutter app di Android headunit.

2. Buka app, masukkan Device ID robot (tertera di bodi robot atau di app xiaozhi.ai).

3. Tap 'Tes Koneksi' — pastikan status Connected muncul.

4. App siap digunakan. Minimize app — akan berjalan di background.

**Setiap Kali Menggunakan di Mobil:**

5. Colok HP ke port USB headunit dengan kabel USB.

6. Di HP: buka Settings → Hotspot & Tethering → aktifkan USB Tethering.

7. Tunggu 5-10 detik hingga ikon koneksi muncul di notifikasi headunit.

8. Bicara ke robot — Car Companion Mode aktif.

# **5\. MCP Server — Android Headunit**

## **5.1 Konfigurasi di xiaozhi.me**

MCP Server baru didaftarkan ke platform xiaozhi.me mengikuti pola konfigurasi MCP yang sudah ada. Langkah yang diperlukan:

9. Buat MCP Server dengan endpoint publik (HTTPS) yang dapat diakses dari cloud xiaozhi.me.

10. Definisikan daftar tools beserta JSON schema parameter (lihat Seksi 5.3).

11. Daftarkan server di konfigurasi xiaozhi.ai agar AI dapat memanggil tools tersebut.

12. Implementasikan mekanisme SSE connection management per device ID.

13. Implementasikan command queue (TTL 60 detik) untuk headunit yang sedang offline.

## **5.2 Mekanisme Push Command**

### **Primary: Server-Sent Events (SSE)**

* Flutter app membuka koneksi SSE persistente ke MCP Server saat startup.

* MCP Server menyimpan mapping: device\_id → SSE connection aktif.

* Saat ada tool call dari xiaozhi.ai, MCP Server push event ke SSE connection headunit yang sesuai.

* Flutter app harus keep-alive koneksi SSE dengan heartbeat setiap 30 detik.

* Target latency: \< 500ms dari tool call hingga command diterima headunit.

### **Command Queue (Offline Buffer)**

* Jika tidak ada SSE connection aktif untuk device\_id yang ditarget, MCP Server menyimpan command di queue (Redis atau in-memory).

* TTL queue: 60 detik. Jika headunit tidak connect dalam 60 detik, command expired.

* Saat headunit connect kembali, MCP Server immediately push queued commands.

### **Acknowledgement: HTTP POST**

* Setelah eksekusi, Flutter app kirim HTTP POST ke /api/v1/ack.

* MCP Server meneruskan status sebagai tool result ke xiaozhi.ai.

* Timeout acknowledgement: 10 detik. Jika tidak ada ack, MCP Server kirim error HEADUNIT\_TIMEOUT.

## **5.3 Daftar MCP Tools**

| Tool Name | Parameter | Deskripsi |
| ----- | ----- | ----- |
| open\_navigation | destination: string app: enum \[google\_maps, waze, here\] (default: google\_maps) | Buka navigasi ke destinasi. URI: google.navigation:q={destination}\&mode=d |
| open\_music | app: enum \[spotify, youtube\_music, default\] action: enum \[play\_playlist, play\_song, play\_artist\] query: string | Buka app musik dan mulai pemutaran via deep link / URI scheme. |
| open\_app | package\_name: string uri: string (optional) extra: object (optional) | Generic app launcher berdasarkan package name. Fallback untuk app yang tidak ter-cover tool spesifik. |
| phone\_call | number: string contact\_name: string (optional) | Panggilan via android.intent.action.CALL dengan URI tel:{number}. |
| send\_message | app: enum \[whatsapp, sms\] contact: string message: string | Kirim pesan via WhatsApp deep link atau SMS intent. |
| get\_headunit\_status | (none) | Cek status koneksi internet headunit, daftar app terinstall, dan versi OS. |

# **6\. Flutter Application — Android Headunit**

## **6.1 Deskripsi Umum**

Flutter app berjalan sebagai foreground service di Android headunit. Tidak ada UI utama yang dioperasikan user setelah setup awal. App otomatis start saat headunit menyala (boot) dan menjaga koneksi SSE ke MCP Server — selama internet dari HP tersedia.

## **6.2 Screens & UI**

| ID | Screen | Deskripsi |
| ----- | ----- | ----- |
| S-01 | Setup Screen | Pertama kali run: input Device ID robot \+ Server URL MCP. Tombol 'Tes Koneksi'. Setelah berhasil, screen ini tidak perlu dibuka lagi. |
| S-02 | Persistent Notification | Notifikasi di notification bar headunit menampilkan: status koneksi (✅ Connected / ⚠️ No Internet / ❌ Disconnected) dan nama device ID. |
| S-03 | Internet Alert | Overlay kecil (toast / snackbar) muncul saat internet tidak tersedia: 'Hubungkan HP via USB Tethering untuk mengaktifkan Car Companion Mode.' |
| S-04 | Command Log (Debug) | Log riwayat command yang diterima dan status eksekusi. Hanya aktif di debug build. Dinonaktifkan di release build. |

## **6.3 Functional Requirements**

| FR-ID | Requirement | Detail |
| ----- | ----- | ----- |
| FR-01 | Auto-start on Boot | Foreground service otomatis start saat Android boot (RECEIVE\_BOOT\_COMPLETED). Service menjaga SSE connection selama internet tersedia. |
| FR-02 | Internet Availability Monitor | Monitor status internet via connectivity\_plus. Saat internet tersedia: init SSE connection. Saat internet putus: tampilkan alert, stop SSE gracefully, tunggu reconnect. |
| FR-03 | SSE Connection Management | Buka koneksi SSE ke MCP Server dengan device\_token. Heartbeat setiap 30 detik. Reconnect otomatis dengan exponential backoff (1s, 2s, 4s, 8s, max 60s) jika koneksi putus. |
| FR-04 | Command Parsing & Validation | Parsing JSON payload dari SSE event. Validasi schema: request\_id, command\_type, parameters wajib ada. Jika invalid: kirim ack error INVALID\_PAYLOAD. |
| FR-05 | Intent: Navigation | Eksekusi Google Maps via URI google.navigation:q={destination}\&mode=d. Untuk Waze: waze://?q={destination}\&navigate=yes. Cek app ter-install sebelum launch. Jika app target belum ter-install, munculkan pesan. |
| FR-06 | Intent: Music | Spotify: spotify:search:{query} atau spotify:user:spotify:playlist:37i9dQZF. YouTube Music: intent ACTION\_VIEW dengan URI. Fallback ke open app tanpa deep link jika URI gagal. |
| FR-07 | Intent: Generic App | Gunakan PackageManager.getLaunchIntentForPackage(packageName). Jika return null → app tidak terinstall → kirim ack error APP\_NOT\_INSTALLED. |
| FR-08 | App Not Installed Handling | TIDAK membuka Play Store. Kirim ack error dengan message: 'Aplikasi {nama app} belum terinstall di headunit.' Robot menyampaikan ini secara verbal ke user. |
| FR-09 | Acknowledgement | HTTP POST ke /api/v1/ack dalam 10 detik setelah setiap eksekusi. Payload: request\_id, status, message, timestamp. Retry POST 3x jika gagal. |
| FR-10 | Phone Call | android.intent.action.CALL dengan URI tel:{number}. Cek permission CALL\_PHONE runtime. Jika belum granted: minta permission, jika ditolak kirim ack error PERMISSION\_DENIED. |
| FR-11 | Device Registration | Pertama kali setup: POST /api/v1/register dengan device\_id, device\_name, android\_version, app\_version. Server simpan untuk routing SSE. |
| FR-12 | No Internet Notification | Jika headunit tidak punya internet: tampilkan persistent notification dengan instruksi USB Tethering. Notifikasi hilang otomatis saat internet tersedia. |

## **6.4 Flutter Dependencies**

| Package | Version (min) | Kegunaan |
| ----- | ----- | ----- |
| flutter\_foreground\_task | ^8.1.0 | Foreground service agar app tetap hidup di background dan auto-start on boot |
| flutter\_client\_sse | ^1.0.1 | SSE client untuk menerima push command dari MCP Server |
| http | ^1.2.0 | HTTP POST untuk device registration dan acknowledgement |
| android\_intent\_plus | ^5.1.0 | Menjalankan Android Intent dari Flutter (launch apps, navigation, call) |
| connectivity\_plus | ^6.0.3 | Monitor status internet (tersedia / tidak tersedia) secara real-time |
| shared\_preferences | ^2.3.0 | Simpan konfigurasi: device\_id, server\_url, device\_token |
| permission\_handler | ^11.3.0 | Runtime permission: CALL\_PHONE, BLUETOOTH\_SCAN, POST\_NOTIFICATIONS |
| flutter\_local\_notifications | ^17.2.2 | Persistent notification untuk status koneksi dan alert no-internet |

# **7\. API Contract**

## **7.1 Base URL & Auth**

| Item | Value |
| ----- | ----- |
| Base URL | https://mcp-android.xiaozhi.me/api/v1  (contoh — disesuaikan saat deploy) |
| Auth Header | Authorization: Bearer {device\_token} |
| SSE Endpoint | GET /stream/{device\_id}  — koneksi SSE persistente |
| Ack Endpoint | POST /ack |
| Register Endpoint | POST /register |
| Status Endpoint | GET /status/{device\_id} |

## **7.2 Command Payload (MCP Server → Flutter App via SSE)**

| {   "request\_id":    "req\_a1b2c3d4",   "command\_type":  "open\_navigation",   "parameters": {     "destination": "SPBU Shell Kemang Jakarta",     "app":         "google\_maps"   },   "ttl":           60,   "timestamp":     "2025-06-01T10:30:00Z" } |
| :---- |

## **7.3 Acknowledgement Payload (Flutter App → MCP Server)**

| // ✅ SUCCESS {   "request\_id":  "req\_a1b2c3d4",   "status":      "success",   "message":     "Google Maps sudah dibuka, navigasi ke SPBU Shell Kemang dimulai.",   "timestamp":   "2025-06-01T10:30:01Z" } // ❌ ERROR — app tidak terinstall {   "request\_id":  "req\_a1b2c3d4",   "status":      "error",   "error\_code":  "APP\_NOT\_INSTALLED",   "message":     "Aplikasi Waze belum terinstall di headunit.",   "timestamp":   "2025-06-01T10:30:01Z" } // ⚠️  ERROR — internet tidak tersedia saat command diterima dari queue {   "request\_id":  "req\_a1b2c3d4",   "status":      "error",   "error\_code":  "NO\_INTERNET",   "message":     "Headunit tidak terhubung ke internet. Aktifkan USB Tethering di HP.",   "timestamp":   "2025-06-01T10:30:01Z" } |
| :---- |

## **7.4 Error Codes**

| error\_code | Deskripsi & Verbal Response Robot |
| ----- | ----- |
| APP\_NOT\_INSTALLED | App target tidak terinstall. Robot: 'Aplikasi {nama} belum terinstall di headunit kamu.' |
| NO\_INTERNET | Headunit tidak punya internet. Robot: 'Headunit tidak terhubung ke internet. Aktifkan USB Tethering di HP kamu.' |
| PERMISSION\_DENIED | Permission Android ditolak. Robot: 'Perintah tidak bisa dijalankan karena izin akses belum diberikan di headunit.' |
| INVALID\_PAYLOAD | Schema command tidak valid. Robot: 'Terjadi kesalahan teknis, coba ulangi perintah kamu.' |
| HEADUNIT\_TIMEOUT | Tidak ada ack dalam 10 detik. Robot: 'Headunit tidak merespons. Pastikan app Car Companion berjalan.' |
| HEADUNIT\_DISCONNECTED | Tidak ada SSE connection aktif dan command expired dari queue. Robot: 'Headunit sedang tidak terhubung.' |
| INTENT\_FAILED | Intent diluncurkan tapi app throw exception. Robot: 'Terjadi kesalahan saat membuka aplikasi, coba lagi.' |
| COMMAND\_EXPIRED | Command TTL 60 detik habis sebelum headunit connect. Robot: 'Perintah kadaluarsa karena headunit tidak terhubung.' |

# **8\. Non-Functional Requirements**

| ID | Kategori | Target | Detail |
| ----- | ----- | ----- | ----- |
| NFR-01 | Latency End-to-End | \< 3 detik | Dari user selesai bicara hingga robot respons verbal (success case, internet stabil). |
| NFR-02 | Latency Eksekusi Intent | \< 1 detik | Dari command diterima Flutter app hingga Android Intent diluncurkan. |
| NFR-03 | MCP Server Availability | 99% uptime | Monitoring wajib. Health check endpoint disediakan. |
| NFR-04 | Security | HTTPS \+ Token auth | Semua komunikasi wajib HTTPS. Setiap device punya device\_token unik yang dirotasi berkala. |
| NFR-05 | Reconnection | Otomatis | SSE reconnect otomatis dengan exponential backoff. Tidak butuh interaksi user. |
| NFR-06 | Android Compatibility | Android 9+ (API 28+) | Minimum OS untuk support semua intent dan foreground service behavior. |
| NFR-07 | Battery / Resource | \< 3% / jam | Foreground service harus efisien. Heartbeat SSE 30 detik (bukan polling). Tidak ada wake lock agresif. |
| NFR-08 | Offline Resilience | Command queue 60s | Command tidak langsung hilang saat headunit offline. Queue di MCP Server selama 60 detik. |

# **9\. Testing Strategy**

## **9.1 Testing Environment**

Testing dilakukan dalam dua fase:

* **Fase 1 — Android Phone:** Gunakan Android phone sebagai pengganti headunit. HP kedua (atau HP yang sama dengan USB OTG \+ tethering dari HP lain) sebagai internet bridge.

* **Fase 2 — Android Headunit:** Testing di headunit sesungguhnya di dalam kendaraan.

**Prerequisite testing:**

* Robot aktif dan terhubung WiFi, conversation mode berfungsi normal.

* MCP Server ter-deploy di cloud xiaozhi.me dan terdaftar di konfigurasi xiaozhi.ai.

* Flutter app terinstall di Android phone/headunit dan konfigurasi device ID sudah dilakukan.

* HP sebagai internet bridge: USB Tethering aktif dan terkoneksi ke headunit.

## **9.2 Test Cases**

| TC-ID | Modul | Skenario | Expected Result | Phase | Status |
| ----- | ----- | ----- | ----- | ----- | ----- |
| TC-01 | Internet Bridge | Aktifkan USB Tethering di HP, colok ke headunit. | Status notifikasi headunit: ✅ Connected dalam 10 detik. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-02 | Navigation | User: 'Buka Google Maps, navigasi ke SPBU terdekat'. | Google Maps terbuka dengan rute aktif. Robot: konfirmasi verbal. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-03 | Music | User: 'Buka Spotify, putar playlist favourite'. | Spotify terbuka dan playlist mulai diputar. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-04 | App Not Installed | User: 'Buka Waze' (Waze tidak terinstall). | Robot: 'Aplikasi Waze belum terinstall di headunit kamu.' Play Store tidak terbuka. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-05 | No Internet | Matikan USB Tethering di HP, lalu beri perintah ke robot. | Robot: 'Headunit tidak terhubung ke internet. Aktifkan USB Tethering di HP.' Notifikasi muncul di headunit. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-06 | Command Queue | Matikan USB Tethering. Beri perintah. Aktifkan kembali dalam 30 detik. | Perintah dieksekusi setelah internet kembali. Robot: konfirmasi verbal. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-07 | Command Expired | Matikan USB Tethering. Beri perintah. Biarkan lebih dari 60 detik. Aktifkan kembali. | Perintah tidak dieksekusi. Robot: 'Perintah kadaluarsa karena headunit tidak terhubung.' | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-08 | Phone Call | User: 'Telepon 0812345678'. | Dialer terbuka dengan nomor ready. Panggilan dimulai. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-09 | WiFi Hotspot Fallback | Gunakan WiFi Hotspot dari HP (bukan USB Tethering). Beri perintah navigasi. | Perintah berhasil dieksekusi sama seperti USB Tethering. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-10 | Auto-start | Restart headunit/phone. Tunggu 30 detik. Beri perintah ke robot. | App berjalan di background otomatis. Perintah berhasil tanpa membuka app manual. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-11 | SSE Reconnect | Matikan WiFi headunit 15 detik (simulasi signal loss), nyalakan lagi. | App reconnect otomatis. Tidak butuh restart atau user action. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-12 | Ack Verbal | Semua TC di atas: verifikasi robot selalu memberikan respons verbal. | Setiap command (sukses/gagal) selalu ada konfirmasi verbal dari robot. | 1 & 2 | \[ \] Pass \[ \] Fail |

# **10\. Assumptions, Dependencies & Risks**

## **10.1 Assumptions**

* xiaozhi.ai mendukung penambahan MCP Server baru via konfigurasi di cloud xiaozhi.me tanpa modifikasi firmware robot.

* Android headunit menggunakan Android 9+ dan tidak memblokir Foreground Service atau penggunaan Android Intent.

* HP user mendukung USB Tethering (fitur standar Android sejak Android 2.2).

* Android headunit memiliki port USB yang dapat digunakan untuk USB Tethering (bukan hanya charging).

* Aplikasi native (Google Maps, Spotify, dll.) yang dikontrol sudah tersedia di Play Store untuk headunit jika perlu diinstall.

## **10.2 Dependencies**

* Dokumentasi API MCP Server dari tim xiaozhi.ai untuk integrasi tool call dan acknowledgement.

* Akses ke cloud xiaozhi.me untuk deploy dan konfigurasi MCP Server baru.

* Android headunit fisik untuk testing Fase 2\.

## **10.3 Risks & Mitigasi**

| Risk | Likelihood | Mitigasi |
| ----- | ----- | ----- |
| Headunit tidak support USB Tethering (port hanya charging). | Low | Gunakan WiFi Hotspot sebagai fallback. Dokumentasikan di user guide. |
| Headunit menggunakan Android custom yang memblokir Intent atau Foreground Service. | Medium | Testing Fase 1 di Android phone terlebih dahulu untuk validasi logic. Identifikasi batasan headunit sebelum Fase 2\. |
| SSE connection tidak stabil karena jaringan mobile (4G/5G HP berfluktuasi di dalam mobil). | Medium | Command queue 60 detik di MCP Server. Reconnect otomatis dengan backoff. Testing di lingkungan bergerak. |
| Spotify / navigasi app URI scheme berubah di versi terbaru. | Low | Implementasikan fallback: open app tanpa deep link jika URI scheme gagal. Monitor URI scheme changes berkala. |
| User lupa mengaktifkan USB Tethering di HP. | High | Notifikasi proaktif di headunit saat internet tidak tersedia dengan instruksi jelas. Robot juga menyampaikan panduan secara verbal. |
| Latency end-to-end \> 3 detik karena chain panjang (robot → cloud → MCP → headunit). | Medium | Profiling per layer. Optimasi SSE keep-alive, minimize TTS latency di xiaozhi.ai, dan SSE push langsung tanpa queue jika headunit online. |

# **11\. Deliverables & Acceptance Criteria**

| \# | Deliverable | Owner | Acceptance Criteria |
| ----- | ----- | ----- | ----- |
| D-01 | FSD v2.0 — Approved by PO | BA \+ PO | PO sign-off. Prerequisite semua deliverable lain. |
| D-02 | MCP Server ter-deploy di xiaozhi.me dengan semua 6 tools aktif | Backend Dev | Tool call dari xiaozhi.ai berhasil push command ke Flutter app via SSE. |
| D-03 | Flutter App APK — Debug build (Android phone) | Mobile Dev | TC-01 hingga TC-12 semua passed di Android phone. |
| D-04 | Integration Test Report — Fase 1 | QA | Semua test case documented dengan hasil pass/fail dan screenshot/log. |
| D-05 | Flutter App APK — Release build (headunit) | Mobile Dev | Debug screen off. Auto-start aktif. Signed APK. |
| D-06 | Integration Test Report — Fase 2 (headunit di kendaraan) | QA \+ PO | Testing di headunit di dalam mobil bergerak. Semua TC passed. |
| D-07 | User Setup Guide | BA | Panduan 1 halaman, bahasa Indonesia, step-by-step dengan screenshot. |

# **12\. Document Change Log**

| Version | Date | Author | Changes |
| ----- | ----- | ----- | ----- |
| 1.0.0 | June 2025 | Business Analyst | Initial release — arsitektur Cloud Relay, headunit dengan internet mandiri. |
| 2.0.0 | June 2025 | Business Analyst | Arsitektur direvisi: headunit tanpa internet mandiri. HP sebagai internet bridge via USB Tethering / WiFi Hotspot. Target: headunit menengah ke bawah, user awam. Tambah: FR-12 (no-internet notification), TC-05 s/d TC-07 (internet & queue scenarios), D-07 (user setup guide), Section 4 (internet bridge), error codes NO\_INTERNET & COMMAND\_EXPIRED. |

