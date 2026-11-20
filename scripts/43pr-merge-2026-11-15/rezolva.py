#!/usr/bin/env python3
# rezolva.py FISIER ALEGERI...  alegeri per conflict, in ordine: L (local), U (upstream), LU (ambele, local intai), @fisier (text din fisier)
import sys,re
p=sys.argv[1]; ch=sys.argv[2:]
t=open(p,encoding='utf-8').read().split('\n')
out=[];i=0;k=0
while i<len(t):
    if t[i].startswith('<<<<<<< '):
        j=i+1; L=[];U=[]
        while not t[j].startswith('======='): L.append(t[j]); j+=1
        j+=1
        while not t[j].startswith('>>>>>>> '): U.append(t[j]); j+=1
        c=ch[k]; k+=1
        if c=='L': out+=L
        elif c=='U': out+=U
        elif c=='LU': out+=L+U
        elif c.startswith('@'): out+=open(c[1:],encoding='utf-8').read().rstrip('\n').split('\n')
        else: sys.exit('alegere necunoscuta '+c)
        i=j+1
    else: out.append(t[i]); i+=1
assert k==len(ch),(k,len(ch))
open(p,'w',encoding='utf-8').write('\n'.join(out)); print(p,'rezolvat',k)
