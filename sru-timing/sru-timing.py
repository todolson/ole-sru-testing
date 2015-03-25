#! /usr/bin/env python

import time
import urllib

search_table = [
    {'name': 'AUTHOR andrew abbott', 'sru':'dc.creator=andrew and dc.creator=abbott' , 'z3950':'' },
    {'name': 'AUTHOR andrew abbott', 'sru':'' , 'z3950':'' },
    {'name': 'AUTHOR andrew abbott', 'sru':'' , 'z3950':'' },
]

def sru_search(base, query, schema):
    params = urllib.urlencode({'version':'1.2', 'operation':'searchRetrieve',
                               'query':query, 'recordSchema':schema})
    url = "%s?%s" % (base, params)
    # print url
    start_time = time.clock()
    f = urllib.urlopen(url)
    end_time = time.clock()
    results = {'query':query, 'schema':schema,
               'time':end_time - start_time, 'code':f.getcode()}
    return results

def print_result(name, results):
    print "%s\t%s\t%s\t%f" % (name, results['schema'], results['code'], results['time'])
    
if __name__ == '__main__':

    host = 'ole.uchicago.edu'
    base = 'http://ole01.uchicago.edu/sru'
    
    for s in search_table:
        query = s['sru']
        name = s['name']
        print_result(name, sru_search(base, query, 'marcxml'))
        print_result(name, sru_search(base, query, 'opac'))
    
