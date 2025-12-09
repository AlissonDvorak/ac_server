from flask import Flask, render_template, request, redirect, url_for
import docker
import os
import configparser

app = Flask(__name__)

# Configuration
CONFIG_PATH = "/data/configs"
SERVER_CONTAINER_NAME = os.environ.get("SERVER_CONTAINER_NAME", "ac-server")

# Initialize Docker Client
try:
    client = docker.from_env()
except Exception as e:
    print(f"Error connecting to Docker: {e}")
    client = None

def get_container():
    if not client:
        return None
    try:
        return client.containers.get(SERVER_CONTAINER_NAME)
    except Exception as e:
        print(f"Error getting container: {e}")
        return None

def read_ini(filename):
    config = configparser.ConfigParser()
    config.optionxform = str
    try:
        config.read(os.path.join(CONFIG_PATH, filename))
    except Exception as e:
        print(f"Error reading {filename}: {e}")
    return config

def write_ini(filename, config):
    try:
        with open(os.path.join(CONFIG_PATH, filename), 'w') as configfile:
            config.write(configfile)
    except Exception as e:
        print(f"Error writing {filename}: {e}")

@app.route('/')
def index():
    container = get_container()
    status = "Unknown"
    if container:
        status = container.status

    server_cfg = {}
    config = read_ini('server_cfg.ini')
    if 'SERVER' in config:
        server_cfg = dict(config['SERVER'])

    entry_list = []
    entry_config = read_ini('entry_list.ini')
    for section in entry_config.sections():
        if section.startswith('CAR_'):
            car_data = dict(entry_config[section])
            car_data['id'] = section # Store section name like CAR_0
            entry_list.append(car_data)

    return render_template('index.html', status=status, server_cfg=server_cfg, entry_list=entry_list)

@app.route('/restart', methods=['POST'])
def restart():
    container = get_container()
    if container:
        container.restart()
    return redirect(url_for('index'))

@app.route('/save_config', methods=['POST'])
def save_config():
    config = read_ini('server_cfg.ini')
    if 'SERVER' not in config:
        config['SERVER'] = {}

    # Update server fields
    for key in request.form:
        if key in ['NAME', 'TRACK', 'PASSWORD', 'ADMIN_PASSWORD', 'MAX_CLIENTS']:
             config['SERVER'][key] = request.form[key]

    write_ini('server_cfg.ini', config)
    return redirect(url_for('index'))

@app.route('/save_entry_list', methods=['POST'])
def save_entry_list():
    config = read_ini('entry_list.ini')

    # Simple implementation: Iterate over known indices based on form data
    # We assume form fields are named like "CAR_0_MODEL", "CAR_0_SKIN", etc.

    # First, gather all unique car IDs from the form keys
    car_ids = set()
    for key in request.form:
        if key.startswith('CAR_'):
            parts = key.split('_')
            # Assuming format CAR_X_FIELD
            if len(parts) >= 3:
                car_id = f"{parts[0]}_{parts[1]}"
                car_ids.add(car_id)

    for car_id in car_ids:
        if car_id not in config:
            config[car_id] = {}

        # Update fields for this car
        for field in ['MODEL', 'SKIN', 'DRIVERNAME', 'TEAM', 'GUID', 'SPECTATOR_MODE']:
            form_key = f"{car_id}_{field}"
            if form_key in request.form:
                 config[car_id][field] = request.form[form_key]

    write_ini('entry_list.ini', config)
    return redirect(url_for('index'))

@app.route('/logs')
def view_logs():
    container = get_container()
    logs = ""
    if container:
        try:
            # Get last 100 lines
            logs = container.logs(tail=100).decode('utf-8')
        except Exception as e:
            logs = f"Error fetching logs: {e}"
    return render_template('logs.html', logs=logs)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
