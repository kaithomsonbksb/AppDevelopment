from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import sqlite3

app = Flask(__name__)
CORS(app)

# Initialize DB
conn = sqlite3.connect("users.db", check_same_thread=False)
cursor = conn.cursor()
cursor.execute(
    """CREATE TABLE IF NOT EXISTS users (email TEXT PRIMARY KEY, password TEXT)"""
)
conn.commit()


@app.route("/", methods=["GET"])
def home():
    cursor.execute("SELECT email FROM users")
    users = cursor.fetchall()
    html = (
        """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Login Server Dashboard</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; justify-content: center; align-items: center; padding: 20px; }
            .container { background: white; border-radius: 10px; box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2); padding: 40px; max-width: 600px; width: 100%; }
            h1 { color: #333; margin-bottom: 10px; text-align: center; }
            .status { text-align: center; color: #666; margin-bottom: 30px; font-size: 14px; }
            .status.online { color: #27ae60; font-weight: bold; }
            .users-section { margin-top: 30px; }
            .users-section h2 { color: #555; font-size: 18px; margin-bottom: 15px; border-bottom: 2px solid #667eea; padding-bottom: 10px; }
            .user-list { list-style: none; }
            .user-item { background: #f8f9fa; padding: 12px 15px; margin-bottom: 8px; border-left: 4px solid #667eea; border-radius: 4px; display: flex; justify-content: space-between; align-items: center; }
            .user-email { color: #333; font-weight: 500; }
            .user-badge { background: #667eea; color: white; padding: 4px 10px; border-radius: 20px; font-size: 12px; }
            .empty-state { text-align: center; color: #999; padding: 20px; background: #f8f9fa; border-radius: 4px; }
            .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; text-align: center; color: #999; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🔐 Login Server</h1>
            <div class="status online">● Server is online</div>
            <div class="users-section">
                <h2>📊 Registered Users ("""
        + str(len(users))
        + """)</h2>
                <ul class="user-list">
    """
    )
    if users:
        for user in users:
            html += f"""
                <li class="user-item">
                    <span class="user-email">{user[0]}</span>
                    <span class="user-badge">Active</span>
                </li>
            """
    else:
        html += """
                <li class="empty-state">No users registered yet</li>
            """
    html += """
                </ul>
            </div>
            <div class="footer">
                <p>Use <strong>/signup</strong> (POST) and <strong>/login</strong> (POST) endpoints</p>
            </div>
        </div>
    </body>
    </html>
    """  # This html section is ai generated code
    return render_template_string(html)


@app.route("/signup", methods=["POST"])
def signup():
    data = request.json
    if not data:
        return jsonify({"error": "No JSON data provided"}), 400
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        return jsonify({"error": "Missing email or password"}), 400
    try:
        cursor.execute(
            "INSERT INTO users (email, password) VALUES (?, ?)", (email, password)
        )
        conn.commit()
        return jsonify({"message": "User created"}), 201
    except sqlite3.IntegrityError:
        return jsonify({"error": "User already exists"}), 409


@app.route("/login", methods=["POST"])
def login():
    data = request.json
    if not data:
        return jsonify({"error": "No JSON data provided"}), 400
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        return jsonify({"error": "Missing email or password"}), 400
    cursor.execute(
        "SELECT * FROM users WHERE email=? AND password=?", (email, password)
    )
    user = cursor.fetchone()
    if user:
        return jsonify({"message": "Login successful"}), 200
    else:
        return jsonify({"error": "Invalid credentials"}), 401


if __name__ == "__main__":
    app.run(host="192.168.1.91", port=5000)
