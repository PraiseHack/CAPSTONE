import psycopg2
from psycopg2 import OperationalError
import os
from dotenv import load_dotenv

load_dotenv()

# connect to postgres DB

def get_pg_creds():
    return {
        "user": os.environ.get("POSTGRES_USER"),
        "password": os.environ.get("POSTGRES_PASSWORD"),
        "host": os.environ.get("POSTGRES_HOST", "localhost"),
        "port": os.environ.get("POSTGRES_PORT", 5433),
        "dbname": os.environ.get("POSTGRES_DBNAME"),
    }

# Function to start a connection to PostgreSQL
def start_postgres_connection():
    creds = get_pg_creds()
    try:
        connection = psycopg2.connect(
            user=creds["user"],
            password=creds["password"],
            host=creds["host"],
            port=creds["port"],
            dbname=creds["dbname"],
        )
        print("Connection to PostgreSQL DB successful")
        return connection
    except OperationalError as e:
        print(f"The error '{e}' occurred")
        return None

# Function to query the database
def query_database(connection, query_str):
    if connection is None:
        print("No connection to the database.")
        return []
    
    try:
        with connection.cursor() as cursor:
            cursor.execute(query_str)
            rows = cursor.fetchall()
        return rows
    except Exception as e:
        print(f"An error occurred: {e}")
        return []
    finally:
        connection.close()
