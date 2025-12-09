FROM python:3.9-slim

WORKDIR /app

RUN pip install flask docker

COPY web/ /app/web/
WORKDIR /app/web

EXPOSE 5000

CMD ["python", "app.py"]
