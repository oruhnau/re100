
import datetime as dt
import subprocess

for year in range(1982, 2016):
    start = (dt.date(year=year, day=1, month=7) - dt.date(year=1982, day=1, month=1)).days * 24 + 1
    end = (dt.date(year=year+1, day=1, month=7) - dt.date(year=1982, day=1, month=1)).days * 24
    print('{} to {}'.format(start, end))
    subprocess.run('gams RE100.gms --start={} --end={}'.format(start, end))
