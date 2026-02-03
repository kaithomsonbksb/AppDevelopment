# Coastline Perks Proof of Concept

## Project Overview
Coastline Perks is a native iOS app (SwiftUI, MVVM) with a Flask backend and SQLite database. Students can log in, view and redeem perks, and manage their entitlements. The app supports offline access to previously assigned perks and local management of saved perks/favourites.

## How to Run the Backend
1. Ensure you have Python 3.8+ and `venv` installed.
2. In the project root, create and activate a virtual environment:
	```
	python3 -m venv venv
	source venv/bin/activate
	```
3. Install requirements:
	```
	pip install flask flask-cors
	```
4. Run the backend server:
	```
	python3 surver.py
	```
	The server runs on `http://(current public ip):5000` by default. Update the host/port in `surver.py` if needed.

## How to Run the iOS App
1. Open the `uni app development.xcodeproj` in Xcode (v14+ recommended).
2. Select a simulator (e.g., iPhone 15) and build/run the app (Cmd+R).
3. Ensure your Mac and device/simulator are on the same network as the backend server.

## Test Credentials / Seeding
- To create a test account, use the Signup screen in the app.
- Assign perks by logging in and using the app UI. Perks are assigned locally and via the backend.
- No separate seed script is required; all data is created via the app or backend endpoints.

## How to Run Tests
1. In Xcode, open the Test Navigator (Cmd+6).
2. Select and run tests (Cmd+U). Ensure the test target is selected.

