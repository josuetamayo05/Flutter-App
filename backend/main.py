from datetime import datetime
from typing import List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel, Field, create_engine, Session, select

class Appointment(SQLModel, table=True):
    id: str=Field(primary_key=True)
    client_name:str
    service_id:str
    duration_minutes:int
    dateTime:datetime
    
class AppointmentCreate(SQLModel):
    id: str
    clientName: str
    serviceId: str
    durationMinutes: int
    dateTime: datetime

DATABASE_URL = "sqlite:///./app.db"
engine = create_engine(DATABASE_URL, echo=False)

def create_db():
    SQLModel.metadata.create_all(engine)

app = FastAPI(title="Turnos API")

# CORS para que Flutter Web (localhost) pueda llamar al backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # en producción se restringe
    allow_credentials=True,
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

        item = Appointment.model_validate(payload)
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