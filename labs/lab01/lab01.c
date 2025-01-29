#include "pico/stdlib.h"


/**
  * @brief Cyclically turns on and off a specified LED
  *        for a specified time.
  *
  * @return none
  */
void toggle_LED(const uint LED_PIN, const uint LED_DELAY){
    static bool LED_state = 0;

    // Update LED state
    LED_state = !LED_state;
    // Toggle the LED 
    gpio_put(LED_PIN, LED_state);
    // Sleep specified time
    sleep_ms(LED_DELAY);

}


/**
 * @brief BLINK_C
 *        Initialise the built-in LED on
 *        the Raspberry Pi Pico and then flash it forever. 
 * 
 * @return int  Application return code (zero for success).
 */
int main() {

    // Specify the PIN number and sleep delay
    const uint LED_PIN   =  25;
    const uint LED_DELAY = 500;

    // Setup the LED pin as an output.
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);

    // Infinitely toggle LED.
    while (true) {
      toggle_LED(LED_PIN, LED_DELAY);
    }
    
    // Should never get here due to infinite while-loop.
    return 0;

}




