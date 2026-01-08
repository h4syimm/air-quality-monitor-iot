import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Quality Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF424242)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _mqttServerController = TextEditingController(text: '192.168.171.28');
  final _mqttPortController = TextEditingController(text: '1883');
  final _mqttUsernameController = TextEditingController();
  final _mqttPasswordController = TextEditingController();
  final _aiServerController = TextEditingController(text: '192.168.171.133:5000');
  bool _isConnecting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _mqttServerController.dispose();
    _mqttPortController.dispose();
    _mqttUsernameController.dispose();
    _mqttPasswordController.dispose();
    _aiServerController.dispose();
    super.dispose();
  }

  Future<void> _connectToMqtt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final client = MqttServerClient(_mqttServerController.text, 'flutter_client');
      client.port = int.parse(_mqttPortController.text);
      client.keepAlivePeriod = 20;
      client.logging(on: false);

      final connMess = MqttConnectMessage()
          .withClientIdentifier('flutter_client')
          .keepAliveFor(20)
          .withWillTopic('willtopic')
          .withWillMessage('My Will message')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      if (_mqttUsernameController.text.isNotEmpty && _mqttPasswordController.text.isNotEmpty) {
        connMess.authenticateAs(_mqttUsernameController.text, _mqttPasswordController.text);
      }

      client.connectionMessage = connMess;

      await client.connect();
      client.disconnect();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            mqttServer: _mqttServerController.text,
            mqttPort: int.parse(_mqttPortController.text),
            mqttUsername: _mqttUsernameController.text,
            mqttPassword: _mqttPasswordController.text,
            aiServer: _aiServerController.text,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal koneksi MQTT: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.air, size: 28),
            SizedBox(width: 8),
            Text('Air Quality Monitor'),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.router, color: Colors.blue[300]),
                            const SizedBox(width: 8),
                            const Text(
                              'Konfigurasi MQTT Server',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _mqttServerController,
                          decoration: const InputDecoration(
                            labelText: 'MQTT Server IP',
                            prefixIcon: Icon(Icons.dns),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Masukkan IP MQTT Server';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mqttPortController,
                          decoration: const InputDecoration(
                            labelText: 'MQTT Port',
                            prefixIcon: Icon(Icons.settings_ethernet),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Masukkan Port MQTT';
                            }
                            final port = int.tryParse(value);
                            if (port == null || port <= 0 || port > 65535) {
                              return 'Port tidak valid (1-65535)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mqttUsernameController,
                          decoration: const InputDecoration(
                            labelText: 'MQTT Username (Opsional)',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mqttPasswordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'MQTT Password (Opsional)',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.smart_toy, color: Colors.green[300]),
                            const SizedBox(width: 8),
                            const Text(
                              'Konfigurasi AI Server',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _aiServerController,
                          decoration: const InputDecoration(
                            labelText: 'AI Server (IP:Port)',
                            prefixIcon: Icon(Icons.cloud),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Masukkan alamat AI Server';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _connectToMqtt,
                    child: _isConnecting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Menghubungkan...'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi),
                              SizedBox(width: 8),
                              Text('Test Koneksi & Masuk', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String mqttServer;
  final int mqttPort;
  final String mqttUsername;
  final String mqttPassword;
  final String aiServer;

  const HomePage({
    super.key,
    required this.mqttServer,
    required this.mqttPort,
    required this.mqttUsername,
    required this.mqttPassword,
    required this.aiServer,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String hasilPrediksi = "Belum ada prediksi";
  String saran = "-";
  String detailMessage = "";
  List<String> problems = [];

  double suhu = 0;
  double kelembapan = 0;
  double tekanan = 0;
  double gas = 0;

  List<double> suhuHistory = [30, 31, 32, 31.5, 33, 34, 33.8];

  late MqttServerClient client;

  @override
  void initState() {
    super.initState();
    setupMqtt();
  }

  Future<void> setupMqtt() async {
    client = MqttServerClient(widget.mqttServer, 'flutter_client');
    client.port = widget.mqttPort;
    client.keepAlivePeriod = 20;
    client.logging(on: false);
    
    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .keepAliveFor(20)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    if (widget.mqttUsername.isNotEmpty && widget.mqttPassword.isNotEmpty) {
      connMess.authenticateAs(widget.mqttUsername, widget.mqttPassword);
    }

    client.connectionMessage = connMess;
    
    client.onDisconnected = () {
      print('MQTT Disconnected');
    };

    try {
      await client.connect();
      print('MQTT Connected');
      client.subscribe('iot/udara', MqttQos.atMostOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        try {
          final data = jsonDecode(payload);
          setState(() {
            suhu = data['temperature'] ?? 0;
            kelembapan = data['humidity'] ?? 0;
            tekanan = data['pressure'] ?? 0;
            gas = data['gas'] ?? 0;
            suhuHistory.add(suhu);
            if (suhuHistory.length > 10) suhuHistory.removeAt(0);
          });
          kirimDataKeAI();
        } catch (e) {
          print('Error parsing MQTT: $e');
        }
      });
    } catch (e) {
      print('MQTT Error: $e');
    }
  }

  Future<void> kirimDataKeAI() async {
    final url = Uri.parse('http://${widget.aiServer}/predict');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "temperature": suhu,
          "humidity": kelembapan,
          "pressure": tekanan,
          "gas": gas,
        }),
      );

      print('AI Response Status: ${response.statusCode}');
      print('AI Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          // Parse detailed response
          final prediction = data['prediction'].toString();
          final message = data['message'] ?? 'Status tidak diketahui';
          final suggestions = data['saran'] ?? 'Tidak ada saran';
          final problemList = List<String>.from(data['problems'] ?? []);
          final totalProblems = data['total_problems'] ?? 0;
          
          // Set prediction result
          hasilPrediksi = prediction;
          detailMessage = message;
          problems = problemList;
          
          // Create detailed advice
          if (prediction == "aman") {
            saran = "✅ $message\n\n💡 Saran:\n$suggestions";
          } else {
            // Create problem icons
            String problemIcons = "";
            for (String problem in problemList) {
              if (problem.contains('suhu')) {
                problemIcons += "🌡️ ";
              } else if (problem.contains('kelembapan')) {
                problemIcons += "💧 ";
              } else if (problem.contains('tekanan')) {
                problemIcons += "📊 ";
              } else if (problem.contains('gas')) {
                problemIcons += "💨 ";
              }
            }
            
            saran = "⚠️ $message\n\n$problemIcons Saran Perbaikan:\n$suggestions";
          }
        });
      } else {
        setState(() {
          hasilPrediksi = "HTTP Error ${response.statusCode}";
          detailMessage = "Gagal menghubungi server AI";
          saran = "❌ Gagal menghubungi server AI\n🔧 Periksa koneksi ke: ${widget.aiServer}";
          problems = [];
        });
      }
    } catch (e) {
      print('AI Error: $e');
      setState(() {
        hasilPrediksi = "Koneksi AI Gagal";
        detailMessage = "Tidak dapat menghubungi AI server";
        saran = "❌ Tidak dapat menghubungi AI server\n🔧 Periksa:\n• Koneksi internet\n• Alamat server: ${widget.aiServer}\n• Status server AI";
        problems = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.air, size: 28),
            SizedBox(width: 8),
            Text("Air Quality Monitor"),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InfoPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              client.disconnect();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Status koneksi
              Card(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[500]!],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Terhubung ke ${widget.mqttServer}:${widget.mqttPort}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Data sensor
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sensors, color: Colors.blue[300], size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            "Data Sensor",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildDataRow("🌡️ Suhu", "${suhu.toStringAsFixed(1)} °C", Colors.orange),
                      const SizedBox(height: 8),
                      buildDataRow("💧 Kelembapan", "${kelembapan.toStringAsFixed(1)} %", Colors.blue),
                      const SizedBox(height: 8),
                      buildDataRow("📊 Tekanan", "${tekanan.toStringAsFixed(1)} hPa", Colors.purple),
                      const SizedBox(height: 8),
                      buildDataRow("💨 Gas", "${gas.toStringAsFixed(1)} KOhms", Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Status AI - Enhanced
              buildStatusCard(),
              const SizedBox(height: 20),
              
              // Grafik
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.show_chart, color: Colors.blue[300], size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            "Grafik Suhu",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                  suhuHistory.length,
                                  (index) => FlSpot(index.toDouble(), suhuHistory[index])),
                              isCurved: true,
                              barWidth: 3,
                              color: Colors.blue[400],
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.blue[300]!,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue[400]!.withOpacity(0.1),
                              ),
                            )
                          ],
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[700]!,
                                strokeWidth: 0.5,
                              );
                            },
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: kirimDataKeAI,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  Widget buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    
    if (hasilPrediksi == "aman") {
      statusColor = Colors.green[600]!;
      statusIcon = Icons.check_circle;
    } else if (hasilPrediksi.contains("tidak_aman")) {
      statusColor = Colors.red[600]!;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.orange[600]!;
      statusIcon = Icons.help_outline;
    }
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [statusColor, statusColor.withOpacity(0.8)],
          ),
        ),
        child: Column(
          children: [
            Icon(statusIcon, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              "Status Kualitas Udara",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasilPrediksi.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                saran,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDataRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: color, 
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.info_outline, size: 28),
            SizedBox(width: 8),
            Text("Panduan Kualitas Udara"),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.health_and_safety, color: Colors.green[300], size: 32),
                          const SizedBox(width: 12),
                          const Text(
                            "Batas Aman & Saran",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      buildDetailedInfoRow(
                        "🌡️", 
                        "Suhu", 
                        "18 - 35 °C", 
                        "< 18°C: Gunakan pemanas ruangan\n> 35°C: Gunakan AC atau kipas angin", 
                        Colors.orange
                      ),
                      const SizedBox(height: 16),
                      
                      buildDetailedInfoRow(
                        "💧", 
                        "Kelembapan", 
                        "20 - 80 %", 
                        "< 20%: Gunakan humidifier\n> 80%: Gunakan dehumidifier atau AC", 
                        Colors.blue
                      ),
                      const SizedBox(height: 16),
                      
                      buildDetailedInfoRow(
                        "📊", 
                        "Tekanan", 
                        "950 - 1100 hPa", 
                        "< 950: Waspada cuaca buruk\n> 1100: Tingkatkan hidrasi", 
                        Colors.purple
                      ),
                      const SizedBox(height: 16),
                      
                      buildDetailedInfoRow(
                        "💨", 
                        "Gas VOC", 
                        "> 50 KOhms", 
                        "< 50: Buka jendela untuk ventilasi,\ngunakan air purifier", 
                        Colors.green
                      ),
                      
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[900]!.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[700]!.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.blue[300]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "💡 Sistem akan memberikan saran spesifik berdasarkan parameter yang melebihi batas aman",
                                style: TextStyle(fontSize: 13),
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
      ),
    );
  }

  Widget buildDetailedInfoRow(String emoji, String title, String safeRange, String advice, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                ),
              ),
              Text(
                safeRange,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "⚠️ Jika di luar batas:",
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w500),
          ),
          Text(
            advice,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)),
          ),
        ],        
      ),
    );
  }
}