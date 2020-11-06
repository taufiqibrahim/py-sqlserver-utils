import logging
import yaml
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

    def parse_stored_procedure_tagging(self):
        data = list()
        with self.engine.connect() as con:
            sql = """
SELECT
DatabaseName,
ObjectId,
ObjectName,
LTRIM(RTRIM(REPLACE(REPLACE(String_Tagging, '__TAGGINGSTART___',''), '___TAGGINGEND___',''))) AS String_Tagging
FROM TblStoreProcedureWithTag WHERE String_Tagging IS NOT NULL
            """
            rs = con.execute(sql)
            for r in rs:
                tags_str = r[3]
                try:
                    tags = yaml.load(tags_str)
                except Exception:
                    print(tags_str)
                    raise

                data.append({
                    "database": r[0],
                    "table_name": r[2],
                    "tags": tags,
                })

        return data