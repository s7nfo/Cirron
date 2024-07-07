from setuptools import setup, find_packages

# Read the contents of README
from pathlib import Path

long_description = (Path(__file__).parent / "README.md").read_text()

setup(
    name="Cirron",
    version="0.3",
    packages=find_packages(),
    package_data={
        "cirron": ["cirronlib.cpp", "apple_arm_events.h", "tracer.py", "cirron.py"],
    },
    author="Matt Stuchlik",
    author_email="matej.stuchlik@gmail.com",
    description="Cirron measures how many CPU instructions and system calls a piece of Python code executes.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/s7nfo/Cirron",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)
