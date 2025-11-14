# docker/docker_app/app.Dockerfile
FROM fel-python-runtime:latest AS app

WORKDIR /app
COPY src/ /app

EXPOSE 8000

CMD ["python3", "app.py"]
