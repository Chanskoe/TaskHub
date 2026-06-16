from pydantic import BaseModel, ConfigDict
from uuid import UUID
from typing import List
from app.schemas.user import UserResponse

class DeskBase(BaseModel):
    title: str
    id_of_admin: UUID

class DeskCreate(DeskBase):
    pass

class DeskResponse(DeskBase):
    id: UUID
    members: List[UserResponse] = []

    model_config = ConfigDict(from_attributes=True)