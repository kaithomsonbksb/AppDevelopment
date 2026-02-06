from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
import sqlite3

app = Flask(__name__)
CORS(app)

# Initialize DB
conn = sqlite3.connect("users.db", check_same_thread=False)
cursor = conn.cursor()
# Add credits column if missing
try:
    cursor.execute("ALTER TABLE users ADD COLUMN credits INTEGER DEFAULT 50")
except sqlite3.OperationalError:
    pass  # Column already exists
cursor.execute(
    """CREATE TABLE IF NOT EXISTS users (email TEXT PRIMARY KEY, password TEXT, credits INTEGER DEFAULT 50)"""
)
cursor.execute("""CREATE TABLE IF NOT EXISTS assignments (email TEXT, perk_id TEXT)""")
conn.commit()


@app.route("/assignments", methods=["GET"])
def assignments():
    email = request.args.get("email")
    if not email:
        return jsonify({"error": "Missing email"}), 400

    cursor.execute("SELECT 1 FROM users WHERE email=?", (email,))
    if cursor.fetchone() is None:
        return jsonify({"error": "User not found"}), 404

    cursor.execute("SELECT perk_id FROM assignments WHERE email=?", (email,))
    perks = [row[0] for row in cursor.fetchall()]
    return jsonify(sorted(perks)), 200


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
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                padding: 20px;
            }
            .container {
                background: white;
                border-radius: 10px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
                padding: 40px;
                max-width: 600px;
                width: 100%;
            }
            h1 {
                color: #333;
                margin-bottom: 10px;
                text-align: center;
            }
            .status {
                text-align: center;
                color: #666;
                margin-bottom: 30px;
                font-size: 14px;
            }
            .status.online { color: #27ae60; font-weight: bold; }
            .users-section {
                margin-top: 30px;
            }
            .users-section h2 {
                color: #555;
                font-size: 18px;
                margin-bottom: 15px;
                border-bottom: 2px solid #667eea;
                padding-bottom: 10px;
            }
            .user-list {
                list-style: none;
            }
            .user-item {
                background: #f8f9fa;
                padding: 12px 15px;
                margin-bottom: 8px;
                border-left: 4px solid #667eea;
                border-radius: 4px;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            .user-email {
                color: #333;
                font-weight: 500;
            }
            .user-actions {
                display: flex;
                gap: 8px;
            }
            .btn {
                padding: 6px 12px;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 12px;
                font-weight: 500;
                transition: all 0.3s ease;
            }
            .btn-edit {
                background: #3498db;
                color: white;
            }
            .btn-edit:hover {
                background: #2980b9;
            }
            .btn-delete {
                background: #e74c3c;
                color: white;
            }
            .btn-delete:hover {
                background: #c0392b;
            }
            .btn-clear {
                background: #e67e22;
                color: white;
                padding: 10px 20px;
                font-size: 14px;
                width: 100%;
                margin-top: 20px;
            }
            .btn-clear:hover {
                background: #d35400;
            }
            .empty-state {
                text-align: center;
                color: #999;
                padding: 20px;
                background: #f8f9fa;
                border-radius: 4px;
            }
            .footer {
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #eee;
                text-align: center;
                color: #999;
                font-size: 12px;
            }
            .modal {
                display: none;
                position: fixed;
                z-index: 1000;
                left: 0;
                top: 0;
                width: 100%;
                height: 100%;
                background-color: rgba(0, 0, 0, 0.5);
            }
            .modal-content {
                background-color: white;
                margin: 10% auto;
                padding: 30px;
                border-radius: 10px;
                width: 90%;
                max-width: 400px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
            }
            .modal-content h2 {
                margin-bottom: 20px;
                color: #333;
            }
            .modal-content input {
                width: 100%;
                padding: 10px;
                margin-bottom: 15px;
                border: 1px solid #ddd;
                border-radius: 4px;
                font-size: 14px;
            }
            .modal-buttons {
                display: flex;
                gap: 10px;
            }
            .modal-buttons button {
                flex: 1;
                padding: 10px;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-weight: 500;
            }
            .btn-save {
                background: #27ae60;
                color: white;
            }
            .btn-save:hover {
                background: #229954;
            }
            .btn-cancel {
                background: #95a5a6;
                color: white;
            }
            .btn-cancel:hover {
                background: #7f8c8d;
            }
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
                        <div class="user-actions">
                            <button class="btn btn-edit" onclick="openEditModal('{user[0]}')">Edit</button>
                            <button class="btn btn-delete" onclick="deleteUser('{user[0]}')">Delete</button>
                        </div>
                    </li>
            """
    else:
        html += """
                    <li class="empty-state">No users registered yet</li>
        """

    html += """
                </ul>
            </div>
            
            <button class="btn btn-clear" onclick="clearAllUsers()">Clear All Users</button>
            
            <div class="footer">
                <p>Use <strong>/signup</strong> (POST) and <strong>/login</strong> (POST) endpoints</p>
            </div>
        </div>

        <div id="editModal" class="modal">
            <div class="modal-content">
                <h2>Edit User</h2>
                <input type="hidden" id="editEmail" />
                <input type="password" id="newPassword" placeholder="New Password" />
                <div class="modal-buttons">
                    <button class="btn-save" onclick="saveEdit()">Save</button>
                    <button class="btn-cancel" onclick="closeEditModal()">Cancel</button>
                </div>
            </div>
        </div>

        <script>
            function openEditModal(email) {
                document.getElementById('editEmail').value = email;
                document.getElementById('newPassword').value = '';
                document.getElementById('editModal').style.display = 'block';
            }

            function closeEditModal() {
                document.getElementById('editModal').style.display = 'none';
            }

            function saveEdit() {
                const email = document.getElementById('editEmail').value;
                const newPassword = document.getElementById('newPassword').value;
                
                if (!newPassword) {
                    alert('Please enter a new password');
                    return;
                }

                fetch('/edit', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ email: email, password: newPassword })
                })
                .then(response => response.json())
                .then(data => {
                    alert(data.message || data.error);
                    location.reload();
                });
                closeEditModal();
            }

            function deleteUser(email) {
                if (confirm('Are you sure you want to delete this user?')) {
                    fetch('/delete', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ email: email })
                    })
                    .then(response => response.json())
                    .then(data => {
                        alert(data.message || data.error);
                        location.reload();
                    });
                }
            }

            function clearAllUsers() {
                if (confirm('Are you sure you want to clear ALL users? This cannot be undone.')) {
                    fetch('/clear', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' }
                    })
                    .then(response => response.json())
                    .then(data => {
                        alert(data.message || data.error);
                        location.reload();
                    });
                }
            }

            window.onclick = function(event) {
                const modal = document.getElementById('editModal');
                if (event.target == modal) {
                    modal.style.display = 'none';
                }
            }
        </script>
    </body>
    </html>
    """

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
            "INSERT INTO users (email, password, credits) VALUES (?, ?, ?)",
            (email, password, 50),
        )
        conn.commit()
        return jsonify({"message": "User signed up successfully"}), 200
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
        return jsonify({"error": "Invalid email or password"}), 401


@app.route("/clear", methods=["POST"])
def clear():
    cursor.execute("DELETE FROM users")
    conn.commit()
    return jsonify({"message": "All user data cleared"}), 200


@app.route("/delete", methods=["POST"])
def delete():
    data = request.json
    if not data:
        return jsonify({"error": "No JSON data provided"}), 400
    email = data.get("email")
    if not email:
        return jsonify({"error": "Missing email"}), 400
    cursor.execute("DELETE FROM users WHERE email=?", (email,))
    conn.commit()
    return jsonify({"message": "User deleted"}), 200


@app.route("/edit", methods=["POST"])
def edit():
    data = request.json
    if not data:
        return jsonify({"error": "No JSON data provided"}), 400
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        return jsonify({"error": "Missing email or password"}), 400
    cursor.execute("UPDATE users SET password=? WHERE email=?", (password, email))
    conn.commit()
    return jsonify({"message": "User password updated"}), 200


@app.route("/balance", methods=["GET"])
def balance():
    email = request.args.get("email")
    if not email:
        return jsonify({"error": "Missing email"}), 400
    cursor.execute("SELECT credits FROM users WHERE email=?", (email,))
    row = cursor.fetchone()
    if row:
        return jsonify({"balance": row[0]}), 200
    else:
        return jsonify({"error": "User not found"}), 404


@app.route("/add_perk", methods=["POST"])
def add_perk():
    data = request.json
    if not data:
        return jsonify({"error": "No JSON data provided"}), 400
    email = data.get("email")
    perk_id = data.get("perk_id")
    if not email or not perk_id:
        return jsonify({"error": "Missing email or perk_id"}), 400
    cost = 10
    cursor.execute("SELECT credits FROM users WHERE email=?", (email,))
    row = cursor.fetchone()
    if not row:
        return jsonify({"error": "User not found"}), 404
    balance = row[0]
    if balance < cost:
        return jsonify({"error": "Insufficient balance"}), 400
    # Check if user already has this perk
    cursor.execute(
        "SELECT 1 FROM assignments WHERE email=? AND perk_id=?", (email, perk_id)
    )
    if cursor.fetchone():
        return jsonify({"error": "Perk already assigned to user"}), 409
    # Deduct credits
    cursor.execute(
        "UPDATE users SET credits = credits - ? WHERE email=?", (cost, email)
    )
    # Assign the perk to the user
    cursor.execute(
        "INSERT INTO assignments (email, perk_id) VALUES (?, ?)", (email, perk_id)
    )
    conn.commit()
    cursor.execute("SELECT credits FROM users WHERE email=?", (email,))
    new_balance = cursor.fetchone()[0]
    return jsonify({"message": "Perk added", "balance": new_balance}), 200


# Health check endpoint
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="192.168.1.151", port=5000)
