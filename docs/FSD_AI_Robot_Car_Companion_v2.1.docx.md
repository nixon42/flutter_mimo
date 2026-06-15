

**FUNCTIONAL SPECIFICATION DOCUMENT**

AI Robot Assistant — Car Companion Feature

Android Headunit Integration via HP Internet Bridge \+ MQTT

| Document Version | 2.1.0 |
| :---- | :---- |
| Status | Draft — For Developer Review |
| Date | June 2025 |
| Author | Business Analyst |
| Target Platform | Android Headunit (menengah ke bawah) \+ Android Phone (Testing) |
| Internet Source | HP User via USB Tethering / WiFi Hotspot |
| Transport Layer | WebSocket (MCP Bridge → Headunit MCP) \+ MQTT QoS 1 (Headunit MCP → Android App) |
| AI Platform | xiaozhi.ai — LLM \+ MCP Orchestrator |

# **1\. Overview**

## **1.1 Background**

AI Robot Assistant adalah perangkat fisik berukuran kecil (P=10cm, L=5cm, T=8cm) yang ditenagai oleh ESP32-S3. Robot sudah memiliki kemampuan percakapan dua arah menggunakan platform xiaozhi.ai, serta telah terintegrasi dengan MCP Server untuk berbagai tool (Gmail, Telegram, Text Editor, Web Search).

Fitur Car Companion adalah ekspansi fungsionalitas robot agar dapat berperan sebagai asisten di dalam kendaraan — memungkinkan user memberikan perintah suara ke robot, dan robot mengeksekusi perintah tersebut di Android headunit secara otomatis. Contoh: 'Buka Google Maps, navigasi ke toko XXX', 'Putar playlist Spotify favourite', 'Telepon Budi'.

Dokumen ini adalah spesifikasi lengkap dan berdiri sendiri untuk fitur Car Companion. Infrastruktur MCP yang sudah ada (MCP Bridge, Gmail, Telegram, Text Editor, Web Search) tidak dibahas di dokumen ini karena sudah berjalan — dokumen ini hanya mencakup komponen baru yang perlu dibangun.

## **1.2 Keputusan Arsitektur Utama**

| Keputusan | Penjelasan |
| ----- | ----- |
| Headunit MCP di cloud sebagai layer tersendiri | MCP Bridge yang sudah ada tidak dimodifikasi. Ditambahkan Headunit MCP sebagai MCP Server baru di cloud, yang terhubung ke MCP Bridge via WebSocket dan meneruskan command ke Android app via MQTT. |
| MQTT sebagai transport Headunit MCP → Android app | MQTT pub/sub dengan QoS 1 dipilih untuk segmen terakhir (cloud ke headunit) karena built-in guaranteed delivery, persistent session untuk offline resilience, dan LWT untuk deteksi disconnect. |

## **1.3 Objectives**

* Membangun Headunit MCP sebagai MCP Server baru di cloud yang terintegrasi ke MCP Bridge yang sudah ada.

* Membangun Flutter app di Android headunit sebagai MQTT client dan Android Intent executor.

* HP user sebagai internet bridge — USB Tethering / WiFi Hotspot, zero dev effort.

* Setup semudah mungkin untuk user awam: aktifkan USB Tethering, colok ke headunit, selesai.

* Acknowledgement verbal ke user setelah setiap perintah dieksekusi (sukses atau gagal).

* Menangani kondisi: app tidak terinstall, internet tidak tersedia, headunit offline, duplicate command.

## **1.4 Scope**

**Komponen baru yang dibangun (in scope):**

* Headunit MCP — MCP Server baru di cloud, terhubung ke MCP Bridge via WebSocket, push command ke Android app via MQTT.

* MQTT Broker — managed cloud service sebagai message broker antara Headunit MCP dan Android app.

* Flutter app — MQTT client di Android headunit, subscribe command, eksekusi Android Intent, publish acknowledgement.

**Komponen existing yang tidak diubah (out of scope):**

* Robot hardware (ESP32-S3), firmware, dan Robot MCP.

* xiaozhi.ai platform dan konfigurasinya.

* MCP Bridge (xiaozhi-mcp-bridge) dan semua MCP Server yang sudah ada (Gmail, Telegram, Text Editor, Web Search).

* Koneksi internet mandiri di headunit.

* UI/dashboard visual di headunit — Flutter app berjalan di background.

# **2\. Stakeholders & Roles**

| Role | Pihak | Tanggung Jawab |
| ----- | ----- | ----- |
| Product Owner | Aji | Menentukan requirement, validasi FSD, sign-off UAT |
| Business Analyst | Aji | Menulis FSD, mediasi PO dan developer |
| Mobile Developer | Alief | Membangun Flutter app untuk Android headunit |
| Backend / MCP Dev | Alief | Membangun Headunit MCP \+ MQTT integration di cloud |
| QA Engineer | Aji/Alief | Integration test dan UAT di Android phone (Fase 1\) dan headunit (Fase 2\) |

# **3\. System Architecture**

