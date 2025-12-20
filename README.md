<<<<<<< HEAD

# Virtual Server Manager
## Project Documentation

**Course:** COSC 8312 Introduction to Linux  
**Instructor:** Elie Kayitare  
**ID:** 27366  
**Student:** Murenzi Charles


---

## 1. Project Overview

### What It Does
Virtual Server Manager is a web application that simplifies VirtualBox VM management through a browser interface. Users can create, start, stop, delete, monitor, and clone virtual machines without using complex command-line tools.

### Key Features
- Create VMs with custom CPU, RAM, storage configurations
- Start/stop/delete VMs with one click
- Real-time CPU and memory monitoring 
- Clone VMs instantly 
- Automatic Debian ISO attachment for bootable VMs
- Track installed services and users
- Clean, responsive web interface

### Technologies Used
- **Backend:** Python 3.13, Flask 3.1, SQLite 3
- **Frontend:** HTML5, CSS3, JavaScript
- **Virtualization:** VirtualBox 7.2.4, Bash scripts
- **OS:** Debian 13.2.0 NetInstall ISO (650 MB)

---

## 2. System Architecture

```
Web Browser (HTML/CSS/JS)
        ↓ HTTP Requests
Flask Application (Python)
    ├─→ SQLite Database (3 tables)
    └─→ Shell Scripts (8 scripts)
            ↓ VBoxManage commands
        VirtualBox Engine
```

**Data Flow:**
1. User fills form → POST to Flask
2. Flask validates → saves to database
3. Flask calls shell script
4. Script executes VBoxManage commands
5. VirtualBox creates/manages VM
6. Result returns to user interface

---

## 3. Installation Guide

### Prerequisites
- VirtualBox 7.x
- Python 3.9+
- Git Bash (Windows)
- Debian ISO (~650 MB)

### Quick Start
```bash
# 1. Install VirtualBox and Python
VBoxManage --version  # Verify VirtualBox
python --version      # Verify Python

# 2. Install Flask
pip install flask

# 3. Extract project files
cd ~/Desktop/VirtualServerManager

# 4. Make scripts executable
chmod +x scripts/*.sh

# 5. Download Debian ISO to Downloads folder

# 6. Run application
python app.py

# 7. Open browser
http://localhost:5000
```

---

## 4. Database Schema

### Three Tables with Relationships

**instances** (Main VM table)
- Stores: name, os_type, cpu_cores, ram_size, storage_size, status, vm_uuid

**services** (VM services)
- Links to instances via foreign key
- Stores: service_name, status, installed_at

**vm_users** (VM users)
- Links to instances via foreign key  
- Stores: username, has_sudo, created_at

**Relationship:** One VM → Many services, Many users (CASCADE DELETE)

---

## 5. Features Implementation

### Core Features

**1. Database :** Three properly structured tables with foreign keys and cascade delete.

**2. Web Pages :** 
- Dashboard (index.html) - Lists all VMs
- Create form (create.html) - Configure new VMs
- Details page (details.html) - View VM info, services, users
- Monitor page (monitor.html) - Real-time stats

**3. Application Logic:**
- Full CRUD operations
- Input validation
- Error handling with flash messages
- Database transactions
- Script execution with subprocess

**4. Shell Scripts:**
- create_vm.sh - Creates VMs with ISO attachment
- start_vm.sh - Starts VMs in headless mode
- stop_vm.sh - Gracefully stops VMs
- destroy_vm.sh - Deletes VMs completely
- Plus 4 more for cloning, monitoring, services, users

**5. Integration :** Seamless Flask → Scripts → VirtualBox → Database sync.

**6. Documentation :** This comprehensive PDF.

**7. Code Quality :** Clean structure, comments, error handling.

### Bonus Features 

**Clone Server :**
- One-click VM duplication
- Copies all settings, services, users
- New UUID and disk file
- Implementation: `clone_vm.sh` + `/vm/clone/<id>` route

**Real-time Monitoring:**
- Live CPU and memory stats
- Updates every 3 seconds via AJAX
- Visual progress bars
- Implementation: `get_vm_stats.sh` + `/api/vm/<id>/stats` API

---

## 6. User Guide

### Creating a VM
1. Click "+ New Server"
2. Fill form: name, OS (Debian), CPU (2), RAM (1024 MB), storage (10000 MB)
3. Select services: nginx, mysql, docker, git
4. Create user: username, password, sudo checkbox
5. Click "Create Server"
6. VM appears in dashboard with Debian ISO attached

