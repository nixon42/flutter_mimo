# Mimo Car Companion - MCP Backend

Server [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) yang bertugas sebagai jembatan antara **AI (LLM)** dan **Aplikasi Android (Flutter)** pada Headunit mobil.

Backend ini mengekspos *Tools* seperti `open_navigation`, `open_music`, dll kepada LLM. Saat LLM memanggil *tool*, backend ini akan meneruskan perintah tersebut ke Headunit via protokol **MQTT** secara real-time.

## 🚀 Fitur Utama
- Berjalan menggunakan **stdio** (Standar Input/Output) sehingga kompatibel dengan semua MCP Client (Claude Desktop, mcp-bridge, XiaoZhi, dll).
- Termasuk **Embedded MQTT Broker** otomatis (`amqtt`). Anda tidak perlu menginstal Mosquitto secara terpisah di OS server Anda.
- Respon dua arah tersinkronisasi (*synchronous acknowledgment*): Server akan menunggu Flutter Android merespon sukses/gagal sebelum melaporkan kembali hasil akhir ke LLM.

---

## 🛠️ Persyaratan
- Python 3.13+
- [uv](https://github.com/astral-sh/uv) package manager terinstal.

---

## ⚙️ Cara Menjalankan (Standalone)
Jika hanya ingin menyalakan server (meskipun ini biasanya dijalankan otomatis oleh MCP Client):
```bash
cd mcp_backend
uv run -m mcp_backend.server
```
*(Broker MQTT otomatis akan aktif di port `1883` begitu perintah ini dijalankan)*

---

## 🔗 Konfigurasi ke MCP Client (Claude / mcp-bridge / XiaoZhi)

Untuk menyambungkan server ini ke LLM, tambahkan konfigurasi berikut ke MCP Client Anda. 

Jika menggunakan **mcp-bridge** atau **Claude Desktop**, tambahkan di `mcp.json` / `config.json`:

```json
{
  "mcpServers": {
    "mimo_car_companion": {
      "command": "uv",
      "args": [
        "--directory",
        "/absolute/path/ke/flutter_mimo/mcp_backend",
        "run",
        "-m",
        "mcp_backend.server"
      ]
    }
  }
}
```

> **Catatan**: Pastikan mengganti `/absolute/path/ke/flutter_mimo/mcp_backend` dengan *path* sebenarnya ke direktori `mcp_backend` Anda di server.

---

## 🧪 Cara Menguji (Test Client)

Kami menyediakan `test_client.py` yang berfungsi sebagai "Simulator LLM". Anda dapat menggunakan skrip ini untuk memastikan komunikasi dari Python hingga ke Headunit Android berjalan lancar tanpa memerlukan API Keys atau LLM yang sebenarnya.

**Langkah-Langkah Uji Coba:**
1. Nyalakan aplikasi Flutter Mimo di HP/Headunit Android Anda (`fvm flutter run`).
2. Masukkan IP server Ubuntu Anda di kolom "MQTT Broker" di layar Dashboard aplikasi, lalu klik **Start**.
3. Buka terminal di server Ubuntu Anda, lalu jalankan test:
   ```bash
   cd mcp_backend
   uv run test_client.py
   ```
4. Perhatikan layar Android. Aplikasi seharusnya memproses notifikasi MQTT dan membuka Google Maps secara otomatis. Skrip Python akan mencetak balasan sukses (Acknowledgement).

## Mengatasi Bug Offline Queueing di AMQTT (Local Testing)

Saat melakukan pengetesan *offline queueing* secara lokal, ada kalanya aplikasi Flutter tiba-tiba kehilangan koneksi internet (contoh: mobil melewati terowongan). Ini menyebabkan koneksi TCP terputus secara sepihak (*half-open connection*).

Secara bawaan, library broker `amqtt` memiliki sebuah **bug/keterbatasan fatal**: ia hanya mau menunggu *ACK* selama 5 detik. Jika dalam 5 detik HP tidak merespons (karena sinyal mati), `amqtt` akan membuang pesan *command* tersebut untuk selamanya alih-alih menyimpannya di antrean offline.

Untuk memperbaiki ini di lingkungan *virtual environment* lokal Anda, kami telah menyediakan *script patch*:

```bash
uv run patch_amqtt.py
```

**Apa yang dilakukan script ini?**
Script ini mencari lokasi library `amqtt` di dalam `.venv` Anda dan mengubah nilai *timeout* yang *hardcoded* dari 5 detik menjadi 90 detik. Dengan begitu, mekanisme standar *Keep-Alive* MQTT (60 detik) akan berjalan lebih dulu untuk mendeteksi matinya sinyal, lalu menyimpan pesan Anda secara aman ke dalam antrean *offline*.

> **Catatan:** Jika Anda mem-publish aplikasi ke *Production* dengan menggunakan Public Broker ternama (seperti `broker.emqx.io` atau Mosquitto yang disebutkan di FSD), Anda tidak akan mengalami bug ini karena broker publik sangat stabil menangani *half-open connection*.

## Troubleshooting

---

## 🌐 Struktur Topik MQTT

Jika Anda ingin melakukan proses *debugging* manual, berikut adalah topik MQTT yang digunakan (tanpa menggunakan password/auth):

- **Command (Server 👉 Android):** `device/default_device/command`
  - Contoh payload: `{"command": "open_navigation", "args": {"destination": "Monas"}}`
- **Ack (Android 👉 Server):** `device/default_device/ack`
  - Contoh payload: `{"status": "success", "message": "Executed open_navigation successfully"}`
