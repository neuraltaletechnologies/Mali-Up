import sys
from pathlib import Path

def idx_to_pos(s, idx):
    # returns (line, col) 1-based
    lines = s.splitlines(True)
    cur = 0
    for i,l in enumerate(lines):
        if cur + len(l) > idx:
            return (i+1, idx - cur + 1)
        cur += len(l)
    return (len(lines), max(1, len(lines[-1]) if lines else 1))

for path in sys.argv[1:]:
    p = Path(path)
    s = p.read_text(encoding='utf-8')
    pairs={'(':')','[':']','{':'}'}
    opens=set(pairs.keys())
    closes=set(pairs.values())
    stack=[]
    mismatch = None
    for i,ch in enumerate(s):
        if ch in opens:
            stack.append((ch,i))
        elif ch in closes:
            if not stack:
                print(f"{path}: Unmatched closing {ch} at index {i}")
                mismatch = ('closing', ch, i)
                break
            last,idx=stack.pop()
            if pairs[last]!=ch:
                print(f"{path}: Mismatched {last} at {idx} with {ch} at {i}")
                mismatch = ('mismatch', last, idx, ch, i)
                break
    if mismatch is None:
        if stack:
            last,idx=stack[-1]
            print(f"{path}: Unmatched opening {last} at index {idx}")
            mismatch = ('unmatched_open', last, idx)
        else:
            print(f"{path}: All brackets matched")
    # show context for mismatch
    if mismatch:
        if mismatch[0] in ('mismatch','unmatched_open'):
            if mismatch[0]=='mismatch':
                _, last, idx, ch, i = mismatch
                print('Opening location: index', idx, '->', idx_to_pos(s, idx))
                print('Closing location: index', i, '->', idx_to_pos(s, i))
                start = max(0, idx-80)
                end = min(len(s), i+80)
                print('\nContext around opening:\n')
                print(s[start: start+160])
                print('\nContext around closing:\n')
                print(s[max(0, i-160): i+80])
            else:
                _, last, idx = mismatch
                print('Unmatched opening at index', idx, '->', idx_to_pos(s, idx))
                start = max(0, idx-80)
                print('\nContext:\n')
                print(s[start: start+320])
