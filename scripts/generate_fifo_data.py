from pathlib import Path
import random

# Memory Dimensions
WIDTH = 16
DEPTH = 32

# Random Generator
random.seed(42)

# Output File Location
output_file = Path(__file__).resolve().parent.parent / "sim" / "input_data.txt"
output_file.parent.mkdir(parents=True, exist_ok=True)

# Write data in File
with output_file.open("w") as file:
    for i in range(DEPTH):
        data = random.randint(0, (1 << WIDTH) - 1)
        file.write(f"{data:04x}\n")


print(f"Generated {DEPTH} values in {output_file}")
