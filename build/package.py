import json
import zipfile
import os
import hashlib as hash
import shutil

def recursive_zip(zipf, directory, folder=""):
    print("Zipping", folder)
    zipf.write(directory, folder)
    for item in os.listdir(directory):
        absolutePath = os.path.join(directory, item)
        if os.path.isfile(absolutePath) and item != ".DS_Store":
            zipf.write(absolutePath, folder + os.sep + item)
        elif os.path.isdir(absolutePath):
            recursive_zip(zipf, absolutePath, folder + os.sep + item)

outdir = "out"
shutil.rmtree(outdir, ignore_errors=True)
os.makedirs(outdir)

## read metadata.json
md_file = open("../resources/metadata.json", "r+")
md = json.load(md_file)
md_file.close()
extensionId = md['id']

# zip the extension
zipName = extensionId + '.muxt'
zipPath = os.path.join(outdir, zipName)
myzip = zipfile.ZipFile(zipPath, mode='w')
recursive_zip(myzip, os.path.abspath('../resources/instruments'), "instruments")
print("instruments zipped")
#recursive_zip(myzip, os.path.abspath('../resources/pallettes'), "pallettes")
#print("pallettes zipped")
#recursive_zip(myzip, os.path.abspath('../resources/plugins'), "plugins")
#print("plugins zipped")
#recursive_zip(myzip, os.path.abspath('../resources/scores'), "scores")
#print("scores zipped")
recursive_zip(myzip, os.path.abspath('../resources/soundfonts'), "soundfonts")
print("sf2 zipped")
recursive_zip(myzip, os.path.abspath('../resources/sfzs'), "sfzs")
print("sfz zipped")
#recursive_zip(myzip, os.path.abspath('../resources/styles'), "styles")
#print("styles zipped")
recursive_zip(myzip, os.path.abspath('../resources/templates'), "templates")
print("templates zipped")
recursive_zip(myzip, os.path.abspath('../resources/workspaces'), "workspaces")
print("workspaces zipped")
print("Recursive zipping complete")
myzip.write('../resources/metadata.json', 'metadata.json')
myzip.close()
print("Packaging successful")

# compute zip size
fileSize = os.path.getsize(zipPath)
print(fileSize)

# compute SHA1 hash
BLOCKSIZE = 65536
sha = hash.sha256()
with open(zipPath, 'rb') as f:
    file_buffer = f.read(BLOCKSIZE)
    while len(file_buffer) > 0:
        sha.update(file_buffer)
        file_buffer = f.read(BLOCKSIZE)
    f.close()
h = str(sha.hexdigest())
print(h)

### create details.json
data = {}
data["type"] = "Extensions"
data["version"] = "2.0"

## read from metadata.json
data[extensionId] = {}
data[extensionId]["file_name"] = zipName
data[extensionId]["name"] = md["name"]
data[extensionId]["description"] = md["description"]
data[extensionId]["tags"] = md["tags"]
data[extensionId]["version"] = md["version"]

data[extensionId]["file_size"] = fileSize
data[extensionId]["hash"] = h

json_file = open(os.path.join(outdir, 'details.json'), "w")
json_file.write(json.dumps(data, sort_keys=True, indent=4))
json_file.close()
