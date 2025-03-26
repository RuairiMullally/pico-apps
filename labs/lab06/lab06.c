
#include <stdio.h> 
#include <stdlib.h> 
#include <math.h> 
#include "pico/stdlib.h" 
#include "pico/float.h"     // Required for using single-precision variables. 
#include "pico/double.h"    // Required for using double-precision variables. 
#include "pico/multicore.h" // Required for using multiple cores on the RP2040. 

#define PI 3.14159265359

const float PI_F = 3.14159265359f;
const double PI_D = 3.14159265359;
const int32_t WALLIS_ITERATIONS = 100000; 

float wallisProductFloat(int32_t iterations);
double wallisProductDoubleCore0(int32_t iterations);
int32_t wallisProductDouble(int32_t iterations);
 
/** 
 * @brief This function acts as the main entry-point for core #1. 
 *        A function pointer is passed in via the FIFO with one 
 *        incoming int32_t used as a parameter. The function will 
 *        provide an int32_t return value by pushing it back on  
 *        the FIFO, which also indicates that the result is ready. 
 */ 
void core1_entry() { 
    while (1) { 
        //  
        int32_t (*func)() = (int32_t(*)()) multicore_fifo_pop_blocking(); 
        int32_t p = multicore_fifo_pop_blocking(); 
        int32_t result = (*func)(p); 
        multicore_fifo_push_blocking(result); 
    } 
} 
 
// Main code entry point for core0. 
int main() { 
 
    const int32_t ITER_MAX   = 100000; 
 
    stdio_init_all(); 
    multicore_launch_core1(core1_entry); 

    //variables for tracking timing
    uint32_t t_total_start, t_total_end;
    uint32_t t_float_start, t_float_end;
    uint32_t t_double_start, t_double_end;
    float f_result;
    double d_result;
    //    Take snapshot of timer and store 
    t_total_start = time_us_32();
    t_float_start = time_us_32();
    //    Run the single-precision Wallis approximation 
    f_result = wallisProductFloat(ITER_MAX);
    t_float_end = time_us_32();
    //    Run the double-precision Wallis approximation
    t_double_start = time_us_32();
    d_result = wallisProductDoubleCore0(ITER_MAX);
    t_double_end = time_us_32(); 
    //    Take snapshot of timer and store 
    t_total_end = time_us_32();
    //    Display time taken for application to run in sequential mode 
    printf("Wallis Product (Float) result: %f\n", f_result);
    printf("Runtime (Float): %u milliseconds\n", (t_float_end - t_float_start)/1000);
    printf("Wallis Product (Double) result: %lf\n", d_result);
    printf("Runtime (Double): %u milliseconds\n", (t_double_end - t_double_start)/1000);
    printf("Total sequential runtime: %u milliseconds\n", (t_total_end - t_total_start)/1000);
 

    //    Take snapshot of timer and store 
    uint32_t t_parallel_start, t_parallel_end;
    float f_result_parallel; 
    double d_result_parallel;
    t_parallel_start = time_us_32();
    //    Run the single-precision Wallis approximation on one core 
    f_result_parallel = wallisProductFloat(WALLIS_ITERATIONS);
    //    Run the double-precision Wallis approximation on the other core 
    multicore_fifo_push_blocking((uint32_t) wallisProductDouble);
    multicore_fifo_push_blocking(WALLIS_ITERATIONS);
    //    Take snapshot of timer and store 
    d_result_parallel = multicore_fifo_pop_blocking();
    t_parallel_end = time_us_32();

    // Display parallel results.
    printf("Parallel Run---------------------------\n");
    printf("Wallis Product (Float) result: %f\n", f_result_parallel);
    printf("Wallis Product (Double) result: %f\n", d_result_parallel/1000000.0);
    printf("Total parallel runtime: %u microseconds\n", (t_parallel_end - t_parallel_start)/1000);
 
    return 0; 
} 

/**
 * @brief Calculates the Wallis product using a _float_ for i iterations.
 * 
 * @param iterations 
 * @return float PI calculation
 */
float wallisProductFloat(int32_t iterations){
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
double wallisProductDoubleCore0(int32_t iterations){
    double pi_double = 1.0;

    for(double i = 1.0; i <= iterations; i++){
        pi_double = pi_double * (4 * i * i) / (4 * i * i - 1);
    }
    return pi_double * 2;
}

/**
 * @brief Calculates Wallis produc and casts to int32_t before returning to work in parrallel operation.
 * 
 * @param iterations 
 * @return int32_t double precision PI calculation
 */
int32_t wallisProductDouble(int32_t iterations){
    double pi_double = 1.0;

    for(double i = 1.0; i <= iterations; i++){
        pi_double = pi_double * (4 * i * i) / (4 * i * i - 1);
    }
    double result = pi_double * 2;

    return (int32_t)(result * 1000000.0); //cast result to an 32 bit int so core 1 can return proper value
}