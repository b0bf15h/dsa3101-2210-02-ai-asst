queries = ["What is the intended use for this device?",
"What are contraindications for this device?"
"Who should not use this device?",
"What are the dimensions of the device?",
"What has this device been approved for?",
"Is the procedure minimally invasive?",
"What anesthesia does the procedure require?",
"When can patients stop taking blood thinners?",
"When can patients stop taking anticoagulants?",
"What is the success rate of the procedure?",
"What is the occurrence of pericardial effusions?",
"Trying to get no answer"]

devices = ["Watchman", "Atriclip", "Lariat"]

import logging

logging.basicConfig(format="%(levelname)s - %(name)s -  %(message)s", level=logging.WARNING)
logging.getLogger("haystack").setLevel(logging.INFO)



import os
from haystack.document_stores import ElasticsearchDocumentStore

# Get the host where Elasticsearch is running, default to localhost
host = os.environ.get("ELASTICSEARCH_HOST", "localhost")
document_store = ElasticsearchDocumentStore(host=host, username="", password="", index="document")


from haystack.nodes import BM25Retriever

retriever = BM25Retriever(document_store=document_store)



from haystack.nodes import FARMReader
# Load a  local model or any of the QA models on
# Hugging Face's model hub (https://huggingface.co/models)
reader = FARMReader(model_name_or_path="deepset/bert-large-uncased-whole-word-masking-squad2", use_gpu=True, return_no_answer=True)



from haystack.pipelines import ExtractiveQAPipeline

pipe = ExtractiveQAPipeline(reader, retriever)


output = dict()

for device in devices:
    output[device] = []
    for query in queries:

    prediction = pipe.run(
        query=query,
        params={"Retriever": {"top_k": 10}, "Reader": {"top_k": 5}, "filters":{"device":device}}
    )

    from haystack.utils import print_answers

    # Change `minimum` to `medium` or `all` to control the level of detail
    output[device].append(print_answers(prediction, details="all"))


import json
with open('outputs.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=4)