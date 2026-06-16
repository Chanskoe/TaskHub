from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime

class CommentBase(BaseModel):
    text: str
    id_of_member: UUID
    id_of_task: UUID

class CommentCreate(CommentBase):
    pass

class CommentResponse(CommentBase):
    id: UUID
    registration_date_time: datetime

    model_config = ConfigDict(from_attributes=True)