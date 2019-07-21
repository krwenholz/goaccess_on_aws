import logging
import sys

import structlog
from pythonjsonlogger import jsonlogger


def configure_logging(environment="development"):
    """
  Configures logging handlers such that `development` gets pretty tab formatted logs and anything
  else gets JSON logs. We only log to STDOUT.
  Args:
    environment: A string (`development` or otherwise) used to determine logging type.
  """
    # Use structlog for nice logs
    shared_processors = [
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_log_level_number,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="%Y-%m-%d %H:%M:%S"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
    ]

    structlog.configure(
        processors=shared_processors + [structlog.stdlib.ProcessorFormatter.wrap_for_formatter],
        context_class=structlog.threadlocal.wrap_dict(dict),
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    # Configure standard logging for imported libraries and be sure to get any already
    # initialized handlers
    if environment != "development":
        processor = structlog.processors.JSONRenderer(sort_keys=True)
    else:
        processor = structlog.dev.ConsoleRenderer()
    formatter = structlog.stdlib.ProcessorFormatter(processor=processor, foreign_pre_chain=shared_processors)

    root_logger = logging.getLogger()
    if root_logger.hasHandlers():
        root_logger.handlers[0].setFormatter(formatter)
    else:
        handler = logging.StreamHandler()
        handler.setFormatter(formatter)
        root_logger.addHandler(handler)

    root_logger.setLevel(logging.WARNING)
    # And then logging for just us
    logging.getLogger("app").setLevel(logging.DEBUG)
