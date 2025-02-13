#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "pico/stdlib.h"
#include "pico/float.h"     // Required for using single-precision variables.
#include "pico/double.h"    // Required for using double-precision variables.

//constants
#define WALLIS_ITERATIONS 100000
#define PI 3.14159265359

const float PI_F = 3.14159265359f;
const double PI_D = 3.14159265359;
const float WALLIS_F = 100000.0f;
const double WALLIS_D = 100000.0; 

float wallisProductFloat(float iterations);
double wallisProductDouble(double iterations);

/**
 * @brief LAB #02
 *        Computes PI using double and float variations of Wallis
 *        products, showing the % error between the defined and 
 *        calculated PI.
 * 
 * @return int      Returns exit-status zero on completion.
 */
int main() {
    #ifndef WOKWI
    // Initialise the IO as we will be using the UART
    // Only required for hardware and not needed for Wokwi
        stdio_init_all();
    #endif
    float pi_float = wallisProductFloat(WALLIS_F);
    double pi_double = wallisProductDouble(WALLIS_D);

    // Print a console message to inform user what's going on.
    printf("Results:\n");
    printf("Float Precision PI: %f\n", pi_float);
    printf("Float Error: %f%%\n\n", (pi_float - PI_F)/PI_F * 100);
    printf("Double Precision PI: %lf\n", pi_double);
    printf("Double Error: %lf%%\n", (pi_double - PI_D)/PI_D * 100);

    // Returning zero indicates everything went okay.
    return 0;
}


/**
 * @brief Calculates the Wallis product using a _float_ for i iterations.
 * 
 * @param iterations 
 * @return float PI calculation
 */
float wallisProductFloat(float iterations){
    float pi_float = 1.0f;

    for(float i = 1.0f; i <= iterations; i++){
        pi_float = pi_float * (4 * i * i) / (4 * i * i - 1);
        //printf("%f", pi_float);
    }
    
    return pi_float * 2;
}

/**
 * @brief Calculates the Wallis product using a _double_ for i iterations.
 * 
 * @param iterations 
 * @return double PI calculation
 */
double wallisProductDouble(double iterations){
    double pi_double = 1.0;

    for(double i = 1.0; i <= iterations; i++){
        pi_double = pi_double * (4 * i * i) / (4 * i * i - 1);
    }
    
    return pi_double * 2;
}
