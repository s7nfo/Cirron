from setuptools import setup

setup(
    name="Cirron",
    version="0.1",
    packages=["cirron"],
    package_data={
        "cirron": ["cirronlib.c"],
    },
)