## **3.1 High-Level Architecture**

Diagram berikut menunjukkan seluruh komponen sistem. Ada 3 komponen yg harus dibangun (NEW) yaitu Headunit MCP, MQTT Cloud dan Headunit App

| 👤 USER Bicara ke robot *\[existing\]* | ▶ | 🤖 ROBOT ESP32-S3 \+ WiFi *\[existing\]* | ▶ | ☁ XIAOZHI.AI LLM \+ MCP Orchestrator *\[existing\]* | ▶ | 🔌 MCP BRIDGE xiaozhi-mcp-bridge *\[existing\]* | ▶ | ⚙ HEADUNIT MCP cloud — NEW *via WebSocket* |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |

| ↓  MQTT pub/sub  (QoS 1 · Persistent Session · LWT)  ↓ |
| :---: |

| 📡  MQTT BROKER  —  HiveMQ Cloud  (NEW) QoS 1 · Persistent Session · Last Will & Testament · TLS 8883 |
| :---: |

| 📺  ANDROID HEADUNIT  —  Flutter App (MQTT Client)  (NEW) Subscribe: car/{device\_id}/cmd  ·  Publish: car/{device\_id}/ack  ·  Eksekusi Android Intent lokal *Maps · Spotify · YouTube Music · WhatsApp · Dialer · Generic App* |
| :---: |

Acknowledgement berjalan balik: **Android App → MQTT Broker → Headunit MCP → MCP Bridge → xiaozhi.ai → Robot Speaker → User.**

## **3.2 Peran Komponen Baru**

| Komponen | Status | Peran & Deskripsi |
| ----- | ----- | ----- |
| MCP Bridge | Existing | Komponen existing (xiaozhi-mcp-bridge). Menerima tool call dari xiaozhi.ai dan mendistribusikan ke MCP Server yang tepat via stdio/WebSocket/HTTP. Tidak dimodifikasi. |
| Headunit MCP | NEW | MCP Server baru di cloud. Terhubung ke MCP Bridge via WebSocket. Menerima tool call untuk Car Companion, lalu publish command JSON ke MQTT Broker. Subscribe topic ack dari Android app dan teruskan sebagai tool result ke MCP Bridge. |
| MQTT Broker | NEW | HiveMQ Cloud. Message broker antara Headunit MCP dan Android app. Handle QoS 1 delivery, persistent session, LWT. Tidak ada logic bisnis di sini. |
| Flutter App | NEW | Berjalan sebagai foreground service di Android headunit. MQTT client yang subscribe command, eksekusi Android Intent lokal, dan publish acknowledgement balik ke MQTT Broker. |

## **3.3 Detail Alur End-to-End**

| \# | Layer | Deskripsi |
| ----- | ----- | ----- |
| 1 | User → Robot | User mengucapkan perintah ke robot. Contoh: 'Buka Google Maps, navigasi ke SPBU terdekat.' |
| 2 | Robot → xiaozhi.ai | Robot streaming audio ke xiaozhi.ai via WiFi. Platform melakukan STT, NLU, dan AI inference. |
| 3 | xiaozhi.ai → MCP Bridge | xiaozhi.ai mengidentifikasi intent Car Companion dan mengirim tool call ke MCP Bridge. |
| 4 | MCP Bridge → Headunit MCP | MCP Bridge meneruskan tool call ke Headunit MCP via WebSocket. |
| 5 | Headunit MCP → MQTT Broker | Headunit MCP mem-parsing tool call, membentuk command payload JSON, dan publish ke MQTT topic car/{device\_id}/cmd dengan QoS 1\. |
| 6 | MQTT Broker → Android App | Broker deliver message ke Flutter app yang subscribe topic car/{device\_id}/cmd. Jika headunit offline, broker tahan message (persistent session QoS 1\) dan deliver saat reconnect. |
| 7 | Android App: Eksekusi | Flutter app parsing command JSON, cek idempotency (duplicate guard via request\_id), lalu eksekusi Android Intent lokal di headunit. |
| 8 | Android App → MQTT Broker | Flutter app publish acknowledgement JSON ke topic car/{device\_id}/ack dengan QoS 1\. Payload berisi status (success/error), pesan verbal, dan request\_id. |
| 9 | MQTT Broker → Headunit MCP | Broker deliver ack ke Headunit MCP yang subscribe topic car/+/ack. |
| 10 | Headunit MCP → MCP Bridge → xiaozhi.ai → Robot | Headunit MCP teruskan ack sebagai tool result ke MCP Bridge. xiaozhi.ai generate TTS dan robot putar via speaker. Contoh: 'Google Maps sudah dibuka, navigasi dimulai.' |

## **3.4 Tech Stack Lengkap**

