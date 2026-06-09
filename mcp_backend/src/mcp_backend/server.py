import os
import asyncio
from typing import Optional, Literal
from pydantic import Field

from mcp.server.fastmcp import FastMCP
from mcp_backend.mqtt_client import MQTTBridge
from mcp_backend import tools

# Initialize FastMCP Server
mcp = FastMCP("RobotCarCompanion")

# Initialize MQTT Bridge
MQTT_BROKER = os.environ.get("MQTT_BROKER", "localhost")
MQTT_PORT = int(os.environ.get("MQTT_PORT", 1883))
DEVICE_ID = os.environ.get("DEVICE_ID", "default_device")

mqtt_bridge = MQTTBridge(broker_url=MQTT_BROKER, port=MQTT_PORT)

# Helper function to process tool call
async def _process_tool_call(tool_name: str, payload: dict) -> str:
    """Publishes command to MQTT and waits for acknowledgement."""
    # Ensure MQTT is connected
    if not mqtt_bridge.client.is_connected():
        try:
            mqtt_bridge.connect()
        except Exception:
            # Let it try to publish anyway, or fail
            pass
            
    mqtt_bridge.publish_command(DEVICE_ID, tool_name, payload)
    
    # Wait for ack (max 10 seconds per FSD)
    ack_response = await mqtt_bridge.wait_for_ack(DEVICE_ID, timeout=10.0)
    
    if ack_response.get("status") == "success":
        return ack_response.get("message", "Success")
    else:
        # Return error message
        return f"Error: {ack_response.get('message', 'Unknown error')}"

# Register Tools
@mcp.tool()
async def open_navigation(
    destination: str = Field(description="Destinasi tujuan navigasi"),
    app: Literal["google_maps", "waze", "here"] = Field(default="google_maps", description="Aplikasi navigasi yang digunakan")
) -> str:
    """Buka navigasi ke destinasi menggunakan aplikasi pilihan."""
    payload = tools.open_navigation(destination=destination, app=app)
    return await _process_tool_call("open_navigation", payload)

@mcp.tool()
async def open_music(
    app: Literal["spotify", "youtube_music", "default"] = Field(description="Aplikasi musik"),
    action: Literal["play_playlist", "play_song", "play_artist"] = Field(description="Aksi pemutaran"),
    query: str = Field(description="Nama lagu, artis, atau playlist")
) -> str:
    """Buka app musik dan mulai pemutaran via deep link / URI scheme."""
    payload = tools.open_music(app=app, action=action, query=query)
    return await _process_tool_call("open_music", payload)

@mcp.tool()
async def open_app(
    package_name: str = Field(description="Package name aplikasi Android"),
    uri: Optional[str] = Field(default=None, description="URI scheme opsional"),
    extra: Optional[dict] = Field(default=None, description="Extra intent data")
) -> str:
    """Generic app launcher berdasarkan package name."""
    payload = tools.open_app(package_name=package_name, uri=uri, extra=extra)
    return await _process_tool_call("open_app", payload)

@mcp.tool()
async def phone_call(
    number: str = Field(description="Nomor telepon"),
    contact_name: Optional[str] = Field(default=None, description="Nama kontak opsional")
) -> str:
    """Melakukan panggilan telepon."""
    payload = tools.phone_call(number=number, contact_name=contact_name)
    return await _process_tool_call("phone_call", payload)

@mcp.tool()
async def send_message(
    app: Literal["whatsapp", "sms"] = Field(description="Aplikasi pesan"),
    contact: str = Field(description="Nomor atau nama kontak"),
    message: str = Field(description="Isi pesan")
) -> str:
    """Kirim pesan via WhatsApp atau SMS."""
    payload = tools.send_message(app=app, contact=contact, message=message)
    return await _process_tool_call("send_message", payload)

@mcp.tool()
async def get_headunit_status() -> str:
    """Cek status koneksi internet headunit, daftar app terinstall, dan versi OS."""
    payload = tools.get_headunit_status()
    return await _process_tool_call("get_headunit_status", payload)

def main():
    # Attempt to connect to MQTT broker before starting server
    try:
        mqtt_bridge.connect()
    except Exception as e:
        import logging
        logging.error(f"Failed to connect to MQTT on startup: {e}")
        
    mcp.run()

if __name__ == "__main__":
    main()
