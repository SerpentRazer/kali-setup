#!/usr/bin/env python3
# resolve.py FILE IDX CHOICE   (IDX 1-based; CHOICE = L | U | LU | UL | C  -> C = text from stdin)
import sys, re
f, idx, ch = sys.argv[1], int(sys.argv[2]), sys.argv[3]
lines = open(f).read().split('\n')
out, i, n = [], 0, 0
while i < len(lines):
    if lines[i].startswith('<<<<<<< '):
        n += 1
        j = i + 1; loc = []
        while not lines[j].startswith('======='): loc.append(lines[j]); j += 1
        j += 1; up = []
        while not lines[j].startswith('>>>>>>> '): up.append(lines[j]); j += 1
        if n == idx:
            if ch == 'L': out += loc
            elif ch == 'U': out += up
            elif ch == 'LU': out += loc + up
            elif ch == 'UL': out += up + loc
            elif ch == 'C': out += sys.stdin.read().rstrip('\n').split('\n')
            else: sys.exit('bad choice')
        else:
            out += [lines[i]] + loc + ['======='] + up + [lines[j]]
        i = j + 1; continue
    out.append(lines[i]); i += 1
if n < idx: sys.exit(f'only {n} conflicts')
open(f, 'w').write('\n'.join(out))
left = sum(1 for l in out if l.startswith('<<<<<<< '))
print(f'{f}: conflict {idx} -> {ch}; raman {left}')
