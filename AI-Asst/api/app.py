from haystack.utils import launch_es

import os
from haystack.document_stores import ElasticsearchDocumentStore
from flask import Flask, request, jsonify, send_file, render_template

# Get the host where Elasticsearch is running, default to localhost
host = os.environ.get("ELASTICSEARCH_HOST", "localhost")
document_store = ElasticsearchDocumentStore(host=host, username="", password="", index="document")




from haystack.utils import convert_files_to_docs
from haystack.nodes import PreProcessor

devices = os.listdir("../../Modelling_Team/Datasets")

for device in devices:
    doc_dir = os.path.join("../../Modelling_Team/Datasets", device)

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



