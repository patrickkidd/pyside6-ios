__version__ = "6.8.3"
__version_info__ = (6, 8, 3, "", "")
__minimum_python_version__ = None
__maximum_python_version__ = None

# Pre-load modules needed by shiboken's signature bootstrap system.
# These must be imported before shiboken6.Shiboken triggers the bootstrap,
# because the bootstrap runs inside the Shiboken module init and cannot
# reliably import .so modules (zipfile->zlib, struct, etc.) at that point.
import sys
import os
import zipfile
import base64
import io
import contextlib
import textwrap
import traceback
import types
import struct
import re
import functools
import typing

from shiboken6.Shiboken import *
