import json
from datetime import datetime, timedelta
from typing import List
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload, joinedload
from sqlalchemy import or_, delete

from app.database import async_session
from app.models.task import Task
from app.models.desk import Desk
from app.models.comment import Comment
from app.models.user import User
from app.services.websocket import manager
from app.models.enums import EDifficulty, EImportance
from app.models.kanban_column import KanbanColumn
from app.models.associations import desk_members

router = APIRouter(
    prefix="/ws",
    tags=["WebSockets"]
)

def get_current_week_days() -> List[tuple]:
    now = datetime.now()
    days_ru = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
    
    week_structure = []
    for i in range(7):
        day_date = now + timedelta(days=i)
        day_title = f"{days_ru[day_date.weekday()]}, {day_date.strftime('%d.%m')}"
        week_structure.append((day_title, day_date.date()))
    return week_structure


async def get_user_state(user_id: str, db: AsyncSession) -> dict:
    from app.models.associations import desk_members

    desk_subquery = select(Desk.id).where(
        or_(
            Desk.id_of_admin == user_id,
            Desk.id.in_(select(desk_members.c.desk_id).where(desk_members.c.user_id == user_id))
        )
    )

    query = select(Task).where(
        or_(
            Task.id_of_creator == user_id,
            Task.id_of_desk.in_(desk_subquery)
        )
    ).options(
        selectinload(Task.members),
        selectinload(Task.comments).joinedload(Comment.member)
    )

    result = await db.execute(query)
    all_tasks = list(result.scalars().all())
    all_tasks.sort(key=lambda x: x.end_date_time if x.end_date_time else datetime.max)

    week_days = get_current_week_days()
    state = {day[0]: [] for day in week_days}
    first_day_title = week_days[0][0]

    for task in all_tasks:
        task_data = {
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "isCompleted": task.isCompleted,
            "end_date_time": task.end_date_time.isoformat() if task.end_date_time else None,
            "registration_date_time": task.registration_date_time.isoformat(),
            "runtime": task.runtime,
            "importance": task.importance.name if task.importance else None,
            "difficulty": task.difficulty.name if task.difficulty else None,
            "id_of_creator": task.id_of_creator,
            "id_of_desk": task.id_of_desk,
            "id_of_members": [m.id for m in task.members],
            "kanban_column_id": task.kanban_column_id,
            "comments": [
                {
                    "id": c.id,
                    "text": c.text,
                    "registration_date_time": c.registration_date_time.isoformat(),
                    "id_of_member": c.id_of_member,
                    "id_of_task": c.id_of_task,
                    "user_nickname": c.member.nickname if c.member else "Пользователь"
                } for c in task.comments
            ]
        }
        
        if not task.end_date_time:
            state[first_day_title].append(task_data)
        else:
            task_date = task.end_date_time.date()
            matched = False
            for day_title, day_date in week_days:
                if task_date == day_date:
                    state[day_title].append(task_data)
                    matched = True
                    break
            if not matched:
                state[first_day_title].append(task_data)

    desk_result = await db.execute(
        select(Desk)
        .where(
            or_(
                Desk.id_of_admin == user_id,
                Desk.id.in_(select(desk_members.c.desk_id).where(desk_members.c.user_id == user_id))
            )
        )
        .options(
            selectinload(Desk.members),
            joinedload(Desk.admin),
            selectinload(Desk.kanban_columns)
        )
        .order_by(Desk.title.asc())
    )
    all_desks = desk_result.scalars().all()

    desks_data = []
    for desk in all_desks:
        members_list = []
        if desk.members:
            members_list = [{"id": m.id, "nickname": m.nickname} for m in desk.members]
        if not any(m["id"] == str(desk.id_of_admin) for m in members_list) and desk.admin:
            members_list.append({"id": str(desk.id_of_admin), "nickname": desk.admin.nickname})

        kanban_columns = [
            {"id": c.id, "title": c.title, "order": c.order}
            for c in desk.kanban_columns
        ]

        desks_data.append({
            "id": str(desk.id),
            "title": desk.title,
            "id_of_admin": str(desk.id_of_admin),
            "members": members_list,
            "kanban_columns": kanban_columns,
        })
                
    return {"view": "Неделя", "tasks": state, "desks": desks_data}


