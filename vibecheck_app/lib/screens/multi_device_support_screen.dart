import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:network_info_plus/network_info_plus.dart';

class MultiDeviceSupportScreen extends StatefulWidget {
  const MultiDeviceSupportScreen({super.key});

  @override
  State<MultiDeviceSupportScreen> createState() =>
      _MultiDeviceSupportScreenState();
}

class _MultiDeviceSupportScreenState extends State<MultiDeviceSupportScreen> {
  String deviceName = 'Unknown Device';
  String ipAddress = 'Unavailable';
  String lastActiveTime = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final now = DateTime.now();
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

    String detectedDeviceName = 'Unknown Device';
    String detectedIp = 'Unavailable';

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        detectedDeviceName =
            '${webInfo.browserName.name.toUpperCase()} Web';
        detectedIp = 'Unavailable on Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        detectedDeviceName =
            '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        detectedDeviceName =
            '${iosInfo.name} (${iosInfo.model})';
      } else if (Platform.isWindows) {
        detectedDeviceName = 'Windows PC';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        detectedDeviceName = macInfo.model;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        detectedDeviceName = linuxInfo.prettyName;
      }

      if (!kIsWeb) {
        try {
          final info = NetworkInfo();
          final wifiIp = await info.getWifiIP();
          if (wifiIp != null && wifiIp.isNotEmpty) {
            detectedIp = wifiIp;
          }
        } catch (_) {
          detectedIp = 'Unavailable';
        }
      }

      if (!mounted) return;

      setState(() {
        deviceName = detectedDeviceName;
        ipAddress = detectedIp;
        lastActiveTime = formattedTime;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        deviceName = 'Unknown Device';
        ipAddress = kIsWeb ? 'Unavailable on Web' : 'Unavailable';
        lastActiveTime = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE9FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const SizedBox(
                            width: 40,
                            child: Icon(
                              Icons.arrow_back,
                              size: 24,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Multi-device Support',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'My Devices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'IP Address: $ipAddress',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7F8794),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Last Active Time: $lastActiveTime',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7F8794),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 22),
                            child: Text(
                              'Current Device',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Supported Devices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: _SupportedDeviceItem(
                              icon: Icons.apple,
                              label: 'iOS Mobile',
                            ),
                          ),
                          Expanded(
                            child: _SupportedDeviceItem(
                              icon: Icons.android,
                              label: 'Android Mobile',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportedDeviceItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SupportedDeviceItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 30,
          color: Colors.black87,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8794),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}