| Komponen | Status | Teknologi | Keterangan |
| ----- | ----- | ----- | ----- |
| Robot \+ Firmware | Existing | ESP32-S3, xiaozhi SDK, Arduino C++ | Tidak ada perubahan. |
| xiaozhi.ai | Existing | xiaozhi.ai cloud platform | Tidak ada perubahan. Hanya mendaftarkan Headunit MCP sebagai MCP Server baru. |
| MCP Bridge | Existing | xiaozhi-mcp-bridge (fast mcp base) | Tidak ada modifikasi. Headunit MCP terhubung ke sini via WebSocket. |
| Headunit MCP | NEW | Node.js / Python \+ MCP SDK \+ mqtt.js / paho-mqtt | Deploy di cloud. WebSocket client ke MCP Bridge. MQTT client ke broker. Handle tool call, publish command, subscribe ack. |
| MQTT Broker | NEW | HiveMQ Cloud (recommended) | Managed cloud broker. QoS 1, persistent session, LWT, TLS port 8883\. Free tier cukup untuk dev & early prod. |
| Flutter App | NEW | Flutter (Dart) \+ mqtt\_client \+ android\_intent\_plus | MQTT client di headunit. Subscribe cmd topic, eksekusi intent lokal, publish ack topic. |

# **4\. MQTT Design**

## **4.1 MQTT Broker** 

| Broker | Free Tier | Connections | Rekomendasi |
| ----- | ----- | ----- | ----- |
| HiveMQ Cloud | 100 connections | 100 (free) | UI mudah, MQTT 5.0, SLA 99.9%, region Singapore tersedia. |
| EMQX Cloud | 1 juta msg/bln | 1000 (free) | Alternatif dengan free tier lebih generous. |
| Self-hosted Mosquitto | Gratis | Unlimited | Opsi jika ingin full control. Butuh setup dan maintain server sendiri. |

Perlu dilakukan assessment terlebih dahulu untuk MQTT Broker ini yang sesuai dengan kebutuhan aplikasi.

## **4.2 Topic Structure**

| Topic | QoS | Retain | Deskripsi |
| ----- | ----- | ----- | ----- |
| car/{device\_id}/cmd | 1 | false | Headunit MCP publish command ke Android app. Flutter app subscribe topic ini. |
| car/{device\_id}/ack | 1 | false | Flutter app publish ack. Headunit MCP subscribe car/+/ack. |
| car/{device\_id}/status | 1 | true | Flutter app publish status online saat connect (retained). Headunit MCP cek status headunit kapanpun. |
| car/{device\_id}/lwt | 1 | true | Last Will & Testament. Broker publish otomatis ke topic ini saat Flutter app disconnect unexpected. |

| // Contoh topic untuk device\_id \= 'robot-abc123' car/robot-abc123/cmd      ← Headunit MCP publish, Flutter subscribe car/robot-abc123/ack      ← Flutter publish, Headunit MCP subscribe car/robot-abc123/status   ← Flutter publish retained (online/offline) car/robot-abc123/lwt      ← Broker publish otomatis saat Flutter disconnect |
| :---- |

## **4.3 QoS & Persistent Session**

| MENGAPA QoS 1 | QoS 1 menjamin command terkirim minimal sekali meski jaringan tidak stabil. Dengan persistent session (cleanSession=false), command tidak hilang saat headunit offline sementara — broker tahan dan deliver otomatis saat reconnect, tanpa perlu custom queue di server. |
| :---: | :---- |

**Konfigurasi wajib di Flutter app saat connect:**

* **cleanSession \= false** — persistent session aktif.

* **client\_id konsisten** — selalu gunakan 'headunit-{device\_id}'. Jangan random.

* **Semua subscribe dengan QoS 1** — agar broker tahu level delivery yang diminta.

## **4.4 Last Will & Testament (LWT)**

LWT dikonfigurasi saat Flutter app connect ke broker. Jika app disconnect tanpa mengirim DISCONNECT packet (crash, network drop tiba-tiba), broker otomatis publish ke topic LWT — Headunit MCP langsung tahu headunit offline tanpa perlu polling atau timeout.

| // Konfigurasi LWT di Flutter app saat connect MqttConnectMessage connectMsg \= MqttConnectMessage()   .withClientIdentifier('headunit-{device\_id}')   .withWillTopic('car/{device\_id}/lwt')   .withWillMessage('{"status": "offline", "timestamp": "..."}')   .withWillQos(MqttQos.atLeastOnce)   .withWillRetain()   .startClean();   // false \= persistent session |
| :---- |

# **5\. Internet Bridge — HP ke Headunit**

## **5.1 Metode Koneksi**

| Metode | Prioritas | Cara Kerja | Catatan |
| ----- | ----- | ----- | ----- |
| USB Tethering | Primary | Colok HP ke headunit via kabel USB. Di HP: Settings → Hotspot & Tethering → USB Tethering → ON. | Paling stabil. Sekaligus charge HP. Support hampir semua headunit Android. |
| WiFi Hotspot | Fallback | HP dijadikan hotspot. Di HP: Settings → Hotspot → ON. Headunit konek ke SSID HP. | Gunakan jika port USB headunit sudah dipakai atau tidak support USB tethering. |

