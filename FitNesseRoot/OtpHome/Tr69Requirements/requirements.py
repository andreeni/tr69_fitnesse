import re

def camelize(s):
    result = ""
    m = re.match(r'(\w?)(\w*-\d*)-(\w?)(\w*-\d*)', s)
    if m == None:
        m = re.match(r'(\w?)(\w*)-(\w?)(\w*)-(\w?)(\w*)-(\w?)(\w*-\d*)', s)

    if m != None:
        nr = 0
        for el in m.groups():
            if nr % 2 == 0:
                result += el
            else:
                result += el.lower().replace('-', '')
            nr += 1
        
    return result
	
def getTXTContent(path):
    found = False
    tfile = None
    Name = ""

    f = open(path, 'r')
    number = 1
    for line in f:
        if (re.findall("<Start:\s",line) != []):
            (_, Rest) = re.split(':', line.strip())
            (Name, _) = re.split(',', Rest.strip())

            if tfile <> None:
                tfile.close()

            tfile = open('tests/' + camelize(Name)+".txt",'w')
            print str(number) + ". [[\"" + Name+ "\"][Tr69Requirements." + camelize(Name) +"]]"
            number += 1
            found = False
        
        if (line.find(Name) != -1):            
            found = True

        if (found == True):            
            tfile.write(line)
     
    f.close()		    		    
    return

getTXTContent("SRS_HeNB_OAM_Interf_v01_02.txt")


