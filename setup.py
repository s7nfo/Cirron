from setuptools import setup

setup(
    name="Cirron",
    version="0.2",
    packages=["cirron"],
    package_data={
        "cirron": ["cirronlib.c"],
    },
)
