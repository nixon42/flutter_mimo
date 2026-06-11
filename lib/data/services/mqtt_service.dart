import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'intent_service.dart';

class MQTTService {
  final IntentService intentService;
  MqttServerClient? _client;

  MQTTService({required this.intentService});

  /// Handles incoming JSON string, executes the intent, and returns the result dictionary
  Future<Map<String, dynamic>> handleIncomingCommand(String payload) async {
    try {
      final data = jsonDecode(payload);
      final command = data['command']?.toString() ?? '';
      final args = data['args'] as Map<String, dynamic>? ?? {};

      if (command.isEmpty) {
        return {'status': 'error', 'message': 'Missing command name'};
      }

      debugPrint('Executing tool call via MQTT: $command with args $args');
      
      final success = await intentService.executeTool(command, args);
      
      if (success) {
        return {'status': 'success', 'message': 'Executed $command successfully'};
      } else {
        return {'status': 'error', 'message': 'Failed to execute $command'};
      }
    } catch (e) {
      debugPrint('Error parsing MQTT payload: $e');
      return {'status': 'error', 'message': 'Invalid payload format: $e'};
    }
  }

  Future<bool> connect(String broker, String deviceId) async {
    _client = MqttServerClient(broker, 'flutter_mimo_$deviceId');
    _client!.port = 1883;
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    _client!.logging(on: true); // <--- Mengaktifkan log debug internal MQTT

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_mimo_$deviceId')
        .withWillTopic('device/$deviceId/status')
        .withWillMessage('{"status": "offline"}')
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain()
        .startClean();
    _client!.connectionMessage = connMessage;

    bool connected = false;
    while (!connected) {
      try {
        final status = await _client!.connect();
        if (status?.state == MqttConnectionState.connected) {
          connected = true;
        } else {
          debugPrint('MQTT Client connection failed, status is ${status?.state}. Retrying in 5s...');
          _client!.disconnect();
          await Future.delayed(const Duration(seconds: 5));
        }
      } catch (e) {
        debugPrint('Exception connecting to MQTT broker: $e. Retrying in 5s...');
        _client!.disconnect();
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('Connected to MQTT Broker: $broker');

      // Publish online status
      final builder = MqttClientPayloadBuilder();
      builder.addString('{"status": "online"}');
      _client!.publishMessage('device/$deviceId/status', MqttQos.atLeastOnce, builder.payload!, retain: true);

      // Subscribe to command topic
      final commandTopic = 'device/$deviceId/command';
      _client!.subscribe(commandTopic, MqttQos.atLeastOnce);

      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) async {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        if (c[0].topic == commandTopic) {
          final ackPayload = await handleIncomingCommand(payload);
          _publishAck(deviceId, ackPayload);
        }
      });

      return true;
    } else {
      debugPrint('MQTT Client connection failed - disconnecting, status is ${_client!.connectionStatus}');
      _client!.disconnect();
      return false;
    }
  }

  void _publishAck(String deviceId, Map<String, dynamic> payload) {
    if (_client == null || _client!.connectionStatus!.state != MqttConnectionState.connected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    
    final ackTopic = 'device/$deviceId/ack';
    debugPrint('Publishing ACK to $ackTopic: $payload');
    _client!.publishMessage(ackTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _client?.disconnect();
  }
}
