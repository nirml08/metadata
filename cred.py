import base64
file=open("C:\\Users\\User\\Desktop\\New folder\\cred",'wb')
uid=raw_input("username")
pwd=raw_input("password")
def encr(tobe=None):
	eeuid=''
	for i in tobe:
		#print(i,ord(i))
		uid=int(ord(i)*3.14)
		print(i,hex(uid))
		file.write("uid="+hex(uid))

encr(tobe=uid)


file.close()
