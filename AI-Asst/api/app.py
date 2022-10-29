from haystack.utils import launch_es

import os
from haystack.document_stores import ElasticsearchDocumentStore
from flask import Flask, request, jsonify, send_file, render_template

import time
time.sleep(30)

# Get the host where Elasticsearch is running, default to localhost
host = os.environ.get("ELASTICSEARCH_HOST", "localhost")
document_store = ElasticsearchDocumentStore(host=host, username="", password="", index="document")


from haystack.nodes import BM25Retriever

retriever = BM25Retriever(document_store=document_store)



from haystack.nodes import FARMReader
# Load a  local model or any of the QA models on
# Hugging Face's model hub (https://huggingface.co/models)
reader = FARMReader(model_name_or_path="deepset/bert-large-uncased-whole-word-masking-squad2", use_gpu=True)



from haystack.pipelines import ExtractiveQAPipeline

pipe = ExtractiveQAPipeline(reader, retriever)


app = Flask(__name__)

@app.route("/prediction", methods=["GET"])
def make_prediction():
    question = request.args.get('question')
    device = request.args.get('device')
    

    prediction = pipe.run(
        query=question,
        params={"Retriever": {"top_k": 15}, "Reader": {"top_k": 5}, "filters":{"device":[device]}}
    )
    return jsonify(prediction)



