"""Stub dateutil.parser for testing vendor package bundling."""
from datetime import datetime


def parse(s):
    return datetime.fromisoformat(s)