| ZERO DEV EFFORT | Kedua metode adalah fitur native Android. Developer tidak perlu membangun apapun untuk internet bridge. HP tidak perlu install app. |
| :---: | :---- |

## **5.2 Deteksi Status Internet di Flutter App**

* Gunakan package connectivity\_plus untuk monitor status koneksi secara real-time.

* **Internet tersedia:** inisiasi MQTT connection ke broker.

* **Internet putus:** MQTT disconnect. Broker trigger LWT otomatis. Flutter app tampilkan persistent notification: 'Hubungkan HP via USB Tethering untuk mengaktifkan Car Companion Mode.'

* **Internet kembali:** MQTT reconnect otomatis. Broker deliver pending QoS 1 messages dari persistent session.

## **5.3 User Setup Guide**

**Setup Awal (hanya sekali):**

1. Install Flutter app di Android headunit.

2. Buka app, masukkan Device ID robot (tertera di bodi robot atau di app xiaozhi.ai, atau ada mekanisme lain please advise).

3. Masukkan MQTT Broker URL dan credentials (please advise apakah mekanisme ini benar).

4. Tap 'Tes Koneksi' — pastikan status Connected muncul.

5. Minimize app — berjalan otomatis di background.

**Setiap Kali Menggunakan di Mobil:**

6. Colok HP ke port USB headunit dengan kabel USB.

7. Di HP: Settings → Hotspot & Tethering → aktifkan USB Tethering.

8. Atau koneksi internet via WiFi Hotspot dari HP.

9. Tunggu 5–10 detik hingga ikon Connected muncul di notifikasi headunit.

10. Bicara ke robot — Car Companion Mode aktif.

# **6\. Headunit MCP — Spesifikasi**

## **6.1 Deskripsi**

Headunit MCP adalah MCP Server baru yang di-deploy di cloud. Perannya adalah menjadi jembatan antara MCP Bridge (yang sudah ada) dan Android Headunit App melalui MQTT Broker.

| Aspek | Detail |
| ----- | ----- |
| Koneksi ke MCP Bridge | WebSocket client — terhubung ke MCP Bridge yang sudah berjalan |
| Koneksi ke MQTT Broker | MQTT client — publish ke car/{device\_id}/cmd, subscribe car/+/ack dan car/+/lwt |
| Registrasi di xiaozhi.ai | Didaftarkan sebagai MCP Server baru di konfigurasi xiaozhi.me, sama seperti MCP Server Gmail/Telegram |
| Ack timeout | 10 detik. Jika tidak ada ack dari Android app, kirim error HEADUNIT\_TIMEOUT sebagai tool result. |
| LWT handling | Saat menerima LWT dari broker (topic car/{device\_id}/lwt), log headunit sebagai offline dan kirim error HEADUNIT\_DISCONNECTED. |

## **6.2 Headunit MCP — Kode Contoh**

| // Node.js — Headunit MCP: publish command \+ subscribe ack const mqtt \= require('mqtt'); const mqttClient \= mqtt.connect('mqtts://broker.hivemq.com:8883', {   username: process.env.MQTT\_USER,   password: process.env.MQTT\_PASS,   clientId: 'headunit-mcp-server' }); // Dipanggil saat MCP Bridge meneruskan tool call function handleToolCall(deviceId, toolName, params) {   const command \= { request\_id: uuid(), command\_type: toolName, parameters: params, timestamp: new Date() };   mqttClient.publish(\`car/${deviceId}/cmd\`, JSON.stringify(command), { qos: 1 });   // tunggu ack via subscribe di bawah, timeout 10 detik } // Subscribe ack, lwt, dan status dari semua headunit mqttClient.subscribe(\['car/+/ack', 'car/+/lwt', 'car/+/status'\], { qos: 1 }); mqttClient.on('message', (topic, payload) \=\> {   const \[, deviceId, type\] \= topic.split('/');   if (type \=== 'ack') forwardAckToMcpBridge(deviceId, JSON.parse(payload));   if (type \=== 'lwt') markHeadunitOffline(deviceId); }); |
| :---- |

## **6.3 Daftar MCP Tools**

| Tool Name | Parameter | Deskripsi |
| ----- | ----- | ----- |
| open\_navigation | destination: string app: enum \[google\_maps, waze, here\] (default: google\_maps) | Buka navigasi ke destinasi. Google Maps URI: google.navigation:q={destination}\&mode=d. Waze: waze://?q={destination}\&navigate=yes. |
| open\_music | app: enum \[spotify, youtube\_music, default\] action: enum \[play\_playlist, play\_song, play\_artist\] query: string | Buka app musik dan mulai pemutaran via URI scheme / deep link. |
| open\_app | package\_name: string uri: string (optional) extra: object (optional) | Generic app launcher berdasarkan package name. Fallback untuk app yang tidak ter-cover tool spesifik. |
| phone\_call | number: string contact\_name: string (optional) | Panggilan telepon via android.intent.action.CALL dengan URI tel:{number}. Butuh permission CALL\_PHONE. |
| send\_message | app: enum \[whatsapp, sms\] contact: string message: string | Kirim pesan via WhatsApp deep link atau SMS intent. |
| get\_headunit\_status | (none) | Cek status koneksi MQTT headunit, daftar app terinstall, dan versi OS Android. |

