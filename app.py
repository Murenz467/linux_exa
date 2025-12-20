import sqlite3
import subprocess
import os
import traceback
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'super_secret_key_change_in_production'

# Directory for shell scripts
SCRIPTS_DIR = os.path.join(os.path.dirname(__file__), 'scripts')

def init_db():
    """Initialize the database with all required tables"""
    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()
    
    # INSTANCES table - stores VM information
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS instances (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            os_type TEXT NOT NULL,
            cpu_cores INTEGER DEFAULT 1,
            ram_size INTEGER DEFAULT 1024,
            storage_size INTEGER DEFAULT 10000,
            ip_address TEXT,
            status TEXT DEFAULT 'stopped',
            vm_uuid TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # SERVICES table - stores installed services
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            instance_id INTEGER NOT NULL,
            service_name TEXT NOT NULL,
            status TEXT DEFAULT 'installed',
            installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (instance_id) REFERENCES instances (id) ON DELETE CASCADE
        )
    ''')
    
    # VM_USERS table - stores users on VMs
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS vm_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            instance_id INTEGER NOT NULL,
            username TEXT NOT NULL,
            has_sudo BOOLEAN DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (instance_id) REFERENCES instances (id) ON DELETE CASCADE
        )
    ''')
    
    conn.commit()
    conn.close()
    print("Database initialized successfully!")

def get_db_connection():
    """Get a database connection"""
    conn = sqlite3.connect('database.db')
    conn.row_factory = sqlite3.Row
    return conn

def run_shell_script(script_name, *args):
    """Execute a shell script and return the result"""
    script_path = os.path.join(SCRIPTS_DIR, script_name)
    
    # Convert to absolute path and normalize for the current OS
    script_path = os.path.abspath(script_path)
    
    if not os.path.exists(script_path):
        return {
            'success': False, 
            'message': f'Script {script_name} not found at {script_path}',
            'stderr': f'Script not found: {script_path}',
            'stdout': ''
        }
    
    # Find bash executable (works on Windows with Git Bash)
    bash_cmd = 'bash'
    possible_bash_paths = [
        'bash',  # If in PATH
        r'C:\Program Files\Git\bin\bash.exe',
        r'C:\Program Files (x86)\Git\bin\bash.exe',
    ]
    
    bash_executable = None
    for bash_path in possible_bash_paths:
        try:
            result = subprocess.run([bash_path, '--version'], 
                                  capture_output=True, 
                                  timeout=5)
            if result.returncode == 0:
                bash_executable = bash_path
                break
        except:
            continue
    
    if not bash_executable:
        return {
            'success': False,
            'message': 'Bash not found. Please install Git Bash.',
            'stderr': 'Bash executable not found',
            'stdout': ''
        }
    
    try:
        # Make script executable (Unix-like systems)
        try:
            os.chmod(script_path, 0o755)
        except:
            pass  # Windows doesn't need this
        
        # Run the script
        print(f"Executing: {bash_executable} \"{script_path}\" {' '.join(str(arg) for arg in args)}")
        
        result = subprocess.run(
            [bash_executable, script_path] + list(args),
            capture_output=True,
            text=True,
            timeout=120,
            cwd=SCRIPTS_DIR  # Set working directory to scripts folder
        )
        
        print(f"Return code: {result.returncode}")
        print(f"STDOUT: {result.stdout}")
        print(f"STDERR: {result.stderr}")
        
        return {
            'success': result.returncode == 0,
            'stdout': result.stdout.strip(),
            'stderr': result.stderr.strip(),
            'returncode': result.returncode
        }
    except subprocess.TimeoutExpired:
        return {
            'success': False, 
            'message': 'Script execution timed out',
            'stderr': 'Timeout after 120 seconds',
            'stdout': ''
        }
    except Exception as e:
        return {
            'success': False, 
            'message': str(e),
            'stderr': str(e),
            'stdout': ''
        }

@app.route('/')
def index():
    """Display all virtual servers"""
    conn = get_db_connection()
    vms = conn.execute('SELECT * FROM instances ORDER BY created_at DESC').fetchall()
    conn.close()
    return render_template('index.html', vms=vms)

