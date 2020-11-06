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
            con.execute('CREATE TABLE #TabParseStoredProcedureTagging (DatabaseName VARCHAR(300), ObjectId VARCHAR(255), ObjectName VARCHAR(300), String_Tagging NVARCHAR(MAX));')
            con.execute('INSERT INTO #TabParseStoredProcedureTagging EXEC ParseStoredProcedureTagging;')
            rs = con.execute('SELECT * FROM #TabParseStoredProcedureTagging')
            for r in rs:
                print(r[0], r[2])
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