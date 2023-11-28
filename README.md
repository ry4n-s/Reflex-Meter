# 🚦 Reflex Meter 🚦

## Overview
Welcome to Reflex Meter, a fascinating journey into the world of embedded systems and real-time computing! 🌟 This project is meticulously crafted using the ARM Thumb instruction set, ensuring compact and efficient code for microcontroller applications.

## Key Features
- 🎮 **User Interaction:** Utilizes a button press system to test reflexes. Players can engage in a simple yet captivating way to measure their reaction times.
- 🌈 **LED Display:** Incorporates a dynamic LED display system, providing real-time visual feedback. The LED patterns are both informative and visually pleasing.
- 🕒 **Timing Precision:** Features high-precision timing to accurately measure and display reaction times, ensuring a fair and challenging experience for users.
- 🔢 **Random Number Generation:** Employs a pseudo-random number generator to create unpredictable and varied scenarios, enhancing the game's replay value.
- 🛠 **Efficient Code:** Written in the Thumb instruction set for ARM, the project boasts compact and efficient code, perfect for embedded systems.

## Core Components
- 🎛 **LED_BASE_ADR:** A permanent pointer to the base address for the LEDs, allowing for intricate control of the LED display.
- 🔘 **FIO2PIN1 Register:** Integral for button press detection, enabling the reflex testing mechanism.
- 📊 **RandomNum Function:** Generates random numbers to create diverse and challenging reflex scenarios.
- ⏱ **DELAY Function:** Precisely calibrated to ensure accurate timing for reflex measurements.

## How It Works
1. **Initialization:** The system initializes and turns off all LEDs to start the game.
2. **Main Loop:** A loop that handles the random number generation, LED control, and button press detection.
3. **LED Control:** Displays numbers and patterns on LEDs based on the player's performance.
4. **Reflex Testing:** Measures the time between LED changes and button presses to calculate reflexes.
