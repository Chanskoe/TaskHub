import uuid
from sqlalchemy import String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
from app.models.associations import desk_members
from app.models.task import Task
from app.models.kanban_column import KanbanColumn

class Desk(Base):
    __tablename__ = "desks"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    id_of_admin: Mapped[str] = mapped_column(String(36), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)

    admin = relationship("User", foreign_keys=[id_of_admin])
    members: Mapped[list["User"]] = relationship(
        "User", 
        secondary=desk_members, 
        back_populates="desks"
    )
    tasks: Mapped[list["Task"]] = relationship("Task", back_populates="desk", cascade="all, delete-orphan")
    kanban_columns: Mapped[list["KanbanColumn"]] = relationship("KanbanColumn", back_populates="desk", cascade="all, delete-orphan")