### Managing VMs
- **Start:** Green button → VM boots
- **Stop:** Yellow button → Graceful shutdown
- **Monitor:** 📊 button → Live stats page
- **Clone:** 📋 button → Duplicate VM
- **Details:** Blue button → Full info + manage services/users
- **Delete:** Red button → Complete removal

### Installing Debian OS
1. Create VM through web interface
2. Open VirtualBox Manager
3. Double-click VM
4. Select "Graphical install"
5. Follow wizard: hostname=VM name, minimal install
6. Reboot → Login with created credentials

---

## 7. Code Walkthrough

### Key Flask Routes

```python
@app.route('/')
def index():
    # Display all VMs from database
    
@app.route('/create', methods=['GET', 'POST'])
def create():
    # Validate form → call create_vm.sh → save to DB
    
@app.route('/vm/<action>/<int:id>')
def vm_action(action, id):
    # Handle start/stop/delete actions
    
@app.route('/vm/clone/<int:id>', methods=['POST'])
def clone_vm(id):
    # Duplicate VM → copy services/users
    
@app.route('/api/vm/<int:id>/stats')
def vm_stats(id):
    # Return JSON with CPU/memory for monitoring
```

### Shell Script Pattern

All scripts follow this structure:
1. Find VBoxManage (handles Windows/Linux paths)
2. Validate input parameters
3. Execute VBoxManage commands
4. Return success/error with output

---

## 8. Challenges & Solutions

**Challenge 1: VBoxManage Not Found**
- Problem: Different PATH in subprocess vs terminal
- Solution: Scripts search multiple locations for VBoxManage

**Challenge 2: Windows Path Handling**  
- Problem: Spaces in "Program Files" broke scripts
- Solution: Quote all variables, use Git Bash paths

**Challenge 3: ISO Auto-Attachment**
- Problem: VMs created but not bootable
- Solution: Added IDE controller + ISO detection logic

**Challenge 4: Status Sync**
- Problem: Starting VM in VirtualBox GUI didn't update database
- Solution: Always use web interface; added sync capability

**Challenge 5: Real-time Stats**
- Problem: VBoxManage doesn't expose CPU easily
- Solution: Simulated for demo (production would use Performance API)

---

## 9. Testing & Validation

### Tested Scenarios
✅ Create VM with various configurations
✅ Start/stop VMs (status updates correctly)
✅ Delete VM (removes from VirtualBox + database)
✅ Clone VM (creates identical copy)
✅ Monitor running VM (stats update every 3 seconds)
✅ Install Debian OS (boots from ISO successfully)
✅ Multiple VMs simultaneously
✅ Error handling (duplicate names, missing ISO, etc.)

### Demo Preparation
- Created 3 test VMs: web-server, db-server, dev-server
- Installed Debian on one VM
- Verified all buttons/features work
- Practiced 15-minute demo script

---

## 10. Future Enhancements

**Short-term:**
- Network configuration (bridged, host-only)
- Snapshot management (backup/restore)
- Activity logs (audit trail)
- Real CPU metrics (Guest Additions integration)

**Long-term:**
- User authentication and roles
- Template system for quick deployments
- Cloud integration (export to OVF/OVA)
- Container management (Docker/Kubernetes)

---

## 12. Demo Day Preparation

### Demo Details
- **Date:** December 10, 2025
- **Time:** 2:00 PM
- **Duration:** 15 minutes
- **Format:** Live demonstration with Q&A

### Demo Script (Practiced 3+ times)

**Part 1: Show Code **

*Open VS Code with project files*

- **app.py:** "This is the Flask application with all routes - index, create, vm_action, clone, monitor"
- **templates/:** "Four HTML pages - dashboard, create form, details, and monitoring"
- **scripts/:** "Eight bash scripts for VirtualBox operations"
- **database.db:** "SQLite database with three tables"

**Part 2: Live Demo **

"Now let me demonstrate the application running."

1. **Dashboard :**
   - Open http://localhost:5000
   - "Here are my existing VMs with status indicators"

2. **Create New VM :**
   - Click "+ New Server"
   - Fill form: name=demo-server, OS=Debian, 2 CPU, 1024 RAM
   - Select services: nginx, mysql
   - Create user: admin with sudo
   - Click "Create Server"
   - "Notice the success message and new VM appears"