@app.route('/create', methods=['GET', 'POST'])
def create():
    """Create a new virtual server"""
    if request.method == 'POST':
        try:
            name = request.form['name']
            os_type = request.form['os_type']
            cpu_cores = request.form['cpu']
            ram_size = request.form['ram']
            storage_size = request.form['storage']
            
            # Get selected services
            services = request.form.getlist('services')
            
            # Get user details
            username = request.form.get('username', '').strip()
            password = request.form.get('password', '').strip()
            has_sudo = 'sudo' in request.form
            
            print(f"\n{'='*50}")
            print(f"Creating VM with parameters:")
            print(f"Name: {name}")
            print(f"OS: {os_type}")
            print(f"CPU: {cpu_cores} cores")
            print(f"RAM: {ram_size} MB")
            print(f"Storage: {storage_size} MB")
            print(f"Services: {services}")
            print(f"User: {username if username else 'None'}")
            print(f"{'='*50}\n")
            
            # Validate inputs
            if not name:
                flash('Server name is required!', 'error')
                return redirect(url_for('create'))
            
            conn = get_db_connection()
            
            # Check if name already exists
            existing = conn.execute('SELECT id FROM instances WHERE name = ?', (name,)).fetchone()
            if existing:
                flash(f'Server with name "{name}" already exists!', 'error')
                conn.close()
                return redirect(url_for('create'))
            
            # Call shell script to create VM in VirtualBox
            print("Calling create_vm.sh script...")
            result = run_shell_script('create_vm.sh', name, os_type, cpu_cores, ram_size, storage_size)
            
            if not result['success']:
                error_msg = result.get('stderr') or result.get('message') or 'Unknown error'
                print(f"ERROR: VM creation failed: {error_msg}")
                flash(f'Error creating VM: {error_msg}', 'error')
                conn.close()
                return redirect(url_for('create'))
            
            # Extract UUID from script output
            stdout_lines = result['stdout'].split('\n')
            vm_uuid = stdout_lines[-1].strip() if stdout_lines else None
            
            print(f"VM created with UUID: {vm_uuid}")
            
            # Insert into database
            cursor = conn.execute(
                '''INSERT INTO instances (name, os_type, cpu_cores, ram_size, storage_size, vm_uuid) 
                   VALUES (?, ?, ?, ?, ?, ?)''',
                (name, os_type, cpu_cores, ram_size, storage_size, vm_uuid)
            )
            instance_id = cursor.lastrowid
            print(f"Inserted into database with ID: {instance_id}")
            
            # Insert selected services
            for service in services:
                conn.execute(
                    'INSERT INTO services (instance_id, service_name) VALUES (?, ?)',
                    (instance_id, service)
                )
                print(f"Queued service: {service}")
            
            # Create user if provided
            if username and password:
                conn.execute(
                    'INSERT INTO vm_users (instance_id, username, has_sudo) VALUES (?, ?, ?)',
                    (instance_id, username, has_sudo)
                )
                print(f"Queued user creation: {username} (sudo: {has_sudo})")
                
                # Call script to create user on VM (this will be simulated)
                user_result = run_shell_script('manage_users.sh', name, username, password, 'yes' if has_sudo else 'no')
                if not user_result['success']:
                    print(f"Warning: User creation script failed: {user_result.get('stderr', 'Unknown')}")
            
            conn.commit()
            conn.close()
            
            flash(f'Server "{name}" created successfully!', 'success')
            print(f"SUCCESS: VM '{name}' created successfully!\n")
            return redirect(url_for('index'))
            
        except Exception as e:
            print(f"EXCEPTION in create(): {str(e)}")
            print(traceback.format_exc())
            flash(f'Unexpected error: {str(e)}', 'error')
            if 'conn' in locals():
                conn.close()
            return redirect(url_for('create'))
    
    return render_template('create.html')

