
target = open('test.txt', 'r')

in_data = target.read()

if in_data == 'Some text\n':
    print 'OK'
    exit(0)
else:
    print 'FAIL'
    exit(1)
if 2 > 1:
    print 'OK'
    exit(0)
