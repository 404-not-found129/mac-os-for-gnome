import urllib.request, json, os, subprocess, sys
import zipfile, io

def install_ext(uuid):
    print(f"Fetching {uuid}...")
    try:
        gnome_version = subprocess.check_output(['gnome-shell', '--version']).decode().split()[2].split('.')[0]
    except Exception:
        gnome_version = '45' # Fallback
    
    url = f'https://extensions.gnome.org/extension-info/?uuid={uuid}'
    req = urllib.request.urlopen(url)
    data = json.loads(req.read())
    
    vmap = data.get('shell_version_map', {})
    if gnome_version in vmap:
        version = vmap[gnome_version]['version']
    else:
        # Fallback to newest
        versions = sorted([v for v in vmap.keys() if v.isdigit()], key=int, reverse=True)
        if not versions:
            versions = list(vmap.keys())
        version = vmap[versions[0]]['version']
        
    dl_url = f"https://extensions.gnome.org/api/v1/extensions/{uuid}/versions/{version}/?format=zip"
    print(f"Downloading from {dl_url}...")
    
    zip_resp = urllib.request.urlopen(dl_url)
    with zipfile.ZipFile(io.BytesIO(zip_resp.read())) as z:
        ext_dir = os.path.expanduser(f"~/.local/share/gnome-shell/extensions/{uuid}")
        os.makedirs(ext_dir, exist_ok=True)
        z.extractall(ext_dir)
        
    print(f"Installed {uuid}. Enabling...")
    try:
        subprocess.run(['gnome-extensions', 'enable', uuid], check=True)
    except Exception:
        pass

for u in sys.argv[1:]:
    install_ext(u)
