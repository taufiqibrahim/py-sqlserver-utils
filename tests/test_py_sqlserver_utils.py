#!/usr/bin/env python

"""Tests for `py_sqlserver_utils` package."""

import os
import unittest

from py_sqlserver_utils import py_sqlserver_utils


class Test(unittest.TestCase):
    """Tests for `py_sqlserver_utils` package."""

    def setUp(self):
        """Set up test fixtures, if any."""

    def tearDown(self):
        """Tear down test fixtures, if any."""

    def test_1_initialize(self):
        """Test SQL Server connection."""
        sqlserver = py_sqlserver_utils.Sqlserver(conn_uri=os.getenv('PYSQLSERVERUTILS_CONN_URI'))

    def test_2_get_stored_procedure_tagging(self):
        """Test SQL Server parse stored procedures tagging metadata"""
        sqlserver = py_sqlserver_utils.Sqlserver(conn_uri=os.getenv('PYSQLSERVERUTILS_CONN_URI'))
        sqlserver.parse_stored_procedure_tagging()

if __name__ == "__main__":
    t = Test()
