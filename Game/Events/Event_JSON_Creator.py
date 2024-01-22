import os
import json


def create_json_from_folders():
    eventId = 1
    script_dir = os.path.dirname(os.path.abspath(__file__))
    for root, dirs, files in os.walk(script_dir):
        for dir in dirs:
            if dir != 'JSON_Files':
                event = {
                    'EventId': eventId,
                    'EventName': dir,
                    'EventTextMain': None,
                    'EventTextFail': None,
                    'EventTextOK': None,
                    'ImgFail': None,
                    'ImgOK': None
                }

                subdir = os.path.join(root, dir)
                print(subdir)
                subdir_splitted = subdir.split('\\')
                department = subdir_splitted[-2]
                print(department)
                for file in os.listdir(subdir):
                    file_path =r"res://Events/" + department + r"/" + dir + r"/" + file
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
