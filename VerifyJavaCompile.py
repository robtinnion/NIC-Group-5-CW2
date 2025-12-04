import subprocess
import os

src_dir = "gecco19-thief/src/main/java"

# Compile all Java files
java_files = []
for root, dirs, files in os.walk(src_dir):
    for file in files:
        if file.endswith(".java"):
            java_files.append(os.path.join(root, file))
subprocess.run(["javac"] + java_files, check=True)

# Run Verify
result = subprocess.run(["java", "-cp", src_dir, "Verify"], capture_output=True, text=True)
print(result.stdout)
print(result.stderr)