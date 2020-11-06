from sqlalchemy import create_engine
from sqlalchemy import types
from sqlalchemy.engine import reflection


class Sqlserver(object):
    """
    Sqlserver object
    """
    def __init__(self, conn_uri):
        self.conn_uri = conn_uri
        self.engine = create_engine(conn_uri)

    def get_databases(self):
        pass