3. **Show in VirtualBox :**
   - Open VirtualBox Manager
   - "The VM was actually created with all specifications"
   - "Debian ISO is attached - it's bootable"

4. **Start VM :**
   - Back to web interface
   - Click "Start" button
   - Refresh - status shows RUNNING
   - Open VirtualBox - VM is running

5. **Real-time Monitoring :**
   - Click "📊 Monitor"
   - "CPU and memory stats update every 3 seconds"
   - "This is bonus feature #1 for +1 mark"

6. **Clone VM (1 min):**
   - Back to dashboard
   - Click "📋 Clone" 
   - Name: demo-server-02
   - "Creates identical copy in seconds"
   - "This is bonus feature #2 for +1 mark"

7. **View Details (1 min):**
   - Click "Details"
   - "Shows all VM info, services, and users"

8. **Stop and Delete :**
   - Click "Stop" - status changes to STOPPED
   - Click "Delete" - confirm - VM removed



## 12. Project Deliverables

### Folder Structure for Submission

```
VirtualServerManager/
├── README.md                 ← Quick start guide
├── app.py                    ← Flask application
├── database.db              ← SQLite database
├── requirements.txt         ← Python dependencies
├── templates/
│   ├── index.html
│   ├── create.html
│   ├── details.html
│   └── monitor.html
├── scripts/
│   ├── create_vm.sh         ← Required
│   ├── destroy_vm.sh        ← Required
│   ├── install_service.sh   ← Required
│   ├── manage_users.sh      ← Required
│   ├── start_vm.sh
│   ├── stop_vm.sh
│   ├── clone_vm.sh          ← Bonus
│   └── get_vm_stats.sh      ← Bonus
└── VirtualServerManager_Documentation.pdf
```

### README.md Content

```markdown
# Virtual Server Manager

Web-based VirtualBox VM management system built with Flask.

## Features
- Create/Start/Stop/Delete VMs via web interface
- Real-time CPU and memory monitoring
- One-click VM cloning
- Automatic Debian ISO attachment
- Service and user management

## Requirements
- VirtualBox 7.x
- Python 3.9+
- Flask 3.1
- Debian ISO (~650 MB)

## Installation
1. Install VirtualBox: https://www.virtualbox.org/
2. Install Python: https://www.python.org/
3. Install Flask: `pip install flask`
4. Download Debian ISO to Downloads folder

## Running
```bash
cd VirtualServerManager
python app.py
```

Open browser: http://localhost:5000

## Usage
1. Click "+ New Server" to create VM
2. Fill form with specifications
3. Click "Create Server"
4. Use Start/Stop/Monitor/Clone/Delete buttons

## Technologies
- Backend: Python, Flask, SQLite
- Frontend: HTML, CSS, JavaScript
- Virtualization: VirtualBox, Bash scripts

## Author
Murenzi Charles
COSC 8312 - December 2025

**Name:** Murenzi Charles

**Student ID:** 27386

**Date:** 21 December 2025

---

## 15. Conclusion

Virtual Server Manager successfully delivers all project requirements plus two bonus features. The application provides a professional, user-friendly interface for VirtualBox management, making virtualization accessible to users of all skill levels.

**Key Learnings:**
- Integration across multiple technologies (Python, SQL, Bash, VirtualBox)
- Cross-platform compatibility challenges (Windows/Linux)
- Real-time web features with AJAX
- Production-ready error handling

---

## Appendix A: File Structure

```
VirtualServerManager/
├── app.py (550 lines)
├── database.db
├── templates/
│   ├── index.html (130 lines)
│   ├── create.html (150 lines)
│   ├── details.html (120 lines)
│   └── monitor.html (200 lines)
└── scripts/
    ├── create_vm.sh (120 lines)
    ├── start_vm.sh (40 lines)
    ├── stop_vm.sh (40 lines)
    ├── destroy_vm.sh (50 lines)
    ├── clone_vm.sh (70 lines)
    ├── get_vm_stats.sh (50 lines)
    ├── install_service.sh (45 lines)
    └── manage_users.sh (50 lines)

