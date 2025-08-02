FROM python:3.11-slim AS builder

WORKDIR /app

RUN apt-get update
RUN apt-get install -y git

COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --prefix=/install -r requirements.txt

FROM python:3.11-slim

WORKDIR /gatekeeper

COPY --from=builder /install /usr/local
COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
