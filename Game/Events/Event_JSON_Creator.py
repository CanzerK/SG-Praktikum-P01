import os
import json
import random


def create_json_from_folders():
    eventId = 1
    script_dir = os.path.dirname(os.path.abspath(__file__))
    possible_locations = [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0), (9, 0), (10, 0),      #Bottom edge
                            (11, 0), (12, 0), (13, 0), (14, 0), (15, 0), (16, 0), (17, 0), (18, 0), (19, 0),
                            (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 9), (0, 10), (0, 11),   #Left edge
                            (0, 12), (0, 13), (0, 14), (0, 15), (0, 16), (0, 17), (0, 18), (0, 19), (0, 20), (0, 21),
                            (0, 22), (0, 23), (0, 24), (0, 25), (0, 26), (0, 27), (0, 28), (0, 29),
                            (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11),
                            (4, 12), (4, 13), (4, 14), (4, 15), (4, 16), (4, 17), (4, 18), (4, 19), (4, 20), (4, 21),   #Diagonal Road on "E"
                            (4, 22), (4, 23), (4, 24), (4, 25), (4, 26), (4, 27), (4, 28), (4, 29),
                            (0, 29), (1, 29), (2, 29), (3, 29), (4, 29), (5, 29), (6, 29), (7, 29), (8, 29), (9, 29),
                            (10, 29), (11, 29), (12, 29), (13, 29), (14, 29), (15, 29), (16, 29), (17, 29), (18, 29),   #Top Edge
                            (19, 29),
                            (1, 16), (2, 16), (3, 16), (4, 16),                                                         #Short street A17:E17
                            (0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3),    #Long Street A4:Q4
                            (11, 3), (12, 3), (13, 3), (14, 3), (15, 3), (16, 3),
                            (0, 7), (1, 7), (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7),    #Long Street A8:Q8
                            (11, 7), (12, 7), (13, 7), (14, 7), (15, 7), (16, 7), (17, 7), (18, 7), (19, 7),
                            (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12), (10, 12), (11, 12), (12, 12),         #Long Street E13:N13
                            (13, 12),
                            (4, 25), (5, 25), (6, 25), (7, 25), (8, 25), (9, 25), (10, 25), (11, 25),                   #Short street E26:L26
                            (11, 0), (11, 1), (11, 2), (11, 3), (11, 4), (11, 5), (11, 6), (11, 7), (11, 8), (11, 9),   #Long street L0:L29
                            (11, 10), (11, 11), (11, 12), (11, 13), (11, 14), (11, 15), (11, 16), (11, 17), (11, 18),
                            (11, 19), (11, 20), (11, 21), (11, 22), (11, 23), (11, 24), (11, 25), (11, 26), (11, 27),
                            (11, 28), (11, 29),
                            (19, 0), (19, 1), (19, 2), (19, 3), (19, 4), (19, 5), (19, 6), (19, 7), (19, 8), (19, 9),   #Right Edge
                            (19, 10), (19, 11), (19, 12), (19, 13), (19, 14), (19, 15), (19, 16), (19, 17), (19, 18),
                            (19, 19), (19, 20), (19, 21), (19, 22), (19, 23), (19, 24), (19, 25), (19, 26), (19, 27),
                            (19, 28), (19, 29),
                            (16, 3), (16, 4), (16, 5), (16, 6), (16, 7), (16, 8), (16, 9), (16, 10),                    #Short Street Q4:Q11
                            (17, 10), (18, 10),
                            (16, 19),  (16, 20),  (16, 21),  (16, 22),  (16, 23),  (16, 24),  (16, 25),                 #Short Street Q17:Q26
                            (17, 25), (18, 25),
                            (13, 12), (13, 13), (13, 14), (13, 15), (13, 16), (13, 17), (13, 18), (13, 19),
                            (12, 19), (13, 19), (14, 19), (15, 19), (16, 19), (17, 19), (18, 19), (19, 19)
                            ]
    possible_locations = list(dict.fromkeys(possible_locations))
    for root, dirs, files in os.walk(script_dir):
        for dir in dirs:
            if dir != 'JSON_Files' and dir != '.idea':
                random_location = random.choice(possible_locations)
                event = {
                    'EventId': eventId,
                    'EventName': dir,
                    'Department': None,
                    'EventTextMain': None,
                    'EventTextFail': None,
                    'EventTextOK': None,
                    'ImgMain': None,
                    'ImgFail': None,
                    'ImgOK': None,
                    'Location': random_location
                }

                subdir = os.path.join(root, dir)
                print(subdir)
                subdir_splitted = subdir.split('\\')
                department = subdir_splitted[-2]
                department = department.split('_', 1)[0]
                event['Department'] = department
                print(department)
                for file in os.listdir(subdir):
                    file_path = r"res://Events/" + department + r"/" + dir + r"/" + file
                    if file.endswith('.txt'):
                        if 'Occurance' in file:
                            event['EventTextMain'] = file_path
                        elif 'Failure' in file:
                            event['EventTextFail'] = file_path
                        elif 'Success' in file:
                            event['EventTextOK'] = file_path
                    elif file.endswith('.png'):
                        if 'Failure' in file:
                            event['ImgFail'] = file_path
                        elif 'Occurance' in file:
                            event['ImgMain'] = file_path
                        elif 'Success' in file:
                            event['ImgOK'] = file_path

                json_path = os.path.join(subdir, f"{dir}.json")
                with open(json_path, 'w') as json_file:
                    json.dump(event, json_file, indent=4)

                eventId += 1


try:
    create_json_from_folders()
    print("Files have been created!")
except Exception:
    print("Ooops! Something went wrong! Scream in panic!")
