# 🌬️ Air Quality Monitor - Sistem Monitoring Kualitas Udara IoT

Aplikasi monitoring kualitas udara berbasis IoT menggunakan **Flutter** dan **ESP8266** dengan sensor **BME680**. Sistem ini dapat memantau suhu, kelembapan, tekanan udara, dan kualitas gas secara real-time dengan prediksi AI.

![Flutter](https://img.shields.io/badge/Flutter-3.7.2-blue?logo=flutter)
![ESP8266](https://img.shields.io/badge/ESP8266-NodeMCU-green?logo=espressif)
![MQTT](https://img.shields.io/badge/Protocol-MQTT-purple)

## 📋 Daftar Isi

- [Fitur](#-fitur)
- [Arsitektur Sistem](#-arsitektur-sistem)
- [Komponen Hardware](#-komponen-hardware)
- [Instalasi](#-instalasi)
- [Konfigurasi](#-konfigurasi)
- [Penggunaan](#-penggunaan)
- [Screenshot](#-screenshot)
- [Kontributor](#-kontributor)

## ✨ Fitur

### Aplikasi Flutter
- 📊 **Dashboard Real-time** - Menampilkan data sensor secara langsung
- 📈 **Grafik Riwayat** - Visualisasi data suhu dalam bentuk grafik
- 🤖 **Prediksi AI** - Analisis kualitas udara menggunakan AI server
- 🔔 **Notifikasi Status** - Peringatan jika kualitas udara tidak aman
- 🌙 **Dark Mode UI** - Tampilan modern dengan tema gelap
- ⚙️ **Konfigurasi Fleksibel** - Pengaturan MQTT dan AI server

### Perangkat IoT (ESP8266 + BME680)
- 🌡️ **Monitoring Suhu** - Pengukuran suhu lingkungan (°C)
- 💧 **Monitoring Kelembapan** - Pengukuran kelembapan relatif (%)
- 📊 **Monitoring Tekanan** - Pengukuran tekanan atmosfer (hPa)
- 💨 **Monitoring Kualitas Gas** - Pengukuran resistansi gas (KOhm)
- 📺 **Display OLED** - Tampilan data lokal pada OLED 128x64
- 📡 **Konektivitas WiFi & MQTT** - Pengiriman data secara wireless

## 🏗️ Arsitektur Sistem

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   ESP8266 +     │     │   MQTT Broker   │     │   Flutter App   │
│   BME680        │────▶│   (Mosquitto)   │────▶│   (Android/iOS) │
│   + OLED        │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │   AI Server     │
                                                │   (Python/Flask)│
                                                └─────────────────┘
```

## 🔧 Komponen Hardware

| Komponen | Deskripsi |
|----------|-----------|
| ESP8266 NodeMCU | Mikrokontroler dengan WiFi |
| BME680 | Sensor suhu, kelembapan, tekanan, dan gas |
| OLED SSD1306 128x64 | Display untuk tampilan lokal |
| Kabel Jumper | Koneksi antar komponen |
| Breadboard | Papan prototipe |

### Wiring Diagram

| BME680 (I2C) | ESP8266 |
|--------------|---------|
| VCC | 3.3V |
| GND | GND |
| SDA | D2 (GPIO4) |
| SCL | D1 (GPIO5) |

| OLED SPI | ESP8266 |
|----------|---------|
| VCC | 3.3V |
| GND | GND |
| MOSI | D7 (GPIO13) |
| CLK | D5 (GPIO14) |
| DC | D4 (GPIO2) |
| CS | D8 (GPIO15) |
| RESET | D3 (GPIO0) |

## 🚀 Instalasi

### Prasyarat

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versi 3.7.2 atau lebih baru)
- [Arduino IDE](https://www.arduino.cc/en/software) untuk ESP8266
- MQTT Broker (contoh: Mosquitto)
- Python 3.x dengan Flask (untuk AI Server - opsional)

### 1. Clone Repository

```bash
git clone https://github.com/username/air-quality-monitor.git
cd air-quality-monitor
```

### 2. Setup Aplikasi Flutter

```bash
# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

### 3. Setup ESP8266

1. Buka file `tubesiot.ino` di Arduino IDE
2. Install library yang diperlukan:
   - Adafruit BME680 Library
   - Adafruit SSD1306
   - Adafruit GFX Library
   - PubSubClient
   - ESP8266WiFi
3. Ubah konfigurasi WiFi dan MQTT di file:
   ```cpp
   const char* ssid = "NAMA_WIFI_ANDA";
   const char* pass = "PASSWORD_WIFI";
   const char* mqtt_server = "IP_MQTT_BROKER";
   const char* mqtt_user = "USERNAME_MQTT";
   const char* mqtt_pass = "PASSWORD_MQTT";
   ```
4. Upload ke ESP8266

## ⚙️ Konfigurasi

### Aplikasi Flutter

Pada halaman login, masukkan:
- **MQTT Server IP**: Alamat IP broker MQTT
- **MQTT Port**: Port broker (default: 1883)
- **MQTT Username**: Username autentikasi (opsional)
- **MQTT Password**: Password autentikasi (opsional)
- **AI Server**: Alamat server AI dalam format `IP:Port`

### MQTT Topic

Aplikasi menggunakan topic MQTT berikut:
- `iot/udara` - Topic untuk data sensor

### Format Data JSON

```json
{
  "temperature": 25.5,
  "humidity": 60.0,
  "pressure": 1013.25,
  "gas": 50.5
}
```

## 📱 Penggunaan

1. **Nyalakan ESP8266** - Pastikan terhubung ke WiFi dan MQTT broker
2. **Buka Aplikasi Flutter** - Masukkan konfigurasi koneksi
3. **Tekan "Test Koneksi & Masuk"** - Untuk masuk ke dashboard
4. **Pantau Data Real-time** - Lihat data sensor dan prediksi AI

## 📸 Screenshot

*Screenshot akan ditambahkan*

## 🛠️ Dependencies

### Flutter
```yaml
dependencies:
  flutter: sdk
  mqtt_client: ^10.10.0
  http: ^1.1.0
  google_fonts: ^6.1.0
  fl_chart: ^1.0.0
```

### Arduino/ESP8266
- Adafruit_BME680
- Adafruit_SSD1306
- Adafruit_GFX
- PubSubClient
- ESP8266WiFi

## 👥 Kontributor

- **Nama Anda** - *Pengembang Utama*

## 📄 Lisensi

Proyek ini dibuat untuk keperluan Tugas Besar mata kuliah **Internet of Things (IoT)** Semester 4.

---

⭐ Jangan lupa untuk memberikan bintang jika proyek ini membantu!
