"""
Database Connection Management
"""
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine
from sqlalchemy.pool import NullPool
import psycopg2
from contextlib import contextmanager

# Primary database (PostgreSQL) - using Flask-SQLAlchemy
db = SQLAlchemy()


class TimescaleDB:
    """TimescaleDB connection manager"""

    def __init__(self, uri=None):
        self.uri = uri
        self.engine = None

    def init_app(self, app):
        """Initialize with Flask app"""
        self.uri = app.config['TIMESCALE_DATABASE_URI']
        self.engine = create_engine(
            self.uri,
            poolclass=NullPool,
            echo=app.config.get('DEBUG', False)
        )

    @contextmanager
    def get_connection(self):
        """Get database connection context manager"""
        if not self.uri:
            raise RuntimeError("TimescaleDB not initialized")

        conn = psycopg2.connect(self.uri)
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def execute(self, query, params=None):
        """Execute a query"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            try:
                return cursor.fetchall()
            except psycopg2.ProgrammingError:
                # No results to fetch (INSERT, UPDATE, DELETE)
                return None

    def execute_one(self, query, params=None):
        """Execute query and return single result"""
        result = self.execute(query, params)
        return result[0] if result else None


# TimescaleDB instance
timescale_db = TimescaleDB()


def init_databases(app):
    """Initialize all database connections"""
    # PostgreSQL (primary)
    db.init_app(app)

    # TimescaleDB
    timescale_db.init_app(app)

    with app.app_context():
        # Create tables if they don't exist
        db.create_all()

    return db, timescale_db
