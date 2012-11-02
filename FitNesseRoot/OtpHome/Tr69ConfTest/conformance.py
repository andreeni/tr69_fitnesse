import re

TC = "Test Cases"
UNIV =  "2010 University of New Hampshire InterOperability Laboratory"
PAGE = "----------------------- Page "

def add_markup(text):
	replace = ["Purpose:", "Target:", "Normative Description:", "Procedure:", "Test Metrics:", "References:"]
	for re in replace:
		text = text.replace(re, "\n!4 " + re + "\n")
	
	return text

def getTXTContent(path):
    content = []
    tc_pages = []
    f = open(path, 'r')
    
    found_tc = False
    for line in f:	    	    
	    if line.find(UNIV) != -1:
		    continue	    
	    if line == '\n':
		    continue
	    
	    if re.findall(r"^\s+\d+\s*$", line) != []:
		    continue
	    
	    if re.findall(".*\.{2,}\s?\d+\s*$", line) != []:
		    if line.find(TC) != -1:
			    found_tc = True
			    continue

		    elif found_tc == True:
			    (_, pgn) = re.split('\.*', line.strip())
			    pgn = pgn.strip()
			    tc_pages.append(pgn)
			    continue
		    else:
			    continue
		    
	    line = line.replace("\xe2\x80\x93", "-")
	    content.append(line)

    f.close()

    rest = []
    found_tc = False
    for line in content:
	    if line.find(TC) != -1:
		    found_tc = True
		    continue		    
	    elif found_tc == True:
		    rest.append(line)
	    else:
		    continue

    content = []
		    
    def find_page(pgn):
	    for line in rest:
		    if re.findall(PAGE+''+str(pgn)+"[ |-]", line) != []:
			    return rest.index(line)
	    return -1

    def clean(testcase):
	    clean = []
	    for line in testcase:
		    if line.find(PAGE) != -1:
			    continue
		    else:
			    clean.append(line)
	    return clean

    this_tc = 0

    content = True

    if content:
	    for number in range(1, len(tc_pages)):	    
		    name = 'TestTr69C' + str(number)
		    next_tc = find_page(tc_pages[number])
		    testcases = clean(rest[this_tc:next_tc])
		    		    
		    print str(number) + ". [[\"" + testcases[0].strip()+ "\"][Tr69ConfTest." + name +"]]"
		    this_tc = next_tc + 1
		    
    else:
	    for number in range(1, len(tc_pages)):	    
		    f = open('TestTr69C' + str(number), 'w')

		    next_tc = find_page(tc_pages[number])
		    testcases = clean(rest[this_tc:next_tc])	    
		    text = add_markup("".join(testcases))
		    this_tc = next_tc + 1
	    
		    f.write(text)
		    f.close()
	    
    return

getTXTContent("TR_069_Conformance_1_0.txt")
