"""
Poetry scripts, defined in pyproject.toml
"""

import os
import subprocess
import sys

import pytest

FILE_ABS_PATH: str = __file__
PROJECT_ABS_PATH: str = os.path.dirname(os.path.dirname(FILE_ABS_PATH))


def run_tests() -> None:
    """
    Run pytest tests
    """

    sys.exit(pytest.main(["-v"]))


def run_format() -> None:
    """
    Run black code formatter
    """

    proc = subprocess.run(
        ["black", "."],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=PROJECT_ABS_PATH,
        check=False,
    )

    print(proc.stdout.decode())
    print(proc.stderr.decode())


def run_lint() -> None:
    """
    Run pylint
    """

    proc_main = subprocess.run(
        ["pylint ftl_msa_rmq_out/**"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=PROJECT_ABS_PATH,
        check=False,
        shell=True,
    )
    proc_tests = subprocess.run(
        ["pylint tests/**"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=PROJECT_ABS_PATH,
        check=False,
        shell=True,
    )

    print(proc_main.stdout.decode())
    print(proc_main.stderr.decode())
    print(proc_tests.stdout.decode())
    print(proc_tests.stderr.decode())
