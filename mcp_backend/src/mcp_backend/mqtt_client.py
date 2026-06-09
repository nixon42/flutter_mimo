import paho.mqtt.client as mqtt
import json
import asyncio
import uuid
import logging

logger = logging.getLogger(__name__)

class MQTTBridge:
    def __init__(self, broker_url: str = "localhost", port: int = 1883):
        self.broker_url = broker_url
        self.port = port
        self.client_id = f"mcp_server_{uuid.uuid4().hex[:8]}"
        self.client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=self.client_id)
        
        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message
        
        # Dictionary to keep track of pending futures for acknowledgements
        # Format: {"device_id": asyncio.Future}
        self.pending_acks = {}
        
    def connect(self):
        """Connects to the MQTT broker and starts the network loop."""
        try:
            self.client.connect(self.broker_url, self.port, 60)
            self.client.loop_start()
        except Exception as e:
            logger.error(f"Failed to connect to MQTT broker: {e}")
            raise
            
    def disconnect(self):
        """Disconnects from the MQTT broker."""
        self.client.loop_stop()
        self.client.disconnect()
        
    def _on_connect(self, client, userdata, flags, rc, properties=None):
        logger.info(f"Connected to MQTT broker with result code {rc}")
        # Note: We should probably subscribe to all acks here, or dynamically when waiting
        # Subscribing to wildcard for all devices ack: device/+/ack
        self.client.subscribe("device/+/ack")
        
    def _on_message(self, client, userdata, msg):
        topic = msg.topic
        try:
            payload = json.loads(msg.payload.decode('utf-8'))
            logger.debug(f"Received message on {topic}: {payload}")
            
            # Extract device_id from topic (format: device/{device_id}/ack)
            parts = topic.split('/')
            if len(parts) >= 3 and parts[0] == "device" and parts[2] == "ack":
                device_id = parts[1]
                
                # If there's a pending future for this device, resolve it
                if device_id in self.pending_acks:
                    future = self.pending_acks[device_id]
                    if not future.done():
                        # Use call_soon_threadsafe because paho-mqtt runs in a separate thread
                        loop = future.get_loop()
                        loop.call_soon_threadsafe(future.set_result, payload)
                        
        except json.JSONDecodeError:
            logger.error(f"Failed to decode MQTT message from {topic}")
        except Exception as e:
            logger.error(f"Error handling MQTT message: {e}")

    def publish_command(self, device_id: str, tool_name: str, payload: dict):
        """Publishes a command to the target device's command topic."""
        topic = f"device/{device_id}/command"
        message = {
            "command": tool_name,
            "args": payload
        }
        json_message = json.dumps(message)
        logger.info(f"Publishing to {topic}: {json_message}")
        self.client.publish(topic, json_message)
        
    async def wait_for_ack(self, device_id: str, timeout: float = 10.0) -> dict:
        """
        Waits for an acknowledgement from the target device.
        Returns the parsed JSON payload of the ack, or a timeout error.
        """
        loop = asyncio.get_running_loop()
        future = loop.create_future()
        
        self.pending_acks[device_id] = future
        
        try:
            result = await asyncio.wait_for(future, timeout=timeout)
            return result
        except asyncio.TimeoutError:
            logger.warning(f"Timeout waiting for ack from device {device_id}")
            return {"status": "error", "message": f"Timeout waiting for headunit acknowledgement after {timeout} seconds"}
        finally:
            if device_id in self.pending_acks:
                del self.pending_acks[device_id]
