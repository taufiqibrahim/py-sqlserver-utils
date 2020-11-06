"""Top-level package for Python SQL Server Utilities."""

__author__ = """Taufiq Ibrahim"""
__email__ = 'taufiq.ibrahim@gmail.com'
__version__ = '0.1.0'

# Set default logging handler to avoid "No handler found" warnings.
import logging
logging.getLogger('py_sqlserver_utils').addHandler(logging.NullHandler())