import sqlite3

def migrate():
    conn = sqlite3.connect("speech_therapy.db")
    cursor = conn.cursor()
    try:
        cursor.execute("ALTER TABLE sessions ADD COLUMN topic TEXT;")
        print("topic column added.")
    except Exception as e:
        print("Error adding topic:", e)
        
    try:
        cursor.execute("ALTER TABLE sessions ADD COLUMN relevancy_score FLOAT;")
        print("relevancy_score column added.")
    except Exception as e:
        print("Error adding relevancy_score:", e)
        
    try:
        cursor.execute("ALTER TABLE sessions ADD COLUMN speech_score FLOAT;")
        print("speech_score column added.")
    except Exception as e:
        print("Error adding speech_score:", e)
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    migrate()
