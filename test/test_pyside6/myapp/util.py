"""Utility functions for the demo app."""
import sys
import os


def appInfo():
    from myapp.build_info import BUILD_UUID, BUILD_DATE
    return {
        "python": sys.version.split()[0],
        "platform": sys.platform,
        "build_uuid": BUILD_UUID[:8],
        "build_date": BUILD_DATE[:10],
    }
