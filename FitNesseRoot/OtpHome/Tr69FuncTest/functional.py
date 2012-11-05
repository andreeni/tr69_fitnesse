import re

UNIV =  "2006 University of New Hampshire InterOperability Laboratory"
HEADER1 = "The University of New Hampshire \n"
HEADER2 = "InterOperability Laboratory \n"
FOOTER1 = "TR069 CPE Conformance \n"
FOOTER2 = "Test Suite (TR69) v1.0 \n"

PAGE = "----------------------- Page "

def add_markup(text):
	replace = ["Purpose:", "References:", "Test setup:", "Discussion",  "Procedure:", "Test Metrics:", "Possible Problems:"]
	for re in replace:
		text = text.replace(re, "\n!4 " + re + "\n")
	
	return text

replacements = {"\xe2\x80\x99": "'",
		"\xe2\x80\x9c": "\"",
		"\xe2\x80\x9d": "\"",
		"\xe2\x80\xa2": "-",
		"\xe2\x80\x93": "-"}

def to_string(test_list):
	return "".join(test_list)

def camel_case(name):
	return re.sub('[.| ]', '', name).replace('R','r')

def write_to_file(fname, tc_list):
    f = open(fname, 'w')		    
    f.write(add_markup(to_string(tc_list)))
    f.close()	
		
def getTXTContent(path):
    content = []
    tc_names = []
    
    found_first_tc = False

    f = open(path, 'r')
    
    
    for line in f:	    	    
	    if ((line.find(UNIV) != -1) \
		or (line.find(HEADER1) != -1) \
		or (line.find(HEADER2) != -1) \
		or (line.find(FOOTER1) != -1) \
		or (line.find(FOOTER2) != -1) \
		or (line.find(PAGE) != -1) \
		or (line == '\n')):		    
		    continue

	    if re.findall(".*\:.*\.{2,}\s?\d+\s*$", line) != []:
		    (name, _) = re.split('\:*', line.strip())
		    tc_names.append(name)
		    continue

	    if (tc_names != [] and line.find(tc_names[0]) != -1):
		    found_first_tc = True

	    if found_first_tc == True:			    
		    for key in replacements.keys(): 
			    line = line.replace(key, replacements[key])
	    
		    content.append(line)

    f.close()

    def find_next_tc(name):
	    for line in content:
		    if line.find(name + ":") != -1:
			    return content.index(line)
	    return -1

    tc = 0
    for name in tc_names[1:]:
	    next_tc = find_next_tc(name)
	    if next_tc != -1:
		    this_tc = tc_names[tc_names.index(name) - 1]
		    file_name = camel_case(this_tc)		    
		    write_to_file(file_name, content[tc:next_tc])
		    tc = next_tc

    file_name = camel_case(tc_names[-1])
    write_to_file(file_name, content[tc:])    
		    		    
    return

getTXTContent("TR069_functional_test_suite_v1_0.txt")