# **7\. Flutter Application — Android Headunit**

## **7.1 Deskripsi Umum**

Flutter app berjalan sebagai foreground service di Android headunit. Tidak ada UI utama yang perlu dioperasikan user setelah setup awal. App otomatis start saat headunit menyala (boot at start di code) dan menjaga koneksi MQTT ke broker selama internet dari HP tersedia.

## **7.2 Screens & UI**

| ID | Screen | Deskripsi |
| ----- | ----- | ----- |
| S-01 | Setup Screen | Pertama kali run: input Device ID robot, MQTT Broker URL, credentials. Tombol 'Tes Koneksi'. Setelah berhasil, tidak perlu dibuka lagi. |
| S-02 | Persistent Notification | Status di notification bar: Connected / No Internet / Disconnected \+ \<nama Device ID\>. |
| S-03 | Internet Alert | Snackbar muncul saat internet tidak tersedia: 'Hubungkan HP via USB Tethering atau WiFi Hotspot untuk mengaktifkan Car Companion Mode.' |
| S-04 | Command Log (Debug) | Log riwayat command dan status eksekusi. Aktif di debug build saja. Nonaktif di release build. |

## **7.3 Functional Requirements**

| FR-ID | Requirement | Detail |
| ----- | ----- | ----- |
| FR-01 | Auto-start on Boot | Foreground service otomatis start saat Android boot (RECEIVE\_BOOT\_COMPLETED). Service menjaga MQTT connection selama internet tersedia. |
| FR-02 | Internet Monitor | Monitor status internet via connectivity\_plus. Internet tersedia → init MQTT. Internet putus → MQTT disconnect gracefully, tampilkan alert. Internet kembali → MQTT reconnect otomatis. |
| FR-03 | MQTT Connection | Connect ke MQTT Broker dengan cleanSession=false, client\_id='headunit-{device\_id}', keepalive=60s. Konfigurasi LWT saat connect. Reconnect otomatis via built-in mqtt\_client. |
| FR-04 | MQTT Subscribe | Saat connect berhasil, subscribe topic car/{device\_id}/cmd dengan QoS 1\. Jika session\_present=true saat reconnect, pending messages dari broker di-deliver otomatis. |
| FR-05 | Intent: Navigation | Google Maps: google.navigation:q={destination}\&mode=d. Waze: waze://?q={destination}\&navigate=yes. Cek via PackageManager sebelum launch. |
| FR-06 | Intent: Music | Spotify: URI spotify:search:{query}. YouTube Music: ACTION\_VIEW. Fallback ke open app tanpa deep link jika URI gagal. |
| FR-07 | Intent: Generic App | PackageManager.getLaunchIntentForPackage(packageName). Jika null → APP\_NOT\_INSTALLED. TIDAK membuka Play Store. |
| FR-08 | Acknowledgement via MQTT | Setelah eksekusi (sukses/gagal), publish JSON ke car/{device\_id}/ack dengan QoS 1\. Payload: request\_id, status, message (teks verbal untuk TTS robot), timestamp. |
| FR-09 | Phone Call | android.intent.action.CALL dengan URI tel:{number}. Cek permission CALL\_PHONE runtime. Jika ditolak → kirim ack PERMISSION\_DENIED. |
| FR-10 | App Not Installed | TIDAK membuka Play Store. Kirim ack APP\_NOT\_INSTALLED dengan message: 'Aplikasi {nama} belum terinstall di headunit.' |
| FR-11 | Status & LWT via MQTT | Saat connect: publish retained {status:'online'} ke car/{device\_id}/status. LWT: {status:'offline'} ke car/{device\_id}/lwt (retained, QoS 1). |
| FR-12 | No Internet Notification | Persistent notification dengan instruksi USB Tethering saat internet tidak tersedia. Hilang otomatis saat internet tersedia. |
| FR-13 | Idempotent Command Handling | Simpan set request\_id yang sudah diproses (in-memory, max 100 entries, FIFO). Jika request\_id duplikat diterima (QoS 1 re-delivery): skip eksekusi, kirim ack ulang saja. |

## **7.4 Android Permissions**

| Permission | Kegunaan |
| ----- | ----- |
| RECEIVE\_BOOT\_COMPLETED | Auto-start foreground service saat headunit boot |
| FOREGROUND\_SERVICE | Menjalankan background service yang persisten |
| CALL\_PHONE | Melakukan panggilan telepon via intent |
| INTERNET | Koneksi MQTT ke broker |
| ACCESS\_NETWORK\_STATE | Monitor status internet via connectivity\_plus |
| POST\_NOTIFICATIONS | Persistent status notification (Android 13+) |

## **7.5 Flutter Dependencies**

