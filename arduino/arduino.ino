#include <SoftwareSerial.h>

#include "Wire.h"
#include "I2Cdev.h"
#include "MPU6050.h"

SoftwareSerial hc12(4, 5);
MPU6050 accelgyro;

const float pi = acos(-1.0);

float oax, oay, oaz; // 'o' stands for 'offset'
float ogx, ogy, ogz;

float rot_y;

const int samples = 10;
const int initCount = 500;

int lastMicros;

bool blinkLed;

// Returns acceleration, as a multiple of g (gravitational acceleration)
void getAcceleration(float &rrax, float &rray, float &rraz) {
  int16_t ax, ay, az;
  float rax = 0.0, ray = 0.0, raz = 0.0;
  for (int i = 0; i < samples; ++i) {
    accelgyro.getAcceleration(&ax, &ay, &az);
    rax += ax;
    ray += ay;
    raz += az;
  }
  rrax = rax / (samples * 16384.0);
  rray = ray / (samples * 16384.0);
  rraz = raz / (samples * 16384.0);
}

void getRotation(float &rrgx, float &rrgy, float &rrgz) {
  int16_t gx, gy, gz;
  float rgx = 0.0, rgy = 0.0, rgz = 0.0;
  for (int i = 0; i < samples; ++i) {
    accelgyro.getRotation(&gx, &gy, &gz);
    rgx += gx;
    rgy += gy;
    rgz += gz;
  }
  rrgx = rgx / (samples * 131.0);
  rrgy = rgy / (samples * 131.0);
  rrgz = rgz / (samples * 131.0);
}

void initSensor() {
  oax = oay = oaz = ogx = ogy = ogz = 0.0;

  for (int i = 0; i < initCount; ++i) {
    float fax, fay, faz, fgx, fgy, fgz;
    getAcceleration(fax, fay, faz);
    getRotation(fgx, fgy, fgz);
    oax += fax, oay += fay, oaz += faz;
    ogx += fgx, ogy += fgy, ogz += fgz;
    Serial.print("Init: ");
    Serial.print(i);
    Serial.print("/");
    Serial.println(initCount);
  }

  oax /= initCount;
  oay /= initCount;
  oaz /= initCount;
  
  ogx /= initCount;
  ogy /= initCount;
  ogz /= initCount;
}

void setup() {
  // HC-12 wireless module setup
  pinMode(4, INPUT);
  pinMode(5, OUTPUT);
  hc12.begin(9600);
  
  // join I2C bus (I2Cdev library doesn't do this automatically)
  Wire.begin();

  // initialize serial communication
  Serial.begin(38400);

  // initialize device
  Serial.println("Initializing I2C devices...");
  accelgyro.initialize();

  // verify connection
  Serial.println("Testing device connections...");
  Serial.println(accelgyro.testConnection() ? "MPU6050 connection successful" : "MPU6050 connection failed");

  // sensor calibration
  initSensor();

  rot_y = 0.0;
  lastMicros = micros();

  // LED
  pinMode(LED_BUILTIN, OUTPUT);
  blinkLed = false;
}

void loop() {
  float ax, ay, az, gx, gy, gz;
//  Serial.println("New loop");
  getAcceleration(ax, ay, az);
//  Serial.println("Got acceleration");
  getRotation(gx, gy, gz);
//  Serial.println("Got rotation");

  float a_z = az - oaz;
  float g_y = gy - ogy;

  int thisMicros = micros();
  rot_y += g_y * (thisMicros - lastMicros) / 1e6;
  lastMicros = thisMicros;

  int8_t data = 0x0;

  Serial.print(a_z, 3);
  Serial.print("\t\t");
  Serial.print(rot_y, 3);

  if (a_z > 0.9) {
    data |= 0x8;
    Serial.print("\t\tU");
  } else {
    Serial.print("\t\t-");
  }

  if (rot_y < -8.0) {
    data |= 0x1;
    Serial.println("R");
  } else if (rot_y > 8.0) {
    data |= 0x2;
    Serial.println("L");
  } else {
    Serial.println("-");
  }

  blinkLed = !blinkLed;
  digitalWrite(LED_BUILTIN, blinkLed);
  
  hc12.print(data);

  delay(20);
}
