#include "pico/stdlib.h"
#include <stdio.h>

/**
 * @brief Toggle a specified LED for a specified time.
 * 
 * @param LED_PIN 
 * @param LED_DELAY 
 */
void toggle_LED(const uint LED_PIN, const uint LED_DELAY){
    
    //get current LED state
    bool LED_state = gpio_get(LED_PIN);
    // Toggle the LED 
    gpio_put(LED_PIN, !LED_state);
    // Sleep specified time
    sleep_ms(LED_DELAY);

}

/**
 * @brief BLINK_C
 *        Initialise the built-in LED on
 *        the Raspberry Pi Pico and then flash it forever.
 * 
 * @return int 
 */
int main() {

    // Specify the PIN number and sleep delay
    const uint LED_PIN   =  25;
    const uint LED_DELAY = 500;

    // Setup the LED pin as an output.
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);

    stdio_init_all();

    // Infinitely toggle LED.
    while (true) {
      toggle_LED(LED_PIN, LED_DELAY);
      printf("Blinking!\n");
    }
    
    // Should never get here due to infinite while-loop.
    return 0;

}




