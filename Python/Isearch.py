import re
import csv
import keyboard
import os

# Gets user input and instantly updates terms variable to pass into search function
def get_terms ():
    global searchterms
    global working
    key = ""
    event = keyboard.read_event()
    if event.event_type == keyboard.KEY_DOWN:
        key = event.name
        #print (key)
        if len(key) == 1:
            # Prevents false negative results.
            if key.isalpha():
                searchterms = searchterms+key.lower()
            else:
                searchterms = searchterms+key
        elif key == 'backspace':
            searchterms = searchterms[:-1]
        elif key == 'space':
            searchterms = searchterms+" "
        elif key == 'esc':
            working = False
        elif key == 'delete':
            searchterms = ""
        os.system('cls')
        print ("ESC to quit, DEL to clear.\nSearching for:\n")
        print (searchterms)
        print ("\nRESULTS__________________________________________________________\n")
        if len(searchterms) >= 1:
            lookup_terms(searchterms)

def lookup_terms(terms):
    for key, value in datalist.items():
        # search terms against key/value, return pair if it gets any hits
        if re.search(terms, key) is not None:
            print ("{:<30} {:<15}".format(key, value))
        elif re.search(terms, value) is not None:
            print ("{:<30} {:<15}".format(key, value))

csvData = 'company codes.csv'
global searchterms
global working 
searchterms = ""
working = True

with open(csvData, 'r') as openfile:
    reader = csv.reader(openfile)
    datalist = {rows[0]:rows[1] for rows in reader}
print ("Start typing:\n")
while working == True:
    get_terms()
