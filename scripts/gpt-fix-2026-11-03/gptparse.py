import sys, struct, zlib, uuid
def hdr(b):
    sig,rev,hs,hcrc,_,my,alt,fu,lu=struct.unpack_from('<8sIIIIQQQQ',b,0)
    dg=uuid.UUID(bytes_le=b[56:72]); pel,ne,es,pcrc=struct.unpack_from('<QIII',b,72)
    hb=bytearray(b[:hs]); hb[16:20]=b'\0'*4
    return dict(sig=sig,my=my,alt=alt,fu=fu,lu=lu,disk=str(dg),pel=pel,ne=ne,es=es,pcrc=pcrc,hcrc_ok=(zlib.crc32(hb)&0xffffffff)==hcrc)
def ents(a,es=128):
    out=[]
    for i in range(len(a)//es):
        e=a[i*es:(i+1)*es]
        if e[:16]==b'\0'*16: continue
        t=str(uuid.UUID(bytes_le=e[:16])).upper(); s,en=struct.unpack_from('<QQ',e,32)
        name=e[56:128].decode('utf-16le').rstrip('\0')
        out.append((i+1,s,en,(en-s+1)*512/2**30,t[:8],name))
    return out
def show(label,h,arr):
    print(f"== {label}: hdrCRC_ok={h['hcrc_ok']} my={h['my']} alt={h['alt']} entriesLBA={h['pel']} n={h['ne']} disk={h['disk']}")
    print(f"   entriesCRC in header={h['pcrc']:08x}  CRC of array read={zlib.crc32(arr)&0xffffffff:08x}  -> {'OK' if (zlib.crc32(arr)&0xffffffff)==h['pcrc'] else 'MISMATCH'}")
    for e in ents(arr,h['es']): print("   p%-3d %12d-%12d %8.1f GiB %s %s"%e)
mode=sys.argv[1]
if mode=='head':   # raw first N sectors of disk
    d=open(sys.argv[2],'rb').read()
    h=hdr(d[512:1024]); n=h['ne']*h['es']
    show('PRIMARY (array at header LBA %d)'%h['pel'],h,d[h['pel']*512:h['pel']*512+n])
    a2=d[1024:1024+n]
    print("-- LBA 2..33: all zero" if a2==b'\0'*n else "-- LBA 2..33 contains data:")
    if a2!=b'\0'*n: show('  array found at LBA 2 vs primary header CRC',h,a2)
elif mode=='sgdisk':  # sgdisk --backup file: MBR + main hdr + backup hdr + array
    d=open(sys.argv[2],'rb').read()
    h=hdr(d[512:1024]); b=hdr(d[1024:1536]); n=h['ne']*h['es']; arr=d[1536:1536+n]
    show('sgdisk backup / main hdr',h,arr); print("   backup hdr: my=%d entriesLBA=%d pcrc=%08x"%(b['my'],b['pel'],b['pcrc']))
elif mode=='tail':  # last 33 sectors: array(32)+backup hdr(1)
    d=open(sys.argv[2],'rb').read()
    h=hdr(d[-512:]); n=h['ne']*h['es']
    show('BACKUP (tail)',h,d[-512-n:-512])
