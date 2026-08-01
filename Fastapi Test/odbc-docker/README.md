# IDLC ODBC server (SQL Server on Docker) + RDS loader

Spins up a **Microsoft SQL Server 2022** instance in Docker (the ODBC server your
`helpers.R` connects to) and loads the two tables stored in `../data.RDS` into a
database called **`IDLC`**.

`data.RDS` is a `save.image()` **workspace**, not a single object, and it also
contains non-table objects (a live DB connection, functions). Python RDS readers
choke on those, so a throwaway **R container** loads it and exports the tables to
CSV; the host then loads them over TDS (`pymssql`) — no ODBC driver needed on the
host for loading.

## Prerequisites

- Docker Desktop running
- Python 3 on the host with: `pip install pandas sqlalchemy pymssql`

## One-time setup

```bash
# from the odbc-docker/ folder
# 1) start the ODBC server (SQL Server 2022)
docker compose up -d sqlserver

# 2) export the two tables from data.RDS via a throwaway R container
docker compose run --rm rexport

# 3) create the IDLC database and load both tables
python load_to_sql.py
```

Everything is parameterised in [`.env`](.env) (SA password, DB name, port).

## Connecting

**Server / port:** `localhost,1433`  **User:** `sa`  **Database:** `IDLC`
**Password:** value of `MSSQL_SA_PASSWORD` in `.env`

From R (`DBI` + `odbc`), using the driver that ships with Windows (no install):

```r
con <- DBI::dbConnect(
  odbc::odbc(),
  Driver   = "SQL Server",       # the legacy driver already on the host
  Server   = "localhost,1433",   # host,port together for this driver
  Database = "IDLC",
  UID      = "sa",
  PWD      = "IDLC@Str0ngPass"
)
DBI::dbListTables(con)
```

> **Which driver?** Run `odbc::odbcListDrivers()` to see what's installed.
> The built-in **`SQL Server`** driver works out of the box (verified against
> this container). For a production-matching setup, install Microsoft's
> **ODBC Driver 18 for SQL Server**, then use:
>
> ```r
> Driver = "ODBC Driver 18 for SQL Server", Server = "localhost", Port = 1433,
> TrustServerCertificate = "yes"   # dev cert is self-signed
> ```

Quick check with `sqlcmd` inside the container (no host driver required):

```bash
docker exec -it idlc-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'IDLC@Str0ngPass' -C \
  -Q "SELECT name FROM IDLC.sys.tables"
```

## Tables

The loader creates one SQL table per data.frame found in the workspace, keeping
the original R object names and column names (spaces preserved, e.g.
`[Nature of Suit]`). Column types are restored from `_columns.tsv`:
R `Date` → `DATE`, `POSIXct` → `DATETIME2`, `integer` → `BIGINT`,
`numeric` → `FLOAT`, `logical` → `BIT`, everything else → `NVARCHAR`.

## Managing the server

```bash
docker compose stop sqlserver     # stop (keeps data volume)
docker compose start sqlserver    # start again
docker compose down               # remove container + network (keeps volume)
docker compose down -v            # remove EVERYTHING incl. the data volume
```
