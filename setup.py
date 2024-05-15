from setuptools import setup, find_packages

setup(
    name="Cirron",
    version="0.2",
    packages=find_packages(),
    package_data={
        "cirron": ["cirronlib.cpp", "apple_arm_events.h", "tracer.py", "cirron.py"],
    },
    author="Matt Stuchlik",
    author_email="matej.stuchlik@gmail.com",
    description="Cirron measures how many CPU instructions and system calls a piece of Python code executes.",
    url="https://github.com/s7nfo/Cirron",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)
