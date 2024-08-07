FROM python:3.10-slim AS base

COPY . /app
WORKDIR /app
# RUN pip install -r requirements.txt
RUN pip install ipython sqlalchemy pydantic pydantic_settings psycopg2-binary PyMySQL

# dummy placeholder to just keep the docker container from exiting
ENTRYPOINT tail -f /dev/null
