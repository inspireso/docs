FROM python:3.11

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE 1
# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED 1
ENV TZ=Asia/Shanghai

# Install pip requirements
COPY requirements.txt .
RUN pip3 install -i https://mirrors.aliyun.com/pypi/simple/ --no-cache-dir --upgrade -r requirements.txt


WORKDIR /app
COPY . /app

CMD ["python3", "./main.py"]