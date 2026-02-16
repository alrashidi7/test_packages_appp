import 'package:biometric_face_vault/biometric_face_vault.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class BiometricTestPage extends StatefulWidget {
  const BiometricTestPage({super.key});

  @override
  State<BiometricTestPage> createState() => _BiometricTestPageState();
}

class _BiometricTestPageState extends State<BiometricTestPage> {
  FaceAuthService? _authService;
  bool _isInitialized = false;
  bool _isStreaming = false;
  String _status = 'Not initialized';
  String _lastResult = '';
  List<String> _logMessages = [];
  FaceCameraController? _faceCameraController;

  @override
  void initState() {
    super.initState();
    _addLog('Page initialized');
  }

  @override
  void dispose() {
    _stopStreaming();
    _authService?.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logMessages.length > 50) {
        _logMessages.removeLast();
      }
    });
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _status = 'Initializing...';
      });
      _addLog('Starting initialization...');

      _authService = FaceAuthService();
      await _authService!.initialize();

      setState(() {
        _isInitialized = true;
        _status = 'Initialized successfully';
        _faceCameraController = _authService!.cameraController;
      });
      _addLog('Initialization successful');
    } on ModelLoadException catch (e) {
      setState(() {
        _status = 'Model load failed: $e';
      });
      _addLog('ModelLoadException: $e');
    } catch (e) {
      setState(() {
        _status = 'Initialization error: $e';
      });
      _addLog('Error: $e');
    }
  }

  Future<void> _startVerificationStream() async {
    if (!_isInitialized || _authService == null) {
      _addLog('Please initialize first');
      return;
    }

    try {
      setState(() {
        _isStreaming = true;
        _status = 'Streaming started...';
      });
      _addLog('Starting verification stream...');

      _authService!.startVerificationStream(
        onResult: (result) {
          setState(() {
            switch (result) {
              case FaceAuthSuccess():
                _status = 'Success!';
                _lastResult = 'Signature: ${result.signature}\n'
                    'Public Key: ${result.publicKey}\n'
                    'Payload: ${result.payloadBase64}';
                _addLog('FaceAuthSuccess - Signature received');
                break;
              case FaceAuthFailure():
                _status = 'Failed: ${result.code}';
                _lastResult = 'Error Code: ${result.code}\n'
                    'Message: ${result.message}';
                _addLog('FaceAuthFailure: ${result.code} - ${result.message}');
                break;
            }
          });
        },
        postToBackend: false,
      );

      _addLog('Verification stream active');
    } catch (e) {
      setState(() {
        _status = 'Stream error: $e';
      });
      _addLog('Stream error: $e');
    }
  }

  void _stopStreaming() {
    if (_isStreaming && _authService != null) {
      try {
        _authService!.stopVerificationStream();
        setState(() {
          _isStreaming = false;
          _status = 'Stream stopped';
        });
        _addLog('Verification stream stopped');
      } catch (e) {
        _addLog('Error stopping stream: $e');
      }
    }
  }

  Future<void> _testManualVerification() async {
    if (!_isInitialized || _authService == null) {
      _addLog('Please initialize first');
      return;
    }

    try {
      setState(() {
        _status = 'Manual verification in progress...';
      });
      _addLog('Starting manual verification...');

      // Note: This requires camera image, so we'll use the camera controller
      if (_faceCameraController != null) {
        _faceCameraController!.startStream((cameraImage, inputImage) async {
          final result = await _authService!.verifyIdentityFromCameraImage(
            image: cameraImage,
            postToBackend: false,
          );

          setState(() {
            switch (result) {
              case FaceAuthSuccess():
                _status = 'Manual verification success!';
                _lastResult = 'Signature: ${result.signature}\n'
                    'Public Key: ${result.publicKey}\n'
                    'Payload: ${result.payloadBase64}';
                break;
              case FaceAuthFailure():
                _status = 'Manual verification failed';
                _lastResult = 'Error Code: ${result.code}\n'
                    'Message: ${result.message}';
                break;
            }
          });
          _addLog('Manual verification completed');
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Manual verification error: $e';
      });
      _addLog('Manual verification error: $e');
    }
  }

  Future<void> _testWithBackend() async {
    if (!_isInitialized || _authService == null) {
      _addLog('Please initialize first');
      return;
    }

    // Show dialog to get backend URL
    final urlController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://api.example.com',
            labelText: 'Backend Base URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, urlController.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        _addLog('Creating service with backend: $result');
        _authService = FaceAuthService(
          backendService: BackendService(baseUrl: result),
        );
        await _authService!.initialize();
        setState(() {
          _isInitialized = true;
          _faceCameraController = _authService!.cameraController;
        });
        _addLog('Backend service configured');
      } catch (e) {
        _addLog('Backend setup error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Face Vault Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _isInitialized ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isStreaming)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Streaming active'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isInitialized ? null : _initialize,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Initialize'),
                ),
                ElevatedButton.icon(
                  onPressed: _isInitialized && !_isStreaming
                      ? _startVerificationStream
                      : null,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Start Stream'),
                ),
                ElevatedButton.icon(
                  onPressed: _isStreaming ? _stopStreaming : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Stream'),
                ),
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _testManualVerification : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Manual Verify'),
                ),
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _testWithBackend : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Test Backend'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Camera Preview
            if (_faceCameraController != null && 
                _isInitialized && 
                _faceCameraController!.cameraController != null &&
                _faceCameraController!.cameraController!.value.isInitialized)
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 300,
                  child: CameraPreview(_faceCameraController!.cameraController!),
                ),
              ),
            const SizedBox(height: 16),

            // Results Card
            if (_lastResult.isNotEmpty)
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Result',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _lastResult,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Log Card
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _logMessages.clear();
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _logMessages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logMessages[index],
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
