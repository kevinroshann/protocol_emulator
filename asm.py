#!/usr/bin/env python3
# asm.py - Protocol Emulator Microcode Assembler

import sys
import re

OPCODES = {
    "SET_PIN":   0x1,
    "DIR_PIN":   0x2,
    "READ_PIN":  0x3,
    "WAIT_CYC":  0x4,
    "WAIT_PIN":  0x5,
    "OUT_SHIFT": 0x6,
    "IN_SHIFT":  0x7,
    "LOAD_IMM":  0x8,
    "JUMP":      0x9,
    "JUMP_NZ":   0x0A,
}

def assemble(asm_filepath, hex_filepath):
    labels = {}
    instructions = []
    
    # Read and strip comments/whitespace
    with open(asm_filepath, 'r') as f:
        raw_lines = f.readlines()

    clean_lines = []
    for line in raw_lines:
        line = line.split(';')[0].strip() # Remove comments
        if line:
            clean_lines.append(line)

    # First Pass: Collect Label Addresses
    pc = 0
    for line in clean_lines:
        if line.endswith(':'):
            label_name = line[:-1].strip()
            labels[label_name] = pc
        else:
            pc += 1

    # Second Pass: Translate Instructions to 16-bit Hex
    pc = 0
    machine_code = []
    for line in clean_lines:
        if line.endswith(':'):
            continue

        parts = re.split(r'[\s,]+', line)
        mnemonic = parts[0].upper()
        args = parts[1:]

        if mnemonic not in OPCODES:
            raise ValueError(f"Unknown opcode '{mnemonic}' at line {line}")

        opcode = OPCODES[mnemonic]
        word = 0

        if mnemonic in ["SET_PIN", "DIR_PIN"]:
            pin = int(args[0]) & 0xF
            val = int(args[1]) & 0x1
            word = (opcode << 12) | (pin << 8) | val

        elif mnemonic == "WAIT_CYC":
            cycles = int(args[0]) & 0xFFF
            word = (opcode << 12) | cycles

        elif mnemonic == "LOAD_IMM":
            # reg 0 = SR, reg 1 = CTR
            reg = 0 if args[0].upper() == "SR" else 1
            val = int(args[1], 0) & 0xFF
            word = (opcode << 12) | (reg << 8) | val

        elif mnemonic in ["OUT_SHIFT", "IN_SHIFT"]:
            pin = int(args[0]) & 0xF
            msb = 1 if len(args) > 1 and args[1].upper() == "MSB" else 0
            word = (opcode << 12) | (pin << 8) | msb

        elif mnemonic == "JUMP":
            target = labels[args[0]] if args[0] in labels else int(args[0], 0)
            word = (opcode << 12) | (target & 0xFF)

        elif mnemonic == "JUMP_NZ":
            target = labels[args[0]] if args[0] in labels else int(args[0], 0)
            word = (opcode << 12) | (target & 0xFF)

        machine_code.append(f"{word:04X}")
        pc += 1


    with open(hex_filepath, 'w') as f:
        for code in machine_code:
            f.write(f"{code}\n")
            
    print(f"Successfully assembled {len(machine_code)} instructions to {hex_filepath}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 asm.py <input.asm> <output.hex>")
    else:
        assemble(sys.argv[1], sys.argv[2])