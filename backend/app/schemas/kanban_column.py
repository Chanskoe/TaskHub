from pydantic import BaseModel, ConfigDict
from uuid import UUID

class KanbanColumnBase(BaseModel):
    title: str
    order: int = 0

class KanbanColumnCreate(KanbanColumnBase):
    desk_id: UUID

class KanbanColumnUpdate(BaseModel):
    title: str | None = None
    order: int | None = None

class KanbanColumnResponse(KanbanColumnBase):
    id: UUID
    desk_id: UUID
    model_config = ConfigDict(from_attributes=True)