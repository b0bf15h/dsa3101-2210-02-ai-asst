from flask import Flask,request
app = Flask(__name__)

@app.route("/prediction", methods=["GET"])
def make_prediction():
    return 'hi'

