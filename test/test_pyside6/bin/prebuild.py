"""Pre-build script: generates build_info.py with build metadata."""
import uuid
import datetime
from pathlib import Path

out = Path(__file__).parent.parent / "myapp" / "build_info.py"
out.write_text(
    f'BUILD_UUID = "{uuid.uuid4()}"\n'
    f'BUILD_DATE = "{datetime.datetime.now(datetime.timezone.utc).isoformat()}"\n'
)
print(f"Generated {out}")
