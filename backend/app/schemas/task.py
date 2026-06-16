from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime
from typing import Optional, List
from app.models.enums import EDifficulty, EImportance
from app.schemas.user import UserResponse

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    isCompleted: bool = False
    end_date_time: Optional[datetime] = None
    runtime: Optional[int] = None
    importance: Optional[EImportance] = None
    difficulty: Optional[EDifficulty] = None
    id_of_desk: Optional[UUID] = None
    kanban_column_id: Optional[UUID] = None

class TaskCreate(TaskBase):
    id_of_members: List[UUID] = []

class TaskResponse(TaskBase):
    id: UUID
    registration_date_time: datetime
    members: List[UserResponse] = []

    model_config = ConfigDict(from_attributes=True)