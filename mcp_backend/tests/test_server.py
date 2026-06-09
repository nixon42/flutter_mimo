import pytest
import asyncio
from unittest.mock import MagicMock, AsyncMock

from mcp_backend.server import mcp, mqtt_bridge, _process_tool_call

def test_mcp_server_has_correct_name():
    assert mcp.name == "RobotCarCompanion"

@pytest.mark.asyncio
async def test_process_tool_call_success(mocker):
    # Mock the MQTT bridge methods
    mocker.patch.object(mqtt_bridge, 'publish_command')
    
    # Mock wait_for_ack to return a successful response
    mock_wait = AsyncMock(return_value={"status": "success", "message": "OK"})
    mocker.patch.object(mqtt_bridge, 'wait_for_ack', side_effect=mock_wait)
    
    # Call our internal helper
    payload = {"destination": "Jakarta", "app": "google_maps"}
    result = await _process_tool_call("open_navigation", payload)
    
    # Verify publish_command was called
    mqtt_bridge.publish_command.assert_called_once()
    args, kwargs = mqtt_bridge.publish_command.call_args
    assert args[1] == "open_navigation"
    assert args[2] == payload
    
    # Verify wait_for_ack was called
    mqtt_bridge.wait_for_ack.assert_called_once()
    
    # Verify result
    assert result == "OK"

@pytest.mark.asyncio
async def test_process_tool_call_error(mocker):
    mocker.patch.object(mqtt_bridge, 'publish_command')
    
    # Mock wait_for_ack to return an error response
    mock_wait = AsyncMock(return_value={"status": "error", "message": "Headunit timeout"})
    mocker.patch.object(mqtt_bridge, 'wait_for_ack', side_effect=mock_wait)
    
    result = await _process_tool_call("open_navigation", {})
    
    assert "Error:" in result
    assert "Headunit timeout" in result
