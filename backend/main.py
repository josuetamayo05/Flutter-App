from datetime import datetime, timedelta
from typing import List

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from jose import JWTError, jwt
from passlib.context import CryptContext

from sqlmodel import SQLModel, Field, create_engine, Session, select
from sqlalchemy import Column
from sqlalchemy.types import JSON


# -------------------- Auth config --------------------
SECRET_KEY = "CAMBIA_ESTO_POR_ALGO_LARGO_Y_RANDOM"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
auth_scheme = HTTPBearer()


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return pwd_context.verify(password, hashed)


def create_access_token(user_id: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": user_id, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# -------------------- DB --------------------
DATABASE_URL = "sqlite:///./app.db"
engine = create_engine(DATABASE_URL, echo=False)


def create_db():
    SQLModel.metadata.create_all(engine)


# -------------------- Models --------------------
class User(SQLModel, table=True):
    id: str = Field(primary_key=True)
    email: str = Field(index=True)
    hashedPassword: str


class RegisterRequest(SQLModel):
    email: str
    password: str


class LoginRequest(SQLModel):
    email: str
    password: str


class TokenResponse(SQLModel):
    accessToken: str
    tokenType: str = "bearer"


class Appointment(SQLModel, table=True):
    id: str = Field(primary_key=True)
    userId: str = Field(index=True)

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
    userId: str = Field(index=True)

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
    userId: str = Field(index=True)

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


# -------------------- App --------------------
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


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(auth_scheme),
) -> User:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    with Session(engine) as session:
        user = session.get(User, user_id)
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user


# -------------------- Auth endpoints --------------------
@app.post("/auth/register", response_model=TokenResponse)
def register(payload: RegisterRequest):
    if len(payload.password.encode("utf-8")) > 72:
        raise HTTPException(
            status_code=400,
            detail="Password demasiado larga (máximo 72 bytes para bcrypt).",
        )

    with Session(engine) as session:
        existing = session.exec(select(User).where(User.email == payload.email)).first()
        if existing:
            raise HTTPException(status_code=409, detail="Email already registered")

        user = User(
            id=str(int(datetime.utcnow().timestamp() * 1_000_000)),
            email=payload.email,
            hashedPassword=hash_password(payload.password),
        )
        session.add(user)
        session.commit()

        token = create_access_token(user.id)
        return TokenResponse(accessToken=token)


@app.post("/auth/login", response_model=TokenResponse)
def login(payload: LoginRequest):
    with Session(engine) as session:
        user = session.exec(select(User).where(User.email == payload.email)).first()
        if not user or not verify_password(payload.password, user.hashedPassword):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        token = create_access_token(user.id)
        return TokenResponse(accessToken=token)


# -------------------- Appointments --------------------
@app.get("/appointments", response_model=List[Appointment])
def list_appointments(current: User = Depends(get_current_user)):
    with Session(engine) as session:
        items = session.exec(
            select(Appointment).where(Appointment.userId == current.id)
        ).all()
        items.sort(key=lambda x: x.dateTime)
        return items


@app.post("/appointments", response_model=Appointment)
def create_appointment(payload: AppointmentCreate, current: User = Depends(get_current_user)):
    with Session(engine) as session:
        exists = session.get(Appointment, payload.id)
        if exists:
            raise HTTPException(status_code=409, detail="Appointment id already exists")

        item = Appointment(**payload.model_dump(), userId=current.id)
        session.add(item)
        session.commit()
        session.refresh(item)
        return item


@app.delete("/appointments/{appointment_id}")
def delete_appointment(appointment_id: str, current: User = Depends(get_current_user)):
    with Session(engine) as session:
        item = session.get(Appointment, appointment_id)
        if not item or item.userId != current.id:
            raise HTTPException(status_code=404, detail="Not found")
        session.delete(item)
        session.commit()
        return {"ok": True}


# -------------------- Time blocks --------------------
@app.get("/time-blocks", response_model=List[TimeBlock])
def list_time_blocks(current: User = Depends(get_current_user)):
    with Session(engine) as session:
        items = session.exec(
            select(TimeBlock).where(TimeBlock.userId == current.id)
        ).all()
        items.sort(key=lambda x: x.start)
        return items


@app.post("/time-blocks", response_model=TimeBlock)
def create_time_block(payload: TimeBlockCreate, current: User = Depends(get_current_user)):
    with Session(engine) as session:
        exists = session.get(TimeBlock, payload.id)
        if exists:
            raise HTTPException(status_code=409, detail="TimeBlock id already exists")

        item = TimeBlock(**payload.model_dump(), userId=current.id)
        session.add(item)
        session.commit()
        session.refresh(item)
        return item


@app.delete("/time-blocks/{block_id}")
def delete_time_block(block_id: str, current: User = Depends(get_current_user)):
    with Session(engine) as session:
        item = session.get(TimeBlock, block_id)
        if not item or item.userId != current.id:
            raise HTTPException(status_code=404, detail="Not found")
        session.delete(item)
        session.commit()
        return {"ok": True}


# -------------------- Recurring blocks --------------------
@app.get("/recurring-blocks", response_model=List[RecurringBlock])
def list_recurring_blocks(current: User = Depends(get_current_user)):
    with Session(engine) as session:
        items = session.exec(
            select(RecurringBlock).where(RecurringBlock.userId == current.id)
        ).all()
        items.sort(key=lambda x: x.startMinutes)
        return items


@app.post("/recurring-blocks", response_model=RecurringBlock)
def create_recurring_block(payload: RecurringBlockCreate, current: User = Depends(get_current_user)):
    with Session(engine) as session:
        exists = session.get(RecurringBlock, payload.id)
        if exists:
            raise HTTPException(status_code=409, detail="RecurringBlock id already exists")

        item = RecurringBlock(**payload.model_dump(), userId=current.id)
        session.add(item)
        session.commit()
        session.refresh(item)
        return item


@app.patch("/recurring-blocks/{block_id}", response_model=RecurringBlock)
def set_recurring_block_active(
    block_id: str,
    payload: RecurringBlockActiveUpdate,
    current: User = Depends(get_current_user),
):
    with Session(engine) as session:
        item = session.get(RecurringBlock, block_id)
        if not item or item.userId != current.id:
            raise HTTPException(status_code=404, detail="Not found")

        item.active = payload.active
        session.add(item)
        session.commit()
        session.refresh(item)
        return item


@app.delete("/recurring-blocks/{block_id}")
def delete_recurring_block(block_id: str, current: User = Depends(get_current_user)):
    with Session(engine) as session:
        item = session.get(RecurringBlock, block_id)
        if not item or item.userId != current.id:
            raise HTTPException(status_code=404, detail="Not found")
        session.delete(item)
        session.commit()
        return {"ok": True}