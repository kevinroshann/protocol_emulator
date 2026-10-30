; uart_tx.asm - Transmit ASCII 'A' over Pin 0
DIR_PIN   0, 1         ; Set Pin 0 as Output
SET_PIN   0, 1         ; Idle Line High
WAIT_CYC  5

LOAD_IMM  SR, 0x41     ; Load ASCII 'A'
LOAD_IMM  CTR, 8       ; Set 8 bits loop counter

SET_PIN   0, 0         ; START Bit
WAIT_CYC  5

tx_loop:
OUT_SHIFT 0, LSB       ; Shift out 1 bit LSB first
WAIT_CYC  5
JUMP_NZ   tx_loop      ; Loop 8 times

SET_PIN   0, 1         ; STOP Bit
WAIT_CYC  10