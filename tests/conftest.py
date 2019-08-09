import os
import sys
from glob import glob
import pytest


root_dir = os.path.dirname(os.path.abspath(__file__)) + '/../'
os.chdir(root_dir)

@pytest.fixture(scope="session")
def rootDir():
    return root_dir