@app.route('/vm/<action>/<int:id>')
def vm_action(action, id):
    """Handle VM actions: start, stop, delete"""
    conn = get_db_connection()
    vm = conn.execute('SELECT * FROM instances WHERE id = ?', (id,)).fetchone()
    
    if not vm:
        flash('Server not found!', 'error')
        conn.close()
        return redirect(url_for('index'))
    
    if action == 'start':
        # Changed to use start_vm.sh instead of manage_vm.sh
        result = run_shell_script('start_vm.sh', vm['name'])
        if result['success']:
            conn.execute('UPDATE instances SET status = ? WHERE id = ?', ('running', id))
            conn.commit()
            flash(f'Server "{vm["name"]}" started successfully!', 'success')
        else:
            error_msg = result.get('stderr') or result.get('message') or result.get('stdout') or 'Unknown error'
            print(f"Start failed: {result}")
            flash(f'Error starting server: {error_msg}', 'error')
    
    elif action == 'stop':
        # Changed to use stop_vm.sh instead of manage_vm.sh
        result = run_shell_script('stop_vm.sh', vm['name'])
        if result['success']:
            conn.execute('UPDATE instances SET status = ? WHERE id = ?', ('stopped', id))
            conn.commit()
            flash(f'Server "{vm["name"]}" stopped successfully!', 'success')
        else:
            error_msg = result.get('stderr') or result.get('message') or result.get('stdout') or 'Unknown error'
            print(f"Stop failed: {result}")
            flash(f'Error stopping server: {error_msg}', 'error')
    
    elif action == 'delete':
        result = run_shell_script('destroy_vm.sh', vm['name'])
        if result['success']:
            conn.execute('DELETE FROM instances WHERE id = ?', (id,))
            conn.commit()
            flash(f'Server "{vm["name"]}" deleted successfully!', 'success')
        else:
            error_msg = result.get('stderr') or result.get('message') or result.get('stdout') or 'Unknown error'
            print(f"Delete failed: {result}")
            flash(f'Error deleting server: {error_msg}', 'error')
    
    else:
        flash('Invalid action!', 'error')
    
    conn.close()
    return redirect(url_for('index'))

@app.route('/vm/clone/<int:id>', methods=['POST'])
def clone_vm(id):
    """Clone an existing VM"""
    new_name = request.form.get('new_name', '').strip()
    
    if not new_name:
        flash('New server name is required!', 'error')
        return redirect(url_for('index'))
    
    conn = get_db_connection()
    source_vm = conn.execute('SELECT * FROM instances WHERE id = ?', (id,)).fetchone()
    
    if not source_vm:
        flash('Source server not found!', 'error')
        conn.close()
        return redirect(url_for('index'))
    
    # Check if new name already exists
    existing = conn.execute('SELECT id FROM instances WHERE name = ?', (new_name,)).fetchone()
    if existing:
        flash(f'Server with name "{new_name}" already exists!', 'error')
        conn.close()
        return redirect(url_for('index'))
    
    try:
        print(f"Cloning VM: {source_vm['name']} -> {new_name}")
        
        # Call clone script
        result = run_shell_script('clone_vm.sh', source_vm['name'], new_name)
        
        if not result['success']:
            error_msg = result.get('stderr') or result.get('message') or 'Unknown error'
            flash(f'Error cloning server: {error_msg}', 'error')
            conn.close()
            return redirect(url_for('index'))
        
        # Extract UUID from output
        stdout_lines = result['stdout'].split('\n')
        new_uuid = stdout_lines[-1].strip() if stdout_lines else None
        
        # Insert cloned VM into database
        cursor = conn.execute(
            '''INSERT INTO instances (name, os_type, cpu_cores, ram_size, storage_size, vm_uuid, status) 
               VALUES (?, ?, ?, ?, ?, ?, 'stopped')''',
            (new_name, source_vm['os_type'], source_vm['cpu_cores'], 
             source_vm['ram_size'], source_vm['storage_size'], new_uuid)
        )
        new_id = cursor.lastrowid
        
        # Copy services from source VM
        services = conn.execute(
            'SELECT service_name FROM services WHERE instance_id = ?',
            (id,)
        ).fetchall()
        
        for service in services:
            conn.execute(
                'INSERT INTO services (instance_id, service_name) VALUES (?, ?)',
                (new_id, service['service_name'])
            )
        
        # Copy users from source VM
        users = conn.execute(
            'SELECT username, has_sudo FROM vm_users WHERE instance_id = ?',
            (id,)
        ).fetchall()
        
        for user in users:
            conn.execute(
                'INSERT INTO vm_users (instance_id, username, has_sudo) VALUES (?, ?, ?)',
                (new_id, user['username'], user['has_sudo'])
            )
        
        conn.commit()
        flash(f'Server "{source_vm["name"]}" cloned to "{new_name}" successfully!', 'success')
        
    except Exception as e:
        print(f"Exception in clone_vm: {str(e)}")
        flash(f'Error cloning server: {str(e)}', 'error')
    finally:
        conn.close()
    
    return redirect(url_for('index'))

