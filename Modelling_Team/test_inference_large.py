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
reader = FARMReader(model_name_or_path="deepset/bert-large-uncased-whole-word-masking-squad2", use_gpu=True)



from haystack.pipelines import ExtractiveQAPipeline

pipe = ExtractiveQAPipeline(reader, retriever)



prediction = pipe.run(
    query="What are the risks of having a Watchman implant procedure?",
    params={"Retriever": {"top_k": 15}, "Reader": {"top_k": 5}, "filters":{"device":["Watchman"]}}
)



from haystack.utils import print_answers

# Change `minimum` to `medium` or `all` to control the level of detail
print_answers(prediction, details="all")