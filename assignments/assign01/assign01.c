#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/gpio.h"

// Declare the main assembly code entry point.
void main_asm();


/**
 * @brief Initialise a GPIO pin – see SDK for detail on gpio_init()
 * 
 * @param pin 
 */
void asm_gpio_init(uint pin) {
    gpio_init(pin);
}

/**
 * @brief Set direction of a GPIO pin – see SDK for detail on gpio_set_dir()
 * 
 * @param pin 
 * @param out 
 * @return * void 
 */
void asm_gpio_set_dir(uint pin, bool out) {
    gpio_set_dir(pin, out);
}

/**
 * @brief Get the value of a GPIO pin – see SDK for detail on gpio_get()
 * 
 * @param pin 
 * @return true 
 * @return false 
 */
bool asm_gpio_get(uint pin) {
    return gpio_get(pin);
}

/**
 * @brief Set the value of a GPIO pin – see SDK for detail on gpio_put()
 * 
 * @param pin 
 * @param value 
 */
void asm_gpio_put(uint pin, bool value) {
    gpio_put(pin, value);
}

/**
 * @brief Enable falling-edge interrupt – see SDK for detail on gpio_set_irq_enabled()
 * 
 * @param pin 
 */
void asm_gpio_set_irq(uint pin) {
    gpio_set_irq_enabled(pin, GPIO_IRQ_EDGE_FALL, true);
}

// Main entry point of the application RM
int main() {
    stdio_init_all();              // Initialise all basic IO
    printf("Assignment #1...\n");  // Basic print to console
    main_asm();                    // Jump into the ASM code
    return 0;                      // Application return code
}