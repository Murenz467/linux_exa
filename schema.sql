DROP TABLE IF EXISTS instances;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS vm_users;

-- Table to store VM details
CREATE TABLE instances (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    os_type TEXT NOT NULL,
    cpu_cores INTEGER NOT NULL,
    ram_size INTEGER NOT NULL,
    storage_size INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'stopped', -- running, stopped
    ip_address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table to store services installed on VMs (e.g., Nginx, Docker)
CREATE TABLE services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vm_id INTEGER NOT NULL,
    service_name TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    installed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vm_id) REFERENCES instances (id) ON DELETE CASCADE
);

-- Table to store users created inside the VMs
CREATE TABLE vm_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vm_id INTEGER NOT NULL,
    username TEXT NOT NULL,
    has_sudo BOOLEAN NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vm_id) REFERENCES instances (id) ON DELETE CASCADE
);