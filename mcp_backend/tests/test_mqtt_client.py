import pytest
import asyncio
from unittest.mock import MagicMock, AsyncMock
import json

from mcp_backend.mqtt_client import MQTTBridge

@pytest.fixture
def mock_paho_client(mocker):
    mock_client = mocker.patch("mcp_backend.mqtt_client.mqtt.Client")
    instance = mock_client.return_value
    instance.publish = MagicMock()
    instance.connect_async = MagicMock()
    instance.loop_start = MagicMock()
    return instance

@pytest.mark.asyncio
async def test_publish_command(mock_paho_client):
    bridge = MQTTBridge(broker_url="localhost", port=1883)
    bridge.connect()
    
    device_id = "test_device"
    tool_name = "open_navigation"
    payload = {"destination": "Jakarta", "app": "google_maps"}
    
    bridge.publish_command(device_id, tool_name, payload)
    
    expected_payload = json.dumps({"command": tool_name, "args": payload})
    mock_paho_client.publish.assert_called_once_with(f"device/{device_id}/command", expected_payload)

@pytest.mark.asyncio
async def test_wait_for_ack_success(mock_paho_client):
    bridge = MQTTBridge(broker_url="localhost", port=1883)
    bridge.connect()
    
    device_id = "test_device"
    
    # Simulate waiting for ack in background
    wait_task = asyncio.create_task(bridge.wait_for_ack(device_id, timeout=1.0))
    
    # Simulate receiving a message from MQTT broker
    mock_message = MagicMock()
    mock_message.topic = f"device/{device_id}/ack"
    mock_message.payload = json.dumps({"status": "success", "message": "Command executed"}).encode('utf-8')
    
    # Yield control so wait_task can start waiting
    await asyncio.sleep(0.1)
    
    # Trigger the on_message callback
    bridge._on_message(mock_paho_client, None, mock_message)
    
    result = await wait_task
    assert result["status"] == "success"
    assert result["message"] == "Command executed"

@pytest.mark.asyncio
async def test_wait_for_ack_timeout(mock_paho_client):
    bridge = MQTTBridge(broker_url="localhost", port=1883)
    bridge.connect()
    
    device_id = "test_device"
    
    # Wait for ack with a short timeout, and don't trigger the message callback
    result = await bridge.wait_for_ack(device_id, timeout=0.1)
    
    assert result["status"] == "error"
    assert "timeout" in result["message"].lower()
