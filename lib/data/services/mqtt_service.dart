import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'intent_service.dart';
import 'contact_service.dart';

class MQTTService {
  final IntentService intentService;
  final ContactService contactService;
  MqttServerClient? _client;
  final Set<String> _processedRequestIds = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  MQTTService({required this.intentService, required this.contactService});

  /// Handles incoming JSON string, executes the intent, and returns the result dictionary
  Future<Map<String, dynamic>> handleIncomingCommand(String payload) async {
    try {
      final data = jsonDecode(payload);
      final command = data['command_type']?.toString() ?? '';
      final args = data['parameters'] as Map<String, dynamic>? ?? {};

      if (command.isEmpty) {
        return {'status': 'error', 'message': 'Missing command name'};
      }

      final requestId = data['request_id']?.toString() ?? '';
      if (requestId.isNotEmpty) {
        if (_processedRequestIds.contains(requestId)) {
          debugPrint('Duplicate request detected: $requestId. Skipping execution.');
          return {'status': 'success', 'message': 'Duplicate request ignored.'};
        }
        _processedRequestIds.add(requestId);
        if (_processedRequestIds.length > 100) {
          _processedRequestIds.remove(_processedRequestIds.first);
        }
      }

      debugPrint('Executing tool call via MQTT: $command with args $args');
      
      final errorMsg = await intentService.executeTool(command, args);
      final success = errorMsg == null;
      
      importFlutterForegroundTaskAndSend(command, args, success);

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
        return {'status': 'error', 'message': errorMsg};
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
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        debugPrint('Hardware network dropped (No Internet/Wi-Fi).');
        FlutterForegroundTask.updateService(
          notificationTitle: '⚠️ Car Companion Offline',
          notificationText: 'Tidak ada koneksi. Mohon nyalakan USB Tethering.',
        );
      }
    });

    _client = MqttServerClient(broker, 'headunit-$deviceId');
    _client!.port = 1883;
    _client!.keepAlivePeriod = 60; // Dikembalikan ke 60 (standar stabil)
    _client!.autoReconnect = true;
    _client!.logging(on: true); // <--- Mengaktifkan log debug internal MQTT
    _client!.setProtocolV311(); // <--- Paksa gunakan protokol MQTT 3.1.1 (bukan MQIsdp/3.1)

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('headunit-$deviceId')
        .withWillTopic('car/$deviceId/lwt')
        .withWillMessage('{"status": "offline", "timestamp": "${DateTime.now().toIso8601String()}"}')
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
        notificationText: 'Tidak ada koneksi. Mohon nyalakan USB Tethering.',
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

        final commandTopic = 'car/$deviceId/cmd';
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
    builder.addString('{"status": "online", "os_version": "${Platform.operatingSystemVersion}", "timestamp": "${DateTime.now().toIso8601String()}"}');
    _client!.publishMessage('car/$deviceId/status', MqttQos.atLeastOnce, builder.payload!, retain: true);

    // Subscribe to command topic
    _client!.subscribe('car/$deviceId/cmd', MqttQos.atLeastOnce);
  }

  void _publishAck(String deviceId, Map<String, dynamic> payload) {
    if (_client == null || _client!.connectionStatus!.state != MqttConnectionState.connected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    
    final ackTopic = 'car/$deviceId/ack';
    debugPrint('Publishing ACK to $ackTopic: $payload');
    _client!.publishMessage(ackTopic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _connectivitySubscription?.cancel();
    _client?.disconnect();
  }
}
