import uuid
from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
from app.models.desk import Desk

class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    nickname: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    email: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    password: Mapped[str] = mapped_column(String(255), nullable=False) # Будем хранить хэш

    desks: Mapped[list["Desk"]] = relationship(
        "Desk", 
        secondary="desk_members", 
        back_populates="members"
    )

    comments: Mapped[list["Comment"]] = relationship("Comment", back_populates="member", cascade="all, delete-orphan")