import uuid
from datetime import datetime
from typing import Optional
from sqlalchemy import String, DateTime, Integer, Enum, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
from app.models.enums import EDifficulty, EImportance
from app.models.associations import task_members
from app.models.kanban_column import KanbanColumn

class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)
    isCompleted: Mapped[bool] = mapped_column(Boolean, default=False)
    
    end_date_time: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    registration_date_time: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    runtime: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    
    importance: Mapped[Optional[EImportance]] = mapped_column(Enum(EImportance), nullable=True)
    difficulty: Mapped[Optional[EDifficulty]] = mapped_column(Enum(EDifficulty), nullable=True)
    
    id_of_creator: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    id_of_desk: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("desks.id", ondelete="CASCADE"), nullable=True)
    kanban_column_id: Mapped[Optional[str]] = mapped_column(String(36), ForeignKey("kanban_columns.id", ondelete="SET NULL"), nullable=True)

    desk = relationship("Desk", back_populates="tasks")
    kanban_column = relationship("KanbanColumn", back_populates="tasks")
    members: Mapped[list["User"]] = relationship( "User", secondary=task_members, lazy="selectin")
    comments: Mapped[list["Comment"]] = relationship("Comment", back_populates="task", cascade="all, delete-orphan", lazy="selectin", order_by="Comment.registration_date_time.asc()")