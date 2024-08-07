import pathlib
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict

ENV_FILE = (pathlib.Path('.') / '.env').absolute()


class BaseEnvSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=ENV_FILE, env_file_encoding='utf-8', extra='ignore')


class AppSettings(BaseEnvSettings):
    max_pool_size: int = Field(5, alias='POOL_SIZE')
    debug: bool = Field(True, alias='DEBUG')


class PostgresSettings(BaseEnvSettings):
    host: str = Field('localhost', alias='PG_HOST')
    port: int = Field(5432, alias='PG_PORT')
    db: str = Field('db', alias='PG_DB_NAME')
    user: str = Field('postgres', alias='PG_USER')
    password: str = Field('', alias='PG_USER_PASSWORD')
    pool_size: int = Field(10, alias='PG_POOL_SIZE')
    pool_recycle: int = Field(3600, alias='PG_POOL_RECYCLE')

    @property
    def url(self) -> str:
        return f'postgresql+psycopg2://{self.user}:{self.password}@{self.host}:{self.port}/{self.db}'


class MysqlSettings(BaseEnvSettings):
    host: str = Field('localhost', alias='MYSQL_HOST')
    port: int = Field(3306, alias='MYSQL_PORT')
    db: str = Field('db', alias='MYSQL_DB_NAME')
    user: str = Field('root', alias='MYSQL_USER')
    password: str = Field('', alias='MYSQL_USER_PASSWORD')

    @property
    def url(self) -> str:
        return f'mysql+pymysql://{self.user}:{self.password}@{self.host}:{self.port}/{self.db}'


class Settings(BaseModel):
    app: AppSettings
    postgres: PostgresSettings
    mysql: MysqlSettings


settings = Settings(
    app=AppSettings(),
    postgres=PostgresSettings(),
    mysql=MysqlSettings(),
)
