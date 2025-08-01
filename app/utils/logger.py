from datetime import datetime
from zoneinfo import ZoneInfo

class LOGGER:
    @staticmethod
    def _format_prefix() -> str:
        now = datetime.now(ZoneInfo("America/New_York"))
        formatted = now.strftime("[%a, %b %d %I:%M:%S %p]")
        return formatted

    @classmethod
    def log(cls, message: str, level: str = None) -> None:
        prefix = cls._format_prefix()
        level_str = f" [{level.upper()}]" if level else ""
        print(f"{prefix}{level_str} {message}")

    @classmethod
    def info(cls, message: str) -> None:
        cls.log(message, level="info")

    @classmethod
    def warn(cls, message: str) -> None:
        cls.log(message, level="warn")

    @classmethod
    def error(cls, message: str) -> None:
        cls.log(message, level="error")
