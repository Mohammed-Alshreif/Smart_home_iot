#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Helper functions for token generation and status
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// Wi-Fi credentials
#define WIFI_SSID "lap"
#define WIFI_PASSWORD "omima 2345"

// Firebase project credentials
#define API_KEY "AIzaSyDEslUsBv8uOyXIXqsbehPDqgHx2PCUYIY"
#define DATABASE_URL "https://esptest1-edcd8-default-rtdb.firebaseio.com/"

// GPIO for built-in LED (adjust if using an external LED)
#define LED_PIN 2

// Interval to check Firebase (in milliseconds)
#define READ_INTERVAL_MS 2000
int counter = 0;
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastReadMillis = 0;
bool signupOK = false;

void setup(){
  Serial.begin(9600);
  pinMode(LED_PIN, OUTPUT);  // Set LED pin as output

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED){
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.println("Connected with IP: " + WiFi.localIP().toString());

  // Assign Firebase credentials
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Sign in anonymously
  if (Firebase.signUp(&config, &auth, "", "")){
    Serial.println("Firebase sign-up successful");
    signupOK = true;
  } else {
    Serial.printf("Firebase sign-up FAILED: %s\n", config.signer.signupError.message.c_str());
  }

  // Token callback for automatic renewal
  config.token_status_callback = tokenStatusCallback;

  // Initialize Firebase connection
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop(){
  // Check if it's time to read from Firebase
  if (Firebase.ready() && signupOK && (millis() - lastReadMillis > READ_INTERVAL_MS || lastReadMillis == 0)){
    lastReadMillis = millis();

    // Read LED state from Firebase at path "led/state"
    if (Firebase.RTDB.getBool(&fbdo, "/led/state")) {
      bool ledState = fbdo.boolData();
      digitalWrite(LED_PIN, ledState ? HIGH : LOW);  // Turn LED ON or OFF
      Serial.print("LED State: ");
      Serial.println(ledState ? "ON" : "OFF");
    } else {
      Serial.println("Failed to read LED state:");
      Serial.println(fbdo.errorReason());
    }

     // Example 1: Send counter value
    if (Firebase.RTDB.setInt(&fbdo, "/led/counter", counter)) {
      Serial.print("Counter sent: ");
      Serial.println(counter);
      counter++;
    } else {
      Serial.println("Failed to send counter:");
      Serial.println(fbdo.errorReason());
    }
  }
}
