from setuptools import setup, find_packages

setup(
    name="gatekeeper",
    version="0.1.0",
    author="Hayes Barber",
    packages=find_packages(include=["app*", "gk*"]),
    entry_points={
        "console_scripts": [
            "gk=gk.main:main",
        ],
    },
)
