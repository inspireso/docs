import os
from concurrent import futures


def task(n):
    return (n, os.getpid())


if __name__ == '__main__':
    ex = futures.ProcessPoolExecutor(max_workers=3)
    results = ex.map(task, range(50, 0, -1))
    for n, pid in results:
        print('ran task {} in process {}'.format(n, pid))
