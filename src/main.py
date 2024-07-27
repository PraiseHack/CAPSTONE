from dbmanager import start_postgres_connection, query_database

conn = start_postgres_connection()
query = """
    SELECT *
    FROM ALT_CAP.OLIST_ORDER_REVIEWS
    limit 5;
"""

result = query_database(connection=conn, query_str=query)

print(result)
