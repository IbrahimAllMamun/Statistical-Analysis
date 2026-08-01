"""
Create the target database on the Dockerized SQL Server and load every table
exported by export_rds.R (CSV + _columns.tsv) into it.

Connection details come from environment variables (with sensible defaults that
match ./.env):

    DB_SERVER   (default: localhost)
    DB_PORT     (default: 1433)
    DB_DATABASE (default: IDLC)
    DB_UID      (default: sa)
    DB_PWD      (default: IDLC@Str0ngPass)
    EXPORT_DIR  (default: ./export next to this script)

Loading goes over the TDS protocol via pymssql, so no ODBC driver needs to be
installed on the host. The SQL Server itself is, of course, ODBC-accessible.
"""
import os
import glob
import sys

import pandas as pd
import sqlalchemy as sa
from sqlalchemy import types as st
from sqlalchemy.dialects import mssql

HERE = os.path.dirname(os.path.abspath(__file__))

SERVER = os.environ.get("DB_SERVER", "localhost")
PORT = int(os.environ.get("DB_PORT", "1433"))
DB = os.environ.get("DB_DATABASE", "IDLC")
UID = os.environ.get("DB_UID", "sa")
PWD = os.environ.get("DB_PWD", os.environ.get("MSSQL_SA_PASSWORD", "IDLC@Str0ngPass"))
EXPORT_DIR = os.environ.get("EXPORT_DIR", os.path.join(HERE, "export"))


def make_url(database: str) -> sa.engine.URL:
    return sa.engine.URL.create(
        "mssql+pymssql",
        username=UID,
        password=PWD,
        host=SERVER,
        port=PORT,
        database=database,
    )


def rclass_to_kind(rclass: str) -> str:
    rc = (rclass or "").lower()
    if "posixct" in rc or "posixt" in rc:
        return "datetime"
    if "date" in rc:
        return "date"
    if rc == "integer":
        return "int"
    if rc in ("numeric", "double"):
        return "float"
    if rc == "logical":
        return "bool"
    return "str"


def coerce_column(s: pd.Series, kind: str):
    if kind == "date":
        return pd.to_datetime(s, format="%Y-%m-%d", errors="coerce")
    if kind == "datetime":
        return pd.to_datetime(s, errors="coerce")
    if kind == "int":
        return pd.to_numeric(s, errors="coerce").astype("Int64")
    if kind == "float":
        return pd.to_numeric(s, errors="coerce")
    if kind == "bool":
        m = {"TRUE": True, "FALSE": False, "T": True, "F": False,
             "true": True, "false": False}
        return s.map(lambda v: m.get(v, pd.NA)).astype("boolean")
    # str: keep as object, blank -> None so it lands as SQL NULL
    return s.where(s.notna(), None)


def sa_type_for(kind: str, series: pd.Series):
    if kind == "date":
        return st.Date()
    if kind == "datetime":
        return mssql.DATETIME2()
    if kind == "int":
        return st.BigInteger()
    if kind == "float":
        return st.Float()
    if kind == "bool":
        return st.Boolean()  # -> BIT
    # str: size to the widest value (in chars), NVARCHAR(MAX) if very wide
    lengths = series.dropna().astype(str).map(len)
    maxlen = int(lengths.max()) if not lengths.empty else 1
    if maxlen > 4000:
        return mssql.NVARCHAR(None)  # NVARCHAR(MAX)
    # round up with head-room, min 10
    size = max(10, min(4000, ((maxlen // 50) + 1) * 50))
    return mssql.NVARCHAR(length=size)


def ensure_database():
    """Create the target database if it does not already exist."""
    master = sa.create_engine(make_url("master"), isolation_level="AUTOCOMMIT")
    with master.connect() as conn:
        exists = conn.execute(
            sa.text("SELECT DB_ID(:n)"), {"n": DB}
        ).scalar()
        if exists is None:
            conn.execute(sa.text(f"CREATE DATABASE [{DB}]"))
            print(f"[db] created database [{DB}]")
        else:
            print(f"[db] database [{DB}] already exists")
    master.dispose()


def load_all():
    meta_path = os.path.join(EXPORT_DIR, "_columns.tsv")
    if not os.path.exists(meta_path):
        sys.exit(f"ERROR: {meta_path} not found. Run the rexport step first.")
    meta = pd.read_csv(meta_path, sep="\t", dtype=str)

    engine = sa.create_engine(make_url(DB))

    csvs = sorted(glob.glob(os.path.join(EXPORT_DIR, "*.csv")))
    if not csvs:
        sys.exit(f"ERROR: no CSV files in {EXPORT_DIR}")

    summary = []
    for csv in csvs:
        table = os.path.splitext(os.path.basename(csv))[0]
        tmeta = meta[meta["table"] == table]
        kinds = dict(zip(tmeta["column"], tmeta["rclass"].map(rclass_to_kind)))

        df = pd.read_csv(csv, dtype=str, keep_default_na=False,
                         na_values=[""], encoding="utf-8")

        dtype_map = {}
        for col in df.columns:
            kind = kinds.get(col, "str")
            df[col] = coerce_column(df[col], kind)
            dtype_map[col] = sa_type_for(kind, df[col])

        ncols = max(1, len(df.columns))
        chunksize = max(1, 2000 // ncols)  # stay under SQL Server's 2100 params

        df.to_sql(table, engine, schema="dbo", if_exists="replace",
                  index=False, dtype=dtype_map, chunksize=chunksize,
                  method="multi")
        print(f"[load] [dbo].[{table}] <- {len(df)} rows, {len(df.columns)} cols")
        summary.append((table, len(df), len(df.columns)))

    # Verify row counts from the server side.
    print("\n[verify] server-side row counts:")
    with engine.connect() as conn:
        for table, _, _ in summary:
            n = conn.execute(
                sa.text(f"SELECT COUNT(*) FROM [dbo].[{table}]")
            ).scalar()
            print(f"    [dbo].[{table}] = {n} rows")
    engine.dispose()
    return summary


if __name__ == "__main__":
    print(f"[cfg] server={SERVER}:{PORT} db={DB} uid={UID} export_dir={EXPORT_DIR}")
    ensure_database()
    load_all()
    print("\nAll done.")
