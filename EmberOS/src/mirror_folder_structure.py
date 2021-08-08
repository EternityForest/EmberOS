import sys,os

for root, dirs, files in os.walk(sys.argv[1]):
    for i in dirs:
        rp = os.path.relpath(os.path.join(root, i), sys.argv[1])
        try:
            os.mkdir(os.path.join(sys.argv[2],rp))
        except Exception as e:
            print(e)
