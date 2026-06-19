import os
import sys

def apply_patch():
    # Temukan path ke handler.py di dalam .venv
    # Kita menggunakan sys.prefix untuk mendapatkan path environment saat ini
    base_path = sys.prefix
    
    # Path relatif ke file yang mengandung bug di amqtt
    # Mendukung Python 3.9 sampai 3.13
    python_version = f"python{sys.version_info.major}.{sys.version_info.minor}"
    handler_path = os.path.join(base_path, "lib", python_version, "site-packages", "amqtt", "mqtt", "protocol", "handler.py")
    
    if not os.path.exists(handler_path):
        print(f"❌ File tidak ditemukan: {handler_path}")
        print("Pastikan script ini dijalankan di dalam virtual environment (uv run patch_amqtt.py)")
        sys.exit(1)
        
    with open(handler_path, "r") as f:
        content = f.read()
        
    # Bug original dari amqtt:
    bug_target = "app_message.puback_packet = await asyncio.wait_for(waiter, timeout=5)"
    
    # Patch kita (timeout 90 detik agar mekanisme Keep-Alive 60d MQTT jalan lebih dulu)
    patch_replacement = """# [HOTFIX MIMO]: Increase timeout from 5 to 90 to prevent amqtt from discarding
                # QoS 1 messages during sudden network drops before keep-alive expires.
                app_message.puback_packet = await asyncio.wait_for(waiter, timeout=90)"""
    
    if patch_replacement in content:
        print("✅ Patch sudah terpasang! Tidak perlu diulang.")
        sys.exit(0)
        
    if bug_target not in content:
        # Mungkin amqtt sudah diupdate atau string sedikit berbeda
        if "timeout=60" in content:
             print("✅ Patch (timeout=60) sudah terpasang secara manual sebelumnya.")
             sys.exit(0)
        else:
             print("⚠️  Gagal menemukan target patch. Mungkin versi amqtt berbeda?")
             sys.exit(1)
             
    # Terapkan patch
    new_content = content.replace(bug_target, patch_replacement)
    
    with open(handler_path, "w") as f:
        f.write(new_content)
        
    print(f"🚀 BERHASIL: Patch QoS 1 amqtt diterapkan ke {handler_path}")

if __name__ == "__main__":
    apply_patch()
