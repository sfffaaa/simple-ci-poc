import base64
import hashlib

from Crypto.Cipher import AES

# reference: https://gist.github.com/swinton/8409454

BS = 16
IV = "c782dc4c098c66cd"


def pad(s):
    return s + (BS - len(s) % BS) * chr(BS - len(s) % BS)


def unpad(s):
    s = s.decode("utf-8")
    return s[0: -ord(s[-1])]


class AESCipher:
    def __init__(self, key):
        self.key = hashlib.sha256(key.encode("utf-8")).digest()

    def encrypt(self, raw):
        raw = pad(raw)
        iv = IV.encode("utf-8")
        cipher = AES.new(self.key, AES.MODE_CBC, iv)
        return base64.b64encode(iv + cipher.encrypt(raw.encode("utf-8")))

    def decrypt(self, enc):
        enc = base64.b64decode(enc.encode("utf-8"))
        iv = enc[:16]
        cipher = AES.new(self.key, AES.MODE_CBC, iv)
        return unpad(cipher.decrypt(enc[16:]))


def decrypt_mnenomic(path, pswd):
    with open(path) as f:
        data = f.readlines()
    cipher = AESCipher(pswd)
    return cipher.decrypt(data[0].strip())
