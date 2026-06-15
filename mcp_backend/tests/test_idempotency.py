import paho.mqtt.client as mqtt
import json
import time

BROKER_URL = "192.168.10.7"
DEVICE_ID = "default_device"

def run_test():
    print(f"🚀 Memulai Uji Coba Idempotency (TC-09) ke {BROKER_URL}...")
    
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="tester_tc09")
    try:
        client.connect(BROKER_URL, 1883, 60)
        client.loop_start() # Jalankan network loop di background
    except Exception as e:
        print(f"❌ Gagal terhubung ke MQTT Broker: {e}")
        return

    topic = f"device/{DEVICE_ID}/command"
    
    # 1. Siapkan payload dengan request_id statis/duplikat
    payload = {
        "request_id": "TEST_IDEMPOTENCY_001",
        "command": "search_contact",
        "args": {"query": "Surya"}
    }
    json_payload = json.dumps(payload)
    
    # 2. Kirim pesan pertama
    print("\n[1/2] 📡 Mengirim perintah PERTAMA...")
    info1 = client.publish(topic, json_payload, qos=1)
    info1.wait_for_publish()
    print("      Berhasil terkirim. Menunggu 1 detik...")
    
    time.sleep(1)
    
    # 3. Kirim pesan kedua (Duplikat identik)
    print("\n[2/2] 📡 Mengirim perintah KEDUA (Duplikat) dengan request_id yang sama...")
    info2 = client.publish(topic, json_payload, qos=1)
    info2.wait_for_publish()
    print("      Berhasil terkirim.")
    
    print("\n✅ Pengujian selesai!")
    print("👉 Silakan cek Debug Tools Log di layar Mimo App Anda.")
    print("👉 Mimo App seharusnya HANYA MENGEKSEKUSI PENCARIAN 1 KALI.")
    print("👉 Untuk perintah kedua, Anda akan melihat pesan: 'Duplicate request detected' di console/log.")
    
    time.sleep(1)
    client.loop_stop()
    client.disconnect()

if __name__ == "__main__":
    run_test()
