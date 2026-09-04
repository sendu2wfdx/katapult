#ifndef __GD32E23X_INTERNAL_H
#define __GD32E23X_INTERNAL_H
#include "autoconf.h"
#include "gd32e23x.h"
#define GPIO(PORT, NUM) (((PORT) - 'A') * 16 + (NUM))
#define GPIO2PORT(PIN) ((PIN) / 16)
#define GPIO2BIT(PIN) (1U << ((PIN) % 16))
void enable_pclock(uint32_t pclk);
uint32_t get_pclock_frequency(uint32_t periph_base);
void gpio_peripheral(uint32_t gpio, uint32_t af, int pullup);
#endif
