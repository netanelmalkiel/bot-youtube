FROM python:3.8.12-slim-buster
WORKDIR /home/ec2-user
COPY . .

RUN ["./pip.sh"]
CMD ["python3", "bot.py"]
