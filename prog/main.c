/********************************************************************************/
#include <cstdint>
#include <cmath>
#include <stdio.h>
#include "st7789.h"
#include "perf.h"

//==========================================================
// rvcpu.h
//==========================================================
extern "C" void printc(const char c);
extern "C" void prints(const char *const s);
extern "C" void finish(void);

const static char *const s = "0123456789abcdef";

void print_num(int num, const int base)
{
    char buf[256];
    int i = 0;
    while (num != 0)
    {
        buf[i] = s[num % base];
        num /= base;
        i++;
    }
    while (--i >= 0)
    {
        printc(buf[i]);
    }
}

void printb(int num)
{
    print_num(num, 2);
}

void printd(int num)
{
    print_num(num, 10);
}

void printh(int num)
{
    print_num(num, 16);
}

//=============================================================================================
// MadgwickAHRS.h
//=============================================================================================

// Variable declaration
class Madgwick
{
private:
    static float invSqrt(float x);
    float beta; // algorithm gain
    float q0;
    float q1;
    float q2;
    float q3; // quaternion of sensor frame relative to auxiliary frame
    float invSampleFreq;
    float roll;
    float pitch;
    float yaw;
    char anglesComputed;
    void computeAngles();

    //-------------------------------------------------------------------------------------------
    // Function declarations
public:
    Madgwick(void);
    void begin(float sampleFrequency) { invSampleFreq = 1.0f / sampleFrequency; }
    void setGain(float gain) { beta = gain; } // add my function 2024-12-5
    void updateIMU(float gx, float gy, float gz, float ax, float ay, float az);
    float getRoll()
    {
        if (!anglesComputed)
            computeAngles();
        return roll * 57.29578f;
    }
    float getPitch()
    {
        if (!anglesComputed)
            computeAngles();
        return pitch * 57.29578f;
    }
    float getYaw()
    {
        if (!anglesComputed)
            computeAngles();
        return yaw * 57.29578f + 180.0f;
    }
    float getRollRadians()
    {
        if (!anglesComputed)
            computeAngles();
        return roll;
    }
    float getPitchRadians()
    {
        if (!anglesComputed)
            computeAngles();
        return pitch;
    }
    float getYawRadians()
    {
        if (!anglesComputed)
            computeAngles();
        return yaw;
    }
};

//=============================================================================================
// MadgwickAHRS.c
//=============================================================================================
// Definitions

#define sampleFreqDef 512.0f // sample frequency in Hz
#define betaDef 0.1f         // 2 * proportional gain

//============================================================================================
// Functions

//-------------------------------------------------------------------------------------------
// AHRS algorithm update

Madgwick::Madgwick()
{
    beta = betaDef;
    q0 = 1.0f;
    q1 = 0.0f;
    q2 = 0.0f;
    q3 = 0.0f;
    invSampleFreq = 1.0f / sampleFreqDef;
    anglesComputed = 0;
}

//-------------------------------------------------------------------------------------------
// IMU algorithm update

