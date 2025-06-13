import random

# Open file for writing
with open('numbers.txt', 'w') as file:
    n = 1_000
    a = -100_000_000.0
    b = 100_000_000.0
    # Generate 1000 random numbers between 0 and 500,000
    for _ in range(n):
        # Generate a random float between 0 and 500,000
        number = random.uniform(a, b)
        # Write the number to the file followed by a newline
        file.write(f"{number}\n")

print(f"File has been created with {n} random numbers between {a} and {b}")
