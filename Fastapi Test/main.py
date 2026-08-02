import os
import pyodbc
import pandas as pd
import numpy as np
from sqlalchemy import create_engine
import urllib

# conn = pyodbc.connect(
#     "DRIVER={SQL Server};"
#     "SERVER=localhost,1433;"          # or SERVER=host,1433
#     "DATABASE=IDLC;"
#     "UID=sa;"
#     "PWD=IDLC@Str0ngPass;"
#     "TrustServerCertificate=yes;"  # skip if you have a valid cert
# )
 

# params = urllib.parse.quote_plus(connection_string)
# engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

# query = "SELECT * FROM your_table_name"
# df = pd.read_sql_query(query, con=engine)

# sql = "SELECT TOP 5 * FROM [dbo].[data]"

# data = pd.read_sql(sql, conn)

# print(data.head(5))  

# conn.close()


server = 'localhost,1433'
database = 'IDLC'
username = 'sa'
password = 'IDLC@Str0ngPass'
driver = '{SQL Server}'

connection_string = (
    f"DRIVER={driver};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
)

params = urllib.parse.quote_plus(connection_string)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

query = "SELECT TOP 5 * FROM [dbo].[data]"
df = pd.read_sql_query(query, con=engine)
print(df.head(5))  