import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'intent_service.dart';
import 'contact_service.dart';

class MQTTService {
  final IntentService intentService;
  final ContactService contactService;
  MqttServerClient? _client;

  MQTTService({required this.intentService, required this.contactService});

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
      
      if (kDebugMode) {
        importFlutterForegroundTaskAndSend(command, args, success);
      }

      if (success) {
        if (command == 'get_headunit_status') {
          return {
            'status': 'success',
            'message': 'Executed $command successfully',
            'data': {
              'connection': 'online (connected to MQTT)',
              'os': Platform.operatingSystem,
              'os_version': Platform.operatingSystemVersion,
            }
          };
        } else if (command == 'search_contact') {
          final query = args['query']?.toString() ?? '';
          try {
            final contacts = await contactService.searchContacts(query);
            return {
              'status': 'success',
              'message': 'Found ${contacts.length} contacts matching "$query"',
              'data': contacts
            };
          } catch (e) {
            return {'status': 'error', 'message': e.toString()};
          }
        }
        return {'status': 'success', 'message': 'Executed $command successfully'};
      } else {
        return {'status': 'error', 'message': 'Failed to execute $command'};
      }
    } catch (e) {
      debugPrint('Error parsing MQTT payload: $e');
      return {'status': 'error', 'message': 'Invalid payload format: $e'};
    }
  }

  void importFlutterForegroundTaskAndSend(String command, Map<String, dynamic> args, bool success) {
    try {
      final data = jsonEncode({
        'type': 'mqtt_tool_log',
        'tool': command,
        'args': args,
        'success': success,
      });
      FlutterForegroundTask.sendDataToMain(data);
    } catch (_) {}
  }

  Future<bool> connect(String broker, String deviceId) async {
    _client = MqttServerClient(broker, 'flutter_mimo_$deviceId');
    _client!.port = 1883;
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    _client!.logging(on: true); // <--- Mengaktifkan log debug internal MQTT
    _client!.setProtocolV311(); // <--- Paksa gunakan protokol MQTT 3.1.1 (bukan MQIsdp/3.1)

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_mimo_$deviceId')
        .withWillTopic('device/$deviceId/status')
        .withWillMessage('{"status": "offline"}')
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain();
        
    _client!.connectionMessage = connMessage;
    // PENTING: Jangan memanggil .startClean() di sini.
    // Jika tidak clean_session, maka broker MQTT akan menyimpan (queue) 
    // pesan QoS 1 yang masuk saat Headunit sedang offline.

    _client!.onConnected = () {
      debugPrint('MQTT Client connected.');
      FlutterForegroundTask.updateService(
        notificationTitle: '✅ Car Companion Active',
        notificationText: 'Device: $deviceId • Connected',
      );
      _publishOnlineStatusAndSubscribe(deviceId);
    };

    _client!.onAutoReconnected = () {
      debugPrint('MQTT Client auto-reconnected.');
      FlutterForegroundTask.updateService(
        notificationTitle: '✅ Car Companion Active',
        notificationText: 'Device: $deviceId • Connected',
      );
      _publishOnlineStatusAndSubscribe(deviceId);
    };
    
    _client!.onDisconnected = () {
      debugPrint('MQTT Client disconnected.');
      FlutterForegroundTask.updateService(
        notificationTitle: '⚠️ Car Companion Offline',
        notificationText: 'Device: $deviceId • Disconnected',
      );
    };

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

      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) async {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        final commandTopic = 'device/$deviceId/command';
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

  void _publishOnlineStatusAndSubscribe(String deviceId) {
    if (_client == null || _client!.connectionStatus!.state != MqttConnectionState.connected) return;
    
    // Publish online status
    final builder = MqttClientPayloadBuilder();
    builder.addString('{"status": "online"}');
    _client!.publishMessage('device/$deviceId/status', MqttQos.atLeastOnce, builder.payload!, retain: true);

    // Subscribe to command topic
    _client!.subscribe('device/$deviceId/command', MqttQos.atLeastOnce);
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
