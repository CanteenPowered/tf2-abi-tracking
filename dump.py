#!/usr/bin/env python3

import json
import os
import shutil
import subprocess
import sys

FILES = [
    [ 'tf', 'bin', 'server_srv.so'  ],
    [ 'bin', 'engine_srv.so'        ],
    [ 'bin', 'libtier0_srv.so'      ],
    [ 'bin', 'libvstdlib_srv.so'    ],
    [ 'bin', 'vscript_srv.so'       ],
]

FILTER='^((?!CryptoPP).)*$'

def main(args):
    if len(args) != 2:
        print('Usage: dump.py <tf2 linux server path>')
        quit(1)
    serverpath = os.path.realpath(args[1])

    vtabledump = shutil.which('vtabledump')
    if vtabledump is None:
        print('Please install https://github.com/hkva/vtabledump')
        quit(1)

    for i, file in enumerate(FILES):
        path = os.path.join(*file)
        print(f'{i+1:04d}/{len(FILES):04d}: Dumping {path} ...')
        path = os.path.join(serverpath, path)
        j = subprocess.run([vtabledump, path, f'--filter={FILTER}', '--mangled', '--json'], capture_output=True, text=True)
        if j.returncode != 0:
            print('Failed')
            quit(1)
        j = json.loads(j.stdout)
        dpath = [ 'vtables', file[len(file)-1][:-3] ]
        os.makedirs(os.path.join(*dpath), exist_ok=True)
        for ii, table in enumerate(j['vtables']):
            print(f'    {ii+1:04d}/{len(j["vtables"]):04d}: {table["classname"]}')
            try:
                with open(os.path.join(*dpath, table['classname'] + '.json'), 'w') as f:
                    json.dump(table, f, indent='\t')
            except:
                pass

    with open(os.path.join(serverpath, 'tf', 'steam.inf'), 'r') as f:
        c=f.read()
        ver=c[c.find('=')+1:c.find('\n')]
        print(f'Dumped game version {ver}')

if __name__ == '__main__':
    main(sys.argv)
