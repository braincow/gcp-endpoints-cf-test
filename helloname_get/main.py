from flask import jsonify

def helloname_get(request):
    # since openapi definition makes sure that we have the argument name in place
    #  we do not enforce its presence and fail here if it is not defined
    name = request.args["name"]
    return jsonify({"message": "Hello {}!".format(name)})
