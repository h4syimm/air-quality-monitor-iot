#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME680.h>
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SEALEVELPRESSURE_HPA (1013.25)

// OLED SPI pins
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_MOSI   13  // D7
#define OLED_CLK    14  // D5
#define OLED_DC     2   // D4
#define OLED_CS     15  // D8
#define OLED_RESET  0   // D3

// Inisialisasi objek
Adafruit_BME680 bme;
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, OLED_MOSI, OLED_CLK, OLED_DC, OLED_RESET, OLED_CS);

// WiFi & MQTT Setting
const char* ssid = "Pixel 8";
const char* pass = "wongunik";
const char* mqtt_server = "192.168.171.28";
const char* mqtt_user = "uas25_hasyim";
const char* mqtt_pass = "uas25_hasyim";

WiFiClient espClient;
PubSubClient client(espClient);

// Variabel untuk data sensor
float suhu, kelembapan, tekanan, gas;
unsigned long lastUpdate = 0;
const unsigned long updateInterval = 2000;

void setup() {
  Serial.begin(115200);
  
  // Inisialisasi OLED SPI
  if(!display.begin(SSD1306_SWITCHCAPVCC)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
  }
  
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0,0);
  display.println(F("Air Quality Monitor"));
  display.println(F("Starting up..."));
  display.display();
  delay(2000);
  
  // WiFi Connection
  WiFi.begin(ssid, pass);
  display.clearDisplay();
  display.setCursor(0,0);
  display.println(F("Connecting WiFi..."));
  display.display();
  
  Serial.print("Menghubungkan WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Terkoneksi!");
  
  display.clearDisplay();
  display.setCursor(0,0);
  display.println(F("WiFi Connected!"));
  display.println(WiFi.localIP());
  display.display();
  delay(2000);

  client.setServer(mqtt_server, 1883);

  // MQTT Connection
  display.clearDisplay();
  display.setCursor(0,0);
  display.println(F("Connecting MQTT..."));
  display.display();
  
  while (!client.connected()) {
    Serial.print("Menghubungkan ke MQTT broker...");
    if (client.connect("ESPClient", mqtt_user, mqtt_pass)) {
      Serial.println("Berhasil terkoneksi ke MQTT!");
      display.clearDisplay();
      display.setCursor(0,0);
      display.println(F("MQTT Connected!"));
      display.display();
      delay(1000);
    } else {
      Serial.print("Gagal, rc=");
      Serial.print(client.state());
      Serial.println(" coba ulang dalam 2 detik");
      delay(2000);
    }
  }

  // Inisialisasi sensor BME680 (menggunakan I2C default pin D1, D2)
  if (!bme.begin()) {
    Serial.println("Sensor BME680 tidak terdeteksi!");
    display.clearDisplay();
    display.setCursor(0,0);
    display.println(F("BME680 Error!"));
    display.display();
    while (1);
  }

  bme.setTemperatureOversampling(BME680_OS_8X);
  bme.setHumidityOversampling(BME680_OS_2X);
  bme.setPressureOversampling(BME680_OS_4X);
  bme.setIIRFilterSize(BME680_FILTER_SIZE_3);
  bme.setGasHeater(320, 150);
  
  display.clearDisplay();
  display.setCursor(0,0);
  display.println(F("System Ready!"));
  display.display();
  delay(1000);
}

void loop() {
  // Reconnect MQTT jika terputus
  if (!client.connected()) {
    client.connect("ESPClient", mqtt_user, mqtt_pass);
  }
  client.loop();

  // Baca sensor setiap interval tertentu
  if (millis() - lastUpdate >= updateInterval) {
    if (!bme.beginReading()) {
      delay(1000);
      return;
    }
    delay(200);
    if (!bme.endReading()) {
      delay(1000);
      return;
    }

    // Ambil data sensor
    suhu = bme.temperature;
    kelembapan = bme.humidity;
    tekanan = bme.pressure / 100.0;
    gas = bme.gas_resistance / 1000.0;

    // Print ke Serial Monitor
    Serial.printf("Suhu: %.2f °C\n", suhu);
    Serial.printf("Kelembapan: %.2f %%\n", kelembapan);
    Serial.printf("Tekanan: %.2f hPa\n", tekanan);
    Serial.printf("Resistansi Gas: %.2f KOhms\n", gas);
    Serial.println("----------------------");

    // Update OLED Display
    updateOLEDDisplay();

    // Buat payload JSON untuk MQTT
    String payload = "{\"temperature\":";
    payload += suhu;
    payload += ",\"humidity\":";
    payload += kelembapan;
    payload += ",\"pressure\":";
    payload += tekanan;
    payload += ",\"gas\":";
    payload += gas;
    payload += "}";

    // Publish ke MQTT
    client.publish("iot/udara", payload.c_str());
    Serial.println("Data published ke MQTT");
    
    lastUpdate = millis();
  }
}

void updateOLEDDisplay() {
  display.clearDisplay();
  
  // Header dengan frame
  display.setTextSize(1);
  display.setCursor(15,2);
  display.println(F("AIR QUALITY"));
  display.drawRect(0, 0, 128, 64, SSD1306_WHITE);
  display.drawLine(5, 12, 123, 12, SSD1306_WHITE);
  
  // Data sensor dengan ikon sederhana
  display.setCursor(8,16);
  display.print(F("T: "));
  display.print(suhu, 1);
  display.print(F("C"));
  
  display.setCursor(70,16);
  display.print(F("H: "));
  display.print(kelembapan, 0);
  display.println(F("%"));
  
  display.setCursor(8,28);
  display.print(F("P: "));
  display.print(tekanan, 0);
  display.println(F(" hPa"));
  
  display.setCursor(8,40);
  display.print(F("Gas: "));
  display.print(gas, 1);
  display.println(F(" KOhm"));
  
  // Status koneksi dengan indikator
  display.setCursor(8,52);
  if (WiFi.status() == WL_CONNECTED && client.connected()) {
    display.print(F("WiFi+MQTT: OK"));
    // Dot indikator online
    display.fillCircle(120, 55, 2, SSD1306_WHITE);
  } else {
    display.print(F("Disconnected"));
    // X indikator offline
    display.drawLine(118, 53, 122, 57, SSD1306_WHITE);
    display.drawLine(122, 53, 118, 57, SSD1306_WHITE);
  }
  
  display.display();
}