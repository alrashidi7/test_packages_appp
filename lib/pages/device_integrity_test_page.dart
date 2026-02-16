import 'package:device_integrity_signature/device_integrity_signature.dart';
import 'package:flutter/material.dart';

class DeviceIntegrityTestPage extends StatefulWidget {
  const DeviceIntegrityTestPage({super.key});

  @override
  State<DeviceIntegrityTestPage> createState() =>
      _DeviceIntegrityTestPageState();
}

class _DeviceIntegrityTestPageState extends State<DeviceIntegrityTestPage> {
  final DeviceIntegritySignature _api = DeviceIntegritySignature();
  DeviceIntegrityReport? _lastReport;
  SecurityException? _lastException;
  bool _isLoading = false;
  bool _throwOnCompromised = true;
  List<String> _logMessages = [];

  @override
  void initState() {
    super.initState();
    _addLog('Page initialized');
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.insert(
          0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logMessages.length > 50) {
        _logMessages.removeLast();
      }
    });
  }

  Future<void> _getReport({bool? throwOnCompromised}) async {
    setState(() {
      _isLoading = true;
      _lastReport = null;
      _lastException = null;
    });
    _addLog('Requesting report (throwOnCompromised: ${throwOnCompromised ?? _throwOnCompromised})...');

    try {
      final report = await _api.getReport(
        throwOnCompromised: throwOnCompromised ?? _throwOnCompromised,
      );

      setState(() {
        _lastReport = report;
        _isLoading = false;
      });
      _addLog('Report received successfully');
      _addLog('Signature: ${report.signature.substring(0, 20)}...');
      _addLog('Is Compromised: ${report.isCompromised}');
    } on SecurityException catch (e) {
      setState(() {
        _lastException = e;
        _isLoading = false;
      });
      _addLog('SecurityException: ${e.reason}');
      if (e.message != null) {
        _addLog('Message: ${e.message}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _addLog('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Integrity Signature Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Settings Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Throw on Compromised'),
                      subtitle: const Text(
                        'If enabled, throws SecurityException when device is compromised',
                      ),
                      value: _throwOnCompromised,
                      onChanged: (value) {
                        setState(() {
                          _throwOnCompromised = value;
                        });
                        _addLog('Throw on compromised: $value');
                      },
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
                  onPressed: _isLoading
                      ? null
                      : () => _getReport(throwOnCompromised: true),
                  icon: const Icon(Icons.security),
                  label: const Text('Get Report (Throw)'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _getReport(throwOnCompromised: false),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Get Report (No Throw)'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _getReport(throwOnCompromised: _throwOnCompromised),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Get Report (Settings)'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading Indicator
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),

            // Security Exception Card
            if (_lastException != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Security Exception',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Reason', _lastException!.reason),
                      if (_lastException!.message != null)
                        _buildInfoRow(
                          'Message',
                          _lastException!.message!,
                        ),
                    ],
                  ),
                ),
              ),

            // Report Card
            if (_lastReport != null)
              Card(
                color: _lastReport!.isCompromised
                    ? Colors.orange[50]
                    : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastReport!.isCompromised
                                ? Icons.warning
                                : Icons.check_circle,
                            color: _lastReport!.isCompromised
                                ? Colors.orange[700]
                                : Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastReport!.isCompromised
                                ? 'Device Compromised'
                                : 'Device Secure',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _lastReport!.isCompromised
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Signature', _lastReport!.signature),
                      _buildInfoRow(
                        'Is Compromised',
                        _lastReport!.isCompromised.toString(),
                      ),
                      if (_lastReport!.metadata.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Metadata',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._lastReport!.metadata.entries.map(
                          (entry) => _buildInfoRow(
                            entry.key,
                            entry.value.toString(),
                          ),
                        ),
                      ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
