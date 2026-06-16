from sqlalchemy import Table, Column, ForeignKey, String
from app.database import Base

desk_members = Table(
    "desk_members",
    Base.metadata,
    Column("desk_id", String(36), ForeignKey("desks.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id", String(36), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
)

task_members = Table(
    "task_members",
    Base.metadata,
    Column("task_id", String(36), ForeignKey("tasks.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id", String(36), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
)