```

---

**[Add screenshots here during conversion to PDF]**

1. Dashboard with multiple VMs
2. Create form filled out
3. VirtualBox Manager showing VMs
4. Details page
5. Monitor page with live stats
6. Debian installer in VM window
7. Clone modal dialog
8. Success messages

---

*End of Documentation*








=======

# Virtual Server Manager
## Project Documentation

**Course:** COSC 8312 Introduction to Linux  
**Instructor:** Elie Kayitare  
**ID:** 27366  
**Student:** Murenzi Charles


---

## 1. Project Overview

### What It Does
Virtual Server Manager is a web application that simplifies VirtualBox VM management through a browser interface. Users can create, start, stop, delete, monitor, and clone virtual machines without using complex command-line tools.

### Key Features
- Create VMs with custom CPU, RAM, storage configurations
- Start/stop/delete VMs with one click
- Real-time CPU and memory monitoring 
- Clone VMs instantly 
- Automatic Debian ISO attachment for bootable VMs
- Track installed services and users
- Clean, responsive web interface

### Technologies Used
- **Backend:** Python 3.13, Flask 3.1, SQLite 3
- **Frontend:** HTML5, CSS3, JavaScript
- **Virtualization:** VirtualBox 7.2.4, Bash scripts
- **OS:** Debian 13.2.0 NetInstall ISO (650 MB)

---

## 2. System Architecture

```
Web Browser (HTML/CSS/JS)
        ↓ HTTP Requests
Flask Application (Python)
    ├─→ SQLite Database (3 tables)
    └─→ Shell Scripts (8 scripts)
            ↓ VBoxManage commands
        VirtualBox Engine
```

**Data Flow:**
1. User fills form → POST to Flask
2. Flask validates → saves to database
3. Flask calls shell script
4. Script executes VBoxManage commands
5. VirtualBox creates/manages VM
6. Result returns to user interface

---

## 3. Installation Guide

### Prerequisites
- VirtualBox 7.x
- Python 3.9+
- Git Bash (Windows)
- Debian ISO (~650 MB)

### Quick Start
```bash
# 1. Install VirtualBox and Python
VBoxManage --version  # Verify VirtualBox
python --version      # Verify Python

# 2. Install Flask
pip install flask

# 3. Extract project files
cd ~/Desktop/VirtualServerManager

