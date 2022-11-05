import os
from haystack.document_stores import ElasticsearchDocumentStore
from haystack.utils import convert_files_to_docs
from haystack.nodes import PreProcessor
from flask import Flask, request, jsonify, send_file, render_template
from werkzeug.utils import secure_filename

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
reader = FARMReader(model_name_or_path="deepset/roberta-large-squad2", use_gpu=True, return_no_answer=True)



from haystack.pipelines import ExtractiveQAPipeline

pipe = ExtractiveQAPipeline(reader, retriever)


app = Flask(__name__)

@app.route("/prediction", methods=["GET"])
def make_prediction():
    question = request.args.get('question')
    device = request.args.get('device')
    

    prediction = pipe.run(
        query=question,
        params={"Retriever": {"top_k": 10}, "Reader": {"top_k": 5}, "filters":{"device":[device]}}
    )
    return jsonify(prediction)


@app.route("/upload", methods=["POST"])
def upload():
    file = request.files["file"]
    filename = secure_filename(file.filename)
    doc_dir = "temp_data"
    file.save(os.path.join(doc_dir, filename))
    device = request.form["device"]

    all_docs = convert_files_to_docs(dir_path=doc_dir, clean_func = lambda x:x.replace("-\n", "").replace("\n"," "), split_paragraphs=True)

    for doc in all_docs:
        doc.meta['device'] = device

    preprocessor = PreProcessor(
        clean_empty_lines=True,
        clean_whitespace=True,
        clean_header_footer=False,
        split_by="word",
        split_length=200,
        split_overlap=30,
        split_respect_sentence_boundary=True,
        add_page_number=True
    )
    docs = preprocessor.process(all_docs)

    document_store.write_documents(docs)
    os.remove(os.path.join(doc_dir, filename))

    return "Successfully Uploaded"






