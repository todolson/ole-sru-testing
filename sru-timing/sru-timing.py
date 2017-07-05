#! /usr/bin/env python

import time
import timeit
import urllib
import urllib2
import xml.etree.ElementTree as ET

search_table = [
    {'name': 'AUTHOR andrew abbott', 'sru':'dc.creator=andrew and dc.creator=abbott' , 'z3950':'' },
    {'name': 'Bib 831: 3 piano pieces / Chopin', 'sru':'id=831', 'z3950':''},
    {'name': 'Bib 3: Journal of applied behavior analysis', 'sru':'id=3', 'z3950':''},
    {'name': 'The Fundametalism Project [mult. locations]', 'sru':'id=2352069', 'z3950':''},
]

def sru_search(base, query, schema):
    params = urllib.urlencode({'version':'1.2', 'operation':'searchRetrieve',
                               'query':query, 'recordSchema':schema})
    url = "%s?%s" % (base, params)
    results = {'query':query,
               'schema':schema,
               'time':0,
               'code':None,
               'msg':''}
    start_time = timeit.default_timer()
    try:
        #print url
        response = urllib2.urlopen(url)
        #print 'reading response'
        contents = response.read()
        #print 'response finished'
        results['code'] = response.getcode()
        root = ET.fromstring(contents)
        num_recs_elt = root.find('{http://www.loc.gov/zing/srw/}numberOfRecords')
        results['msg'] = '%s hits' % num_recs_elt.text
    except urllib2.HTTPError as e:
        results['code'] = e.getcode()
        results['msg'] = e.reason
        
    end_time = timeit.default_timer()
    results['time'] = end_time - start_time
    
    return results

def print_result(name, results):
    print "%s\t%s\t%f\t%s\t%s" % (results['schema'], results['code'], results['time'], results['msg'], name)

def main(base, pause):
    global search_table
    
    for s in search_table:
        query = s['sru']
        name = s['name']
        print_result(name, sru_search(base, query, 'marcxml'))
        time.sleep(pause)

    for s in search_table:
        query = s['sru']
        name = s['name']
        print_result(name, sru_search(base, query, 'opac'))
        time.sleep(pause)

    
if __name__ == '__main__':

    host = 'ole.uchicago.edu'
    base = 'http://ole01.uchicago.edu/sru'
    #base = 'http://raspberry.lib.uchicago.edu:8080/oledocstore/sru'
    PAUSE = 5

    try:
        main(base, PAUSE)
    except KeyboardInterrupt:
        pass
    