| Package | Version (min) | Kegunaan |
| ----- | ----- | ----- |
| mqtt\_client | ^10.4.0 | MQTT client — subscribe cmd, publish ack, persistent session, LWT |
| flutter\_foreground\_task | ^8.1.0 | Foreground service — tetap hidup di background, auto-start on boot |
| android\_intent\_plus | ^5.1.0 | Menjalankan Android Intent dari Flutter (navigation, music, call, generic app) |
| connectivity\_plus | ^6.0.3 | Monitor status internet real-time |
| flutter\_local\_notifications | ^17.2.2 | Persistent notification status koneksi dan alert no-internet |
| shared\_preferences | ^2.3.0 | Simpan konfigurasi: device\_id, broker URL, credentials |
| permission\_handler | ^11.3.0 | Runtime permission: CALL\_PHONE, POST\_NOTIFICATIONS |

# **8\. Message Contract**

## **8.1 Command Payload — Topic: car/{device\_id}/cmd  (QoS 1\)**

Published by Headunit MCP. Received by Flutter app.

| {   "request\_id":    "req\_a1b2c3d4",       // unique ID per command, untuk idempotency   "command\_type":  "open\_navigation",     // lihat Section 6.3 untuk semua command\_type   "parameters": {     "destination": "SPBU Shell Kemang Jakarta",     "app":         "google\_maps"   },   "timestamp":     "2025-06-01T10:30:00Z" } |
| :---- |

## **8.2 Acknowledgement Payload — Topic: car/{device\_id}/ack  (QoS 1\)**

Published by Flutter app. Received by Headunit MCP.

| // SUCCESS {   "request\_id":  "req\_a1b2c3d4",   "status":      "success",   "message":     "Google Maps sudah dibuka, navigasi ke SPBU Shell Kemang dimulai.",   "timestamp":   "2025-06-01T10:30:01Z" } // ERROR — app tidak terinstall {   "request\_id":  "req\_a1b2c3d4",   "status":      "error",   "error\_code":  "APP\_NOT\_INSTALLED",   "message":     "Aplikasi Waze belum terinstall di headunit.",   "timestamp":   "2025-06-01T10:30:01Z" } // ERROR — internet tidak tersedia {   "request\_id":  "req\_a1b2c3d4",   "status":      "error",   "error\_code":  "NO\_INTERNET",   "message":     "Headunit tidak terhubung ke internet. Aktifkan USB Tethering di HP.",   "timestamp":   "2025-06-01T10:30:01Z" } |
| :---- |

## **8.3 Status & LWT Payload**

| // Topic: car/{device\_id}/status (retained) — Flutter app publish saat connect { "status": "online",  "app\_version": "1.0.0", "android\_version": "11", "timestamp": "..." } // Topic: car/{device\_id}/lwt (retained) — Broker publish otomatis saat Flutter disconnect { "status": "offline", "timestamp": "..." } |
| :---- |

## **8.4 Error Codes**

| error\_code | Deskripsi & Verbal Response Robot |
| ----- | ----- |
| APP\_NOT\_INSTALLED | App target tidak terinstall. Play Store tidak dibuka. Robot: 'Aplikasi {nama} belum terinstall di headunit kamu.' |
| NO\_INTERNET | Headunit tidak punya internet. Robot: 'Headunit tidak terhubung ke internet. Aktifkan USB Tethering di HP kamu.' |
| PERMISSION\_DENIED | Permission Android ditolak. Robot: 'Perintah tidak bisa dijalankan karena izin akses belum diberikan di headunit.' |
| INVALID\_PAYLOAD | Schema command JSON tidak valid. Robot: 'Terjadi kesalahan teknis, coba ulangi perintah kamu.' |
| HEADUNIT\_TIMEOUT | Tidak ada ack dalam 10 detik. Robot: 'Headunit tidak merespons. Pastikan app Car Companion berjalan.' |
| HEADUNIT\_DISCONNECTED | LWT diterima dari broker — headunit offline. Robot: 'Headunit sedang tidak terhubung.' |
| INTENT\_FAILED | Intent diluncurkan tapi app throw exception. Robot: 'Terjadi kesalahan saat membuka aplikasi, coba lagi.' |
| DUPLICATE\_COMMAND | request\_id sudah diproses (QoS 1 re-delivery). Intent tidak dieksekusi ulang. Ack dikirim ulang. Tidak ada respons verbal. |

# **9\. Non-Functional Requirements**

| ID | Kategori | Target | Detail |
| ----- | ----- | ----- | ----- |
| NFR-01 | Latency End-to-End | \< 3 detik | Dari user selesai bicara hingga robot respons verbal (success case, jaringan stabil). |
| NFR-02 | Latency MQTT Delivery | \< 200ms | Dari Headunit MCP publish hingga Flutter app terima message. Broker region Singapore. |
| NFR-03 | Latency Intent Execution | \< 1 detik | Dari message diterima Flutter app hingga Android Intent diluncurkan. |
| NFR-04 | Broker Availability | 99.9% uptime | HiveMQ Cloud SLA. Monitor via broker dashboard dan uptime alert. |
| NFR-05 | Security | TLS 1.2+ \+ Auth | Semua koneksi MQTT via TLS port 8883\. Username/password auth per device. |
| NFR-06 | Offline Resilience | QoS 1 \+ Persistent | Command tidak hilang saat headunit offline sementara. Broker handle via persistent session. |
| NFR-07 | Android Compatibility | Android 9+ (API 28+) | Minimum OS untuk foreground service, intent, dan runtime permission. |
| NFR-08 | Battery / Resource | \< 3% / jam | MQTT persistent TCP lebih efisien dari HTTP polling. Keepalive 60 detik. |
| NFR-09 | Idempotency | In-memory dedup | Flutter app dedup QoS 1 duplicate via request\_id cache (max 100 entries, FIFO). |

# **10\. Testing Strategy**

## **10.1 Testing Environment**

Testing dilakukan dalam dua fase:

* **Fase 1 — Android Phone (wajib):** Android phone sebagai pengganti headunit. HP kedua sebagai internet bridge via USB Tethering atau Hotspot. Semua TC harus passed sebelum lanjut ke Fase 2\.

* **Fase 2 — Android Headunit:** Testing di headunit sesungguhnya di dalam kendaraan yang bergerak.

**Prerequisite sebelum testing:**

* Robot aktif dan terhubung WiFi, conversation mode berfungsi normal.

* MQTT Broker (HiveMQ Cloud) dikonfigurasi, credentials tersedia.

* Headunit MCP ter-deploy di cloud, terhubung ke MCP Bridge dan MQTT Broker.

* Flutter app terinstall dengan konfigurasi yang benar (device\_id, broker URL, credentials).

* HP sebagai internet bridge: USB Tethering aktif dan terkoneksi ke headunit/phone.

## **10.2 Test Cases**

| TC-ID | Modul | Skenario | Expected Result | Phase | Status |
| ----- | ----- | ----- | ----- | ----- | ----- |
| TC-01 | Internet Bridge | Aktifkan USB Tethering di HP, colok ke headunit/phone. | Notifikasi Connected dalam 10 detik. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-02 | MQTT Connect | Start app, pastikan MQTT broker terhubung. | Notifikasi Connected. Broker dashboard: 1 client aktif. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-03 | Navigation | User: 'Buka Google Maps, navigasi ke SPBU terdekat'. | Google Maps terbuka dengan rute aktif. Robot: konfirmasi verbal. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-04 | Music | User: 'Buka Spotify, putar playlist favourite'. | Spotify terbuka dan playlist diputar. Robot: konfirmasi verbal. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-05 | App Not Installed | User: 'Buka Waze' (tidak terinstall). | Robot: 'Aplikasi Waze belum terinstall di headunit kamu.' Play Store tidak terbuka. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-06 | No Internet | Matikan USB Tethering. Beri perintah ke robot. | Robot: error no internet. Notifikasi instruksi USB Tethering muncul di headunit. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-07 | QoS Offline Delivery | Matikan USB Tethering. Beri perintah. Aktifkan kembali dalam 30 detik. | MQTT broker deliver pending message setelah reconnect. Perintah dieksekusi. Robot: konfirmasi. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-08 | LWT Detection | Kill Flutter app paksa (force stop). Cek log Headunit MCP. | Broker publish LWT. Headunit MCP log headunit sebagai offline. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-09 | Idempotency | Kirim command dengan request\_id yang sama 2x ke MQTT Broker. | Intent dieksekusi hanya sekali. Ack dikirim 2x tapi tidak ada eksekusi duplikat. | 1 | \[ \] Pass \[ \] Fail |
| TC-10 | Phone Call | User: 'Telepon 0812345678'. | Dialer terbuka dengan nomor ready. Panggilan dimulai. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-11 | WhatsApp | User: 'Kirim WhatsApp ke Budi, bilang saya sudah otw'. | WhatsApp terbuka dengan chat Budi dan pesan siap dikirim. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-12 | WiFi Hotspot | Gunakan WiFi Hotspot sebagai internet bridge. Beri perintah navigasi. | Perintah berhasil sama seperti USB Tethering. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-13 | Auto-start | Restart headunit/phone. Tunggu 30 detik. Beri perintah ke robot. | App auto-start, MQTT connect, perintah berhasil tanpa manual action. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-14 | MQTT Reconnect | Matikan WiFi headunit 15 detik, nyalakan kembali. | MQTT reconnect otomatis. Tidak butuh restart atau user action. | 1 & 2 | \[ \] Pass \[ \] Fail |
| TC-15 | Ack Verbal | Semua TC di atas: verifikasi robot memberikan respons verbal. | Setiap command (sukses/gagal) selalu ada konfirmasi verbal dari robot. | 1 & 2 | \[ \] Pass \[ \] Fail |

# **11\. Assumptions, Dependencies & Risks**

## **11.1 Assumptions**

* MCP Bridge sudah berjalan dan mendukung registrasi MCP Server baru via WebSocket tanpa modifikasi kode existing.

* xiaozhi.ai mendukung penambahan MCP Server baru (Headunit MCP) via konfigurasi di xiaozhi.me tanpa modifikasi firmware robot.

* Android headunit menggunakan Android 9+ dan tidak memblokir Foreground Service atau Android Intent.

* HP user mendukung USB Tethering (fitur standar Android sejak Android 2.2).

* Android headunit memiliki port USB yang dapat digunakan untuk USB Tethering.

## **11.2 Dependencies**

* Akses dokumentasi WebSocket interface MCP Bridge untuk koneksi Headunit MCP.

* Akses ke cloud xiaozhi.me untuk deploy Headunit MCP dan mendaftarkannya ke xiaozhi.ai.

* MQTT Broker (HiveMQ Cloud) — akun dan credentials sebelum development dimulai.

* Android headunit fisik untuk testing Fase 2\.

## **11.3 Risks & Mitigasi**

| Risk | Priority | Mitigasi |
| ----- | ----- | ----- |
| User lupa aktifkan USB Tethering di HP. | High | Persistent notification di headunit \+ robot sampaikan instruksi verbal saat internet tidak tersedia. |
| MCP Bridge WebSocket interface tidak terdokumentasi atau berubah. | Medium | Koordinasi dengan developer MCP Bridge sebelum development Headunit MCP dimulai. |
| Headunit Android custom memblokir Foreground Service atau Intent. | Medium | Wajib Fase 1 testing di Android phone untuk validasi logic sebelum deploy ke headunit. |
| QoS 1 duplicate message menyebabkan intent dieksekusi ganda. | Medium | FR-13: idempotent handling via request\_id dedup cache di Flutter app. |
| MQTT Broker downtime. | Low | HiveMQ Cloud SLA 99.9%. Setup uptime monitoring dan alert. |
| Latency end-to-end \> 3 detik karena chain panjang. | Medium | Profiling per layer. MQTT broker region Singapore. Monitor xiaozhi.ai TTS latency. |
| Headunit tidak support USB Tethering (port hanya charging). | Low | WiFi Hotspot tersedia sebagai fallback. |

# **12\. Deliverables & Acceptance Criteria**

| \# | Deliverable | Owner | Acceptance Criteria |
| ----- | ----- | ----- | ----- |
| D-01 | FSD v2.1.0 — Approved by PO | BA \+ PO | PO sign-off. Prerequisite semua deliverable lain. |
| D-02 | MQTT Broker dikonfigurasi (HiveMQ Cloud) dengan credentials dan topic ACL | Backend Dev | Publish/subscribe dari CLI berhasil. TLS aktif. Credentials per device tersedia. |
| D-03 | Headunit MCP ter-deploy di cloud, terhubung ke MCP Bridge via WebSocket dan MQTT Broker | Backend Dev | Tool call dari xiaozhi.ai via MCP Bridge berhasil push command ke MQTT Broker dan terima ack. Semua 6 tools berfungsi. |
| D-04 | Flutter App APK — Debug build (Android phone, Fase 1\) | Mobile Dev | TC-01 hingga TC-15 semua passed di Android phone. |
| D-05 | Integration Test Report — Fase 1 | QA | Semua TC documented dengan hasil pass/fail, screenshot, dan log. |
| D-06 | Flutter App APK — Release build (headunit) | Mobile Dev | Debug screen off. Auto-start aktif. Command Log nonaktif. Signed APK. |
| D-07 | Integration Test Report — Fase 2 (headunit di kendaraan) | QA \+ PO | TC-01 hingga TC-15 passed di headunit dalam kondisi mobil bergerak. |
| D-08 | User Setup Guide (1 halaman, Bahasa Indonesia) | BA | Step-by-step dengan screenshot. Divalidasi oleh non-technical user. |

# **13\. Document Change Log**

| Version | Date | Author | Summary of Changes |
| ----- | ----- | ----- | ----- |
| 1.0.0 | June 2025 | Business Analyst | Initial release. Cloud Relay, headunit internet mandiri, transport SSE. |
| 2.0.0 | June 2025 | Business Analyst | HP sebagai internet bridge via USB Tethering/Hotspot. Transport SSE \+ HTTP POST. |
| 2.1.0 | June 2025 | Business Analyst | Transport layer: SSE+HTTP → MQTT QoS 1\. Arsitektur direvisi sesuai diagram aktual: tambah layer Headunit MCP (cloud, via WebSocket ke MCP Bridge), MQTT Broker sebagai komponen baru. MCP Bridge dan tools existing (Gmail, Telegram, dll) tidak dibahas. Dokumen dijadikan standalone. Tambah FR-13 (idempotency), Section MQTT Design lengkap, Section Headunit MCP, kode contoh Node.js, TC baru (LWT, idempotency, MQTT reconnect, WhatsApp). Risk baru: MCP Bridge WebSocket interface. |

