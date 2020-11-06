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

    def test_initialize(self):
        """Test something."""
        self.sqlserver = py_sqlserver_utils.Sqlserver(conn_uri=)

if __name__ == "__main__":
    test = Test()

