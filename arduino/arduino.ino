#include <SimpleKalmanFilter.h>

#include <SoftwareSerial.h>

#include "Wire.h"
#include "I2Cdev.h"
#include "MPU6050.h"

#define DEBUG

SoftwareSerial hc12(4, 5);
SimpleKalmanFilter kf_ax(0.2, 0.2, 0.01), kf_ay(0.2, 0.2, 0.01), kf_az(0.2, 0.2, 0.01);
MPU6050 accelgyro;

const float pi = acos(-1.0);

float oax = 0, oay = 0, oaz = 0; // 'o' stands for 'offset'
// float ogx = 0, ogy = 0, ogz = 0;

float vel_x = 0.0, vel_y = 0.0, vel_z = 0.0; // velocity
float disp_x = 0.0, disp_y = 0.0, disp_z = 0.0; // displacement

//float gravity;

long lastMicros;

// Returns acceleration, as a multiple of g (gravitational acceleration)
void getAcceleration(float &rrax, float &rray, float &rraz) {
  int16_t ax, ay, az;
  float rax, ray, raz;
  accelgyro.getAcceleration(&ax, &ay, &az);
  rax = ax / 16384.0;
  ray = ay / 16384.0;
  raz = az / 16384.0;
  rrax = kf_ax.updateEstimate(rax);
  rray = kf_ay.updateEstimate(ray);
  rraz = kf_az.updateEstimate(raz);
}

void initSensor() {
  const int samples = 1000;

  for (int i = 0; i < samples; ++i) {
    float fax, fay, faz;
//    accelgyro.getAcceleration(&ax, &ay, &az);
    getAcceleration(fax, fay, faz);
    oax += fax, oay += fay, oaz += faz;
  }

  Serial.print("Init: acceleration offset = (");
  Serial.print(oax, 3);
  Serial.print(", ");
  Serial.print(oay, 3);
  Serial.print(", ");
  Serial.print(oaz, 3);
  Serial.println(")");

  oax /= samples, oay /= samples, oaz /= samples;

  Serial.print("Init: acceleration offset = (");
  Serial.print(oax, 3);
  Serial.print(", ");
  Serial.print(oay, 3);
  Serial.print(", ");
  Serial.print(oaz, 3);
  Serial.println(")");

//  gravity = sqrt(oax * oax + oay * oay + oaz * oaz);
}

void setup() {
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

  // HC-12 wireless module setup
  pinMode(4, INPUT);
  pinMode(5, OUTPUT);
  hc12.begin(9600);

  // sensor calibration
  initSensor();

  // timer
  lastMicros = micros();
}

void loop() {
//  int16_t ax, ay, az;
//  accelgyro.getAcceleration(&ax, &ay, &az);
  float ax, ay, az;
  getAcceleration(ax, ay, az);

  // acceleration, in meters per square second
  float a_x = ax - oax;
  float a_y = ay - oay;
  float a_z = az - oaz;

  long thisMicros = micros();
  if (thisMicros == lastMicros) {
    return;
  }
  
  float interval = (thisMicros - lastMicros) / 1e6;

  disp_x += interval * (vel_x + 0.5 * a_x * interval);
  disp_y += interval * (vel_y + 0.5 * a_y * interval);
  disp_z += interval * (vel_z + 0.5 * a_z * interval);
  
  vel_x += a_x * interval;
  vel_y += a_y * interval;
  vel_z += a_z * interval;

  Serial.print("a = (");
  Serial.print(a_x, 3);
  Serial.print(", ");
  Serial.print(a_y, 3);
  Serial.print(", ");
  Serial.print(a_z, 3);
  Serial.print("), v = (");
  Serial.print(vel_x, 3);
  Serial.print(", ");
  Serial.print(vel_y, 3);
  Serial.print(", ");
  Serial.print(vel_z, 3);
  Serial.print("), x = (");
  Serial.print(disp_x, 3);
  Serial.print(", ");
  Serial.print(disp_y, 3);
  Serial.print(", ");
  Serial.print(disp_z, 3);
  Serial.println(")");

  lastMicros = thisMicros;
  delay(15);
}
