#ifndef __GD32E23X_FLASH_H
#define __GD32E23X_FLASH_H
#include <stdint.h>
int flash_write_block(uint32_t block_address, uint32_t *data);
int flash_complete(void);
#endif
