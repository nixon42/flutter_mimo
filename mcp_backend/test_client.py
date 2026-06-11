import asyncio
import os
import sys
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def run_test():
    print("🚀 Memulai simulasi LLM memanggil MCP Server...")
    
    # Path ke file server MCP
    server_script = os.path.join(os.path.dirname(__file__), "src", "mcp_backend", "server.py")
    
    # Konfigurasi parameter server stdio
    # Kita menambahkan 'src' ke PYTHONPATH agar module 'mcp_backend' bisa di-import
    env = os.environ.copy()
    env["PYTHONPATH"] = os.path.join(os.path.dirname(__file__), "src")

    server_params = StdioServerParameters(
        command=sys.executable,
        args=["-m", "mcp_backend.server"],
        env=env
    )
    
    print(f"🔄 Menjalankan server melalui stdio: {server_params.command} {server_params.args}")
    
    try:
        async with stdio_client(server_params) as (read, write):
            async with ClientSession(read, write) as session:
                # Inisialisasi koneksi dengan server
                print("✅ Terhubung ke MCP Server via stdio.")
                await session.initialize()
                
                # 1. List semua tools yang tersedia
                print("\n📋 Mengambil daftar tools yang didukung oleh server...")
                tools = await session.list_tools()
                for tool in tools.tools:
                    print(f"   - {tool.name}: {tool.description}")
                
                # 2. Simulasi pemanggilan tool (Tool Call)
                tool_name = "open_navigation"
                tool_args = {
                    "destination": "Monas, Jakarta",
                    "app": "google_maps"
                }
                
                # Beri waktu 5 detik agar aplikasi Android (MQTT client) bisa menyadari 
                # broker baru menyala dan melakukan auto-reconnect.
                print("\n⏳ Menunggu 5 detik agar aplikasi Flutter di HP bisa auto-reconnect ke broker...")
                await asyncio.sleep(5)
                
                print(f"\n🤖 LLM mengeksekusi tool: '{tool_name}' dengan argumen: {tool_args}")
                
                # CATATAN: Panggilan ini mungkin memakan waktu hingga 10 detik menunggu ACK dari MQTT
                # Jika tidak ada MQTT broker / Headunit yang terkoneksi, akan timeout (sesuai FSD)
                try:
                    result = await session.call_tool(tool_name, tool_args)
                    print(f"\n🎯 Hasil dari Tool Call:")
                    is_queued = False
                    for content in result.content:
                        print(f"   > {content.text}")
                        if "queued" in content.text:
                            is_queued = True
                            
                    if is_queued:
                        print("\n⏳ Tool mengembalikan status 'queued' karena HP sedang offline!")
                        print("👉 Script akan tetap menyala selama 60 detik.")
                        print("👉 Silakan NYALAKAN APLIKASI FLUTTER sekarang untuk mengecek apakah antrean masuk!")
                        
                        # Hitung mundur 60 detik (tampilkan setiap 10 detik agar tidak membosankan)
                        for i in range(60, 0, -10):
                            print(f"   [Sisa waktu tunggu: {i} detik...]")
                            await asyncio.sleep(10)
                        
                        print("\n⏰ Waktu tunggu simulasi habis.")
                        
                except Exception as e:
                    print(f"\n❌ Tool Call gagal (mungkin karena MQTT Timeout): {e}")
                    
    except Exception as e:
        print(f"❌ Terjadi kesalahan saat mencoba terhubung ke server: {e}")

if __name__ == "__main__":
    asyncio.run(run_test())
