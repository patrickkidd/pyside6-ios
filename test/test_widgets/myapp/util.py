import sys
import uuid
from datetime import datetime


def appInfo():
    return {
        "python": sys.version.split()[0],
        "platform": sys.platform,
        "build_uuid": str(uuid.uuid4())[:8],
        "build_date": datetime.now().strftime("%Y-%m-%d"),
    }