void Madgwick::updateIMU(float gx, float gy, float gz, float ax, float ay, float az)
{
    float recipNorm;
    float s0, s1, s2, s3;
    float qDot1, qDot2, qDot3, qDot4;
    float _2q0, _2q1, _2q2, _2q3, _4q0, _4q1, _4q2, _8q1, _8q2, q0q0, q1q1, q2q2, q3q3;

    // Convert gyroscope degrees/sec to radians/sec
    gx *= 0.0174533f;
    gy *= 0.0174533f;
    gz *= 0.0174533f;

    // Rate of change of quaternion from gyroscope
    qDot1 = 0.5f * (-q1 * gx - q2 * gy - q3 * gz);
    qDot2 = 0.5f * (q0 * gx + q2 * gz - q3 * gy);
    qDot3 = 0.5f * (q0 * gy - q1 * gz + q3 * gx);
    qDot4 = 0.5f * (q0 * gz + q1 * gy - q2 * gx);

    // Compute feedback only if accelerometer measurement valid (avoids NaN in accelerometer normalisation)
    if (!((ax == 0.0f) && (ay == 0.0f) && (az == 0.0f)))
    {

        // Normalise accelerometer measurement
        recipNorm = invSqrt(ax * ax + ay * ay + az * az);
        ax *= recipNorm;
        ay *= recipNorm;
        az *= recipNorm;

        // Auxiliary variables to avoid repeated arithmetic
        _2q0 = 2.0f * q0;
        _2q1 = 2.0f * q1;
        _2q2 = 2.0f * q2;
        _2q3 = 2.0f * q3;
        _4q0 = 4.0f * q0;
        _4q1 = 4.0f * q1;
        _4q2 = 4.0f * q2;
        _8q1 = 8.0f * q1;
        _8q2 = 8.0f * q2;
        q0q0 = q0 * q0;
        q1q1 = q1 * q1;
        q2q2 = q2 * q2;
        q3q3 = q3 * q3;

        // Gradient decent algorithm corrective step
        s0 = _4q0 * q2q2 + _2q2 * ax + _4q0 * q1q1 - _2q1 * ay;
        s1 = _4q1 * q3q3 - _2q3 * ax + 4.0f * q0q0 * q1 - _2q0 * ay - _4q1 + _8q1 * q1q1 + _8q1 * q2q2 + _4q1 * az;
        s2 = 4.0f * q0q0 * q2 + _2q0 * ax + _4q2 * q3q3 - _2q3 * ay - _4q2 + _8q2 * q1q1 + _8q2 * q2q2 + _4q2 * az;
        s3 = 4.0f * q1q1 * q3 - _2q1 * ax + 4.0f * q2q2 * q3 - _2q2 * ay;
        recipNorm = invSqrt(s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3); // normalise step magnitude
        s0 *= recipNorm;
        s1 *= recipNorm;
        s2 *= recipNorm;
        s3 *= recipNorm;

        // Apply feedback step
        qDot1 -= beta * s0;
        qDot2 -= beta * s1;
        qDot3 -= beta * s2;
        qDot4 -= beta * s3;
    }

    // Integrate rate of change of quaternion to yield quaternion
    q0 += qDot1 * invSampleFreq;
    q1 += qDot2 * invSampleFreq;
    q2 += qDot3 * invSampleFreq;
    q3 += qDot4 * invSampleFreq;

    // Normalise quaternion
    recipNorm = invSqrt(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
    q0 *= recipNorm;
    q1 *= recipNorm;
    q2 *= recipNorm;
    q3 *= recipNorm;
    anglesComputed = 0;
}

//-------------------------------------------------------------------------------------------

float Madgwick::invSqrt(float x)
{
    float halfx = 0.5f * x;
    float y = x;
    long i = *(long *)&y;
    i = 0x5f3759df - (i >> 1);
    y = *(float *)&i;
    y = y * (1.5f - (halfx * y * y));
    y = y * (1.5f - (halfx * y * y));
    return y;
}

//-------------------------------------------------------------------------------------------

void Madgwick::computeAngles()
{
    roll = atan2f(q0 * q1 + q2 * q3, 0.5f - q1 * q1 - q2 * q2);
    pitch = asinf(-2.0f * (q1 * q3 - q0 * q2));
    yaw = atan2f(q1 * q2 + q0 * q3, 0.5f - q2 * q2 - q3 * q3);
    anglesComputed = 1;
}

/********************************************************************************/
int constrain(int value, int min, int max){
    if (value<min) return min;
    if (value>max) return max;
    return value;
}

/**********************************************************************************/
#define LOOP_HZ      100  // Hz of main loop
#define V_MIN         60  // PWM min
#define V_MAX        255  // PWM max
#define STOPTHETA     40  // default:20  : stop angle difference from target
#define FILTER_GAIN  0.1  // default:0.1, Madgwick Filter Gain
/**********************************************************************************/
#define TARGET       400  // default:2.0 : pendulum target angle, horiazon = 0.0
#define P_DIV         40  // default: 90
#define P_GAIN       500  // default:800
#define I_GAIN         0  // default:200
#define D_GAIN         0  // default: 75
/**********************************************************************************/
///// MMIO
int *const MPU_ADDR_ayax = (int *)0x30000000;
int *const MPU_ADDR_gxaz = (int *)0x30000004;
int *const MPU_ADDR_gzgy = (int *)0x30000008;
int *const MTR_ADDR_ctrl = (int *)0x30000040;

/**********************************************************************************/
int main() {
    st7789_reset();
    Madgwick MadgwickFilter; // MPU6050 mpu;

    float Kp = P_GAIN;
    float Ki = I_GAIN;
    float Kd = D_GAIN;
    float target = (float)TARGET / 100.0;

    float roll, dt, P, I, D, preP;
    int power, pwm;
    int16_t ax, ay, az, gx, gy, gz;

    MadgwickFilter.begin(LOOP_HZ);
    MadgwickFilter.setGain(FILTER_GAIN);
    dt = 1.0 / (float)LOOP_HZ;

    int loops = 0;
    while (1) {
        loops++;
        unsigned int data;
        data = *(MPU_ADDR_ayax);
        ax = data & 0xffff;
        ay = data >> 16;

        data = *(MPU_ADDR_gxaz);
        az = data & 0xffff;
        gx = data >> 16;

        data = *(MPU_ADDR_gzgy);
        gy = data & 0xffff;
        gz = data >> 16;

        MadgwickFilter.updateIMU(gx / 131.0, gy / 131.0, gz / 131.0,
                                 ax / 16384.0, ay / 16384.0, az / 16384.0);
        roll = MadgwickFilter.getRoll();

        // PID control
        P = (target - roll) / (float)P_DIV;
        I += P * dt;
        D = (P - preP) / dt;
        preP = P;

        int Pterm = Kp * P;
        int Iterm = Ki * I;
        int Dterm = Kd * D;
        power = Pterm + Iterm + Dterm;
        pwm = (constrain(abs(power), V_MIN, V_MAX));

        int motor_ctrl = 0;
        if (roll < (target - STOPTHETA) || (target + STOPTHETA) < roll) {
            power = 0;
            pwm = 0;
            P = I = D = 0;
            Pterm = Iterm = Dterm = 0;
            motor_ctrl = 0;
        }
        else {
            motor_ctrl = (power < 0) ? 2 : 1;
        }

        *(MTR_ADDR_ctrl) = (pwm & 0xff) | (motor_ctrl << 16);


        st7789_set_pos(0, 0);

        char buf[32];
        sprintf(buf, "roll  :%6.2f\n", roll);    st7789_printf(buf);
        sprintf(buf, "power :%6d\n", power);     st7789_printf(buf);
        sprintf(buf, "pwm   :%6d\n", pwm);       st7789_printf(buf);
        st7789_printf("\n");
        sprintf(buf, "Pterm :%6d\n", Pterm);     st7789_printf(buf);
        sprintf(buf, "Iterm :%6d\n", Iterm);     st7789_printf(buf);
        sprintf(buf, "Dterm :%6d\n", Dterm);     st7789_printf(buf);
        st7789_printf("\n");        
        sprintf(buf, "loops :%6d\n", loops);     st7789_printf(buf);
        
//        st7789_printf("roll  :%d  \n", (int)(roll * 100.0));
//        st7789_printf("power :%d  \n", power);
//        st7789_printf("pwm   :%d  \n", pwm);
//        st7789_printf("           \n");
//        st7789_printf("target:%d  \n", TARGET);

//        st7789_printf("Pterm :%d  \n", Pterm);
//        st7789_printf("Iterm :%d  \n", Iterm);
//        st7789_printf("Dterm :%d  \n", Dterm);
//        st7789_printf("           \n");
//        st7789_printf("loop  :%d  \n", (loops & 0xffff));
        
//        st7789_printf("ax   :%d   \n", ax);
//        st7789_printf("ay   :%d   \n", ay);
//        st7789_printf("az   :%d   \n", az);
//        st7789_printf("gx  :%d   \n", gx);
//        st7789_printf("gy  :%d   \n", gy);
//        st7789_printf("gz  :%d   \n", gz);
        st7789_printf("          \n");
        if (motor_ctrl==0) st7789_printf("*STOP*\n");
        if (motor_ctrl==1) st7789_printf("*FWD* \n");
        if (motor_ctrl==2) st7789_printf("*REV* \n");

            
//        *(VIO_ADDR_roll) = roll; // control here


        { ///// delay()
            volatile int i = 0;
            while (i < 50'000) i++;
        }
    }
    return 0;
}
/********************************************************************************/

