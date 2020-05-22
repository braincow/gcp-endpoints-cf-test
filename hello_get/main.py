from flask import jsonify

def hello_get(request):
    return jsonify({"message": "Hello World!"})
