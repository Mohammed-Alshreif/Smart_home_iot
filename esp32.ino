#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include <ESP32Servo.h>

// Helper functions
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// Wi-Fi credentials
#define WIFI_SSID "lap"
#define WIFI_PASSWORD "omima 2345"

// Firebase credentials
#define API_KEY "AIzaSyDEslUsBv8uOyXIXqsbehPDqgHx2PCUYIY"
#define DATABASE_URL "https://esptest1-edcd8-default-rtdb.firebaseio.com/"

// GPIO pins
#define SOIL_PIN 34
#define DHT_PIN 4
#define DHT_TYPE DHT11
#define TRIG_PIN 5
#define ECHO_PIN 18
#define SERVO_PIN 15
#define MOTORPIN  19

//=========================================
long waterLevel=0;
int soil =0;
float temp = 0;
float hum =0;
bool servoState;
bool  MOTORState;

//=========================================
// Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastReadMillis = 0;
#define READ_INTERVAL_MS 4000
bool signupOK = false;

DHT dht(DHT_PIN, DHT_TYPE);
Servo servo;

// fixed paths
String basePath = "/apartments/flat1/rooms/";

long readUltrasonicFiltered() {
  const int samples = 7;   // عدد القراءات
  long values[samples];

  // ناخد 7 قراءات
  for (int i = 0; i < samples; i++) {
    digitalWrite(TRIG_PIN, LOW);
    delayMicroseconds(2);
    digitalWrite(TRIG_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(TRIG_PIN, LOW);

    long duration = pulseIn(ECHO_PIN, HIGH, 30000); // max 30ms
    values[i] = duration * 0.034 / 2; // يتحول سم
    delay(50); // راحة بين القراءات
  }

  // ترتيب القيم (Bubble sort بسيط)
  for (int i = 0; i < samples - 1; i++) {
    for (int j = i + 1; j < samples; j++) {
      if (values[i] > values[j]) {
        long tmp = values[i];
        values[i] = values[j];
        values[j] = tmp;
      }
    }
  }

  // ناخد الميديان (القيمة الوسطية)
  long medianValue = values[samples / 2];

  // فلتر إضافي: تجاهل أي قيمة بعيدة عن الميديان أكتر من ±20%
  long sum = 0;
  int count = 0;
  for (int i = 0; i < samples; i++) {
    if (values[i] > medianValue * 0.8 && values[i] < medianValue * 1.2) {
      sum += values[i];
      count++;
    }
  }

  if (count > 0) {
    return sum / count; // متوسط القيم المعقولة
  } else {
    return medianValue; // fallback
  }
}


void setup() {
  Serial.begin(9600);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(MOTORPIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  dht.begin();
  servo.attach(SERVO_PIN);
  servo.write(0); // start closed

  // connect Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.println("Connected with IP: " + WiFi.localIP().toString());

  // Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  if (Firebase.signUp(&config, &auth, "", "")) {
    signupOK = true;
    Serial.println("Firebase sign-up OK");
  } else {
    Serial.printf("Firebase sign-up failed: %s\n", config.signer.signupError.message.c_str());
  }
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
   if (Firebase.ready() && signupOK){
     //=====================Motor ===================
    Firebase.RTDB.setString(&fbdo, basePath + "room1/devices/device3/name","Motor");
    Firebase.RTDB.setInt(&fbdo, basePath + "room1/devices/device3/status",true);
    
   }
}

void loop() {
  if (Firebase.ready() && signupOK && (millis() - lastReadMillis > READ_INTERVAL_MS)) {
    lastReadMillis = millis();

    // ====== Read sensors ======
     soil = analogRead(SOIL_PIN)/40.95;
     temp = dht.readTemperature();
     hum = dht.readHumidity();
     waterLevel = readUltrasonicFiltered();
     waterLevel = (waterLevel>100)?100:waterLevel;

    // ====== Upload to Firebase ======
    // Living room sensors
    Firebase.RTDB.setInt(&fbdo, basePath + "room1/sensors/sensors1/value", temp);
    Firebase.RTDB.setInt(&fbdo, basePath + "room1/sensors/sensors2/value", hum);

    // Room1 soil + water
    Firebase.RTDB.setInt(&fbdo, basePath + "room1/sensors/sensors3/value", soil);
    Firebase.RTDB.setString(&fbdo, basePath + "room1/sensors/sensors3/name","soil");
    Firebase.RTDB.setString(&fbdo, basePath + "room1/sensors/sensors3/unit","%");
  
    Firebase.RTDB.setInt(&fbdo, basePath + "room1/sensors/sensors4/value", waterLevel);
    Firebase.RTDB.setString(&fbdo, basePath + "room1/sensors/sensors4/name","waterLevel");
    Firebase.RTDB.setString(&fbdo, basePath + "room1/sensors/sensors4/unit","cm");

    Serial.printf("Soil=%d Temp=%.1f Hum=%.1f Water=%ld\n", soil, temp, hum, waterLevel);

    // ====== Servo device control ======
    Firebase.RTDB.setString(&fbdo, basePath + "room1/devices/device1/name","Servo device");

    if (Firebase.RTDB.getBool(&fbdo, basePath + "room1/devices/device1/status")) {
       servoState = fbdo.boolData();
      if (servoState) {
        servo.write(90); // open valve
        Serial.println("Servo OPEN");
      } else {
        servo.write(0); // close valve
        Serial.println("Servo CLOSE");
      }
    } else {
      Serial.println("Failed to read servo state");
      Serial.println(fbdo.errorReason());
    }

    //=====================Motor ===================
   
    if (Firebase.RTDB.getBool(&fbdo, basePath + "room1/devices/device3/status")) {
       MOTORState = fbdo.boolData();
      if (MOTORState) {
        digitalWrite(MOTORPIN,LOW);
        Serial.println("MOTOR OPEN");
      } else {
        digitalWrite(MOTORPIN,HIGH);
        Serial.println("MOTOR CLOSE");
      }
    } else {
      Serial.println("Failed to read MOTOR state");
      Serial.println(fbdo.errorReason());
    }

  }
}
