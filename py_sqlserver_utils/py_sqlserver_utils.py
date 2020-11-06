import logging
from sqlalchemy import create_engine
from sqlalchemy import types
from sqlalchemy.engine import reflection

LOG_FORMAT = '[%(asctime)s] %(levelname)s %(filename)s line:%(lineno)d\t- %(message)s'
logging.basicConfig(format=LOG_FORMAT, level=logging.INFO)
logging.getLogger('py_sqlserver_utils')


class Sqlserver(object):
    """
    Sqlserver object
    """

    def __init__(self, conn_uri=None):
        self.conn_uri = conn_uri if conn_uri else os.getenv(
            'PYSQLSERVERUTILS_CONN_URI')
        self.engine = create_engine(conn_uri)
        logging.info('Connected')

    def get_databases(self):
        pass
