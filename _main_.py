from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.sql import text

from settings import settings

engine = create_engine(settings.postgres.url)

with engine.connect() as conn:
    print(settings.postgres.host)
    print("Aloha!", "\n=============================")
    query = text("SELECT * FROM imports WHERE created_at > '2024-08-07' LIMIT 30;")
    res = conn.execute(query)
    for data in res:
    	print(data[0], data[2], data[3], data[4], data[5])
