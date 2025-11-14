# docker/docker_runtime/runtime.Dockerfile
FROM fel-python-base:latest AS runtime

WORKDIR /app

COPY src/requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt
