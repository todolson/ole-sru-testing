#! /usr/bin/env python

import time
import urllib

search_table = [
    {'name': 'Bib 831: 3 piano pieces / Chopin', 'bib_id':831},
    {'name': 'Bib 3: Journal of applied behavior analysis', 'bib_id':3},
]

def holdings_tree_search(base, bibId):
    params = urllib.urlencode({'bibId':bib_id})
    url = "%s?%s" % (base, params)
    # print url
    start_time = time.clock()
    f = urllib.urlopen(url)
    end_time = time.clock()
    results = {'query':'bibId=%d' % bib_id,
               'time':end_time - start_time, 'code':f.getcode()}
    return results

def print_result(name, results):
    print "%s\t%s\t%f" % (name, results['code'], results['time'])
    
if __name__ == '__main__':

    # http://raspberry.lib.uchicago.edu:8080/oledocstore/documentrest/holdings/tree?bibId=831

    host = 'ole.uchicago.edu'
    base = 'http://raspberry.lib.uchicago.edu:8080/oledocstore/documentrest/holdings/tree'
    SLEEP = 5
    
    for s in search_table:
        bib_id = s['bib_id']
        name = s['name']
        print_result(name, holdings_tree_search(base, bib_id,))
        time.sleep(SLEEP)
