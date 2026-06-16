import uuid
from sqlalchemy import String, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base

class KanbanColumn(Base):
    __tablename__ = "kanban_columns"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    order: Mapped[int] = mapped_column(Integer, default=0)
    desk_id: Mapped[str] = mapped_column(String(36), ForeignKey("desks.id", ondelete="CASCADE"), nullable=False)

    desk = relationship("Desk", back_populates="kanban_columns")
    tasks = relationship("Task", back_populates="kanban_column")