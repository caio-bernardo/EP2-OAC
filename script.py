import random

# Open file for writing
with open('numbers.txt', 'w') as file:
    # Generate 1000 random numbers between 0 and 500,000
    for _ in range(1000):
        # Generate a random float between 0 and 500,000
        number = random.uniform(0, 5000)
        # Write the number to the file followed by a newline
        file.write(f"{number}\n")

print("File has been created with 1000 random numbers between 0 and 500,000.")