@app.route('/vm/details/<int:id>')
def vm_details(id):
    """Display detailed information about a VM"""
    conn = get_db_connection()
    vm = conn.execute('SELECT * FROM instances WHERE id = ?', (id,)).fetchone()
    
    if vm is None:
        flash('Server not found!', 'error')
        conn.close()
        return redirect(url_for('index'))
    
    # Get services for this VM
    services = conn.execute(
        'SELECT * FROM services WHERE instance_id = ? ORDER BY installed_at DESC',
        (id,)
    ).fetchall()
    
    # Get users for this VM
    users = conn.execute(
        'SELECT * FROM vm_users WHERE instance_id = ? ORDER BY created_at DESC',
        (id,)
    ).fetchall()
    
    conn.close()
    
    return render_template('details.html', vm=vm, services=services, users=users)

@app.route('/vm/monitor/<int:id>')
def vm_monitor(id):
    """Real-time monitoring page for a VM"""
    conn = get_db_connection()
    vm = conn.execute('SELECT * FROM instances WHERE id = ?', (id,)).fetchone()
    conn.close()
    
    if vm is None:
        flash('Server not found!', 'error')
        return redirect(url_for('index'))
    
    return render_template('monitor.html', vm=vm)

@app.route('/api/vm/<int:id>/stats')
def vm_stats(id):
    """Get real-time VM statistics"""
    conn = get_db_connection()
    vm = conn.execute('SELECT * FROM instances WHERE id = ?', (id,)).fetchone()
    conn.close()
    
    if not vm:
        return jsonify({'error': 'VM not found'}), 404
    
    # Call monitoring script
    result = run_shell_script('get_vm_stats.sh', vm['name'])
    
    if result['success']:
        try:
            import json
            stats = json.loads(result['stdout'])
            return jsonify(stats)
        except:
            return jsonify({'error': 'Failed to parse stats', 'output': result['stdout']})
    else:
        return jsonify({'error': 'Failed to get stats', 'message': result.get('stderr', 'Unknown error')})

@app.route('/vm/<int:id>/install_service', methods=['POST'])
def install_service(id):
    """Install a service on a VM"""
    service_name = request.form.get('service_name')
    
    if not service_name:
        flash('Service name is required!', 'error')
        return redirect(url_for('vm_details', id=id))
    
    conn = get_db_connection()
    vm = conn.execute('SELECT * FROM instances WHERE id = ?', (id,)).fetchone()
    
    if not vm:
        flash('Server not found!', 'error')
        conn.close()
        return redirect(url_for('index'))
    
    # Call script to install service
    result = run_shell_script('install_service.sh', vm['name'], service_name)
    
    if result['success']:
        conn.execute(
            'INSERT INTO services (instance_id, service_name) VALUES (?, ?)',
            (id, service_name)
        )
        conn.commit()
        flash(f'Service "{service_name}" installed successfully!', 'success')
    else:
        flash(f'Error installing service: {result.get("stderr", result.get("message"))}', 'error')
    
    conn.close()
    return redirect(url_for('vm_details', id=id))

@app.route('/vm/<int:id>/create_user', methods=['POST'])
def create_user(id):
    """Create a user on a VM"""
    username = request.form.get('username', '').strip()
    password = request.form.get('password', '').strip()
    has_sudo = 'sudo' in request.form
    
    if not username or not password:
        flash('Username and password are required!', 'error')
        return redirect(url_for('vm_details', id=id))
    
    conn = get_db_connection()
    vm = conn.execute('SELECT * FROM instances WHERE id = ?', (id,)).fetchone()
    
    if not vm:
        flash('Server not found!', 'error')
        conn.close()
        return redirect(url_for('index'))
    
    # Call script to create user
    result = run_shell_script('manage_users.sh', vm['name'], username, password, 'yes' if has_sudo else 'no')
    
    if result['success']:
        conn.execute(
            'INSERT INTO vm_users (instance_id, username, has_sudo) VALUES (?, ?, ?)',
            (id, username, has_sudo)
        )
        conn.commit()
        flash(f'User "{username}" created successfully!', 'success')
    else:
        flash(f'Error creating user: {result.get("stderr", result.get("message"))}', 'error')
    
    conn.close()
    return redirect(url_for('vm_details', id=id))

if __name__ == '__main__':
    # Create scripts directory if it doesn't exist
    os.makedirs(SCRIPTS_DIR, exist_ok=True)
    
    # Initialize database
    init_db()
    
    print("=" * 50)
    print("Virtual Server Manager Started!")
    print("=" * 50)
    print("Access the application at: http://localhost:5000")
    print("Make sure VirtualBox is installed on your system")
    print(f"Scripts directory: {SCRIPTS_DIR}")
    print("=" * 50)
    
    app.run(debug=True, port=5000)