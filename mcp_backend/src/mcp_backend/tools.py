from typing import Optional, Literal
from pydantic import BaseModel, Field

# Using Pydantic models for explicit schema definition is standard for MCP SDK

def open_navigation(
    destination: str = Field(description="Destinasi tujuan navigasi"),
    app: Literal["google_maps", "waze", "here"] = Field(default="google_maps", description="Aplikasi navigasi yang digunakan")
) -> dict:
    """Buka navigasi ke destinasi menggunakan aplikasi pilihan."""
    return {"destination": destination, "app": app}

def open_music(
    app: Literal["spotify", "youtube_music", "default"] = Field(description="Aplikasi musik"),
    action: Literal["play_playlist", "play_song", "play_artist"] = Field(description="Aksi pemutaran"),
    query: str = Field(description="Nama lagu, artis, atau playlist")
) -> dict:
    """Buka app musik dan mulai pemutaran via deep link / URI scheme."""
    return {"app": app, "action": action, "query": query}

def open_youtube(
    query: str = Field(description="Kata kunci pencarian video")
) -> dict:
    """Buka aplikasi YouTube dan cari video."""
    return {"query": query}

def play_local_media(
    query: str = Field(description="Kata kunci pencarian judul atau artis untuk file media lokal")
) -> dict:
    """Putar file musik atau video lokal yang ada di memori headunit."""
    return {"query": query}

def open_app(
    package_name: str = Field(description="Package name aplikasi Android"),
    uri: Optional[str] = Field(default=None, description="URI scheme opsional"),
    extra: Optional[dict] = Field(default=None, description="Extra intent data")
) -> dict:
    """Generic app launcher berdasarkan package name."""
    return {"package_name": package_name, "uri": uri, "extra": extra}

def phone_call(
    number: str = Field(description="Nomor telepon"),
    contact_name: Optional[str] = Field(default=None, description="Nama kontak opsional")
) -> dict:
    """Melakukan panggilan telepon."""
    return {"number": number, "contact_name": contact_name}

def send_message(
    app: Literal["whatsapp", "sms"] = Field(description="Aplikasi pesan"),
    contact: str = Field(description="Nomor atau nama kontak"),
    message: str = Field(description="Isi pesan")
) -> dict:
    """Kirim pesan via WhatsApp atau SMS."""
    return {"app": app, "contact": contact, "message": message}

def get_headunit_status() -> dict:
    """Cek status koneksi internet headunit, daftar app terinstall, dan versi OS."""
    return {}

def search_contact(
    query: str = Field(description="Nama kontak yang ingin dicari, bisa berupa sebagian nama (wildcard)")
) -> dict:
    """Cari kontak di phonebook berdasarkan nama. Mengembalikan nama dan daftar nomor telepon."""
    return {"query": query}
