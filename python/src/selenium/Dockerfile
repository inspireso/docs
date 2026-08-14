FROM python:3.12.7

ENV \
    # Keeps Python from generating .pyc files in the container
    PYTHONDONTWRITEBYTECODE=1 \
    # Turns off buffering for easier container logging
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai

# Install pip requirements
COPY requirements.txt .
RUN pip3 install -i https://mirrors.cloud.tencent.com/pypi/simple --no-cache-dir --upgrade -r requirements.txt
COPY . /app
WORKDIR /app

CMD ["python3", "./main.py"]