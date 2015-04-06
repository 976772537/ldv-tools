import time
import datetime

target = open('test.txt', 'r')

in_data = target.readline()
time.sleep(1)
target.close()
target = open('test.txt', 'w')

cur_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

line1 = "Time of testing: %s!" % cur_time
target.write("%s%s" % (in_data, line1))

if in_data == 'Some text\n':
    print cur_time + ': OK'
    exit(0)
else:
    print cur_time + ': FAIL'
    exit(1)
