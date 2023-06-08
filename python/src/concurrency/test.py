import asyncio
import threading


async def send_sms(phone_number, message):
    await asyncio.sleep(1)
    print("test_async", threading.current_thread().getName())


def schedule_send_sms():
    phone_numbers = ['1234567890', '0987654321']
    messages = ['Hello', 'World']
    loop = asyncio.get_event_loop()
    tasks = [
        send_sms(phone_number, message)
        for phone_number, message in zip(phone_numbers, messages)
    ]
    loop.run_until_complete(asyncio.gather(*tasks))
    loop.close()


if __name__ == '__main__':
    # 在 5 秒后调用 schedule_send_sms 函数
    t = threading.Timer(5.0, schedule_send_sms)
    t.start()
