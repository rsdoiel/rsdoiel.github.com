#!/usr/bin/env python3
#
# indexer.py, index my website and generate a LunrJS style JSON
# index for use by LunrJS in for website search.
#
import sys
import os
import json
from lunr import lunr

def get_json_frontmatter(fname):
    with open(fname) as fp:
        src = fp.read()
        if src[0] == "{":
            c = 1
            i = 1
            #FIXME: this is a naive implementation, if {} are included in a string it'll miss count.
            while (c != 0) and (i < len(src)):
                if src[i] == '{':
                    c += 1
                elif src[i] == '}':
                    c -= 1
                i += 1
            jsrc = src[0:i]
            data = src[i:]
            try:
                obj = json.loads(jsrc)
            except Exception as err:
                return None, err
            obj['content'] = data
            return obj, None
    return None, None


class Indexer:
    def __init__(self, start_path = ".", htdocs_prefix = "", index_name = "lunr.json"):
        self.start_path = start_path
        self.htdocs_prefix = htdocs_prefix
        self.index_name = index_name
        self.files = []
        self.documents = []

    def harvest_metadata(self):
        for root, dirs, files in os.walk(self.start_path):
            for name in files:
                fname = os.path.join(root, name)
                _, ext = os.path.splitext(name)
                if ext == ".md":
                    self.files.append(fname)
                    [obj, err] = get_json_frontmatter(fname)
                    if err:
                        print(f'WARNING: {err}')
                    elif obj != None:
                        if fname.startswith("./"):
                            key = self.htdocs_prefix + fname[2:]
                            obj['_Key'] = key
                        self.documents.append(obj)

    def lunr_index(self):
        print('Collecting fields ...')
        field_names = []
        fields = []
        for i, obj in enumerate(self.documents):
            for key in obj:
                if not key in field_names:
                    field_names.append(key)
                    if type(obj[key]) != 'string':
                        fields.append(dict(field_name=key, extractor = lambda x: f'{x}'))
                    else:
                        fields.append(key)
        print(f'Found {len(fields)} unique fields to index')
        print(f'Fields: {", ".join(field_names)}')
        print(f'Generatiing LunrJS index {self.index_name}')
        idx = lunr(ref = '_Key', fields = fields, documents = self.documents)
        index = idx.serialize()
        with open(self.index_name, 'w') as fp:
            src = json.dumps(index)
            fp.write(src)

    def report(self):
        print(f'Start path: {self.start_path}')
        print(f'Htdocs prefix: {self.htdocs_prefix}')
        print(f'Index name: {self.index_name}')
        print(f"{len(self.files)} files scanned.")
        print(f"{len(self.documents)} documents indexed.")

    
if __name__ in "__main__":
    site = Indexer()
    site.harvest_metadata()
    site.lunr_index()
    site.report()
