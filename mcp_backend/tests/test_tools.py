from pydantic import BaseModel
import inspect

from mcp_backend import tools

def test_tool_open_navigation_exists():
    assert hasattr(tools, "open_navigation")
    sig = inspect.signature(tools.open_navigation)
    assert "destination" in sig.parameters
    assert "app" in sig.parameters

def test_tool_open_music_exists():
    assert hasattr(tools, "open_music")
    sig = inspect.signature(tools.open_music)
    assert "app" in sig.parameters
    assert "action" in sig.parameters
    assert "query" in sig.parameters

def test_tool_open_youtube_exists():
    assert hasattr(tools, "open_youtube")
    sig = inspect.signature(tools.open_youtube)
    assert "query" in sig.parameters

def test_tool_play_local_media_exists():
    assert hasattr(tools, "play_local_media")
    sig = inspect.signature(tools.play_local_media)
    assert "query" in sig.parameters

def test_tool_search_local_media_exists():
    assert hasattr(tools, "search_local_media")
    sig = inspect.signature(tools.search_local_media)
    assert "keywords" in sig.parameters

def test_tool_open_app_exists():
    assert hasattr(tools, "open_app")
    sig = inspect.signature(tools.open_app)
    assert "package_name" in sig.parameters
    assert "uri" in sig.parameters
    assert "extra" in sig.parameters

def test_tool_phone_call_exists():
    assert hasattr(tools, "phone_call")
    sig = inspect.signature(tools.phone_call)
    assert "number" in sig.parameters
    assert "contact_name" in sig.parameters

def test_tool_send_message_exists():
    assert hasattr(tools, "send_message")
    sig = inspect.signature(tools.send_message)
    assert "app" in sig.parameters
    assert "contact" in sig.parameters
    assert "message" in sig.parameters

def test_tool_get_headunit_status_exists():
    assert hasattr(tools, "get_headunit_status")
