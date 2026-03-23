from datetime import datetime
from typing import List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel, Field, create_engine, Session, select
from sqlalchemy import Column
from sqlalchemy.types import JSON


class Appointment(SQLModel, table=True):
    id: str = Field(primary_key=True)
    clientName: str
    serviceId: str
    durationMinutes: int
    dateTime: datetime


class AppointmentCreate(SQLModel):
    id: str
    clientName: str
    serviceId: str
    durationMinutes: int
    dateTime: datetime


class TimeBlock(SQLModel, table=True):
    id: str = Field(primary_key=True)
    title: str
    start: datetime
    end: datetime


class TimeBlockCreate(SQLModel):
    id: str
    title: str
    start: datetime
    end: datetime


class RecurringBlock(SQLModel, table=True):
    id: str = Field(primary_key=True)
    title: str

    weekdays: list[int] = Field(default_factory=list, sa_column=Column(JSON))
    startMinutes: int
    durationMinutes: int
    active: bool = True


class RecurringBlockCreate(SQLModel):
    id: str
    title: str
    weekdays: list[int]
    startMinutes: int
    durationMinutes: int
    active: bool = True


class RecurringBlockActiveUpdate(SQLModel):
    active: bool



DATABASE_URL = "sqlite:///./app.db"
engine = create_engine(DATABASE_URL, echo=False)


def create_db():
    SQLModel.metadata.create_all(engine)


app = FastAPI(title="Turnos API")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    create_db()


@app.get("/appointments", response_model=List[Appointment])
def list_appointments():
    with Session(engine) as session:
        items = session.exec(select(Appointment)).all()
        items.sort(key=lambda x: x.dateTime)
        return items


@app.post("/appointments", response_model=Appointment)
def create_appointment(payload: AppointmentCreate):
    with Session(engine) as session:
        exists = session.get(Appointment, payload.id)
        if exists:
            raise HTTPException(status_code=409, detail="Appointment id already exists")

        # Construimos el modelo DB usando exactamente los mismos campos (camelCase)
        item = Appointment(**payload.model_dump())

        session.add(item)
        session.commit()
        session.refresh(item)
        return item


@app.delete("/appointments/{appointment_id}")
def delete_appointment(appointment_id: str):
    with Session(engine) as session:
        item = session.get(Appointment, appointment_id)
        if not item:
            raise HTTPException(status_code=404, detail="Not found")
        session.delete(item)
        session.commit()
        return {"ok": True}
    
    
@app.get("/time-blocks", response_model=List[TimeBlock])
def list_time_blocks():
    with Session(engine) as session:
        items = session.exec(select(TimeBlock)).all()
        items.sort(key=lambda x: x.start)
        return items


@app.post("/time-blocks", response_model=TimeBlock)
def create_time_block(payload: TimeBlockCreate):
    with Session(engine) as session:
        exists = session.get(TimeBlock, payload.id)
        if exists:
            raise HTTPException(status_code=409, detail="TimeBlock id already exists")

        item = TimeBlock(**payload.model_dump())
        session.add(item)
        session.commit()
        session.refresh(item)
        return item


@app.delete("/time-blocks/{block_id}")
def delete_time_block(block_id: str):
    with Session(engine) as session:
        item = session.get(TimeBlock, block_id)
        if not item:
            raise HTTPException(status_code=404, detail="Not found")
        session.delete(item)
        session.commit()
        return {"ok": True}


@app.get("/recurring-blocks", response_model=List[RecurringBlock])
def list_recurring_blocks():
    with Session(engine) as session:
        items = session.exec(select(RecurringBlock)).all()
        items.sort(key=lambda x: x.startMinutes)
        return items


@app.post("/recurring-blocks", response_model=RecurringBlock)
def create_recurring_block(payload: RecurringBlockCreate):
    with Session(engine) as session:
        exists = session.get(RecurringBlock, payload.id)
        if exists:
            raise HTTPException(status_code=409, detail="RecurringBlock id already exists")

        item = RecurringBlock(**payload.model_dump())
        session.add(item)
        session.commit()
        session.refresh(item)
        return item


@app.patch("/recurring-blocks/{block_id}", response_model=RecurringBlock)
def set_recurring_block_active(block_id: str, payload: RecurringBlockActiveUpdate):
    with Session(engine) as session:
        item = session.get(RecurringBlock, block_id)
        if not item:
            raise HTTPException(status_code=404, detail="Not found")

        item.active = payload.active
        session.add(item)
        session.commit()
        session.refresh(item)
        return item


@app.delete("/recurring-blocks/{block_id}")
def delete_recurring_block(block_id: str):
    with Session(engine) as session:
        item = session.get(RecurringBlock, block_id)
        if not item:
            raise HTTPException(status_code=404, detail="Not found")
        session.delete(item)
        session.commit()
        return {"ok": True}