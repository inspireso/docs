import os
import signal
from concurrent import futures

if __name__ == '__main__':
    with futures.ProcessPoolExecutor(max_workers=2) as ex:
        print('getting the pid for one worker')
        f1 = ex.submit(os.getpid)
        pid1 = f1.result()

        print('killing process {}'.format(pid1))
        os.kill(pid1, signal.SIGHUP)

        print('submitting another task')
        f2 = ex.submit(os.getpid)
        try:
            pid2 = f2.result()
        except futures.process.BrokenProcessPool as e:
            print('could not start new tasks: {}'.format(e))
