from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
app = Flask(__name__)
CORS(app)

@app.route("/status")
def status():
	return jsonify({"status": "ok", "message": "Server is running!"})

@app.route("/")
def helloworld():
	html_content = """
	<!DOCTYPE html>
	<html>
	<head>
		<title>My First Flask Page</title>
	</head>
	<body>
		<h1>Hello World!</h1>
		<p>Welcome to my Flask web app.</p>
	</body>
	</html>
	"""
	return render_template_string(html_content)

@app.route('/process', methods=['POST'])
def process():
	print("Received data:", request.json)
	data = request.json
	return jsonify({"success": True, "message": f"Hello {data['name']}! Data received successfully."})

if __name__ == '__main__':
	app.run(host='0.0.0.0', port=5000)