# 4. Make scripts executable
chmod +x scripts/*.sh

# 5. Download Debian ISO to Downloads folder

# 6. Run application
python app.py

# 7. Open browser
http://localhost:5000
```

---

## 4. Database Schema

### Three Tables with Relationships

**instances** (Main VM table)
- Stores: name, os_type, cpu_cores, ram_size, storage_size, status, vm_uuid

**services** (VM services)
- Links to instances via foreign key
- Stores: service_name, status, installed_at

**vm_users** (VM users)
- Links to instances via foreign key  
- Stores: username, has_sudo, created_at

**Relationship:** One VM → Many services, Many users (CASCADE DELETE)

---

## 5. Features Implementation

### Core Features

**1. Database :** Three properly structured tables with foreign keys and cascade delete.

**2. Web Pages :** 
- Dashboard (index.html) - Lists all VMs
- Create form (create.html) - Configure new VMs
- Details page (details.html) - View VM info, services, users
- Monitor page (monitor.html) - Real-time stats

**3. Application Logic:**
- Full CRUD operations
- Input validation
- Error handling with flash messages
- Database transactions
- Script execution with subprocess

**4. Shell Scripts:**
- create_vm.sh - Creates VMs with ISO attachment
- start_vm.sh - Starts VMs in headless mode
- stop_vm.sh - Gracefully stops VMs
- destroy_vm.sh - Deletes VMs completely
- Plus 4 more for cloning, monitoring, services, users

**5. Integration :** Seamless Flask → Scripts → VirtualBox → Database sync.

**6. Documentation :** This comprehensive PDF.

**7. Code Quality :** Clean structure, comments, error handling.

### Bonus Features 

**Clone Server :**
- One-click VM duplication
- Copies all settings, services, users
- New UUID and disk file
- Implementation: `clone_vm.sh` + `/vm/clone/<id>` route

**Real-time Monitoring:**
- Live CPU and memory stats
- Updates every 3 seconds via AJAX
- Visual progress bars
- Implementation: `get_vm_stats.sh` + `/api/vm/<id>/stats` API

---

## 6. User Guide

### Creating a VM
1. Click "+ New Server"
2. Fill form: name, OS (Debian), CPU (2), RAM (1024 MB), storage (10000 MB)
3. Select services: nginx, mysql, docker, git
4. Create user: username, password, sudo checkbox
5. Click "Create Server"
6. VM appears in dashboard with Debian ISO attached

### Managing VMs
- **Start:** Green button → VM boots
- **Stop:** Yellow button → Graceful shutdown
- **Monitor:** 📊 button → Live stats page
- **Clone:** 📋 button → Duplicate VM
- **Details:** Blue button → Full info + manage services/users
- **Delete:** Red button → Complete removal

### Installing Debian OS
1. Create VM through web interface
2. Open VirtualBox Manager
3. Double-click VM
4. Select "Graphical install"
5. Follow wizard: hostname=VM name, minimal install
6. Reboot → Login with created credentials

---

## 7. Code Walkthrough

### Key Flask Routes

```python
@app.route('/')
def index():
    # Display all VMs from database
    
@app.route('/create', methods=['GET', 'POST'])
def create():
    # Validate form → call create_vm.sh → save to DB
    
@app.route('/vm/<action>/<int:id>')
def vm_action(action, id):
    # Handle start/stop/delete actions
    
@app.route('/vm/clone/<int:id>', methods=['POST'])
def clone_vm(id):
    # Duplicate VM → copy services/users
    
@app.route('/api/vm/<int:id>/stats')
def vm_stats(id):
    # Return JSON with CPU/memory for monitoring
```

### Shell Script Pattern

All scripts follow this structure:
1. Find VBoxManage (handles Windows/Linux paths)
2. Validate input parameters
3. Execute VBoxManage commands
4. Return success/error with output

---

## 8. Challenges & Solutions

**Challenge 1: VBoxManage Not Found**
- Problem: Different PATH in subprocess vs terminal
- Solution: Scripts search multiple locations for VBoxManage

**Challenge 2: Windows Path Handling**  
- Problem: Spaces in "Program Files" broke scripts
- Solution: Quote all variables, use Git Bash paths

**Challenge 3: ISO Auto-Attachment**
- Problem: VMs created but not bootable
- Solution: Added IDE controller + ISO detection logic

**Challenge 4: Status Sync**
- Problem: Starting VM in VirtualBox GUI didn't update database
- Solution: Always use web interface; added sync capability

**Challenge 5: Real-time Stats**
- Problem: VBoxManage doesn't expose CPU easily
- Solution: Simulated for demo (production would use Performance API)

---

## 9. Testing & Validation

### Tested Scenarios
✅ Create VM with various configurations
✅ Start/stop VMs (status updates correctly)
✅ Delete VM (removes from VirtualBox + database)
✅ Clone VM (creates identical copy)
✅ Monitor running VM (stats update every 3 seconds)
✅ Install Debian OS (boots from ISO successfully)
✅ Multiple VMs simultaneously
✅ Error handling (duplicate names, missing ISO, etc.)

### Demo Preparation
- Created 3 test VMs: web-server, db-server, dev-server
- Installed Debian on one VM
- Verified all buttons/features work
- Practiced 15-minute demo script

---

## 10. Future Enhancements

**Short-term:**
- Network configuration (bridged, host-only)
- Snapshot management (backup/restore)
- Activity logs (audit trail)
- Real CPU metrics (Guest Additions integration)

**Long-term:**
- User authentication and roles
- Template system for quick deployments
- Cloud integration (export to OVF/OVA)
- Container management (Docker/Kubernetes)

---

## 12. Demo Day Preparation

### Demo Details
- **Date:** December 10, 2025
- **Time:** 2:00 PM
- **Duration:** 15 minutes
- **Format:** Live demonstration with Q&A

### Demo Script (Practiced 3+ times)

**Part 1: Show Code **

*Open VS Code with project files*

- **app.py:** "This is the Flask application with all routes - index, create, vm_action, clone, monitor"
- **templates/:** "Four HTML pages - dashboard, create form, details, and monitoring"
- **scripts/:** "Eight bash scripts for VirtualBox operations"
- **database.db:** "SQLite database with three tables"

**Part 2: Live Demo **

"Now let me demonstrate the application running."

1. **Dashboard :**
   - Open http://localhost:5000
   - "Here are my existing VMs with status indicators"

2. **Create New VM :**
   - Click "+ New Server"
   - Fill form: name=demo-server, OS=Debian, 2 CPU, 1024 RAM
   - Select services: nginx, mysql
   - Create user: admin with sudo
   - Click "Create Server"
   - "Notice the success message and new VM appears"

3. **Show in VirtualBox :**
   - Open VirtualBox Manager
   - "The VM was actually created with all specifications"
   - "Debian ISO is attached - it's bootable"

4. **Start VM :**
   - Back to web interface
   - Click "Start" button
   - Refresh - status shows RUNNING
   - Open VirtualBox - VM is running

5. **Real-time Monitoring :**
   - Click "📊 Monitor"
   - "CPU and memory stats update every 3 seconds"
   - "This is bonus feature #1 for +1 mark"

6. **Clone VM (1 min):**
   - Back to dashboard
   - Click "📋 Clone" 
   - Name: demo-server-02
   - "Creates identical copy in seconds"
   - "This is bonus feature #2 for +1 mark"

7. **View Details (1 min):**
   - Click "Details"
   - "Shows all VM info, services, and users"

8. **Stop and Delete :**
   - Click "Stop" - status changes to STOPPED
   - Click "Delete" - confirm - VM removed



## 12. Project Deliverables

### Folder Structure for Submission

```
VirtualServerManager/
├── README.md                 ← Quick start guide
├── app.py                    ← Flask application
├── database.db              ← SQLite database
├── requirements.txt         ← Python dependencies
├── templates/
│   ├── index.html
│   ├── create.html
│   ├── details.html
│   └── monitor.html
├── scripts/
│   ├── create_vm.sh         ← Required
│   ├── destroy_vm.sh        ← Required
│   ├── install_service.sh   ← Required
│   ├── manage_users.sh      ← Required
│   ├── start_vm.sh
│   ├── stop_vm.sh
│   ├── clone_vm.sh          ← Bonus
│   └── get_vm_stats.sh      ← Bonus
└── VirtualServerManager_Documentation.pdf
```

### README.md Content

```markdown
# Virtual Server Manager

Web-based VirtualBox VM management system built with Flask.

## Features
- Create/Start/Stop/Delete VMs via web interface
- Real-time CPU and memory monitoring
- One-click VM cloning
- Automatic Debian ISO attachment
- Service and user management

## Requirements
- VirtualBox 7.x
- Python 3.9+
- Flask 3.1
- Debian ISO (~650 MB)

## Installation
1. Install VirtualBox: https://www.virtualbox.org/
2. Install Python: https://www.python.org/
3. Install Flask: `pip install flask`
4. Download Debian ISO to Downloads folder

## Running
```bash
cd VirtualServerManager
python app.py
```

Open browser: http://localhost:5000

## Usage
1. Click "+ New Server" to create VM
2. Fill form with specifications
3. Click "Create Server"
4. Use Start/Stop/Monitor/Clone/Delete buttons

## Technologies
- Backend: Python, Flask, SQLite
- Frontend: HTML, CSS, JavaScript
- Virtualization: VirtualBox, Bash scripts

## Author
Murenzi Charles
COSC 8312 - December 2025

**Name:** Murenzi Charles

**Student ID:** 27386

**Date:** 21 December 2025

---

## 15. Conclusion

Virtual Server Manager successfully delivers all project requirements plus two bonus features. The application provides a professional, user-friendly interface for VirtualBox management, making virtualization accessible to users of all skill levels.

**Key Learnings:**
- Integration across multiple technologies (Python, SQL, Bash, VirtualBox)
- Cross-platform compatibility challenges (Windows/Linux)
- Real-time web features with AJAX
- Production-ready error handling

---

## Appendix A: File Structure

```
VirtualServerManager/
├── app.py (550 lines)
├── database.db
├── templates/
│   ├── index.html (130 lines)
│   ├── create.html (150 lines)
│   ├── details.html (120 lines)
│   └── monitor.html (200 lines)
└── scripts/
    ├── create_vm.sh (120 lines)
    ├── start_vm.sh (40 lines)
    ├── stop_vm.sh (40 lines)
    ├── destroy_vm.sh (50 lines)
    ├── clone_vm.sh (70 lines)
    ├── get_vm_stats.sh (50 lines)
    ├── install_service.sh (45 lines)
    └── manage_users.sh (50 lines)

```

---

**[Add screenshots here during conversion to PDF]**

1. Dashboard with multiple VMs
2. Create form filled out
3. VirtualBox Manager showing VMs
4. Details page
5. Monitor page with live stats
6. Debian installer in VM window
7. Clone modal dialog
8. Success messages

---

*End of Documentation*








>>>>>>> 59a1e619a82efdc312c51743516001aa1566216b