@router.websocket("/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(user_id, websocket)
    async with async_session() as db:
        init_state = await get_user_state(user_id, db)
        await websocket.send_text(json.dumps(init_state, default=str))
        
        try:
            while True:
                data = await websocket.receive_text()
                event = json.loads(data)
                action = event.get("action")
                
                if action == "create_task":
                    end_date = datetime.fromisoformat(event["end_date_time"]) if event.get("end_date_time") else None
                    new_task = Task(
                        title=event["title"],
                        end_date_time=end_date,
                        id_of_desk=event.get("id_of_desk"),
                        id_of_creator=user_id,
                        isCompleted=False
                    )
                    db.add(new_task)

                    if "kanban_column_id" in event:
                        col_name = event["kanban_column_title"]
                        if col_name:
                            desk_id = event.get("id_of_desk")
                            stmt = select(KanbanColumn).where(
                                KanbanColumn.desk_id == desk_id,
                                KanbanColumn.title == col_name
                            )
                            res = await db.execute(stmt)
                            col = res.scalar_one_or_none()
                            if col:
                                new_task.kanban_column_id = col.id
                            else:
                                new_col = KanbanColumn(title=col_name, desk_id=desk_id, order=0)
                                db.add(new_col)
                                await db.flush()
                                new_task.kanban_column_id = new_col.id
                        else:
                            new_task.kanban_column_id = None
                    await db.commit()

                elif action == "update_task":
                    task_id = event.get("id")
                    res = await db.execute(select(Task).where(Task.id == task_id))
                    task = res.scalar_one_or_none()
                    if task:
                        if "title" in event: task.title = event["title"]
                        if "description" in event: task.description = event["description"]
                        if "isCompleted" in event: task.isCompleted = event["isCompleted"]
                        if "runtime" in event: task.runtime = event["runtime"]
                        
                        if "importance" in event:
                            task.importance = EImportance[event["importance"]] if event["importance"] else None
                        if "difficulty" in event:
                            task.difficulty = EDifficulty[event["difficulty"]] if event["difficulty"] else None
                            
                        if "id_of_desk" in event:
                            task.id_of_desk = event["id_of_desk"]
                            
                        if "end_date_time" in event:
                            task.end_date_time = datetime.fromisoformat(event["end_date_time"]) if event["end_date_time"] else None
                        
                        if "id_of_members" in event:
                            task.members.clear()
                            for m_id in event["id_of_members"]:
                                u_res = await db.execute(select(User).where(User.id == m_id))
                                u = u_res.scalar_one_or_none()
                                if u: task.members.append(u)

                        if "kanban_column_id" in event:
                            task.kanban_column_id = event["kanban_column_id"]
                        elif "kanban_column_id" in event and event["kanban_column_id"] is None:
                            task.kanban_column_id = None

                        await db.commit()
                    
                elif action == "delete_task":
                    task_id = event.get("id")
                    res = await db.execute(select(Task).where(Task.id == task_id))
                    task_to_del = res.scalar_one_or_none()
                    if task_to_del:
                        await db.delete(task_to_del)
                        await db.commit()

                elif action == "add_comment":
                    new_comment = Comment(
                        text=event["text"],
                        id_of_task=event["id_of_task"],
                        id_of_member=user_id
                    )
                    db.add(new_comment)
                    await db.commit()

                elif action == "delete_comment":
                    comment_id = event.get("id")
                    res = await db.execute(select(Comment).where(Comment.id == comment_id))
                    comment_to_del = res.scalar_one_or_none()
                    if comment_to_del:
                        await db.delete(comment_to_del)
                        await db.commit()

                elif action == "create_desk":
                    new_desk = Desk(
                        title=event["title"],
                        id_of_admin=user_id
                    )
                    db.add(new_desk)
                    await db.commit()

                elif action == "rename_desk":
                    desk_id = event.get("desk_id")
                    new_title = event.get("title")
                    if desk_id and new_title:
                        res = await db.execute(select(Desk).where(Desk.id == desk_id))
                        desk = res.scalar_one_or_none()
                        if desk:
                            desk.title = new_title
                            await db.commit()

                elif action == "delete_desk":
                    desk_id = event.get("desk_id")
                    if desk_id:
                        await db.execute(delete(desk_members).where(desk_members.c.desk_id == desk_id))
                        res = await db.execute(select(Desk).where(Desk.id == desk_id))
                        desk = res.scalar_one_or_none()
                        if desk:
                            await db.delete(desk)
                            await db.commit()

                elif action == "add_desk_member":
                    desk_id = event.get("desk_id")
                    user_id_to_add = event.get("user_id")
                    if desk_id and user_id_to_add:
                        check = await db.execute(
                            select(desk_members).where(
                                (desk_members.c.desk_id == desk_id) & (desk_members.c.user_id == user_id_to_add)
                            )
                        )
                        if check.first() is None:
                            ins = desk_members.insert().values(desk_id=desk_id, user_id=user_id_to_add)
                            await db.execute(ins)
                            await db.commit()

                elif action == "remove_desk_member":
                    desk_id = event.get("desk_id")
                    user_id_to_remove = event.get("user_id")
                    if desk_id and user_id_to_remove:
                        desk_res = await db.execute(select(Desk).where(Desk.id == desk_id))
                        desk = desk_res.scalar_one_or_none()
                        if desk and desk.id_of_admin != user_id_to_remove:
                            await db.execute(
                                desk_members.delete().where(
                                    (desk_members.c.desk_id == desk_id) & (desk_members.c.user_id == user_id_to_remove)
                                )
                            )
                            await db.commit()

                elif action == "search_users":
                    query = event.get("query", "")
                    if len(query) < 1:
                        await websocket.send_text(json.dumps({"action": "search_users_result", "users": []}))
                    else:
                        stmt = select(User).where(User.nickname.contains(query)).limit(20)
                        result = await db.execute(stmt)
                        users = result.scalars().all()
                        users_data = [{"id": u.id, "nickname": u.nickname} for u in users]
                        await websocket.send_text(json.dumps({"action": "search_users_result", "users": users_data}))

                elif action == "create_kanban_column":
                    desk_id = event.get("desk_id")
                    title = event.get("title")
                    if desk_id and title:
                        stmt = select(KanbanColumn).where(KanbanColumn.desk_id == desk_id)
                        result = await db.execute(stmt)
                        columns = result.scalars().all()
                        max_order = max([c.order for c in columns], default=-1) + 1
                        new_col = KanbanColumn(title=title, desk_id=desk_id, order=max_order)
                        db.add(new_col)
                        await db.commit()

                elif action == "update_kanban_column":
                    col_id = event.get("id")
                    new_title = event.get("title")
                    if col_id and new_title:
                        res = await db.execute(select(KanbanColumn).where(KanbanColumn.id == col_id))
                        col = res.scalar_one_or_none()
                        if col:
                            col.title = new_title
                            await db.commit()

                elif action == "delete_kanban_column":
                    col_id = event.get("id")
                    if col_id:
                        res = await db.execute(select(KanbanColumn).where(KanbanColumn.id == col_id))
                        col = res.scalar_one_or_none()
                        if col:
                            for task in col.tasks:
                                task.kanban_column_id = None
                            await db.delete(col)
                            await db.commit()

                elif action == "reorder_kanban_columns":
                    columns_order = event.get("columns", [])
                    for item in columns_order:
                        col_id = item.get("id")
                        new_order = item.get("order")
                        if col_id is not None and new_order is not None:
                            res = await db.execute(select(KanbanColumn).where(KanbanColumn.id == col_id))
                            col = res.scalar_one_or_none()
                            if col:
                                col.order = new_order
                    await db.commit()

                db.expire_all()

                updated_state = await get_user_state(user_id, db)
                await manager.broadcast_to_user(user_id, updated_state)
                
        except WebSocketDisconnect:
            manager.disconnect(user_id, websocket)