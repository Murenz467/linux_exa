import sqlite3

def init_db():
    connection = sqlite3.connect('database.db')
    
    with open('schema.sql') as f:
        connection.executescript(f.read())
    
    cur = connection.cursor()
    
    # Optional: Insert a dummy VM to test the display later
    cur.execute("INSERT INTO instances (name, os_type, cpu_cores, ram_size, storage_size, status) VALUES (?, ?, ?, ?, ?, ?)",
                ('Test-Server-01', 'Ubuntu', 2, 2048, 20, 'stopped')
                )
    
    connection.commit()
    connection.close()
    print("Database initialized successfully! 'database.db' created.")

if __name__ == "__main__":
    init_db()